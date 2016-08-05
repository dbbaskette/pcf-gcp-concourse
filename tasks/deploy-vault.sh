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
########## Install omg-cli on Bastion  ######################
#############################################################
OMG_CLI="https://github.com$(wget -q -O- https://github.com/enaml-ops/omg-cli/releases/latest | grep omg-linux | awk -F '"' '{print$2}')"
echo "Installing $OMG_CLI to Bastion ..."
fn_gcp_ssh "wget $OMG_CLI -O /sbin/omg-cli" root
fn_gcp_ssh "chmod 755 /sbin/omg-cli" root

OMG_PRODUCT_CC="https://github.com$(wget -q -O- https://github.com/enaml-ops/omg-product-bundle/releases/latest | grep vault-plugin-linux | awk -F '"' '{print$2}')"
echo "Installing OMG-CLI product $OMG_PRODUCT_CC to Bastion ..."
CC_ENAML_PLUGIN_FILE_NAME=$(echo $OMG_PRODUCT_CC | awk -F "/" '{print$NF}')
fn_gcp_ssh "if [ -f .plugins/product/vault-plugin-linux ]; then rm .plugins/product/vault-plugin-linux; fi"
fn_gcp_ssh "wget $OMG_PRODUCT_CC -O ~/$CC_ENAML_PLUGIN_FILE_NAME"
fn_gcp_ssh "omg-cli register-plugin --type product --pluginpath ~/$CC_ENAML_PLUGIN_FILE_NAME"

#############################################################
########## Deploy Vault     w/ ENAML  #######################
#############################################################
echo "Using ENAML goodness to deploy Vault ..."
export OMG_CC_DEPLOY_CMD="omg-cli deploy-product \
--bosh-url https://$gcp_terraform_subnet_bosh_static \
--bosh-port 25555 \
--bosh-user $bosh_director_user \
--bosh-pass $bosh_director_password \
--ssl-ignore \
--print-manifest \
vault-plugin-linux \
# \
"

fn_gcp_ssh "$OMG_CC_DEPLOY_CMD" bosh
