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
	@kind create cluster --name my-cluster --config=cluster-config.yaml

	@$(MAKE) -f $(THIS_FILE) tunnel
	@$(MAKE) -f $(THIS_FILE) argocd

.PHONY: destroy
destroy: ## Destroys Kind Cluster
	$(info $(DATE) - destroying cluster)
	@$(MAKE) -f $(THIS_FILE) tunnel_delete
	@kind delete cluster --name my-cluster

#################### CLOUDFLARED TUNNEL ####################
# Prerequisites: install cloudflared, run `cloudflared tunnel login`
.PHONY: tunnel
tunnel: ## Set up Cloudflared Tunnel
	$(info $(DATE) - creating cloudflared tunnel)
	@cert_path=$$(cloudflared tunnel create k8s-tunnel | sed -n 's/^Tunnel credentials written to \(.*\.json\).*/\1/p') && \
		mv $$cert_path cloudflared/secrets/credentials.json

	@echo "$(shell date -u +'%Y-%m-%dT%H:%M:%SZ') - adding DNS record"
	@cloudflared tunnel route dns --overwrite-dns k8s-tunnel "*.lucascajal.com"

	@echo "$(shell date -u +'%Y-%m-%dT%H:%M:%SZ') - creating cloudflared secrets"
	@kubectl apply -k cloudflared/secrets

.PHONY: tunnel_delete
tunnel_delete: ## Delete Cloudflared Tunnel
	$(info $(DATE) - deleting cloudflared tunnel)
	@kubectl delete -k cloudflared/secrets
	@rm -f cloudflared/secrets/credentials.json
	@cloudflared tunnel cleanup k8s-tunnel
	@sleep 5
	@cloudflared tunnel delete k8s-tunnel

#################### ARGO CD ####################
.PHONY: argocd
argocd: ## Set up ArgoCD
	$(info $(DATE) - setting up ArgoCD)
	@kubectl apply -k argocd/
	@kubectl apply -k argocd/secrets/
	@echo "$(shell date -u +'%Y-%m-%dT%H:%M:%SZ') - waiting for argocd-server to be up..."
	@sleep 10
	@kubectl wait --for=condition=Ready pods -l app.kubernetes.io/name=argocd-server -n argocd --timeout=600s

	@kubectl apply -k argocd-resources/

	@sleep 30
	@kubectl patch -n argocd app argocd --patch-file argocd-resources/installation/sync-hook.yaml --type merge
	@kubectl patch -n argocd app ingress-nginx --patch-file argocd-resources/installation/sync-hook.yaml --type merge
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
	@kubectl delete -k argocd/
