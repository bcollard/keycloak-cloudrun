# Project notes for Claude

## Deploy pipeline is two-phase, not fully automated

GitHub Actions (`.github/workflows/build-push.yml`) only builds & pushes the
container image to GHCR, and only when `KEYCLOAK_VERSION` changes. It does
**not** run `terraform apply`. To roll out a new image or any `cloudrun.tf` /
`load-balancer.tf` change to the live service, you must:

1. `make gcloud-login` — interactive: activates the `kong` gcloud config
   (project `intense-clarity-338816`, account `baptiste.collard@konghq.com`)
   and refreshes Application Default Credentials. Terraform uses ADC, and the
   default `perso` gcloud config does not have access to this project, so
   skipping this step gives 403s on every resource refresh.
2. `make tfa` (or `terraform apply`).

## Keep `--features` flags in sync between build and runtime

Keycloak's optimized start (`kc.sh start --optimized …`) requires the runtime
feature set to match what was baked at build time. Whenever you change
`--features=…` in one of these places, change the other to the exact same
list:

- `Dockerfile` — `RUN /opt/keycloak/bin/kc.sh build --features=…`
- `cloudrun.tf` — `args = ["start", "--optimized", "--features=…"]`

The current value is `spiffe:v1` (the only feature still in preview that this
deployment needs to opt into). Standard token exchange v2, JWT authorization
grant, and Kubernetes service-account grants became default-on in Keycloak
26.6 — don't re-add them to the flag list.

See https://www.keycloak.org/server/features for the current status of each
flag.

## `terraform plan` reads the entire working tree

Plan/apply will pick up uncommitted edits in `*.tf` files even if they're
unrelated to what you intend to ship. Before applying, `git status` and either
stash the unrelated changes or scope the apply with `-target=…`. The
`google_compute_ssl_certificate.main` resource in particular forces a destroy
+ recreate of the live wildcard cert when its `name_prefix` changes.
