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

#export OMG_CC_DEPLOY_CMD="omg-cli deploy-product \
#--bosh-url https://10.1.0.4 \
#--bosh-port 25555 \
#--bosh-user admin \
#--bosh-pass gcpblah \
#--ssl-ignore \
#--print-manifest \
#concourse-plugin-linux \
#--web-vm-type concourse-public \
#--worker-vm-type concourse-public \
#--database-vm-type concourse-public \
#--network-name concourse \
#--url my.concourse.com \
#--username concourse \
#--password concourse \
#--web-instances 1 \
#--web-azs z1 \
#--worker-azs z1 \
#--database-azs z1 \
#--bosh-stemcell-alias ubuntu-trusty \
#--postgresql-db-pwd secret \
#--database-storage-type large \
#--stemcell-ver latest"

#fn_gcp_ssh "$OMG_CC_DEPLOY_CMD > /home/bosh/concourse.yml"
#############################################################
####### wont use enaml omg-cli just yet #####################
####### Need a new Plugin for concourse 1.6.x ###############
#############################################################


#############################################################
########## generate manifest for Concourse w/ BASH  #########
#############################################################
# Edit cloud-config & Deploy BOSH, at some point in future we can change to ENAML
echo "Updating Concourse template $concourse_manifest_template ..."
if [ ! -f $concourse_manifest_template ]; then
    echo "Error: Concourse template $concourse_manifest_template not found !!!"
    exit 1
fi

concourse_manifest="/tmp/concourse.yml"
cp $concourse_manifest_template $concourse_manifest

BOSH_UUID=$(fn_gcp_ssh "bosh status" | grep UUID | awk '{print$2}')

perl -pi -e "s/<<BOSH_UUID>>/$BOSH_UUID/g" $concourse_manifest
perl -pi -e "s/<<concourse_static_ips_web>>/$concourse_static_ips_web/g" $concourse_manifest
perl -pi -e "s~<<concourse_external_url>>~$concourse_external_url~g" $concourse_manifest
perl -pi -e "s/<<concourse_basic_auth_username>>/$concourse_basic_auth_username/g" $concourse_manifest
perl -pi -e "s/<<concourse_basic_auth_password>>/$concourse_basic_auth_password/g" $concourse_manifest
perl -pi -e "s/<<concourse_static_ips_db>>/$concourse_static_ips_db/g" $concourse_manifest
perl -pi -e "s/<<gcp_terraform_prefix>>/$gcp_terraform_prefix/g" $concourse_manifest

echo "Will Deploy Concourse using the following mainfest...."
cat $concourse_manifest
concourse_manifest_run="/home/bosh/concourse.yml"
fn_gcp_scp_up $concourse_manifest $concourse_manifest_run


#############################################################
########## Deploying Concourse                       ########
#############################################################
echo "Uploading Concourse Releases..."

for x in $(fn_gcp_ssh "ls /home/bosh/concourse-releases" bosh | grep -v 'gcloud compute ssh using id'); do
  fn_gcp_ssh "bosh upload release /home/bosh/concourse-releases/$x" bosh
done

fn_gcp_ssh "for i in $(ls ~/concourse-releases);do bosh upload release ~/concourse-releases/$i; done" bosh
echo "Deploying Concourse..."
fn_gcp_ssh "bosh deployment $concourse_manifest_run"
fn_gcp_ssh "bosh -n deploy"
