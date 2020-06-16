#!/bin/bash

config_file=$1

. ./$config_file

sed -i'' -e "s/<VCENTER IP>/$ip/g" config.yaml
sed -i'' -e "s/<VCENTER USERNAME>/$user/g" config.yaml
sed -i'' -e "s/<VCENTER PASSWORD>/$password/g" config.yaml
sed -i'' -e "s/<VCENTER DATACENTER NAME>/$datacenter/g" config.yaml
sed -i'' -e "s/<DATASTORE NAME>/$datastore/g" config.yaml
sed -i'' -e "s/<CLUSTER NAME>/$cluster_name/g" config.yaml
sed -i'' -e "s/<TKG OVA>/$photon_image/g" config.yaml
sed -i'' -e "s/<PROXY OVA>/"$haproxy_image"/g" config.yaml
sed -i'' -e "s/<JUMPBOX SSH KEY>/$ssh_key/g" config.yaml
sed -i'' -e "s/<RESOURCE POOL>/$resource_pool/g" config.yaml

#copy modified to .tkg
mkdir -p $HOME/.tkg/
cp ./vsphere/config.yaml $HOME/.tkg/config-yaml

#import OVAs
bash vsphere-mgm.sh $user $password $ip $datacenter $photon_image $datastore $resource_pool $haproxy_image
