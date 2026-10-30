# You can easily repackage Keycloak with a latest version by using this arg during the docker build
ARG KEYCLOAK_VERSION=26.6.2

# See https://www.keycloak.org/server/containers
FROM quay.io/keycloak/keycloak:${KEYCLOAK_VERSION} AS builder

ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true

# Configure a database vendor
ENV KC_DB=postgres

WORKDIR /opt/keycloak

# here is the workaround to enable json logs on Cloud Logging
ADD server/conf/quarkus.properties /opt/keycloak/conf

# Feature flags — see https://www.keycloak.org/server/features
# Must match the --features arg in cloudrun.tf exactly.
#   spiffe:v1                  preview       SPIFFE trust relationship provider
#   cimd:v1                    experimental  OAuth Client ID Metadata Document (MCP clients)
#   parameterized-scopes:v1    preview       parameterized OAuth 2.0 client scopes
#   identity-assertion-jwt:v1  experimental  Identity Assertion JWT Authorization Grant (ID-JAG, partial)
#   client-admin-api:v2        preview       Client Admin API v2 under /admin/api/{realm}/clients/v2
# token-exchange-standard:v2, jwt-authorization-grant:v1 and
# kubernetes-service-accounts:v1 are default-on since 26.6.
RUN /opt/keycloak/bin/kc.sh build --features=spiffe:v1,cimd:v1,parameterized-scopes:v1,identity-assertion-jwt:v1,client-admin-api:v2

# Final image
FROM quay.io/keycloak/keycloak:${KEYCLOAK_VERSION}
COPY --from=builder /opt/keycloak/ /opt/keycloak/

WORKDIR /opt/keycloak

ENV KC_DB=postgres
ENV KC_LOG_LEVEL=INFO

ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]