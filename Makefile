.PHONY: help setup build push build-push dev-paas dev-iaas prod-paas prod-iaas validate plan-paas plan-iaas destroy-dev destroy-prod import-state test logs clean

# Colors
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

# Configuration
ENV ?= dev
DOCKER_TAG ?= latest

help: ## Afficher l'aide
	@echo "$(BLUE)╔══════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║         TERRACLOUD - Makefile Commands                  ║$(NC)"
	@echo "$(BLUE)╚══════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(GREEN)Setup & Configuration:$(NC)"
	@grep -E '^setup.*:.*##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*##"}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(GREEN)Docker:$(NC)"
	@grep -E '^(build|push|build-push).*:.*##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*##"}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(GREEN)Development (dev):$(NC)"
	@grep -E '^dev-.*:.*##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*##"}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(GREEN)Production (prod):$(NC)"
	@grep -E '^prod-.*:.*##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*##"}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(GREEN)Infrastructure:$(NC)"
	@grep -E '^(validate|plan-.*|destroy-.*|import-.*).*:.*##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*##"}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(GREEN)Utilities:$(NC)"
	@grep -E '^(test|logs|clean).*:.*##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*##"}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(BLUE)Examples:$(NC)"
	@echo "  make setup              # Setup environment"
	@echo "  make build-push         # Build and push Docker image"
	@echo "  make dev-paas           # Deploy PaaS to dev"
	@echo "  make dev-iaas           # Deploy IaaS to dev"
	@echo "  make prod-paas          # Deploy PaaS to prod"
	@echo ""

# Setup & Configuration
setup: ## Installer toutes les dépendances et configurer l'environnement
	@echo "$(BLUE)→ Setting up environment...$(NC)"
	@chmod +x scripts/*.sh scripts/common/*.sh
	@./scripts/setup-environment.sh

# Docker
build: ## Build Docker image (ENV=dev|prod, TAG=custom)
	@echo "$(BLUE)→ Building Docker image for $(ENV)...$(NC)"
	@./scripts/build-push-image.sh $(ENV) $(DOCKER_TAG) --build-only || true

push: ## Push Docker image to ACR (ENV=dev|prod)
	@echo "$(BLUE)→ Pushing Docker image for $(ENV)...$(NC)"
	@cd sample-app-master && docker push $$(cat .docker-image-name 2>/dev/null || echo "tcdevacrfrc01.azurecr.io/sample-app:latest")

build-push: ## Build et push Docker image (ENV=dev|prod)
	@echo "$(BLUE)→ Building and pushing Docker image for $(ENV)...$(NC)"
	@./scripts/build-push-image.sh $(ENV) $(DOCKER_TAG)

# Development Deployments
dev-paas: ## Déployer PaaS en dev
	@echo "$(BLUE)→ Deploying PaaS to dev...$(NC)"
	@./scripts/deploy-paas.sh dev

dev-iaas: ## Déployer IaaS en dev
	@echo "$(BLUE)→ Deploying IaaS to dev...$(NC)"
	@./scripts/deploy-iaas.sh dev

dev-iaas-no-https: ## Déployer IaaS en dev sans HTTPS
	@echo "$(BLUE)→ Deploying IaaS to dev (no HTTPS)...$(NC)"
	@SETUP_HTTPS=false ./scripts/deploy-iaas.sh dev

# Production Deployments
prod-paas: ## Déployer PaaS en production
	@echo "$(RED)→ Deploying PaaS to PRODUCTION...$(NC)"
	@./scripts/deploy-paas.sh prod

prod-iaas: ## Déployer IaaS en production
	@echo "$(RED)→ Deploying IaaS to PRODUCTION...$(NC)"
	@./scripts/deploy-iaas.sh prod

prod-iaas-no-https: ## Déployer IaaS en production sans HTTPS
	@echo "$(RED)→ Deploying IaaS to PRODUCTION (no HTTPS)...$(NC)"
	@SETUP_HTTPS=false ./scripts/deploy-iaas.sh prod

# Infrastructure Management
validate: ## Valider la syntaxe Terraform
	@echo "$(BLUE)→ Validating Terraform...$(NC)"
	@cd terraform && terraform init -backend=false && terraform validate

plan-paas: ## Plan PaaS (ENV=dev|prod)
	@echo "$(BLUE)→ Planning PaaS for $(ENV)...$(NC)"
	@DRY_RUN=true ./scripts/deploy-paas.sh $(ENV)

plan-iaas: ## Plan IaaS (ENV=dev|prod)
	@echo "$(BLUE)→ Planning IaaS for $(ENV)...$(NC)"
	@DRY_RUN=true ./scripts/deploy-iaas.sh $(ENV)

destroy-dev: ## Détruire l'environnement dev (COMPONENT=paas|iaas|all)
	@echo "$(YELLOW)→ Destroying dev environment...$(NC)"
	@./scripts/destroy-environment.sh dev $(COMPONENT)

destroy-prod: ## Détruire l'environnement prod (COMPONENT=paas|iaas|all)
	@echo "$(RED)→ Destroying PRODUCTION environment...$(NC)"
	@./scripts/destroy-environment.sh prod $(COMPONENT)

import-state: ## Importer les ressources existantes dans le state Terraform (ENV=dev|prod)
	@echo "$(BLUE)→ Importing existing resources into Terraform state...$(NC)"
	@chmod +x scripts/import-existing-resources.sh
	@./scripts/import-existing-resources.sh $(ENV)

# Testing
test: ## Exécuter les tests (ENV=dev|prod, TYPE=paas|iaas|all)
	@echo "$(BLUE)→ Running tests...$(NC)"
	@if [ "$(TYPE)" = "paas" ] || [ "$(TYPE)" = "all" ]; then \
		./tests/test-paas.sh $(ENV); \
	fi
	@if [ "$(TYPE)" = "iaas" ] || [ "$(TYPE)" = "all" ]; then \
		./tests/test-iaas.sh $(ENV); \
	fi

test-paas: ## Tester PaaS (ENV=dev|prod)
	@echo "$(BLUE)→ Testing PaaS...$(NC)"
	@./tests/test-paas.sh $(ENV)

test-iaas: ## Tester IaaS (ENV=dev|prod)
	@echo "$(BLUE)→ Testing IaaS...$(NC)"
	@./tests/test-iaas.sh $(ENV)

test-https: ## Tester HTTPS/SSL
	@echo "$(BLUE)→ Testing HTTPS/SSL...$(NC)"
	@./tests/test-https.sh

test-db: ## Tester connectivité base de données
	@echo "$(BLUE)→ Testing database...$(NC)"
	@./tests/test-database.sh $(ENV)

# Logs & Monitoring
logs-paas: ## Voir les logs App Service (ENV=dev|prod)
	@echo "$(BLUE)→ Fetching PaaS logs...$(NC)"
	@if [ "$(ENV)" = "prod" ]; then \
		az webapp log tail --name tc-prod-web-frc-01 --resource-group rg-nan_1; \
	else \
		az webapp log tail --name tc-dev-web-frc-01 --resource-group rg-nan_1; \
	fi

logs-iaas: ## Voir les logs VMSS/containers (ENV=dev|prod)
	@echo "$(BLUE)→ Fetching IaaS logs...$(NC)"
	@cd ansible && ansible all -i inventory/static.yml -m shell -a 'docker logs laravel-app --tail 50' -b

ssh-paas: ## SSH vers App Service (ENV=dev|prod)
	@echo "$(BLUE)→ Connecting to PaaS via SSH...$(NC)"
	@if [ "$(ENV)" = "prod" ]; then \
		az webapp ssh --name tc-prod-web-frc-01 --resource-group rg-nan_1; \
	else \
		az webapp ssh --name tc-dev-web-frc-01 --resource-group rg-nan_1; \
	fi

ssh-iaas: ## SSH vers premier instance VMSS (ENV=dev|prod)
	@echo "$(BLUE)→ Connecting to IaaS via SSH...$(NC)"
	@IP=$$(az vmss list-instance-public-ips \
		--name tc-$(ENV)-vmss-frc-01 \
		--resource-group rg-nan_1 \
		--query "[0].ipAddress" -o tsv 2>/dev/null); \
	ssh -i ~/.ssh/id_ed25519 azureuser@$$IP

# Utilities
clean: ## Nettoyer les fichiers temporaires
	@echo "$(BLUE)→ Cleaning temporary files...$(NC)"
	@find . -type f -name "*.tfplan" -delete
	@find . -type f -name "*.retry" -delete
	@find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	@echo "$(GREEN)✓ Cleaned$(NC)"

fmt: ## Formater le code Terraform
	@echo "$(BLUE)→ Formatting Terraform...$(NC)"
	@cd terraform && terraform fmt -recursive
	@echo "$(GREEN)✓ Formatted$(NC)"

status: ## Afficher le statut des ressources (ENV=dev|prod)
	@echo "$(BLUE)→ Checking status for $(ENV)...$(NC)"
	@echo ""
	@echo "$(YELLOW)PaaS (App Service):$(NC)"
	@az webapp show \
		--name tc-$(ENV)-web-frc-01 \
		--resource-group rg-nan_1 \
		--query "{Name:name, State:state, URL:defaultHostName}" -o table 2>/dev/null || echo "Not deployed"
	@echo ""
	@echo "$(YELLOW)IaaS (VMSS):$(NC)"
	@az vmss list-instances \
		--name tc-$(ENV)-vmss-frc-01 \
		--resource-group rg-nan_1 \
		--query "[].{Name:name, State:provisioningState, PowerState:instanceView.statuses[1].displayStatus}" -o table 2>/dev/null || echo "Not deployed"
	@echo ""
	@echo "$(YELLOW)MySQL:$(NC)"
	@az mysql flexible-server show \
		--name tc-$(ENV)-mysql-frc-01 \
		--resource-group rg-nan_1 \
		--query "{Name:name, State:state, Version:version}" -o table 2>/dev/null || echo "Not deployed"

urls: ## Afficher les URLs d'accès (ENV=dev|prod)
	@echo "$(BLUE)╔══════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║         Application URLs - $(ENV)                           $(NC)"
	@echo "$(BLUE)╚══════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(GREEN)PaaS (App Service):$(NC)"
	@APP_URL=$$(az webapp show --name tc-$(ENV)-web-frc-01 --resource-group rg-nan_1 --query "defaultHostName" -o tsv 2>/dev/null); \
	if [ -n "$$APP_URL" ]; then echo "  https://$$APP_URL"; else echo "  Not deployed"; fi
	@echo ""
	@echo "$(GREEN)IaaS (VMSS):$(NC)"
	@az vmss list-instance-public-ips --name tc-$(ENV)-vmss-frc-01 --resource-group rg-nan_1 --query "[].ipAddress" -o tsv 2>/dev/null | \
	while read ip; do echo "  http://$$ip"; done || echo "  Not deployed"
	@if [ "$(ENV)" = "dev" ]; then \
		echo ""; \
		echo "$(GREEN)HTTPS (Domain):$(NC)"; \
		echo "  https://epi-clo.axel-martin.fr"; \
	fi
	@echo ""

info: ## Afficher les informations du projet
	@echo "$(BLUE)╔══════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║         TERRACLOUD Project Information                  ║$(NC)"
	@echo "$(BLUE)╚══════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(GREEN)Project:$(NC) TERRACLOUD"
	@echo "$(GREEN)Subscription:$(NC) 6b9318b1-2215-418a-b0fd-ba0832e9b333"
	@echo "$(GREEN)Resource Group:$(NC) rg-nan_1"
	@echo "$(GREEN)Location:$(NC) France Central"
	@echo ""
	@echo "$(GREEN)Environments:$(NC)"
	@echo "  • dev  - Development (cost-optimized)"
	@echo "  • prod - Production (high-availability)"
	@echo ""
	@echo "$(GREEN)Deployment Types:$(NC)"
	@echo "  • PaaS - Azure App Service + ACR"
	@echo "  • IaaS - VMSS + Docker + Ansible"
	@echo ""
	@echo "$(GREEN)Documentation:$(NC)"
	@echo "  • README.md"
	@echo "  • docs/ci-cd.md"
	@echo "  • docs/scripts.md"
	@echo "  • .github/workflows/README.md"
	@echo ""

# Special targets
.DEFAULT_GOAL := help

