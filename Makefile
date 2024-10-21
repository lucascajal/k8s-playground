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
	kind create cluster --name my-cluster --config=cluster-config.yaml

	@echo "$(shell date -u +'%Y-%m-%dT%H:%M:%SZ') - setting up ingress controler"
	kubectl apply -k ingress-nginx/

	@echo "$(shell date -u +'%Y-%m-%dT%H:%M:%SZ') - setting up namespaces for each environment"
	kubectl apply -k namespaces/

	@$(MAKE) -f $(THIS_FILE) tunnel
	# @$(MAKE) -f $(THIS_FILE) dashboard

.PHONY: destroy
destroy: ## Destroys Kind Cluster
	$(info $(DATE) - destroying cluster)
	@$(MAKE) -f $(THIS_FILE) tunnel_delete
	kind delete cluster --name my-cluster

#################### TUNNEL CLOUDFLARED ####################
# Prerequisites: install cloudflared, run `cloudflared tunnel login`

.PHONY: tunnel
tunnel: ## Set up Cloudflared Tunnel
	$(info $(DATE) - creating cloudflared tunnel)
	@cert_path=$$(cloudflared tunnel create k8s-tunnel | sed -n 's/^Tunnel credentials written to \(.*\.json\).*/\1/p') && \
		mv $$cert_path cloudflared/credentials.json
	@echo "$(shell date -u +'%Y-%m-%dT%H:%M:%SZ') - adding DNS record"
	@cloudflared tunnel route dns --overwrite-dns k8s-tunnel "*"
	@echo "$(shell date -u +'%Y-%m-%dT%H:%M:%SZ') - deploying cloudflared tunnel"
	@kubectl apply -k cloudflared

.PHONY: tunnel_delete
tunnel_delete: ## Delete Cloudflared Tunnel
	$(info $(DATE) - deleting cloudflared tunnel)
	@kubectl delete -k cloudflared --ignore-not-found
	cloudflared tunnel cleanup k8s-tunnel
	cloudflared tunnel delete k8s-tunnel
	rm -f cloudflared/credentials.json

#################### DASHBOARD ####################
.PHONY: dashboard
dashboard: ## Set up Kubernetes Dashboard
	$(info $(DATE) - creating Kubernetes Dashboard)

	helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
	helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace kubernetes-dashboard

	@echo "$(shell date -u +'%Y-%m-%dT%H:%M:%SZ') - creating dashboard admin user ServiceAccount"
	kubectl apply -f dashboard-adminuser.yaml

.PHONY: dashboard_open
dashboard_open: ## Open Kubernetes Dashboard
	$(info $(DATE) - opening Kubernetes Dashboard)
	kubectl -n kubernetes-dashboard port-forward svc/kubernetes-dashboard-kong-proxy 8443:443 & 
	open https://localhost:8443

#################### APP DEPLOYMENT ####################
.PHONY: deploy
deploy: ## Deploy app
	$(info $(DATE) - creating app '$(app)')
	kubectl apply -k ./apps/$(app)/base

.PHONY: delete
delete: ## Delete app
	$(info $(DATE) - deleting app '$(app)')
	kubectl delete -k ./apps/$(app)/base


#################### APP DEPLOYMENT  WITH OVERLAYS (ENVs) ####################
.PHONY: deploy_overlay
deploy_overlay: ## Deploy app with overlays
	$(info $(DATE) - deploying app '$(app)' in env=$(env))
	kubectl apply -k ./apps/$(app)/overlays/$(env)

.PHONY: delete_overlay
delete_overlay: ## Delete app with overlays
	$(info $(DATE) - deleting app '$(app)' in env=$(env))
	kubectl delete -k ./apps/$(app)/overlays/$(env)