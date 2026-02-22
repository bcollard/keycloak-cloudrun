# Makefile for Keycloak on Cloud Run with Terraform
.ONESHELL:
.DEFAULT_GOAL := help
.PHONY: help gcloud-login tfv tfi tfp tfa tfd server-cert keycloak-build

help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'


gcloud-login: ## Authenticate with Google Cloud (User and Application Default)
	@gcloud config configurations activate kong
	@gcloud auth application-default login

tfi: ## init Terraform
	@echo "Initializing Terraform..."
	@terraform init

tfp: ## plan Terraform
	@echo "Planning Terraform..."
	@terraform plan

tfa: ## apply Terraform
	@echo "Applying Terraform..."
	@terraform apply

tfd: ## destroy Terraform
	@echo "Destroying Terraform..."
	@terraform destroy

server-cert: ## exec glb-wildcard-cert.sh to create a wildcard certificate for the load balancer (requires DNS_ZONE_NAME, GCP_PROJECT_DNS, GCP_CREDENTIALS_FILE)
	@echo "Creating wildcard certificate for load balancer..."; \
	DNS_ZONE_NAME="$(DNS_ZONE_NAME)" ./glb-wildcard-cert.sh

keycloak-build: ## prompt for Keycloak version and update KEYCLOAK_VERSION (requires gum)
	@./scripts/set-keycloak-version.sh

