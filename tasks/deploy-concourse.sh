#!/bin/bash
set -e

#############################################################
#################### GCP Auth  & functions ##################
#############################################################
echo $gcp_svc_acct_key > /tmp/blah
gcloud auth activate-service-account --key-file /tmp/blah
rm -rf /tmp/blah

gcloud config set project $gcp_proj_id
gcloud config set compute/region $gcp_region

function fn_gcp_scp_up {
gcloud compute copy-files $1 bosh@${gcp_terraform_prefix}-bosh-bastion:$2 \
--zone ${gcp_zone_1} --quiet
}

function fn_gcp_ssh {

  if [ ! $2 ]; then
    gcp_ssh_user="bosh"
  else
    gcp_ssh_user=$2
  fi
  echo "gcloud compute ssh using id=$gcp_ssh_user ..."

  gcloud compute ssh $gcp_ssh_user@${gcp_terraform_prefix}-bosh-bastion \
  --command "$1" \
  --zone ${gcp_zone_1} --quiet
}

#############################################################
########## Get Latest Concourse Bosh Releases ###############
#############################################################
echo "Downloading Concourse Releases ..."
CC_RELEASES=$(wget -q -O- https://concourse.ci/downloads.html | grep -m 1 "releases/download"  | grep -oh BOSH.* | perl -ne 'print map("$_\n", m/href=\".*?\"/g);' | tr -d '"' | awk -F "href=" '{print$2}')
fn_gcp_ssh "mkdir -p ~/concourse-releases"
for z in ${CC_RELEASES[@]}; do
  FILE_NAME=$(echo $z | awk -F "/" '{print$NF}')
  fn_gcp_ssh "wget $z -O ~/concourse-releases/$FILE_NAME"
done

#############################################################
########## Install omg-cli on Bastion  ######################
#############################################################
OMG_CLI="https://github.com$(wget -q -O- https://github.com/enaml-ops/omg-cli/releases/latest | grep omg-linux | awk -F '"' '{print$2}')"
echo "Installing $OMG_CLI to Bastion ..."
fn_gcp_ssh "wget $OMG_CLI -O /sbin/omg-cli" root
fn_gcp_ssh "chmod 755 /sbin/omg-cli" root


exit 1
#wget https://github.com/enaml-ops/omg-product-bundle/releases/download/v0.0.8/concourse-plugin-linux
#wget https://github.com/enaml-ops/omg-cli/releases/download/v0.0.10/aws-cloudconfigplugin-linux

#omg-cli register-plugin --type cloudconfig --pluginpath aws-cloudconfigplugin-linux
