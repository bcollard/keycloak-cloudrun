# Makefile for Keycloak on Cloud Run with Terraform

# Configuration
PROJECT_ID ?= $(shell gcloud config get-value project)
REGION ?= europe-west9
TRIGGER_NAME ?= keycloak-build-trigger
BRANCH ?= main

# Terraform variables
TF_VAR_project_id ?= $(PROJECT_ID)
TF_VAR_region ?= $(REGION)

.PHONY: help
help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: gcloud-login
gcloud-login: ## Authenticate with Google Cloud (User and Application Default)
	gcloud auth login
	gcloud auth application-default login

.PHONY: gcloud-set-project
gcloud-set-project: ## Set the active Google Cloud project (usage: make gcloud-set-project PROJECT_ID=your-project-id)
	gcloud config set project $(PROJECT_ID)

.PHONY: tf-init
tf-init: ## Initialize Terraform
	terraform init

.PHONY: tf-plan
tf-plan: ## Plan Terraform changes
	terraform plan -var="project_id=$(PROJECT_ID)" -var="region=$(REGION)"

.PHONY: tf-apply
tf-apply: ## Apply Terraform changes
	terraform apply -var="project_id=$(PROJECT_ID)" -var="region=$(REGION)"

.PHONY: tf-destroy
tf-destroy: ## Destroy Terraform infrastructure
	terraform destroy -var="project_id=$(PROJECT_ID)" -var="region=$(REGION)"

.PHONY: all
all: tf-init tf-apply ## Run init and apply
