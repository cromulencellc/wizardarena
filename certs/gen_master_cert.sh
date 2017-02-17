#!/bin/sh


if [ $# -ne 1 ]
then
    echo "Enter master hostname number to create"
    exit 1
fi

if [ ! -d "master$1" ]; then
    mkdir -p master$1
fi

MASTER_DIRECTORY_NAME="master"
MASTER_END_NAME=""

./cert-tool --tls-ca-org "orgas" --tls-ca-cert ca_cert/rootCA.crt --tls-ca-key ca_cert/rootCA.key --server master$1 -d master$1

echo "Certificate created successully"
