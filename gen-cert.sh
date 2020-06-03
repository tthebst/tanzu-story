rm core.harbor.internal.key
rm ca.key
rm core.harbor.internal.csr
rm core.harbor.internal.crt

openssl genrsa -out ca.key 4096
openssl req -x509 -new -nodes -sha512 -days 3650 -subj "/C=CN/ST=Beijing/L=Beijing/O=example/OU=Personal/CN=core.harbor.internal" -key ca.key -out ca.crt
openssl genrsa -out core.harbor.internal.key 4096
openssl req -sha512 -new -subj "/C=CN/ST=Beijing/L=Beijing/O=example/OU=Personal/CN=core.harbor.internal" -key core.harbor.internal.key -out core.harbor.internal.csr

openssl x509 -req -sha512 -days 3650 -CA ca.crt -CAkey ca.key -CAcreateserial -in core.harbor.internal.csr -out core.harbor.internal.crt
kubectl create secret generic tls-harbor --from-file=ca.crt=./ca.crt --from-file=tls.crt=./core.harbor.internal.crt --from-file=tls.key=./core.harbor.internal.key
