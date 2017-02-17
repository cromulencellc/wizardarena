#!/bin/sh


if [ $# -ne 1 ]
then
    echo "Enter client hostname to create"
    exit 1
fi

if [ ! -d "$1" ]; then
    mkdir -p $1
fi

./cert-tool --tls-ca-org "orgas" --tls-ca-cert ca_cert/rootCA.crt --tls-ca-key ca_cert/rootCA.key --server $1 -d $1

echo "Certificate for client created successully"
