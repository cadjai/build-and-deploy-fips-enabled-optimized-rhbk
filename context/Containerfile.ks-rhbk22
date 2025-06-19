ARG BASE_IMAGE="registry.redhat.io/rhbk/keycloak-rhel9:22-7"
ARG SUMMARY="Custom RHBK Container with custom themes and FIPS libraries"
ARG NAME="Optimized RHBK Container Image"
ARG MAINTAINER="The Platform team <platformteam@test.org>"

FROM registry.redhat.io/ubi9/ubi as openssl-build 

RUN mkdir -p /mnt/rootfs
RUN yum install --installroot /mnt/rootfs --releasever 9 --setopt install_weak_deps=false --nodocs  -y coreutils-single glibc-minimal-langpack openssl; yum clean all
RUN rm -rf /mnt/rootfs/var/cache/*


#FROM $BASE_IMAGE  as builder

FROM registry.redhat.io/rhbk/keycloak-rhel9:22-7
COPY --from=openssl-build /mnt/rootfs / 

USER root

ARG BASE_IMAGE

# Enable health and metrics support
ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true

# Enable scripts features
ENV KC_FEATURES=scripts,kerberos,fips,docker,authorization,client-secret-rotation,impersonation,token-exchange,web-authn

# Configure a database vendor
ENV KC_DB=postgres

# Configure default cache stack
ENV KC_CACHE_STACK=kubernetes

# Configure XA Transaction
ENV KC_TRANSACTION_XA_ENABLED=true
ENV QUARKUS_TRANSACTION_MANAGER_ENABLE_RECOVERY=true

# ENABLE FIPS mode
ENV KC_FIPS_MODE=strict


# Add custom java security file to override default
COPY _build/kcadm.java.security /tmp/kcadm.java.security
COPY _build/java.security /usr/lib/jvm/jre-17-openjdk/conf/security/java.security

# Add Bouncy Castle
#ADD --chown=keycloak:keycloak _build/extensions/*.jar /tmp/files/
ADD _build/extensions/*.jar /tmp/files/

# copy libraries to jre dir
RUN cp /tmp/files/*.jar /usr/lib/jvm/jre-17-openjdk/lib/

WORKDIR /opt/keycloak

ENV KC_DB=postgres

# copy libraries to providers dir
RUN cp /tmp/files/*.jar /opt/keycloak/providers/

RUN fips-mode-setup --enable

RUN export KC_OPTS="-Djava.security.properties=/usr/lib/jvm/jre-17-openjdk/conf/security/java.security -Dcom.redhat.fips=true"

RUN /opt/keycloak/bin/kc.sh build  --features=fips,docker,authorization,client-secret-rotation,impersonation,token-exchange,web-authn --fips-mode=strict

