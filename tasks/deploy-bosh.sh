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
####### Detect bosh, CPI, stemcell  versions ################
#############################################################
# Bosh Release
bosh_release=latest
bosh_gcp_cpi_release=latest
echo "Getting sha for bosh release:${bosh_release} ..."
if [[ ${bosh_release} -eq "latest" ]]; then
     BOSH_SHA1=$(wget -q -O- http://bosh.io/releases/github.com/cloudfoundry/bosh?latest | grep sha | head -n 1 | awk '{print$2}')
     BOSH_URL=$(wget -q -O- http://bosh.io/releases/github.com/cloudfoundry/bosh?latest | grep url | head -n 1 | awk '{print$2}')
else
     BOSH_SHA1=$(wget -q -O- http://bosh.io/releases/github.com/cloudfoundry/bosh?version=${bosh_release} | grep sha | head -n 1 | awk '{print$2}')
     BOSH_URL=$(wget -q -O- http://bosh.io/releases/github.com/cloudfoundry/bosh?version=${bosh_release}| grep url | head -n 1 | awk '{print$2}')
fi

if [[ ! $(echo $BOSH_SHA1 | perl -pe 's/^[0-9a-f]{40}$/true/g') -eq "true" ]]; then
    echo "ERROR: wget did dot return a valid SHA1 for bosh release..."
    echo "ERROR: I got :$BOSH_SHA1"
    exit 1
fi
# Bosh Google CPI
echo "Getting sha & url for bosh gcp cpi release:${bosh_gcp_cpi_release} ..."
if [[ ${bosh_gcp_cpi_release} -eq "latest" ]]; then
     GCP_CPI=$(wget -q -O- https://storage.googleapis.com/bosh-cpi-artifacts | perl -ne 'print map("$_\n", m/<Key>bosh-google-cpi.*?Key>/g);' | awk -F "-" '{print$4}' | grep -v sha1 | perl -pe  's~\.tgz</Key>$~~g' | sort -ur | head -n 1)
else
     GCP_CPI=$bosh_gcp_cpi_release
fi
GCP_CPI_URL="https://storage.googleapis.com/bosh-cpi-artifacts/bosh-google-cpi-$GCP_CPI.tgz"
GCP_CPI_SHA1=$(wget -q -O- $GCP_CPI_URL.sha1)

if [[ ! $(echo $GCP_CPI_SHA1 | perl -pe 's/^[0-9a-f]{40}$/true/g') -eq "true" ]]; then
    echo "ERROR: wget did dot return a valid SHA1 for bosh gcp cpi release..."
    echo "ERROR: I got :$GCP_CPI_SHA1"
    exit 1
fi
# Determine Stemcell
if [[ ${bosh_stemcell_version} -eq "latest" ]]; then
     AVAIL_GCP_STEMCELLS=$(wget -q -O- https://storage.googleapis.com/bosh-cpi-artifacts | perl -ne 'print map("$_\n", m/<Key>.*?light-bosh-stemcell.*?Key>/g);' | grep -v "<Contents>" | awk -F "-" '{print$4}' | sort -u)
     IFS=$'\n'
     STEMCELL_ID=$(echo "${AVAIL_GCP_STEMCELLS[*]}" | sort -nr | head -n1)
else
     STEMCELL_ID=$bosh_stemcell_version
fi
STEMCELL_URL="https://storage.googleapis.com/bosh-cpi-artifacts/light-bosh-stemcell-$STEMCELL_ID-google-kvm-ubuntu-trusty-go_agent.tgz"
STEMCELL_SHA1=$(wget -q -O- $STEMCELL_URL.sha1)

echo "Using the following for bosh-init manifest:"
echo "BOSH_URL=$BOSH_URL"
echo "BOSH_SHA1=$BOSH_SHA1"
echo "GCP_CPI_URL=$GCP_CPI_URL"
echo "GCP_CPI_SHA1=$GCP_CPI_SHA1"
echo "STEMCELL_URL=$STEMCELL_URL"
echo "STEMCELL_SHA1=$STEMCELL_SHA1"

#############################################################
#################### Gen Bosh Manifest ######################
#############################################################
# Edit Bosh Manifest & Deploy BOSH, at some point in future we can change to ENAML
echo "Updating BOSH Manifest template $bosh_manifest_template ..."
if [ ! -f $bosh_manifest_template ]; then
    echo "Error: Bosh Manifest $bosh_manifest_template not found !!!"
    exit 1
fi

bosh_manifest="/tmp/bosh-init.yml"
cp $bosh_manifest_template $bosh_manifest

#Alt regex delim ~ for subnet cidr & url variables
perl -pi -e "s~<<gcp_terraform_subnet_bosh>>~$gcp_terraform_subnet_bosh~g" $bosh_manifest
perl -pi -e "s/<<gcp_terraform_subnet_bosh_gateway>>/$gcp_terraform_subnet_bosh_gateway/g" $bosh_manifest
perl -pi -e "s/<<gcp_terraform_subnet_bosh_static>>/$gcp_terraform_subnet_bosh_static/g" $bosh_manifest
perl -pi -e "s/<<gcp_terraform_prefix>>/$gcp_terraform_prefix/g" $bosh_manifest
perl -pi -e "s/<<gcp_region>>/$gcp_region/g" $bosh_manifest
perl -pi -e "s/<<gcp_proj_id>>/$gcp_proj_id/g" $bosh_manifest
perl -pi -e "s/<<gcp_zone_1>>/$gcp_zone_1/g" $bosh_manifest
perl -pi -e "s/<<bosh_director_user>>/$bosh_director_user/g" $bosh_manifest
perl -pi -e "s/<<bosh_director_password>>/$bosh_director_password/g" $bosh_manifest
perl -pi -e "s~<<BOSH_URL>>~$BOSH_URL~g" $bosh_manifest
perl -pi -e "s/<<BOSH_SHA1>>/$BOSH_SHA1/g" $bosh_manifest
perl -pi -e "s~<<GCP_CPI_URL>>~$GCP_CPI_URL~g" $bosh_manifest
perl -pi -e "s/<<GCP_CPI_SHA1>>/$GCP_CPI_SHA1/g" $bosh_manifest
perl -pi -e "s~<<STEMCELL_URL>>~$STEMCELL_URL~g" $bosh_manifest
perl -pi -e "s/<<STEMCELL_SHA1>>/$STEMCELL_SHA1/g" $bosh_manifest

echo "Will use the following manifest:"
cat $bosh_manifest


#############################################################
#################### Deploy Bosh via Bastion ################
#############################################################
echo "Deploying BOSH ..."

# Send manifest up to Bastion
#gcloud compute copy-files ${bosh_manifest} ${gcp_terraform_prefix}-bosh-bastion:/home/bosh --zone ${gcp_zone_1} --quiet
fn_gcp_scp_up ${bosh_manifest} "/home/bosh/bosh-init.yml"

# Start bosh-init deploy on Bastion, but first check for bosh-init to exist since metadata_startup_script is slow
GCP_CMD="while [ ! -f /sbin/bosh-init ]; do echo \"metadata_startup_script has not deployed bosh-init yet...\"; sleep 10 ; done && echo \"Found bosh-init...\""
fn_gcp_ssh "$GCP_CMD" root
# Test if we are running deploy again on bastion thats already deployed & wipe the json state to deploy new bosh (assumes old one is wiped manual)
fn_gcp_ssh "if [ -f /home/bosh/bosh-init-state.json ]; then rm -rf /home/bosh/bosh-init-state.json ; fi" root
# Run bosh-init on bastion
fn_gcp_ssh "cd /home/bosh && bosh-init --version && bosh-init deploy /home/bosh/bosh-init.yml"

echo "Sleeping 3 minutes while BOSH starts..."
sleep 180
# Target BOSH
fn_gcp_ssh "bosh -n target https://${gcp_terraform_subnet_bosh_static}"
#Login to BOSH
echo "Logging into director with:  bosh -n login ${bosh_director_user} ${bosh_director_password}"
fn_gcp_ssh "bosh -n login ${bosh_director_user} ${bosh_director_password}"
#Get BOSH Status && UUID
fn_gcp_ssh "bosh -n status"


#############################################################
#################### Gen Cloud Config  ######################
#############################################################
# Edit cloud-config & Deploy BOSH, at some point in future we can change to ENAML
echo "Updating cloud-config template $bosh_cloud_config_template ..."
if [ ! -f $bosh_cloud_config_template ]; then
    echo "Error: cloud-config $bosh_cloud_config_template not found !!!"
    exit 1
fi

cloud_config="/tmp/cloud_config.yml"
cp $bosh_cloud_config_template $cloud_config

#Alt regex delim ~ for subnet cidr variables
perl -pi -e "s~<<gcp_terraform_subnet_bosh>>~$gcp_terraform_subnet_bosh~g" $cloud_config
perl -pi -e "s/<<gcp_terraform_subnet_bosh_gateway>>/$gcp_terraform_subnet_bosh_gateway/g" $cloud_config
perl -pi -e "s~<<gcp_terraform_subnet_concourse>>~$gcp_terraform_subnet_concourse~g" $cloud_config
perl -pi -e "s/<<gcp_terraform_subnet_concourse_gateway>>/$gcp_terraform_subnet_concourse_gateway/g" $cloud_config
perl -pi -e "s~<<gcp_terraform_subnet_pcf_zone1>>~$gcp_terraform_subnet_pcf_zone1~g" $cloud_config
perl -pi -e "s/<<gcp_terraform_subnet_pcf_zone1_gateway>>/$gcp_terraform_subnet_pcf_zone1_gateway/g" $cloud_config
perl -pi -e "s~<<gcp_terraform_subnet_pcf_zone2>>~$gcp_terraform_subnet_pcf_zone2~g" $cloud_config
perl -pi -e "s/<<gcp_terraform_subnet_pcf_zone2_gateway>>/$gcp_terraform_subnet_pcf_zone2_gateway/g" $cloud_config
perl -pi -e "s/<<gcp_terraform_subnet_bosh_static>>/$gcp_terraform_subnet_bosh_static/g" $cloud_config
perl -pi -e "s/<<gcp_terraform_prefix>>/$gcp_terraform_prefix/g" $cloud_config
perl -pi -e "s/<<gcp_region>>/$gcp_region/g" $cloud_config
perl -pi -e "s/<<gcp_proj_id>>/$gcp_proj_id/g" $cloud_config
perl -pi -e "s/<<gcp_zone_1>>/$gcp_zone_1/g" $cloud_config
perl -pi -e "s/<<gcp_zone_2>>/$gcp_zone_2/g" $cloud_config
perl -pi -e "s/<<bosh_director_user>>/$bosh_director_user/g" $cloud_config
perl -pi -e "s/<<bosh_director_password>>/$bosh_director_password/g" $cloud_config
perl -pi -e "s/<<bosh_subnet_static>>/$bosh_subnet_static/g" $cloud_config
perl -pi -e "s/<<bosh_subnet_reserved>>/$bosh_subnet_reserved/g" $cloud_config
perl -pi -e "s/<<bosh_subnet_DNS>>/$bosh_subnet_DNS/g" $cloud_config
perl -pi -e "s/<<concourse_subnet_static>>/$concourse_subnet_static/g" $cloud_config
perl -pi -e "s/<<concourse_subnet_reserved>>/$concourse_subnet_reserved/g" $cloud_config
perl -pi -e "s/<<concourse_subnet_DNS>>/$concourse_subnet_DNS/g" $cloud_config
perl -pi -e "s/<<pcf_subnet_zone1_static>>/$pcf_subnet_zone1_static/g" $cloud_config
perl -pi -e "s/<<pcf_subnet_zone1_reserved>>/$pcf_subnet_zone1_reserved/g" $cloud_config
perl -pi -e "s/<<pcf_subnet_zone1_DNS>>/$pcf_subnet_zone1_DNS/g" $cloud_config
perl -pi -e "s/<<pcf_subnet_zone2_static>>/$pcf_subnet_zone2_static/g" $cloud_config
perl -pi -e "s/<<pcf_subnet_zone2_reserved>>/$pcf_subnet_zone2_reserved/g" $cloud_config
perl -pi -e "s/<<pcf_subnet_zone2_DNS>>/$pcf_subnet_zone2_DNS/g" $cloud_config

echo "Will use the following cloud-config:"
cat $cloud_config


#############################################################
#################### Update Cloud Config     ################
#############################################################
echo "Updating Cloud Config ..."
fn_gcp_scp_up $cloud_config /home/bosh/cloud-config.yml
fn_gcp_ssh "bosh update cloud-config /home/bosh/cloud-config.yml"

#############################################################
#################### Upload Stemcell         ################
#############################################################
echo "Uploading stemcell ${bosh_stemcell_version} ..."
#Upload stemcell...
fn_gcp_ssh "bosh upload stemcell $STEMCELL_URL"
