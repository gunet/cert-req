#!/bin/bash

if [[ $# -gt 0 && $1 == "renew" ]]; then
    echo "Generating server certificate CSR (reusing key).."
    openssl req -new -key certs/privkey.pem -out certs/server.csr -config server.cnf -batch
    exit 0
fi
if [[ $# -gt 0 && $1 == "create" ]]; then
    echo "Generating server certificate CSR (recreating key).."
    openssl req -new -newkey rsa:4096 -nodes -keyout certs/privkey.pem -out certs/server.csr -config server.cnf -batch
    exit 0
fi
echo "Usage: $0 <option>"
echo "Available options:"
echo "create    Create a new private key and server.csr"
echo "renew     Regenerate the CSR reusing the same key"