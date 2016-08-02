#!/bin/bash
#set -e
echo "Executing Terraform ...."

export PATH=/opt/terraform/terraform:$PATH

/opt/terraform/terraform plan \
  -var "project=$gcp_proj_id" \
  -var "region=$gcp_region" \
  -var "resource-prefix=$gcp_terraform_prefix" \
  -var "bosh-subnet-cidr-range=$gcp_terraform_subnet_bosh" \
  -var "zone1=$gcp_zone_1" \
  -var "zone2=$gcp_zone_2" \
  -var "concourse-subnet-cidr-range=$gcp_terraform_subnet_concourse" \
  -var "pcf-subnet-zone1-cidr-range=$gcp_terraform_subnet_pcf_zone1" \
  -var "pcf-subnet-zone2-cidr-range=$gcp_terraform_subnet_pcf_zone2" \
  -var "sys-domain=$pcf_ert_sys_domain" \
  -var "key-json=$gcp_svc_acct_key" \
  pcf-gcp/terraform/pcf

  /opt/terraform/terraform apply \
    -var "project=$gcp_proj_id" \
    -var "region=$gcp_region" \
    -var "resource-prefix=$gcp_terraform_prefix" \
    -var "bosh-subnet-cidr-range=$gcp_terraform_subnet_bosh" \
    -var "zone1=$gcp_zone_1" \
    -var "zone2=$gcp_zone_2" \
    -var "concourse-subnet-cidr-range=$gcp_terraform_subnet_concourse" \
    -var "pcf-subnet-zone1-cidr-range=$gcp_terraform_subnet_pcf_zone1" \
    -var "pcf-subnet-zone2-cidr-range=$gcp_terraform_subnet_pcf_zone2" \
    -var "sys-domain=$pcf_ert_sys_domain" \
    -var "key-json=$gcp_svc_acct_key" \
    pcf-gcp/terraform/pcf
