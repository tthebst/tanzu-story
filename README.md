<a href="http://vmware.com"><img style="width: 10em;" src="https://logos-download.com/wp-content/uploads/2016/09/VMware_logo-700x107.png" title="FVCproductions" alt="FVCproductions"></a>

# TANZU STORY SETUP

These are the instruction to setup the tanzu-story demo. In general you need a jumpbox from where you control everything. As of now this tutorial is only for TKG on AWS.

## Jumpbox setup

It is recommended that you use ubuntu as a jumbox and add at least 20GB storage.

### Requirements

- [Docker](https://docs.docker.com/engine/install/ubuntu/#install-using-the-convenience-script)
- kubeclt (sudo snap install kubectl --classic)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
- jq (sudo apt install jq)
- [clusterawsadm]("https://www.vmware.com/go/get-tkg)
- [TKG](https://www.vmware.com/go/get-tkg)
- [duffle](https://network.pivotal.io/products/build-service)
- [pb](https://network.pivotal.io/products/build-service)</a> 
- [build-service-0.1.0.tgz](https://network.pivotal.io/products/build-service)</a>

### Initial TKG setup

First we need to have a working TKG cluster. This is mostly the same as in the TKG [documentation](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.1/vmware-tanzu-kubernetes-grid-11/GUID-index.html).

``` bash
clusterawsadm alpha bootstrap create-stack
bash ./create-creds.sh <AWS_ACCESS_KEY_ID> <AWS_SECRET_ACCESS_KEY> <AWS_REGION>
tkg init --infrastructure=aws --plan=dev  --config config.yaml
tkg create cluster tkg-demo --plan=dev --config config.yaml
tkg get credentials tkg-demo --config config.yaml
tkg get cluster tkg-demo --config config.yaml
kubectl config use-context <CONTEXT NAME>
```

### Create Storage Class for persistence

This will give kubernetes do dynamically provision volumes for deployments.

``` bash
kubectl apply -f store-class.yml
```

## Deploy internet facing Load Balancer

Deploy [contour](https://projectcontour.io/)

``` bash
helm repo add stable https://kubernetes-charts.storage.googleapis.com/
helm repo update
helm install contour stable/contour
```


Deploy Harbor. But first created tls certificates and deploy them as a secret to kubernetes and add harbor to trusted CA
```
sudo certbot certonly --standalone //harbor.tanzudemo.ml
sudo kubectl create secret tls tls-harbor --cert=/etc/letsencrypt/live/harbor.tanzudemo.ml/fullchain.pem --key=/etc/letsencrypt/live/harbor.tanzudemo.ml/privkey.pem


helm install harbor harbor/harbor --set harborAdminPassword=secretharbor --set expose.tls.secretName=tls-harbor --set expose.ingress.hosts.core=harbor.tanzudemo.ml --set externalURL=https://harbor.tanzudemo.ml 
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
rm /tmp/relocated.json > /dev/null
pb secrets registry apply -f registry-creds.yaml
pb image apply -f buildservice/example-build.yaml
```


### Concourse


```
sudo certbot certonly --standalone //cicd.tanzudemo.ml
sudo kubectl create secret tls concourse-web-tls --cert=/etc/letsencrypt/live/cicd.tanzudemo.ml/fullchain.pem --key=/etc/letsencrypt/live/cicd.tanzudemo.ml/privkey.pem
helm repo add concourse https://concourse-charts.storage.googleapis.com/
helm repo update
helm install concourse concourse/concourse -f concourse/values.yaml
```



### General Tips

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