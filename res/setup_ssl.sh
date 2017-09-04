#!/bin/bash
FQDN=$(hostname -f)
SSL_DIR="/tmp/mock_code_manager_ssl"
PRIV_DIR=$SSL_DIR/private_keys
PRIV_KEY=$PRIV_DIR/server.pem
CERT_DIR=$SSL_DIR/certs
CSR=$SSL_DIR/server.csr
CA_CRT="$SSL_DIR/ca.crt"
CA_KEY="$SSL_DIR/ca.pem"
CERT=$CERT_DIR/server.pem

rm -rf $SSL_DIR
mkdir -p $SSL_DIR
mkdir -p $PRIV_DIR
mkdir -p $CERT_DIR

# CA
echo "CA generation"
openssl req -new -x509 -days 3650 -subj "/C=AU/ST=NSW/L=SYDNEY/O=Acme, Inc./CN=Fake Root CA" -keyout $CA_KEY -out $CA_CRT -nodes
#openssl req -new -x509 -keyout $PRIV_DIR/ca.pem -out $CERT_DIR/ca.pem -days 3650 -nodes -config openssl.cnf

# server private key
echo "server key+csr"
openssl genrsa -out $PRIV_KEY 2048
openssl req -newkey rsa:2048 -nodes -keyout $PRIV_KEY -subj "/C=AU/ST=NSW/L=SYDNEY/O=Fake, Inc./CN=${FQDN}" -out $CSR

# SIGN
echo "signing"
openssl x509 -days 3650 -req -in $CSR -CA $CA_CRT -CAkey $CA_KEY -CAcreateserial -out $CERT
rm $CSR

echo "done!"