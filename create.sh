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
if [[ $# -gt 0 && $1 == "print" ]]; then
    echo "Printing CSR .."
    openssl req -text -noout -verify -in certs/server.csr
    exit 0
fi
if [[ $# -gt 0 && $1 == "encrypt" ]]; then
    echo "Encrypting private key .."
    openssl rsa -des -in certs/privkey.pem -out certs/privkey.pem
    exit 0
fi
if [[ $# -gt 0 && $1 == "decrypt" ]]; then
    echo "Decrypting private key .."
    openssl rsa -in certs/privkey.pem -out certs/privkey.pem
    exit 0
fi

echo "Usage: $0 <option>"
echo "Available options:"
echo "create    Create a new private key and server.csr"
echo "print     Print CSR"
echo "renew     Regenerate the CSR reusing the same key"