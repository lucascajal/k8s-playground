.DEFAULT_GOAL := help

PATH          := $(PATH):$(PWD)/bin
OS            := $(shell uname -s | tr '[:upper:]' '[:lower:]' | sed 's/darwin/apple-darwin/' | sed 's/linux/linux-gnu/')
ARCH          := $(shell uname -m)
DATE          := $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
SHELL         := bash

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

.PHONY: destroy
destroy: ## Destroys Kind Cluster
	$(info $(DATE) - destroying cluster)
	kind delete cluster --name my-cluster

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