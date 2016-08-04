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
unset FILE_NAME

#############################################################
########## Install omg-cli on Bastion  ######################
#############################################################
OMG_CLI="https://github.com$(wget -q -O- https://github.com/enaml-ops/omg-cli/releases/latest | grep omg-linux | awk -F '"' '{print$2}')"
echo "Installing $OMG_CLI to Bastion ..."
fn_gcp_ssh "wget $OMG_CLI -O /sbin/omg-cli" root
fn_gcp_ssh "chmod 755 /sbin/omg-cli" root

OMG_PRODUCT_CC="https://github.com$(wget -q -O- https://github.com/enaml-ops/omg-product-bundle/releases/latest | grep concourse-plugin-linux | awk -F '"' '{print$2}')"
echo "Installing OMG-CLI product $OMG_PRODUCT_CC to Bastion ..."
CC_ENAML_PLUGIN_FILE_NAME=$(echo $OMG_PRODUCT_CC | awk -F "/" '{print$NF}')
fn_gcp_ssh "if [ .plugins/product/concourse-plugin-linux ]; then rm .plugins/product/concourse-plugin-linux; fi"
fn_gcp_ssh "wget $OMG_PRODUCT_CC -O ~/$CC_ENAML_PLUGIN_FILE_NAME"
fn_gcp_ssh "omg-cli register-plugin --type product --pluginpath ~/$CC_ENAML_PLUGIN_FILE_NAME"

#############################################################
########## generate manifest for Concourse w/ ENAML  ########
#############################################################

export OMG_CC_DEPLOY_CMD="omg-cli deploy-product \
--bosh-url https://10.1.0.4 \
--bosh-port 25555 \
--bosh-user admin \
--bosh-pass gcpblah \
--ssl-ignore \
--print-manifest \
concourse-plugin-linux \
--web-vm-type concourse-public \
--worker-vm-type concourse-public \
--database-vm-type concourse-public \
--network-name concourse \
--url my.concourse.com \
--username concourse \
--password concourse \
--web-instances 1 \
--web-azs z1 \
--worker-azs z1 \
--database-azs z1 \
--bosh-stemcell-alias ubuntu-trusty \
--postgresql-db-pwd secret \
--database-storage-type large \
--stemcell-ver latest"

fn_gcp_ssh "$OMG_CC_DEPLOY_CMD > /home/bosh/concourse.yml"

#cat /tmp/blah.yml | grep -v "  sha" | grep -v "  url" | perl -pe '/\s\sversion.*$/ && s/version:.*/\s\sversion: latest/'
fn_gcp_ssh "perl -pi -e '/\s\sversion.*$/ && s/version:.*/version: latest/' /home/bosh/concourse.yml"
fn_gcp_ssh "cat /home/bosh/concourse.yml | grep -v '  sha' | grep -v '  url' > /home/bosh/concourse-scrub.yml"
