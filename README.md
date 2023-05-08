# cert-req
A simple Docker image to create certificate requests for web servers

## Process
* Create certificate request with new key: `openssl req -new -newkey rsa:4096 -nodes -keyout privkey.pem -out server.csr -config server.cnf -batch`
* Renew certificate request reusing key: `openssl req -new -key certs/privkey.pem -out certs/server.csr -config server.cnf -batch`
* Print CSR: `openssl req -text -noout -verify -in certs/server.csr`

## Private Keys
* Check if a private key is encrypted or not: `openssl rsa -text -noout -in <name of key>.key`
* Encrypt a private key or change the passphrase: `openssl rsa -des -passout PASS -in <unencrypted name> -out <encrypted name>`
* Remove the passphrase: `openssl rsa -in <encrypted name> -out <unencrypted name>`
* Remove the passphrase (passing the passphrase): `openssl rsa -passin PASS -in <encrypted named> -out <unencrypted name>`
* It is usually recommended to have the unencrypted private key end in `.pem` and the encrypted in `.key`
* Symmetrical encryption on a file (passphrase in env variable):
  - Encrypt: `openssl enc -aes-256-cbc -md sha512 -pbkdf2 -iter 100000 -salt -pass PASS -in <unencrypted> -out <encrypted>`
  - Decrypt: `openssl enc -aes-256-cbc -md sha512 -pbkdf2 -iter 100000 -salt -d -pass PASS -in <encrypted> -out <unencrypted>`
* `PASS` can be one of:
  - `pass:${PASS}`: A text passphrase
  - `env:PASS`: The passphrase will take the value of the environment variable `PASS`

## Environment Variables
* `ORG`: Organization (ie `GUNET`)
* `SERVER`: The server DNS name
* `PASSPHRASE`: The passphrase to use when encryting/decrypting. If it is not passed as an environment variable, it will be requested (you need to pass `-it` option in this case)
* `SUBJALTNAMES`: A comma separated list of subAltNames to be included in the certificate request/self-signed certificate.

## Docker
* Build: `docker build -t gunet/cert-req:latest .`
* Run: `docker run --rm -e ORG=<ORG> -e SERVER=<hostname> -v $PWD/certs:/var/cert-req/certs gunet/cert-req <argument>`
* Possible arguments
  - `create`: Create a new private key and server.csr
  - `print`: Print CSR
  - `renew`: Regenerate the CSR reusing the same key
  - `encrypt`: Encrypt the private key with a pass phrase
  - `decrypt`: Remove the passphrase from an encrypted key
  - `self-sign`: Create a CA and self-sign a certificate. The certs folder will include the CSR and private key will be in $PWD/certs.
* Passphrase:
  - Generally, the passphrase will be requested (applies to `encrypt` and `decrypt` arguments)
  - If an environment variable called `PASSPHRASE` is present then that will be used
  - If the environment variable is present and the command is `self-sign` then we will use it to encrypt the private key as well.

## docker-compose
* Build: `docker-compose build`
* Run: `docker-compose run -e ORG=<ORG> -e SERVER=<hostname> --rm cert-req <command>`
* CSR and private key will be in $PWD/certs

## Image size
* gunet/cert-req: 82.5MB
  - debian:bullseye-slm: 80.5MB
