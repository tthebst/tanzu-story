# HOW TO

### On jumpbox

Requirements:
- Docker
- Kubeclt (sudo snap install kubectl --classic)
- AWS cli
- jq 
- clusterawsadm
- tkg
- duffle
- pb
- build-service-0.1.0.tgz
- 20GB storage

Preconfigure AWS credentials to start tkg

```
bash ./create-creds.sh <AWS_ACCESS_KEY_ID> <AWS_SECRET_ACCESS_KEY> <AWS_REGION>
tkg init --infrastructure=aws --plan=dev  --config config.yaml
tkg create cluster tkg-demo --plan=dev --config config.yaml
```



Create ebs storage class:

```
kubectl apply -f store-class.yml
```

Deploy Harbor. But first created tls certificates and deploy them as a secret to kubernetes and add harbor to trusted CA
```
sh ./gen-cert.sh

helm install harbor harbor/harbor --set harborAdminPassword=secretharbor --set expose.type=loadBalancer --set expose.tls.secretName=tls-harbor --set expose.ingress.hosts.core=core.harbor.internal --set externalURL=https://core.harbor.internal
sudo cp core.harbor.internal.crt /usr/share/ca-certificates/core.harbor.internal.crt
sudo bash -c "echo core.harbor.internal.crt >>  /etc/ca-certificates.conf"
sudo update-ca-certificates --fresh
curl https://core.harbor.internal
```


### Prepare repository for build service:

Go to Route53 and create an zone "internal" and connect it to the VPC of the ubuntu jumpbox. In the zone add a CNAME record with the FQDN of the ELB of  harbor

```
kubectl get svc harbor
```

Now go to core.harbor.internal and add a project for your buildservice named build-service

```
docker login core.harbor.internal/build-service
duffle relocate -f ~/build-service-0.1.0.tgz -m /tmp/relocated.json -p core.harbor.internal/build-service
```





helm install concourse concourse/concourse --set web.service.type=LoadBalancer
```



forward browser:

ssh -vv -ND 8888 -i "default.pem" ubuntu@ec2-3-127-107-117.eu-central-1.compute.amazonaws.com

firefox-> prefrences->networksettings-> Manual Proxy config-> SOCKS Host-> localhost 8888-> OK