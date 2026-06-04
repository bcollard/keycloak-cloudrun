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
# As of 26.6, kubernetes-service-accounts:v1, jwt-authorization-grant:v1, and
# token-exchange-standard:v2 are supported and enabled by default. The legacy
# token-exchange:v1 flag is deprecated. Only spiffe:v1 is still preview here.
RUN /opt/keycloak/bin/kc.sh build --features=spiffe:v1

# Final image
FROM quay.io/keycloak/keycloak:${KEYCLOAK_VERSION}
COPY --from=builder /opt/keycloak/ /opt/keycloak/

WORKDIR /opt/keycloak

ENV KC_DB=postgres
ENV KC_LOG_LEVEL=INFO

ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]