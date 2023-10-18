# cert-req
A simple Docker image to create certificate requests for web servers

## Certificate operations via docker run
* (Optional) Build: `docker build -t gunet/cert-req:latest .`
* (Typical) Run: `docker run --rm -e ORG=<ORG> -e SERVER=<hostname> -v $PWD/certs:/var/cert-req/certs gunet/cert-req <argument>`
* Example: `docker run --rm -e ORG=sch.gr -e SERVER=sso-01-test.sch.gr -v $PWD/certs:/var/cert-req/certs gunet/cert-req create`
* If we want to pass the passphrase in stdin then we **need** to add the `-it` option.
* Possible arguments
  - `create`: Create a new private key and server.csr
  - `print`: Print CSR
  - `renew`: Regenerate the CSR reusing the same key
  - `encrypt`: Encrypt the private key with a pass phrase
  - `decrypt`: Remove the passphrase from an encrypted key
  - `encrypt-file`: Encrypt the file provided in the `FILE` environment variable with the `PASSPHRASE` (or we will request it) with symmetrical encryption. The resulting file will get a `.aes` extension
  - `decrypt-file`: Decrypt the file with symmetrical encryption. For the output file we remove the `.aes` extension. If it does not exist, we fail.
  - `self-sign`: Create a CA and self-sign a certificate. The certs folder will include the CSR and private key will be in $PWD/certs.
  - `resign`: Re-sign the server certificate using the existing CA.
* Passphrase:
  - Generally, the passphrase will be requested.
  - If an environment variable called `PASSPHRASE` is present then that will be used
  - If the environment variable is present and the command is `self-sign` then we will use it to encrypt the private key as well.

## docker-compose
* Build: `docker-compose build`
* Run: `docker-compose run -e ORG=<ORG> -e SERVER=<hostname> --rm cert-req <command>`
* CSR and private key will be in $PWD/certs


## Environment Variables
* `ORG`: Organization (ie `GUNET`)
* `SERVER`: The server DNS name
* `PASSPHRASE`: The passphrase to use when encryting/decrypting. If it is not passed as an environment variable, it will be requested (you need to pass `-it` option in this case)
* `SUBJALTNAMES`: A comma separated list of subAltNames to be included in the certificate request/self-signed certificate.
* `FILE`: The (absolute) path (in the container context) for a file to be encrypted or decrypted

## Image size
* gunet/cert-req: 82.5MB
  - debian:bullseye-slm: 80.5MB

## Process
* Create certificate request with new key: `openssl req -new -newkey rsa:4096 -nodes -keyout privkey.pem -out server.csr -config server.cnf -batch`
* Renew certificate request reusing key: `openssl req -new -key certs/privkey.pem -out certs/server.csr -config server.cnf -batch`
* Print CSR: `openssl req -text -noout -verify -in certs/server.csr`

## Private Keys
* Check if a private key is encrypted or not: `openssl rsa -text -noout -in <name of key>.key`
* Encrypt a private key or change the passphrase: `openssl rsa -aes256 -passout PASS -in <unencrypted name> -out <encrypted name>`
  - Note: Some algorithms like `des` are **not** supported by default by OpenSSL `v3.0` and should **not** be used
* Remove the passphrase: `openssl rsa -in <encrypted name> -out <unencrypted name>`
* Remove the passphrase (passing the passphrase): `openssl rsa -passin PASS -in <encrypted named> -out <unencrypted name>`
* It is usually recommended to have the unencrypted private key end in `.pem` and the encrypted in `.key`
* Symmetrical encryption on a file (passphrase in env variable):
  - Encrypt: `openssl enc -aes-256-cbc -md sha512 -pbkdf2 -iter 100000 -salt -pass PASS -in <unencrypted> -out <encrypted>`
  - Decrypt: `openssl enc -aes-256-cbc -md sha512 -pbkdf2 -iter 100000 -salt -d -pass PASS -in <encrypted> -out <unencrypted>`
* `PASS` can be one of:
  - `pass:${PASS}`: A text passphrase
  - `env:PASS`: The passphrase will take the value of the environment variable `PASS`

## Print Certificate
* Print certificate: `openssl x509 -text -in server.crt`
* Print a certificate which is stored in DER format (usually certificates taken from an `Authority Information Access` endpoint): `openssl x509 -text -inform der -in <cert-file>`
* Print certificate chain: `openssl crl2pkcs7 -nocrl -certfile server.crt | openssl pkcs7 -print_certs -noout`
* Print md5 checksums:
  - For certificate: `openssl x509 -noout -modulus -in server.crt| openssl md5`
  - For key: `openssl rsa -noout -modulus -in privkey.pem| openssl md5`
* Expiration:
  - Show expiration: `openssl x509 -noout -enddate -in server.crt`
  - Show all dates: `openssl x509 -noout -dates -in server.crt`
  - Check expiration: `openssl x509 -noout -checkend <seconds> -in server.crt`

## crt.sh
* [crt.sh](https://crt.sh/) is a tool to check/download Sectigo certificates online
* Return a JSON strcture with non-expired leaf certificates for a specific domain: `https://crt.sh/?Identity=<domaain>&exclude=expired&deduplicate=Y&output=json`

## OpenSSL connect
* We can use `openssl s_client` to directly connect to a server and check the TLS protocol
* The usual run is: `openssl s_client -connect <name>:443`
* To quit just after TLS connection establishment: `time echo "Q" | openssl s_client -connect <name>:443 2>1 >/dev/null`
* If we add the `-servername` argument then openssl also does SNI
### Testing SMTP (StartTLS)
* [Reference](https://halon.io/blog/how-to-test-smtp-servers-using-the-command-line)
* Connect to an SMTP server with StartTLS: `openssl s_client -quiet -connect relay.grnet.gr:587 -starttls smtp`
* The `-quiet` flag is important in order to be able to issue capitalized SMTP commands with no problem.
* Total test:
```
# openssl s_client -quiet -connect relay.grnet.gr:587 -starttls smtp
depth=2 C = US, ST = New Jersey, L = Jersey City, O = The USERTRUST Network, CN = USERTrust RSA Certification Authority
verify return:1
depth=1 C = NL, O = GEANT Vereniging, CN = GEANT OV RSA CA 4
verify return:1
depth=0 C = GR, ST = Attik\C3\AD, O = National Infrastructures for Research and Technology, CN = relay.grnet.gr
verify return:1
250 HELP
MAIL FROM: <kkalev@noc.ntua.gr>
250 OK
RCPT TO: <kkalev@gunet.gr>
250 Accepted
DATA
354 Enter message, ending with "." on a line by itself
Subject: Test
test
.
250 OK id=1q6SbR-0007fb-Tr
QUIT
221 relay.grnet.gr closing connection
```
* Test SMTP auth:
```
# echo -n "username" | base64
dXNlcm5hbWU=
# echo -n "password" | base64
cGFzc3dvcmQ=

(cut)
250 8BITMIME
AUTH LOGIN
334 VXNlcm5hbWU6
dXNlcm5hbWU=
334 UGFzc3dvcmQ6
cGFzc3dvcmQ=
235 2.7.0 Authentication successful
```
## OpenSSL Timer
* OpenSSL also provides an option to time SSL connections for a server: `openssl s_time -connect <host>:<port>`
