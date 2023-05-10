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
if [[ $# -gt 0 && $1 == "encrypt-file" ]]; then
    set -x
    if [[ -v FILE ]]; then
        ENC_FILE="${FILE}.aes"
        if [[ ! -f ${FILE} ]]; then
            echo "File ${FILE} does not exist!"
            exit 1
        fi
        echo "Encrypting ${FILE} with symmetrical encryption .."
        if [[ -v PASSPHRASE ]]; then
            openssl enc -aes-256-cbc -md sha512 -pbkdf2 -iter 100000 -salt -pass env:PASSPHRASE -in ${FILE} -out ${ENC_FILE}
        else
            openssl enc -aes-256-cbc -md sha512 -pbkdf2 -iter 100000 -salt -in ${FILE} -out ${ENC_FILE}
        fi
    else
        echo "No FILE environment variable!"
        exit 1
    fi
    set -v
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
if [[ $# -gt 0 && $1 == "decrypt-file" ]]; then
    set -x
    if [[ -v FILE ]]; then
        if [[ ! ${FILE} =~ .aes$ ]]; then
            echo "File ${FILE} does not have an .aes extension!"
            exit 1
        fi
        if [[ ! -f ${FILE} ]]; then
            echo "File ${FILE} does not exist!"
            exit 1
        fi
        CLEAR_FILE=$(echo ${FILE} | sed -e 's/.aes$//')
        if [[ ${FILE} == ${CLEAR_FILE} ]]; then
            echo "Input and Output file will be exactly the same and equal to ${FILE}"
            exit 1
        fi
        echo "Decrypting ${FILE} with symmetrical encryption .."
        if [[ -v PASSPHRASE ]]; then
            openssl enc -aes-256-cbc -md sha512 -pbkdf2 -iter 100000 -salt -d -pass env:PASSPHRASE -in ${FILE} -out ${CLEAR_FILE}
        else
            openssl enc -aes-256-cbc -md sha512 -pbkdf2 -iter 100000 -salt -d -in ${FILE} -out ${CLEAR_FILE}
        fi
    else
        echo "No FILE environment variable!"
        exit 1
    fi
    set -v
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
        echo "Encrypting private keys using PASSPHRASE env var.."
        openssl rsa -des -passout env:PASSPHRASE -in certs/cakey.pem -out certs/cakey.key
        openssl rsa -des -passout env:PASSPHRASE -in certs/privkey.pem -out certs/privkey.key
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