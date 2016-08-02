#!/bin/bash
set -e

#################### GCP Auth Begin ##########################
echo $gcp_svc_acct_key > /tmp/blah
gcloud auth activate-service-account --key-file /tmp/blah
rm -rf /tmp/blah

gcloud config set project $gcp_proj_id
gcloud config set compute/region $gcp_region


#################### Gen BOSH Manifest ######################
#### Edit Bosh Manifest & Deploy BOSH, at seom point in future we can change to ENAML
echo "Updating BOSH Manifest template $bosh_manifest_template ..."
if [ ! -f $bosh_manifest_template ]; then
    echo "Error: Bosh Manifest $bosh_manifest_template not found !!!"
    exit 1
fi

# Set Photon Specific Deployment Object IDs in BOSH Manifest
bosh_manifest="/tmp/bosh-init.yml"
cp $bosh_manifest_template $bosh_manifest

#Alt regex delim ~ for subnet cidr variable
perl -pi -e "s~<<gcp_terraform_subnet_bosh>>~$gcp_terraform_subnet_bosh~g" $bosh_manifest
perl -pi -e "s/<<gcp_terraform_subnet_bosh_gateway>>/$gcp_terraform_subnet_bosh_gateway/g" $bosh_manifest
perl -pi -e "s/<<gcp_terraform_subnet_bosh_static>>/$gcp_terraform_subnet_bosh_static/g" $bosh_manifest
perl -pi -e "s/<<gcp_terraform_prefix>>/$gcp_terraform_prefix/g" $bosh_manifest
perl -pi -e "s/<<gcp_region>>/$gcp_region/g" $bosh_manifest
perl -pi -e "s/<<gcp_proj_id>>/$gcp_proj_id/g" $bosh_manifest
perl -pi -e "s/<<gcp_zone_1>>/$gcp_zone_1/g" $bosh_manifest
perl -pi -e "s/<<bosh_director_user>>/$bosh_director_user/g" $bosh_manifest
perl -pi -e "s/<<bosh_director_password>>/$bosh_director_password/g" $bosh_manifest

echo "Will use the following manifest:"
cat $bosh_manifest



#################### Deploy Bosh ############################
echo "Deploying BOSH ..."
# Send Manifest up to Bastion
gcloud compute copy-files ${bosh_manifest} ${gcp_terraform_prefix}-bosh-bastion:/home/bosh --zone ${gcp_zone_1} --quiet
sleep 60
# Start bosh-init deploy on Bastion
gcloud compute ssh ${gcp_terraform_prefix}-bosh-bastion \
--command "cd /home/bosh && if [ -f /home/bosh/bosh-init-state.json ]; then rm -rf /home/bosh/bosh-init-state.json ; fi && /sbin/bosh-init deploy /home/bosh/bosh-init.yml" \
--zone ${gcp_zone_1}

echo "Sleeping 3 minutes while BOSH starts..."
sleep 180
# Target BOSH
gcloud compute ssh ${gcp_terraform_prefix}-bosh-bastion \
--command "bosh -n target https://${gcp_terraform_subnet_bosh_static}" \
--zone ${gcp_zone_1}

#Login to BOSH
gcloud compute ssh ${gcp_terraform_prefix}-bosh-bastion \
--command "bosh -n login ${bosh_director_user} ${bosh_director_password}" \
--zone ${gcp_zone_1}

#Get BOSH Status
gcloud compute ssh ${gcp_terraform_prefix}-bosh-bastion \
--command "bosh -n status" \
--zone ${gcp_zone_1}
