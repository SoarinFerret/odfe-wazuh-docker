#!/bin/bash

if [[ -z "$1" || -z "$2" || -z "$3" || !("$#" == 3) ]]; then
    echo >&2 "This script requires exactly 3 arguments
Usage:
        ./buildcerts.sh countryCode organization domain

For example:
        ./buildcerts.sh US 'My Homelab' 'example.com'
"
    exit
fi

# Create CA
echo "#################################################################
                      Certificate Authority
#################################################################"
openssl genrsa -out root-ca-key.pem 2048
openssl req -new -x509 -sha256 -key root-ca-key.pem -out root-ca.pem -subj "/C=$1/O=$2/CN=CA Root"

# Build admin cert
echo "#################################################################
                      ADMIN Cert
#################################################################"
openssl genrsa -out admin-key-temp.pem 2048
openssl pkcs8 -inform PEM -outform PEM -in admin-key-temp.pem -topk8 -nocrypt -v1 PBE-SHA1-3DES -out admin-key.pem
openssl req -new -key admin-key.pem -out admin.csr -subj "/C=$1/O=$2/CN=ADMIN"
openssl x509 -req -in admin.csr -CA root-ca.pem -CAkey root-ca-key.pem -CAcreateserial -sha256 -out admin.pem

# Build odfe-node stuff
echo "#################################################################
                      Node1 & 2 Certs
#################################################################"
openssl genrsa -out odfe-node1-key-temp.pem 2048
openssl pkcs8 -inform PEM -outform PEM -in odfe-node1-key-temp.pem -topk8 -nocrypt -v1 PBE-SHA1-3DES -out odfe-node1-key.pem
openssl req -new -key odfe-node1-key.pem -out odfe-node1.csr -subj "/C=$1/O=$2/CN=odfe-node1.$3"
openssl x509 -req -in odfe-node1.csr -CA root-ca.pem -CAkey root-ca-key.pem -CAcreateserial -sha256 -out odfe-node1.pem
openssl genrsa -out odfe-node2-key-temp.pem 2048
openssl pkcs8 -inform PEM -outform PEM -in odfe-node2-key-temp.pem -topk8 -nocrypt -v1 PBE-SHA1-3DES -out odfe-node2-key.pem
openssl req -new -key odfe-node2-key.pem -out odfe-node2.csr -subj "/C=$1/O=$2/CN=odfe-node2.$3"
openssl x509 -req -in odfe-node2.csr -CA root-ca.pem -CAkey root-ca-key.pem -CAcreateserial -sha256 -out odfe-node2.pem

echo "#################################################################
                      Kibana Cert
#################################################################"
openssl genrsa -out kibana-key-temp.pem 2048
openssl pkcs8 -inform PEM -outform PEM -in kibana-key-temp.pem -topk8 -nocrypt -v1 PBE-SHA1-3DES -out kibana-key.pem
openssl req -new -key kibana-key.pem -out kibana.csr -subj "/C=$1/O=$2/CN=kibana.$3"
openssl x509 -req -in kibana.csr -CA root-ca.pem -CAkey root-ca-key.pem -CAcreateserial -sha256 -out kibana.pem

# Cleanup certs
rm admin-key-temp.pem
rm admin.csr
rm odfe-node1-key-temp.pem
rm odfe-node1.csr
rm odfe-node2-key-temp.pem
rm odfe-node2.csr
rm kibana-key-temp.pem
rm kibana.csr