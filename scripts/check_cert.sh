#!/bin/bash

# Script to check a certificate expiration and look it up using
# https://crt.sh online tool for Sectigo certificates
# Takes as argument the relative/absolute path to the CRT certificate file
#
# The environment variables MAX_DAYS sets how many days ahead the certificate
# might expire (default is 30)

MAX_DAYS=${MAX_DAYS:-30}

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <certificate path>"
fi

SECONDS=$(( ${MAX_DAYS} * 86400))
EXPIRATION=$(openssl x509 -noout -checkend ${SECONDS} -in $1)

if [[ ${EXPIRATION} =~ "not expire" ]]; then
  echo "The certificate is valid and within expiration bounds"
  exit 0
else
  echo "Certificate is outside expiration bounds or has expired"
  exit 1
fi