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
clusterawsadm alpha bootstrap create-stack
bash ./create-creds.sh <AWS_ACCESS_KEY_ID> <AWS_SECRET_ACCESS_KEY> <AWS_REGION>
tkg init --infrastructure=aws --plan=dev  --config config.yaml
tkg create cluster tkg-demo --plan=dev --config config.yaml
tkg get credentials tkg-demo --config config.yaml 
```



Create ebs storage class:

```
kubectl apply -f store-class.yml
```

Deploy Harbor. But first created tls certificates and deploy them as a secret to kubernetes and add harbor to trusted CA
```
sudo certbot certonly --standalone
sudo kubectl create secret generic tls-harbor --from-file=tls.crt=/etc/letsencrypt/live/harbor.tanzudemo.ml/fullchain.pem --from-file=tls.key=/etc/letsencrypt/live/harbor.tanzudemo.ml/privkey.pem


helm install harbor harbor/harbor --set harborAdminPassword=secretharbor --set expose.type=loadBalancer --set expose.tls.secretName=tls-harbor --set expose.ingress.hosts.core=harbor.tanzudemo.ml --set externalURL=https://harbor.tanzudemo.ml
```


### Prepare repository for build service:

Go to Route53 and create an zone "internal" and connect it to the VPC of the ubuntu jumpbox. In the zone add a CNAME record with the FQDN of the ELB of  harbor

```
kubectl get svc harbor
```

Now go to harbor.tanzudemo.ml and add a project for your buildservice named build-service

```
docker login harbor.tanzudemo.ml/build-service
duffle relocate -f ~/build-service-0.1.0.tgz -m /tmp/relocated.json -p harbor.tanzudemo.ml/build-service
sudo duffle install -v build-service -c credentials.yaml --set kubernetes_env=tkg-demo --set docker_registry=harbor.tanzudemo.ml --set docker_repository=harbor.tanzudemo.ml/build-service --set registry_username=admin --set registry_password=secretharbor --set custom_builder_image=harbor.tanzudemo.ml/build-service/default-builder -f ~/build-service-0.1.0.tgz  -m /tmp/relocated.json
```

Build Petclinic on TBS:
```
pb secrets registry apply -f registry-creds.yaml
pb image apply -f buildservice/example-build.yaml
```





```
helm install concourse concourse/concourse --set web.service.type=LoadBalancer
```



Install certbor on ubuntu:
```
sudo apt-get update
sudo apt-get install software-properties-common
sudo add-apt-repository universe
sudo add-apt-repository ppa:certbot/certbot
sudo apt-get update
sudo apt-get install certbot
```


Harbor2 bugfix 

```
kubectl set env deployment/kpack-controller -n kpack LIFECYCLE_IMAGE=kpack/lifecycle-080@sha256:8b0dea6d3ac03a2d4a2e6728e64ae0d6bf15bf619d4bfbe9ddd70e0fcd7909bc
```



Connect local browser 
```
ssh -vv -ND 8888 -i "default.pem" ubuntu@ec2-3-127-107-117.eu-central-1.compute.amazonaws.com
```
firefox-> prefrences->networksettings-> Manual Proxy config-> SOCKS Host-> localhost 8888-> OK

[proxy localhost](https://stackoverflow.com/questions/57419408/how-to-make-firefox-use-a-proxy-server-for-localhost-connections)