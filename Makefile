.DEFAULT_GOAL := help

PATH          := $(PATH):$(PWD)/bin
OS            := $(shell uname -s | tr '[:upper:]' '[:lower:]' | sed 's/darwin/apple-darwin/' | sed 's/linux/linux-gnu/')
ARCH          := $(shell uname -m)
DATE          := $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
SHELL         := bash
THIS_FILE	  := $(lastword $(MAKEFILE_LIST))

# .POSIX:

.PHONY: help
help: ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m\033[0m\n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

#################### CLUSTER MANAGEMENT ####################
k8s_distribution ?= k3s

K3S_KUBE_CONFIG ?= $(CURDIR)/k3s_kubeconfig.yaml
K3S_VERSION := v1.33.3+k3s1

# Select cluster implementation based on k8s_distribution
ifeq ($(k8s_distribution),k3s)
CLUSTER_TARGET := cluster_k3s
DESTROY_TARGET := destroy_k3s
KUBECTL := kubectl --kubeconfig $(K3S_KUBE_CONFIG)
$(info Using '$(k8s_distribution)' as a Kubernetes distribution)
else ifeq ($(k8s_distribution),kind)
CLUSTER_TARGET := cluster_kind
DESTROY_TARGET := destroy_kind
KUBECTL := kubectl
$(info Using '$(k8s_distribution)' as a Kubernetes distribution)
else
$(error Unknown k8s_distribution '$(k8s_distribution)'. Use 'k3s' or 'kind')
endif

.PHONY: cluster
cluster: ## Create a cluster (k3s by default)
	@$(MAKE) -f $(THIS_FILE) $(CLUSTER_TARGET)
	@$(MAKE) -f $(THIS_FILE) terraform
	@$(MAKE) -f $(THIS_FILE) argocd

.PHONY: destroy
destroy: ## Destroy a cluster (k3s by default)
	@$(MAKE) -f $(THIS_FILE) $(DESTROY_TARGET)
	@sleep 60
	@$(MAKE) -f $(THIS_FILE) terraform_destroy

.PHONY: cluster_k3s
cluster_k3s: ## Creates K3s Cluster. Following https://docs.k3s.io/quick-start
	$(info $(DATE) - creating k3s cluster)
	@curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=$(K3S_VERSION) sh -s - \
		--write-kubeconfig $(K3S_KUBE_CONFIG) \
		--write-kubeconfig-mode 644 \
		--config $(CURDIR)/cluster-k3s-config.yaml
	# cat ./k3s_kubeconfig.yaml > ~/.kube/config
	# To add new nodes: sudo cat /var/lib/rancher/k3s/server/node-token
	# 	curl -sfL https://get.k3s.io | \
	# 		INSTALL_K3S_VERSION=$(K3S_VERSION) \
	# 		K3S_URL=https://192.168.1.140:6443 \
	# 		K3S_TOKEN=<token> sh -

.PHONY: destroy_k3s
destroy_k3s: ## Destroys K3s Cluster. https://docs.k3s.io/installation/uninstall
	$(info $(DATE) - destroying k3s cluster)
	@/usr/local/bin/k3s-uninstall.sh

.PHONY: cluster_kind
cluster_kind: ## Creates Kind Cluster. Following https://kind.sigs.k8s.io/docs/user/ingress/
	$(info $(DATE) - creating kind cluster)
	@kind create cluster --name pi5 --config=cluster-config.yaml
	# sudo cat /root/.kube/config > ~/.kube/config

.PHONY: destroy_kind
destroy_kind: ## Destroys Kind Cluster & terraform resources
	$(info $(DATE) - destroying kind cluster)
	@kind delete cluster --name pi5

#################### TERRAFORM ####################
.PHONY: terraform
terraform: ## Create infrastructure: cloudflare tunnel, bitwarden vault, etc.
	$(info $(DATE) - creating terraform resources)
	@terraform -chdir=terraform apply -auto-approve

	@echo "Creating secret 'bitwarden-access-token' in namespace 'external-secrets'..."
	@$(KUBECTL) get namespace external-secrets >/dev/null 2>&1 || $(KUBECTL) create namespace external-secrets
	@$(KUBECTL) create secret generic bitwarden-access-token \
		--from-literal=token=$$(terraform -chdir=terraform output -json | jq -r '.bitwarden_token.value') \
		--namespace=external-secrets

.PHONY: terraform_destroy
terraform_destroy: ## Delete infrastructure: cloudflare tunnel, bitwarden vault, etc.
	$(info $(DATE) - destroying terraform resources)
	@terraform -chdir=terraform destroy -auto-approve

#################### ARGO CD ####################
.PHONY: argocd
argocd: ## Set up ArgoCD
	$(info $(DATE) - setting up ArgoCD)
	@$(KUBECTL) apply -k argocd/base/
	@echo "$(shell date -u +'%Y-%m-%dT%H:%M:%SZ') - waiting for argocd-server to be up..."
	@sleep 10
	@$(KUBECTL) wait --for=condition=Ready pods -l app.kubernetes.io/name=argocd-server -n argocd --timeout=600s

	@$(KUBECTL) apply -k argocd-resources/

	@sleep 30
	# @$(KUBECTL) patch -n argocd app argocd --patch-file argocd-resources/installation/sync-hook.yaml --type merge
	# @$(KUBECTL) patch -n argocd app ingress-nginx --patch-file argocd-resources/installation/sync-hook.yaml --type merge
	@echo "$(shell date -u +'%Y-%m-%dT%H:%M:%SZ') - waiting for ingress controler to be synced..."
	@$(KUBECTL) wait --for=jsonpath='{.status.sync.status}'=Synced applications.argoproj.io ingress-nginx -n argocd --timeout=600s

.PHONY: argocd_delete
argocd_delete: ## Delete ArgoCD
	$(info $(DATE) - deleting up ArgoCD)
	@$(KUBECTL) delete -k argocd-resources/
	@$(KUBECTL) delete -k argocd/base/
