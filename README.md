# cert-req
A simple Docker image to create certificate requests for web servers

## Process
* Create certificate request with new key: `openssl req -new -newkey rsa:4096 -nodes -keyout privkey.pem -out server.csr -config server.cnf -batch`
* Renew certificate request reusing key: `openssl req -new -key certs/privkey.pem -out certs/server.csr -config server.cnf -batch`
* Print CSR: `openssl req -text -noout -verify -in certs/server.csr`

## Docker
* Build: `docker build -t gunet/cert-req:latest .`
* Run: `docker run --rm -e ORG=<ORG> -e SERVER=<hostname> -v $PWD/certs:/var/cert-req/certs gunet/cert-req`
* Possible arguments
  - `create`: Create a new private key and server.csr
  - `print`: Print CSR
  - `renew`: Regenerate the CSR reusing the same key
* CSR will be in $PWD/certs

## docker-compose
* Build: `docker-compose build`
* Run: `docker-compose run -e ORG=<ORG> -e SERVER=<hostname> --rm cert-req <command>`
* CSR will be in $PWD/certs

## Image size
* gunet/cert-req: 82.5MB
  - debian:bullseye-slm: 80.5MB