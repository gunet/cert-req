# cert-req
A simple Docker image to create certificate requests for web servers

## Process
* Create certificate request with new key: `openssl req -new -newkey rsa:4096 -nodes -keyout privkey.pem -out server.csr -config server.cnf -batch`
* Renew certificate request reusing key: `openssl req -new -key certs/privkey.pem -out certs/server.csr -config server.cnf -batch`
* Print CSR: `openssl req -text -noout -verify -in certs/server.csr`

## Private Keys
* Check if a private key is encrypted or not: `openssl rsa -text -noout -in <name of key>.key`
* Encrypt a private key or change the passphrase: `openssl rsa -des -passin env:PRIVKEY_PASSPHRASE -in <unencrypted name>.key -out <encrypted name>.key`
* Remove the passphrase: `openssl rsa -in <encrypted name>.key -out <unencrypted name>.key`
* Remove the passphrase using an environment variable: `openssl rsa -passin env:PRIVKEY_PASSPHRASE -in <encrypted named>.pem -out <unencrypted name>.key`
* Symmetrical encryption on a file (passphrase in env variable):
  - Encrypt: `openssl enc -aes-256-cbc -md sha512 -pbkdf2 -iter 100000 -salt -pass env:ENCKEY_PASSPHRASE -in <unencrypted> -out <encrypted>`
  - Decrypt: `openssl enc -aes-256-cbc -md sha512 -pbkdf2 -iter 100000 -salt-d  -pass env:ENCKEY_PASSPHRASE -in <encrypted> -out <unencrypted>`

## Docker
* Build: `docker build -t gunet/cert-req:latest .`
* Run: `docker run --rm -e ORG=<ORG> -e SERVER=<hostname> -it -v $PWD/certs:/var/cert-req/certs gunet/cert-req <argument>`
* Possible arguments
  - `create`: Create a new private key and server.csr
  - `print`: Print CSR
  - `renew`: Regenerate the CSR reusing the same key
  - `encrypt`: Encrypt the private key with a pass phrase
  - `decrypt`: Remove the passphrase from an encrypted key
  - `self-sign`: Create a CA and self-sign a certificate. The certs folder will include the 
* CSR and private key will be in $PWD/certs

## docker-compose
* Build: `docker-compose build`
* Run: `docker-compose run -e ORG=<ORG> -e SERVER=<hostname> --rm cert-req <command>`
* CSR and private key will be in $PWD/certs

## Image size
* gunet/cert-req: 82.5MB
  - debian:bullseye-slm: 80.5MB