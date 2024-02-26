#!/bin/bash

openssl pkcs12 -in /certs/$CERTFILE -inkey /certs/$KEYFILE -certfile /certs/$INTCHAINCERTFILE \
	-export -out /certs/$DESTSTOREFILE.p12 -passout pass:$DESTSTOREPASS

keytool -importkeystore -srckeystore /certs/$DESTSTOREFILE.p12 -srcstoretype PKCS12 \
	-destkeystore /certs/$DESTSTOREFILE.bcfks \
	-srcstorepass $DESTSTOREPASS \
	-deststorepass $DESTSTOREPASS -deststoretype BCFKS \
	-providerclass org.bouncycastle.jcajce.provider.BouncyCastleFipsProvider \
	-provider org.bouncycastle.jcajce.provider.BouncyCastleFipsProvider \
	-providerpath /opt/keycloak/providers/bc-fips-1.0.2.3.jar \
	-J-Djava.security.properties=/usr/lib/jvm/jre-17-openjdk/conf/security/java.security \
        -J--add-exports=java.base/sun.security.provider=ALL-UNNAMED \
        -J--add-opens=java.base/sun.security.provider=ALL-UNNAMED \
	-providername BCFIPS
