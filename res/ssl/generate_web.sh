#!/bin/bash

openssl genrsa -days 3650 -out private_keys/localhost.pem 1024
openssl req -new -key private_keys/localhost.pem -out localhost.csr

openssl x509 -days 3650 -req -in localhost.csr -CA certs/ca.pem -CAkey private_keys/ca.pem -set_serial 1 -out certs/localhost.pem
rm localhost.csr
