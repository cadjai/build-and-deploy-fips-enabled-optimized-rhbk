#!/bin/bash

keytool -importcert -noprompt  -alias $CAALIAS -file /certs/$CACHAINCERTFILE \
    -storepass $DESTSTOREPASS -keypass $DESTSTOREPASS -trustcacerts \
    -keystore /certs/$DESTSTOREFILE.bcfks -storetype BCFKS \
    -providerclass org.bouncycastle.jcajce.provider.BouncyCastleFipsProvider \
    -providerpath /opt/keycloak/providers/bc-fips-1.0.2.3.jar \
    -providername BCFIPS -J-Djava.security.properties=/usr/lib/jvm/jre-17-openjdk/conf/security/java.security \
    -J--add-exports=java.base/sun.security.provider=ALL-UNNAMED \
    -J--add-opens=java.base/sun.security.provider=ALL-UNNAMED
