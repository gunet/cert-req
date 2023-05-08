#!/bin/bash

if [[ -v SUBJALTNAMES ]]; then
    ALTNAMES="subjectAltName = $(echo $SUBJALTNAMES|sed -e 's/\,/,DNS:/g' -e 's/^/DNS:/')"
fi

if [[ $# -gt 0 && $1 == "renew" ]]; then
    echo "Generating server certificate CSR (reusing key).."
    if [[ -v SUBJALTNAMES ]]; then
        openssl req -new -key certs/privkey.pem -addext "${ALTNAMES}" -out certs/server.csr -config server.cnf -batch
    else
        openssl req -new -key certs/privkey.pem -out certs/server.csr -config server.cnf -batch
    fi
    exit 0
fi
if [[ $# -gt 0 && $1 == "create" ]]; then
    echo "Generating server certificate CSR (recreating key).."
    if [[ -v SUBJALTNAMES ]]; then    
        openssl req -new -newkey rsa:4096 -nodes -keyout certs/privkey.pem -addext "${ALTNAMES}" -out certs/server.csr -config server.cnf -batch
    else
        openssl req -new -newkey rsa:4096 -nodes -keyout certs/privkey.pem -out certs/server.csr -config server.cnf -batch
    fi
    exit 0
fi
if [[ $# -gt 0 && $1 == "print" ]]; then
    echo "Printing CSR .."
    openssl req -text -noout -verify -in certs/server.csr
    exit 0
fi
if [[ $# -gt 0 && $1 == "encrypt" ]]; then
    echo "Encrypting private key .."
    if [[ -v PASSPHRASE ]]; then
        openssl rsa -des -passout env:PASSPHRASE -in certs/privkey.pem -out certs/privkey.key
    else
        openssl rsa -des -in certs/privkey.pem -out certs/privkey.key
    fi
    exit 0
fi
if [[ $# -gt 0 && $1 == "decrypt" ]]; then
    echo "Decrypting private key .."
    if [[ -v PASSPHRASE ]]; then
        openssl rsa -passin env:PASSPHRASE -in certs/privkey.key -out certs/privkey.pem
    else
        openssl rsa -in certs/privkey.key -out certs/privkey.pem
    fi
    exit 0
fi
if [[ $# -gt 0 && $1 == "self-sign" ]]; then
    echo "Generating private CA key..."
    openssl genrsa -out certs/cakey.pem 4096
    echo "Signing CA certificate (for 22 years)..."
    openssl req -x509 -new -nodes -key certs/cakey.pem -sha256 -days 8030 -config ca.cnf \
    -out certs/ca.crt -extensions ca_ext -batch
    echo "Generating server certificate CSR..."
    if [[ -v SUBJALTNAMES ]]; then
        openssl req -new -newkey rsa:4096 -nodes -keyout certs/privkey.pem -addext "${ALTNAMES}" \
        -out certs/server.csr -config server.cnf -batch
    else
        openssl req -new -newkey rsa:4096 -nodes -keyout certs/privkey.pem -out certs/server.csr -config server.cnf \
        -batch
    fi
    echo "Signing server certificate (for 20 years)..."
    if [[ -v SUBJALTNAMES ]]; then
        echo ${ALTNAMES} > certs/req.ext
        openssl x509 -req -in certs/server.csr -CA certs/ca.crt -CAkey certs/cakey.pem -CAcreateserial \
        -out certs/server.crt -days 7300 -sha256 -extfile certs/req.ext
        rm certs/req.ext        
    else
        openssl x509 -req -in certs/server.csr -CA certs/ca.crt -CAkey certs/cakey.pem -CAcreateserial \
        -out certs/server.crt -days 7300 -sha256
    fi
    if [[ -v PASSPHRASE ]]; then
        echo "Encrypting private key using PASSPHRASE env var.."
        openssl rsa -passin env:PASSPHRASE -in certs/privkey.key -out certs/privkey.pem
    fi    
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