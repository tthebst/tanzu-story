#!/bin/bash

user=$1
password=$2
ip=$3
datacenter=$4
photon_image=$5
datastore=$6
resource_pool=$7
haproxy_image=$8

#create vm in vcenter from TKG ovas
sudo -u tkg bash -c "govc folder.create -u $user:"$password"@$ip -k=true -dc=$datacenter /$datacenter/vm/TKG"

sudo -u tkg bash -c "govc import.spec $photon_image.ova | jq ".Name=\"$photon_image\"" | jq '.NetworkMapping[0].Network="VM Network"' >$photon_image.json"

sudo -u tkg bash -c "govc import.ova -u $user:"$password"@$ip -k=true -dc=$datacenter -ds=$datastore -pool=$resource_pool -options=$photon_image.json $HOME/$photon_image.ova"

sudo -u tkg bash -c "govc object.mv -u $user:"$password"@$ip -k=true -dc=$datacenter /$datacenter/vm/$photon_image /$datacenter/vm/TKG"

sudo -u tkg bash -c "govc import.spec $haproxy_image.ova | jq ".Name=\"$haproxy_image\"" | jq '.NetworkMapping[0].Network="VM Network"' >$haproxy_image.json"

sudo -u tkg bash -c "govc import.ova -u $user:"$password"@$ip -k=true -dc=$datacenter -ds=$datastore -pool=$resource_pool -options=$haproxy_image.json $HOME/$haproxy_image.ova"

sudo -u tkg bash -c "govc object.mv -u $user:"$password"@$ip -k=true -dc=$datacenter /$datacenter/vm/$haproxy_image /$datacenter/vm/TKG"

sudo -u tkg bash -c "govc snapshot.create -u $user:"$password"@$ip -k=true -dc=$datacenter -vm /$datacenter/vm/TKG/$photon_image root"

sudo -u tkg bash -c "govc vm.markastemplate -u $user:"$password"@$ip -k=true -dc=$datacenter /$datacenter/vm/TKG/$photon_image"

sudo -u tkg bash -c "govc snapshot.create -u $user:"$password"@$ip -k=true -dc=$datacenter -vm /$datacenter/vm/TKG/$haproxy_image root"

sudo -c "govc vm.markastemplate -u $user:"$password"@$ip -k=true -dc=$datacenter /$datacenter/vm/TKG/$haproxy_image"

# turn off vsphere 7 kubernetes add on
sshpass -p "$password" ssh -o StrictHostKeyChecking=no "$user"@$ip 'service-control --stop wcp'
