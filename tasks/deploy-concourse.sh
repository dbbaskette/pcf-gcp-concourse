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
gcloud compute copy-files $1 ${gcp_terraform_prefix}-bosh-bastion:$2 \
--zone ${gcp_zone_1} --quiet
}

function fn_gcp_ssh {
  gcloud compute ssh bosh@${gcp_terraform_prefix}-bosh-bastion \
  --command "$1" \
  --zone ${gcp_zone_1}
}

#############################################################
########## Get Latest Concourse Bosh Releases ###############
#############################################################
CC_RELEASES=$(wget -q -O- https://concourse.ci/downloads.html | grep -m 1 "releases/download"  | grep -oh BOSH.* | perl -ne 'print map("$_\n", m/href=\".*?\"/g);' | tr -d '"' | awk -F "href=" '{print$2}')
mkdir -p ~/concourse-releases
for z in ${CC_RELEASES[@]}; do
  FILE_NAME=$(echo $z | awk -F "/" '{print$NF}')
  wget $z -O ~/concourse-releases/$FILE_NAME
done

#############################################################
########## Push Releases up to Bastion  #####################
#############################################################

fn_gcp_ssh "mkdir -p /home/bosh/concourse-releases"

for y in $(ls ~/concourse-releases/); do
  fn_gcp_scp ~/concourse-releases/$y /home/bosh/concourse-releases/$y
done