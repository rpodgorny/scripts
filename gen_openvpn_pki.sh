#!/bin/sh
set -e -x

DAYS=365000
KEY_SIZE=20148

#easyrsa init-pki
#easyrsa build-ca
#easyrsa gen-req server nopass
#exit 33


echo '
[ca]
default_ca=CA_default
[CA_default]
private_key=ca.key
certificate=ca.crt
new_certs_dir=.
database=./index.txt
default_md=
' > openssl.conf

echo "CZ







" | openssl req -days ${DAYS} -nodes -new -x509 -keyout ca.key -out ca.crt
#openssl dhparam -out dh${KEY_SIZE}.pem ${KEY_SIZE}
echo "CZ









" | openssl req -days ${DAYS} -nodes -new -keyout server.key -out server.csr
openssl ca -days ${DAYS} -out server.crt -in server.csr -config openssl.conf
