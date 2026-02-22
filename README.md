# Keycloak on Google Cloud Run

A complete infrastructure-as-code deployment of Keycloak on Google Cloud Run with load balancing, SSL/TLS, and serverless VPC connectivity to Cloud SQL.

## Table of Contents

- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Infrastructure Components](#infrastructure-components)
- [Keycloak Configuration](#keycloak-configuration)
- [Advanced Features](#advanced-features)
- [Troubleshooting](#troubleshooting)

## Architecture

```
keycloak.kong.runlocal.dev
        ↓
    DNS (GCP Private)
        ↓
Google Cloud Load Balancer (Kong tenant)
    + SSL/TLS Certificate
        ↓
    Cloud Run (Kong tenant)
        ↓
  Serverless VPC Connector
        ↓
  Cloud SQL PostgreSQL (Kong tenant)
```

**Key Components:**
- **Global Load Balancer (GLB)** - Provides high availability and SSL/TLS termination
- **Cloud Run** - Serverless containerized Keycloak deployment
- **Cloud SQL PostgreSQL** - Managed database backend
- **Serverless VPC Connector** - Secure connectivity between Cloud Run and Cloud SQL
- **Artifact Registry** - Hosts custom Keycloak Docker image
- **Service Accounts & Secrets** - Manages authentication and sensitive data

## Prerequisites

- Google Cloud Platform (GCP) account with project setup
- `gcloud` CLI installed and configured
- Terraform >= 1.10
- Docker (for building custom Keycloak image)
- Valid SSL/TLS certificate (wildcard recommended)

## Quick Start

### 1. Authenticate with GCP

```bash
make gcloud-login
```

This sets up both user authentication and application default credentials.

### 2. Initialize Terraform

```bash
make tfi
```

Initializes Terraform and downloads required providers.

### 3. Plan Deployment

```bash
make tfp
```

Review the resources that will be created.

### 4. Apply Configuration

```bash
make tfa
```

Deploys all infrastructure. When prompted, review the changes and type `yes` to confirm.

### 5. Verify Deployment

Access Keycloak at: `https://keycloak.kong.runlocal.dev`

## Infrastructure Components

### Google Cloud SQL PostgreSQL

**Database Configuration:**
- Instance: `keycloak-cloud-run-postgres-db`
- Database: `keycloak`
- User: `keycloak-cloud-run`
- Password: Stored in Google Secret Manager as `keycloak-kong-runlocal-dev-db-pwd`

**Access:**
- Managed by Terraform
- Automatic backups enabled
- Accessible only via Serverless VPC Connector

### Cloud Run Service

**Deployment Details:**
- Service: `kong-keycloak-on-cloudrun`
- Region: `europe-west9`
- Image: Custom Keycloak from Artifact Registry (GitHub Proxy)
- Environment: Configured via `values.auto.tfvars`

**Configuration File:**
- Main deployment: `cloudrun.tf`
- Quarkus properties: `server/conf/quarkus.properties`
- Docker image: `Dockerfile`

### Global Load Balancer

**Configuration:**
- Backend Service: `keycloak-cloud-run` (serverless backend)
- URL Map: `baptiste-glb-http`
- SSL Certificate: `wildcard-kong-runlocal-dev-2026-01`
- Forwarding Rule: `keycloak-kong-runlocal-dev`
- IP Address: `34.110.159.193` (from outputs)

**File:** `load-balancer.tf`

### Custom Keycloak Image

This project builds a custom Keycloak Docker image optimized for Cloud Run.

**Build Process:**
- Based on official Keycloak image
- Custom Quarkus configuration for Cloud Run environment
- Reference: https://blog.ineat-group.com/2023/09/deployer-keycloak-sous-cloudrun/

**Related Files:**
- `Dockerfile` - Container build configuration
- `server/conf/quarkus.properties` - Keycloak Quarkus settings

## Keycloak Configuration

### Default Credentials

| Component | Username | Password |
|-----------|----------|----------|
| Keycloak Admin | `admin` | *See Google Secret Manager* |
| Database Super User | `postgres` | - |
| Database Keycloak User | `keycloak-cloud-run` | *See Google Secret Manager* |

### Accessing Admin Console

1. Navigate to: `https://keycloak.kong.runlocal.dev/admin`
2. Login with admin credentials from Google Secret Manager
3. Retrieve via: `gcloud secrets versions access latest --secret="keycloak-kong-runlocal-dev-kc-admin-pwd"`

## Advanced Features

### WebAuthn / Passwordless Authentication

**Setup Instructions:**

1. **Create Browser with Passkeys Flow:**
   - Admin Console → Authentication → Flows
   - Copy "Browser" flow → Name it "Browser with Passkeys"
   - Set as default browser flow

2. **Enable Required Actions:**
   - Admin Console → Authentication → Required Actions
   - Enable: WebAuthn Register
   - Enable: WebAuthn Register Passwordless

3. **Enable Passkeys Policy:**
   - Admin Console → Authentication → Policies
   - Toggle on "Enable Passkeys"

### Direct Grant Flow (kcadm.sh)

If using `kcadm.sh` command-line administration:

1. Admin Console → Authentication → Flows
2. Edit "Direct Grant" flow
3. **Disable all OTP (One-Time Password) related authenticators** - They conflict with `kcadm.sh` API access

### VSCode as MCP Client

To use VSCode with Model Context Protocol (MCP) via Keycloak:

**Scope Configuration:**
- Add `openid` scope globally in Keycloak
- Add to your client's allowed scopes
- Request scopes: `openid`, `phone`, `address`, `offline_access`, `organization`, `profile`, `email`, `microprofile-jwt`

**Token Configuration:**
- Increase access token lifespan to **30 minutes** (account for clock skew between local machine and Cloud Run)
- Add client mapper: **Audience** mapper
  - Name: "Add audience"
  - Mapper Type: "Audience"
  - Add to access token: ON
  - Include client audience: ON

**Note:** There's a pending fix for dynamic audience claim injection - see https://github.com/keycloak/keycloak/issues/41526

## Terraform Files Overview

| File | Purpose |
|------|---------|
| `terraform.tf` | Terraform configuration & remote GCS backend |
| `variables.tf` | Variable definitions for GCP resources |
| `values.auto.tfvars` | Variable values (GCP project, region, etc.) |
| `cloudrun.tf` | Cloud Run service deployment |
| `load-balancer.tf` | Global Load Balancer & networking |
| `tf-provider-google.tf` | Google provider configuration |
| `tf-imports.sh` | Script for importing existing resources |
| `merge-tf-projects.sh` | Script for merging multiple state files |

## Terraform Operations

```bash
# Initialize Terraform (downloads providers, sets up backend)
make tfi

# Validate syntax (optional)
terraform validate

# Plan changes (shows what will be created/modified)
make tfp

# Apply configuration
make tfa

# Destroy infrastructure (WARNING: Destructive!)
make tfd

# View current state
terraform state list
terraform state show <resource_name>
```

## Troubleshooting

### Cloud Run Service Not Accessible

**Check:**
- Cloud Run service status: `gcloud run services list --region=europe-west9`
- Review logs: `gcloud run services logs read kong-keycloak-on-cloudrun --region=europe-west9 --limit=50`
- Verify firewall rules and VPC connector status

### Database Connection Issues

**Check:**
- Cloud SQL instance status: `gcloud sql instances list`
- VPC Connector: `gcloud compute networks vpc-access connectors list --region=europe-west9`
- Network connectivity from Cloud Run to Cloud SQL

### Backend Service Timeout Error

If you see: `Timeout sec is not supported for a backend service with Serverless network endpoint groups`

**Solution:** Remove `timeout_sec` from the backend service configuration (already fixed in this repo). Serverless backends don't support custom timeouts.

### Terraform State Issues

When working with multiple state files:

```bash
# List resources from specific state file
terraform state list -state=kc-glb.tfstate

# Show specific resource
terraform state show -state=kc-glb.tfstate google_compute_backend_service.main

# Merge state files (use the provided script)
./merge-tf-projects.sh
```

## State Management

This project uses a remote GCS backend for Terraform state:
- **Bucket:** `tf-state-bco-scripts-kong-gcp`
- **Prefix:** `terraform/bco/keycloak-cloudrun`
- **Credentials:** `tf-state-backend-kong-scripts.json`

Backups of local state files are maintained in the `backup/` directory.

## Contributing

When modifying Terraform configuration:
1. Always run `terraform plan` first
2. Review changes carefully before applying
3. Keep state files in sync with GCS backend
4. Document any configuration changes in this README

## References

- [Keycloak on Cloud Run - French Blog](https://blog.ineat-group.com/2023/09/deployer-keycloak-sous-cloudrun/)
- [Google Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [WebAuthn Specification](https://www.w3.org/TR/webauthn-2/)
- [Keycloak Documentation](https://www.keycloak.org/documentation)






