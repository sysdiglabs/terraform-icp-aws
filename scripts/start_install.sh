#!/bin/bash

source /tmp/icp_scripts/functions.sh

##### MAIN #####
while getopts ":b:i:" arg; do
    case "${arg}" in
      b)
        s3_config_bucket=${OPTARG}
        ;;
      i)
        inception_image=${OPTARG}
        ;;
    esac
done

# Figure out the version
# This will populate $org $repo and $tag
parse_icpversion ${inception_image}
echo "registry=${registry:-not specified} org=$org repo=$repo tag=$tag"

inception_image=${registry}${registry:+/}${org}/${repo}:${tag}

# create the cluster directory and merge the custom config
docker run \
  -e LICENSE=accept \
  -v /opt/ibm:/data ${inception_image} \
  cp -r cluster /data

# pull down the config items
aws s3 cp s3://${s3_config_bucket}/hosts /opt/ibm/cluster/hosts
aws s3 cp s3://${s3_config_bucket}/cfc-certs /opt/ibm/cluster/cfc-certs
aws s3 cp s3://${s3_config_bucket}/ssh_key /opt/ibm/cluster/ssh_key
aws s3 cp s3://${s3_config_bucket}/icp-terraform-config.yaml /tmp/icp-terraform-config.yaml

# append the image repo
if [ ! -z "${registry}${registry:+}" ]; then
  echo "image_repo: ${registry}${registry:+/}${org}" >> /tmp/icp-terraform-config.yaml
fi

# append private registry user, password if we detect it
if [ ! -z "${username}" ]; then
  echo "docker_username: ${username}" >> /tmp/icp-terraform-config.yaml
  echo "docker_password: ${password}" >> /tmp/icp-terraform-config.yaml
  echo "private_registry_enabled: true" >> /tmp/icp-terraform-config.yaml
  echo "private_registry_server: ${registry}${registry:+}" >> /tmp/icp-terraform-config.yaml
fi

# merge config
python - <<EOF
import os, sys, yaml, json, getpass
ci = '/tmp/icp-terraform-config.yaml'
co = '/opt/ibm/cluster/config.yaml'

# Load config items if provided
with open(ci, 'r') as stream:
  config_i = yaml.load(stream)

with open(co, 'r') as stream:
  try:
    config_o = yaml.load(stream)
  except yaml.YAMLError as exc:
    print(exc)

# Second accept any changes from supplied config items
config_o.update(config_i)

# Automatically add the ansible_become if it does not exist, and if we are not root
if not 'ansible_user' in config_o and getpass.getuser() != 'root':
  config_o['ansible_user'] = getpass.getuser()
  config_o['ansible_become'] = True

# Write the new configuration
with open(co, 'w') as of:
  yaml.safe_dump(config_o, of, explicit_start=True, default_flow_style = False)
EOF

chmod 400 /opt/ibm/cluster/ssh_key

# find my IP address, which will be on the interface the default route is configured on
myip=`ip route get 8.8.8.8 | awk 'NR==1 {print $NF}'`

# wait for all hosts in the cluster to finish cloud-init
export ANSIBLE_HOST_KEY_CHECKING=false
ansible \
  -i /opt/ibm/cluster/hosts all:\!${myip} \
  --private-key /opt/ibm/cluster/ssh_key \
  -u icpdeploy \
  -b \
  -m wait_for \
  -a "path=/var/lib/cloud/instance/boot-finished timeout=18000"

# kick off the installer
docker run \
  -e LICENSE=accept \
  --net=host \
  -t \
  -v /opt/ibm/cluster:/installer/cluster \
  ${inception_image} \
  install

# backup the config
aws s3 sync /opt/ibm/cluster s3://${s3_config_bucket}
