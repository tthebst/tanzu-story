#!/bin/bash

user=$1
password=$2
ip=$3
datacenter=$4
photon_image=$5
datastore=$6
resource_pool=$7
haproxy_image=$8

whoami

#create vm in vcenter from TKG ovas
govc folder.create -persist-session=false -u $user:"$password"@$ip -k=true -dc=$datacenter /$datacenter/vm/TKG

govc import.spec /home/tkg/$photon_image.ova | jq ".Name=\"$photon_image\"" | jq '.NetworkMapping[0].Network="VM Network"' >/home/tkg/$photon_image.json

govc import.ova -persist-session=false -u $user:"$password"@$ip -k=true -dc=$datacenter -ds=$datastore -pool=$resource_pool -options=/home/tkg/$photon_image.json /home/tkg/$photon_image.ova

govc object.mv -persist-session=false -u $user:"$password"@$ip -k=true -dc=$datacenter /$datacenter/vm/$photon_image /$datacenter/vm/TKG

govc import.spec /home/tkg/$haproxy_image.ova | jq ".Name=\"$haproxy_image\"" | jq '.NetworkMapping[0].Network="VM Network"' >/home/tkg/$haproxy_image.json

govc import.ova -persist-session=false -u $user:"$password"@$ip -k=true -dc=$datacenter -ds=$datastore -pool=$resource_pool -options=/home/tkg/$haproxy_image.json /home/tkg/$haproxy_image.ova

govc object.mv -persist-session=false -u $user:"$password"@$ip -k=true -dc=$datacenter /$datacenter/vm/$haproxy_image /$datacenter/vm/TKG

govc snapshot.create -persist-session=false -u $user:"$password"@$ip -k=true -dc=$datacenter -vm /$datacenter/vm/TKG/$photon_image root

govc vm.markastemplate -persist-session=false -u $user:"$password"@$ip -k=true -dc=$datacenter /$datacenter/vm/TKG/$photon_image

govc snapshot.create -persist-session=false -u $user:"$password"@$ip -k=true -dc=$datacenter -vm /$datacenter/vm/TKG/$haproxy_image root

govc vm.markastemplate -persist-session=false -u $user:"$password"@$ip -k=true -dc=$datacenter /$datacenter/vm/TKG/$haproxy_image

# turn off vsphere 7 kubernetes add on
sshpass -p "$password" ssh -o StrictHostKeyChecking=no "$user"@$ip 'service-control --stop wcp'

yes | tkg init --infrastructure=vsphere
