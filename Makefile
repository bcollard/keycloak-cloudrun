# Makefile for Keycloak on Cloud Run with Terraform
.ONESHELL:
.DEFAULT_GOAL := help
.PHONY: help gcloud-login tfv tfi tfp tfa tfd server-cert keycloak-build diagrams image-digest

help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'


GCLOUD_CONFIG ?= kong

gcloud-login: ## Activate the gcloud config GCLOUD_CONFIG (default: kong) and refresh Application Default Credentials
	@gcloud config configurations activate $(GCLOUD_CONFIG)
	@gcloud auth application-default login

tfi: ## init Terraform (reads backend settings from backend.hcl)
	@echo "Initializing Terraform..."
	@terraform init -reconfigure -backend-config=backend.hcl

tfp: ## plan Terraform
	@echo "Planning Terraform..."
	@terraform plan

tfa: ## apply Terraform
	@echo "Applying Terraform..."
	@terraform apply

tfd: ## destroy Terraform
	@echo "Destroying Terraform..."
	@terraform destroy

server-cert: ## exec glb-wildcard-cert.sh to create a wildcard certificate for the load balancer (requires DNS_ZONE_NAME, GCP_PROJECT_DNS, GCP_CREDENTIALS_FILE, ACME_EMAIL)
	@echo "Creating wildcard certificate for load balancer..."; \
	DNS_ZONE_NAME="$(DNS_ZONE_NAME)" ./glb-wildcard-cert.sh

image-digest: ## print the GHCR digest of the image tagged with KEYCLOAK_VERSION (for keycloak_image_digest)
	@v=$$(tr -d ' \t\r\n' < KEYCLOAK_VERSION); \
	tok=$$(curl -fsS "https://ghcr.io/token?scope=repository:bcollard/keycloak-cloudrun:pull" | python3 -c 'import json,sys;print(json.load(sys.stdin)["token"])'); \
	curl -fsSI -H "Authorization: Bearer $$tok" -H "Accept: application/vnd.oci.image.index.v1+json" \
	  "https://ghcr.io/v2/bcollard/keycloak-cloudrun/manifests/$$v" | tr -d '\r' | awk -F': ' 'tolower($$1)=="docker-content-digest"{print $$2}'

keycloak-build: ## prompt for Keycloak version and update KEYCLOAK_VERSION (requires gum)
	@./scripts/set-keycloak-version.sh

diagrams: ## regenerate docs/img/{architecture,stack}.{svg,png} (requires rsvg-convert)
	@python3 scripts/diagrams.py docs/img
	@for f in architecture stack; do rsvg-convert -z 2 docs/img/$$f.svg -o docs/img/$$f.png; done
