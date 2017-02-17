#!/bin/sh


if [ $# -ne 1 ]
then
    echo "Enter agent hostname number to create"
    exit 1
fi

if [ ! -d "agent$1" ]; then
    mkdir -p agent$1
fi

MASTER_DIRECTORY_NAME="agent"
MASTER_END_NAME=""

./cert-tool --tls-ca-org "orgas" --tls-ca-cert ca_cert/rootCA.crt --tls-ca-key ca_cert/rootCA.key --server agent$1 -d agent$1

echo "Certificate created successully"
