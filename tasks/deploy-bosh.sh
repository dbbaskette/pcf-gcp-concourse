#!/bin/bash
set -e

#################### GCP Auth Begin ##########################
echo $gcp_svc_acct_key > /tmp/blah
gcloud auth activate-service-account --key-file /tmp/blah
rm -rf /tmp/blah

gcloud config set project $gcp_proj_id
gcloud config set compute/region $gcp_region


#################### Gen BOSH Manifest ######################
#### Edit Bosh Manifest & Deploy BOSH
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

echo "Will use the following manifest:"
cat $bosh_manifest



#################### Deploy Bosh ############################
echo "Deploying BOSH ..."
# Send Manifest up to Bastion
gcloud compute copy-files ${bosh_manifest} ${gcp_terraform_prefix}-bosh-bastion:/home/bosh --zone ${gcp_zone_1} --quiet
# Gen BOSH instance SSH Keys on Bastion
gcloud compute ssh ${gcp_terraform_prefix}-bosh-bastion \
--command "cd /home/bosh && ssh-keygen -t rsa -f bosh_key -P '' -C '' && chmod 400 bosh_key" \
--zone ${gcp_zone_1}
# Start bosh-init deploy on Bastion
gcloud compute ssh ${gcp_terraform_prefix}-bosh-bastion \
--command "cd /home/bosh && bosh-init deploy /home/bosh/bosh-init.yml" \
--zone ${gcp_zone_1}


# Target Bosh and test Status Reply
echo "sleep 3 minutes while BOSH starts..."
#sleep 180
#BOSH_TARGET=$(cat /tmp/bosh.yml | shyaml get-values jobs.0.networks.0.static_ips)
#BOSH_LOGIN=$(cat /tmp/bosh.yml | shyaml get-value jobs.0.properties.director.user_management.local.users.0.name)
#BOSH_PASSWD=$(cat /tmp/bosh.yml | shyaml get-value jobs.0.properties.director.user_management.local.users.0.password)
#bosh -n target https://${bosh_deployment_network_ip}
#bosh -n login ${bosh_deployment_user} ${bosh_deployment_passwd}
#bosh status
exit 1
