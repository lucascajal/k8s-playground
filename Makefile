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

.PHONY: cluster
cluster: ## Creates Kind Cluster. Following https://kind.sigs.k8s.io/docs/user/ingress/
	$(info $(DATE) - creating cluster)
	@kind create cluster --name pi5 --config=cluster-config.yaml

	@$(MAKE) -f $(THIS_FILE) terraform
	@$(MAKE) -f $(THIS_FILE) argocd

# sudo cat /root/.kube/config > ~/.kube/config

.PHONY: destroy
destroy: ## Destroys Kind Cluster & terraform resources
	$(info $(DATE) - destroying ArgoCD resources)
	$(info $(DATE) - destroying cluster)
	@kind delete cluster --name pi5
	@sleep 30
	$(info $(DATE) - destroying terraform resources)
	@terraform -chdir=terraform destroy -auto-approve

#################### TERRAFORM ####################
.PHONY: terraform
terraform: ## Create infrastructure: cloudflare tunnel, bitwarden vault, etc.
	terraform -chdir=terraform apply -auto-approve

	@echo "Creating secret 'bitwarden-access-token' in namespace 'external-secrets'..."
	@kubectl get namespace external-secrets >/dev/null 2>&1 || kubectl create namespace external-secrets
	@kubectl create secret generic bitwarden-access-token \
		--from-literal=token=$$(terraform -chdir=terraform output -json | jq -r '.bitwarden_token.value') \
		--namespace=external-secrets

#################### ARGO CD ####################
.PHONY: argocd
argocd: ## Set up ArgoCD
	$(info $(DATE) - setting up ArgoCD)
	@kubectl apply -k argocd/base/
	@echo "$(shell date -u +'%Y-%m-%dT%H:%M:%SZ') - waiting for argocd-server to be up..."
	@sleep 10
	@kubectl wait --for=condition=Ready pods -l app.kubernetes.io/name=argocd-server -n argocd --timeout=600s

	@kubectl apply -k argocd-resources/

	@sleep 30
	# @kubectl patch -n argocd app argocd --patch-file argocd-resources/installation/sync-hook.yaml --type merge
	# @kubectl patch -n argocd app ingress-nginx --patch-file argocd-resources/installation/sync-hook.yaml --type merge
	@echo "$(shell date -u +'%Y-%m-%dT%H:%M:%SZ') - waiting for ingress controler to be synced..."
	@kubectl wait --for=jsonpath='{.status.sync.status}'=Synced applications.argoproj.io ingress-nginx -n argocd --timeout=600s

.PHONY: argocd_creds
argocd_creds: ## Get ArgoCD admin login
	@echo "===== ArgoCD Initial credentials ====="
	@echo "Username: admin"
	@echo "Password: $$(kubectl get secrets argocd-initial-admin-secret -o jsonpath='{.data.password}' -n argocd | base64 -d)"
	@echo "======================================"

.PHONY: argocd_delete
argocd_delete: ## Delete ArgoCD
	$(info $(DATE) - deleting up ArgoCD)
	@kubectl delete -k argocd-resources/
	@kubectl delete -k argocd/base/
