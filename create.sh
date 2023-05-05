#!/bin/bash

if [[ $# -gt 0 && $1 == "renew" ]]; then
    echo "Generating server certificate CSR (reusing key).."
    openssl req -new -key certs/privkey.pem -out certs/server.csr -config server.cnf -batch
    exit 0
fi
if [[ $# -gt 0 && $1 == "create" ]]; then
    echo "Generating server certificate CSR (recreating key).."
    openssl req -new -newkey rsa:4096 -nodes -keyout certs/privkey.pem -out certs/server.csr \
    -config server.cnf -batch
    exit 0
fi
if [[ $# -gt 0 && $1 == "print" ]]; then
    echo "Printing CSR .."
    openssl req -text -noout -verify -in certs/server.csr
    exit 0
fi
if [[ $# -gt 0 && $1 == "encrypt" ]]; then
    echo "Encrypting private key .."
    openssl rsa -des -in certs/privkey.pem -out certs/privkey.key
    exit 0
fi
if [[ $# -gt 0 && $1 == "decrypt" ]]; then
    echo "Decrypting private key .."
    openssl rsa -in certs/privkey.key -out certs/privkey.pem
    exit 0
fi
if [[ $# -gt 0 && $1 == "self-sign" ]]; then
    echo "Generating private CA key..."
    openssl genrsa -out certs/cakey.pem 4096
    echo "Signing CA certificate (for 22 years)..."
    openssl req -x509 -new -nodes -key certs/cakey.pem -sha256 -days 8030 -config ca.cnf \
    -out certs/ca.crt -extensions ca_ext -batch
    echo "Generating server certificate CSR..."
    openssl req -new -newkey rsa:4096 -nodes -keyout certs/privkey.pem -out certs/server.csr -config server.cnf -batch
    echo "Signing server certificate (for 20 years)..."
    openssl x509 -req -in certs/server.csr -CA certs/ca.crt -CAkey certs/cakey.pem -CAcreateserial \
    -out certs/server.crt -days 7300 -sha256
    exit 0
fi

echo "Usage: $0 <option>"
echo "Available options:"
echo "create    Create a new private key and server.csr"
echo "print     Print CSR"
echo "renew     Regenerate the CSR reusing the same key"
echo "encrypt   Encrypt the private key with a passphrase"
echo "decrypt   Decrypt an encrypted private key"
echo "self-sign Self sign a certificate"