# HOW TO

### On jumpbox

Requirements:
- Docker
- Kubeclt
- AWS cli
- jq

Preconfigure AWS credentials to start tkg

```
bash ./create-creds.sh <AWS_ACCESS_KEY_ID> <AWS_SECRET_ACCESS_KEY> <AWS_REGION>
tkg init --infrastructure=aws --plan=dev  --config config.yaml
```



Create ebs storage class:

```
kubectl apply -f store-class.yml
```

Deploy Harbor. But first created tls certificates and deploy them as a secret to kubernetes
```
sh ./gen-cert.sh

helm install harbor harbor/harbor --set harborAdminPassword=secretharbor --set expose.type=loadBalancer --set expose.tls.secretName=tls-harbor --set expose.loadBalancer.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-internal"=\"true\"
```



helm install concourse concourse/concourse --set web.service.type=LoadBalancer
```

On ubuntu:

sudo cp core.harbor.internal.crt /usr/share/ca-certificates/core.harbor.internal.crt
echo core.harbor.internal.crt >> sudo nano /etc/ca-certificates.conf
sudo update-ca-certificates --fresh
curl https://core.harbor.internal

forward browser:

ssh -vv -ND 8888 -i "default.pem" ubuntu@ec2-3-127-107-117.eu-central-1.compute.amazonaws.com

firefox-> prefrences->networksettings-> Manual Proxy config-> SOCKS Host-> localhost 8888-> OK