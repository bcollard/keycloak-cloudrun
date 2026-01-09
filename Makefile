# Makefile for Keycloak on Cloud Run with Terraform
.ONESHELL:
.DEFAULT_GOAL := help
.PHONY: help gcloud-login tfv tfi tfp tfa tfd

# Configuration
REGION ?= europe-west9
BRANCH ?= main


help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'


gcloud-login: ## Authenticate with Google Cloud (User and Application Default)
	@gcloud config configurations activate kong
	@gcloud auth application-default login

tfv: ## initialize Terraform variables (.tfvars file)
	@echo "Initializing the .tfvars file..."
	./init-tf-scripts.sh

tfi: ## init Terraform
	@echo "Initializing Terraform..."
	@terraform init

tfp: ## plan Terraform
	@echo "Planning Terraform..."
	@terraform plan -var-file=./values.tfvars -var-file=./clusters.tfvars

tfa: ## apply Terraform
	@echo "Applying Terraform..."
	@terraform apply -var-file=./values.tfvars -var-file=./clusters.tfvars

tfd: ## destroy Terraform
	@echo "Destroying Terraform..."
	@terraform destroy -var-file=./values.tfvars -var-file=./clusters.tfvars

