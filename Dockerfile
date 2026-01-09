# You can easily repackage Keycloak with a latest version by using this arg during the docker build
ARG KEYCLOAK_VERSION=26.2

# See https://www.keycloak.org/server/containers
FROM quay.io/keycloak/keycloak:${KEYCLOAK_VERSION} as builder

ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true

# Configure a database vendor
ENV KC_DB=postgres

WORKDIR /opt/keycloak

# here is the workaround to enable json logs on Cloud Logging
ADD server/conf/quarkus.properties /opt/keycloak/conf

RUN /opt/keycloak/bin/kc.sh build --feature-kubernetes-service-accounts=enabled --feature-spiffe=enabled


# Final image
FROM quay.io/keycloak/keycloak:${KEYCLOAK_VERSION}
COPY --from=builder /opt/keycloak/ /opt/keycloak/

WORKDIR /opt/keycloak

ENV KC_DB=postgres

ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]