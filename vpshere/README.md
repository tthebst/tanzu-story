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

```bash
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

```bash
kubectl apply -f store-class.yml
```

## Deploy internet facing Load Balancer

Deploy [contour](https://projectcontour.io/)

```bash
helm repo add stable https://kubernetes-charts.storage.googleapis.com/
helm repo update
helm install contour stable/contour
```

## Create Certificates for Concourse && Harbor

To make things easier it is a good idea to use certificates everywhere. The easiest way to do this is to get yourself a domain and issue certificates for this domain. If you are using AWS it is a good idea to use Route53.

1. Go to [freenom](freenom.com) to get a free domain name
2. Go to AWS Route53 and create hosted zone with your domain name
3. Add A record set to your hosted which is pointing to the public IP of your jumpbox
4. Install [Certbot](#Install-certbort)
5. `sudo certbot certonly --standalone` for harbor use **harbor.\<your Domain\>**
6. `sudo certbot certonly --standalone` for concourse use **cicd.\<your Domain\>**
7. Create harbor secret `sudo kubectl create secret tls tls-harbor --cert=/etc/letsencrypt/live/harbor.<your Domain>/fullchain.pem --key=/etc/letsencrypt/live/harbor.<your Domain>/privkey.pem`
8. Create harbor secret `sudo kubectl create secret tls concourse-web-tls --cert=/etc/letsencrypt/live/cicd.<your Domain>/fullchain.pem --key=/etc/letsencrypt/live/cicd.<your Domain>/privkey.pem`

## Configure DNS

Run following command to get the external address of your ingress.

```bash
kubectl describe svc contour --namespace default | grep Ingress | awk '{print $3}'
```

Now go to Route53 and create a new **CNAME** Record set. With **HOST: \*.\<your Domain\>** and the CNAME entry pointing to your ingress.

## Install Harbor

```bash
helm install harbor harbor/harbor --set harborAdminPassword=secretharbor --set expose.tls.secretName=tls-harbor --set expose.ingress.hosts.core=harbor.<your Domain> --set externalURL=https://harbor.<your Domain>
```

You can now access harbor under **harbor.\<your Domain\>** with **username: admin** and **password: secretharbor**.

## Install Tanzu Build Service

Now go to your Harbor registry and add a project for your buildservice named build-service

```bash
docker login harbor.<your Domain>/build-service

duffle relocate -f ~/build-service-0.1.0.tgz -m /tmp/relocated.json -p harbor.<your Domain>/build-service

sudo duffle install -v build-service -c credentials.yaml --set kubernetes_env=tkg-demo --set docker_registry=harbor.<your Domain> --set docker_repository=harbor.<your Domain>/build-service --set registry_username=admin --set registry_password=secretharbor --set custom_builder_image=harbor.<your Domain>/build-service/default-builder -f ~/build-service-0.1.0.tgz -m /tmp/relocated.json
```

Build Petclinic Demo Application with TBS. Tanzu build service will automatically detect the source code and build a container image which gets pushed to Harbor.

```bash
pb secrets registry apply -f registry-creds.yaml
pb image apply -f buildservice/example-build.yaml
```

### Concourse

Concourse is a CI/CD Platform. You can deploy it onto your cluster and access it at  **cicd.\<your Domain\>**.

```bash
sudo certbot certonly --standalone //cicd.tanzudemo.ml
sudo kubectl create secret tls concourse-web-tls --cert=/etc/letsencrypt/live/cicd.<your Domain>/fullchain.pem --key=/etc/letsencrypt/live/cicd.<your Domain>/privkey.pem
helm repo add concourse https://concourse-charts.storage.googleapis.com/
helm repo update
helm install concourse concourse/concourse -f concourse/values.yaml
```

## General Tips

## Install certbort

```bash
sudo apt-get update
sudo apt-get install software-properties-common
sudo add-apt-repository universe
sudo add-apt-repository ppa:certbot/certbot
sudo apt-get update
sudo apt-get install certbot
```


## Connect local browser with Remote

This allows you to use the firefox browser on your local machine as if you were on the remote machine. It works by proxying the browser requests through ssh socket to the remote.

```bash 
ssh -vv -ND 8888 -i "<YOUR AWS INSTANCE KEY>" ubuntu@ec2-3-127-107-117.eu-central-1.compute.amazonaws.com
```

firefox-> prefrences->networksettings-> Manual Proxy config-> SOCKS Host-> localhost 8888-> OK

You can also proxy calls to localhost to the remote by following the steps from this [post](https://stackoverflow.com/questions/57419408/how-to-make-firefox-use-a-proxy-server-for-localhost-connections).





## Troubleshooting

### Reinstall Tanzu Build Service

```bash 
sudo duffle uninstall -v build-service -c credentials.yaml -m /tmp/relocated.json
rm /tmp/relocated.json > /dev/null
```


### Harbor 2.0 bugfix

Known issue with pushing to Harbor 2.0 from Tanzu Build Service. Gets fixed by updating kpack to newer version.
```bash 
kubectl set env deployment/kpack-controller -n kpack LIFECYCLE_IMAGE=kpack/lifecycle-080@sha256:8b0dea6d3ac03a2d4a2e6728e64ae0d6bf15bf619d4bfbe9ddd70e0fcd7909bc
```
