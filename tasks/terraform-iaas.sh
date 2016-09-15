#!/bin/bash
set -e
echo "Executing Terraform ...."

export PATH=/opt/terraform/terraform:$PATH

/opt/terraform/terraform plan \
 -var "gcp_proj_id=$gcp_proj_id" \
  -var "gcp_region_1=$gcp_region_1" \
  -var "gcp_terraform_prefix=$gcp_terraform_prefix" \
  -var "gcp_terraform_subnet_bosh=$gcp_terraform_subnet_bosh" \
  -var "gcp_zone_1=$gcp_zone_1" \
  -var "gcp_zone_2=$gcp_zone_2" \
  -var "gcp_zone_3=$gcp_zone_3" \
  -var "gcp_terraform_subnet_ert_region_1=$gcp_terraform_subnet_ert_region_1" \
  -var "gcp_terraform_subnet_services_1_region_1=$gcp_terraform_subnet_services_1_region_1" \
  -var "pcf_ert_sys_domain=$pcf_ert_sys_domain" \
  -var "gcp_svc_acct_key=$gcp_svc_acct_key" \
  pcf-gcp-concourse/terraform/pcf-thd

  /opt/terraform/terraform apply \
    -var "gcp_proj_id=$gcp_proj_id" \
    -var "gcp_region_1=$gcp_region_1" \
    -var "gcp_terraform_prefix=$gcp_terraform_prefix" \
    -var "gcp_terraform_subnet_bosh=$gcp_terraform_subnet_bosh" \
    -var "gcp_zone_1=$gcp_zone_1" \
    -var "gcp_zone_2=$gcp_zone_2" \
    -var "gcp_zone_3=$gcp_zone_3" \
    -var "gcp_terraform_subnet_ert_region_1=$gcp_terraform_subnet_ert_region_1" \
    -var "gcp_terraform_subnet_services_1_region_1=$gcp_terraform_subnet_services_1_region_1" \
    -var "pcf_ert_sys_domain=$pcf_ert_sys_domain" \
    -var "gcp_svc_acct_key=$gcp_svc_acct_key" \
    pcf-gcp-concourse/terraform/pcf-thd

#############################################################
#################### GCP Auth  & functions ##################
#############################################################
    echo $gcp_svc_acct_key > /tmp/blah
    gcloud auth activate-service-account --key-file /tmp/blah
    rm -rf /tmp/blah

    gcloud config set project $gcp_proj_id
    gcloud config set compute/region $gcp_region_1

#############################################################
#################### Print vcap ssh key for OpsMan###########
#############################################################
    echo "============================"
    echo "SSH RSA Key for user vCAP..."
    echo "============================"
    ssh-keygen -b 2048 -t rsa -f ~/.ssh/google_compute_engine -q -N ""
    gcloud compute ssh vcap@$gcp_terraform_prefix-bosh-bastion --zone $gcp_zone_1 --command "cat /home/vcap/.ssh/vcap"
