#!/bin/bash
#set -e
echo "test terraform exec here...."

export PATH=/opt/terraform/terraform:$PATH

/opt/terraform/terraform plan \
  -var "project=$gcp_proj_id" \
  -var "region=$gcp_region" \
  -var "resource-prefix=$gcp_terraform_prefix" \
  -var "bosh-subnet-cidr-range=$gcp_terraform_subnet_bosh" \
  -var "zone1=$gcp_zone_1" \
  -var "zone2=$gcp_zone_2" \
  -var "concourse-subnet-public-cidr-range=$gcp_terraform_subnet_concourse_private" \
  -var "concourse-subnet-private-cidr-range=$gcp_terraform_subnet_pcf_private" \
  -var "pcf-subnet-private-zone1-cidr-range=$gcp_terraform_subnet_pcf_zone1_private" \
  -var "pcf-subnet-public-zone1-cidr-range=$gcp_terraform_subnet_pcf_zone1_public" \
  -var "pcf-subnet-private-zone2-cidr-range=$gcp_terraform_subnet_pcf_zone2_private" \
  -var "pcf-subnet-public-zone2-cidr-range=$gcp_terraform_subnet_pcf_zone2_public" \
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
    -var "concourse-subnet-public-cidr-range=$gcp_terraform_subnet_concourse_private" \
    -var "concourse-subnet-private-cidr-range=$gcp_terraform_subnet_pcf_private" \
    -var "pcf-subnet-private-zone1-cidr-range=$gcp_terraform_subnet_pcf_zone1_private" \
    -var "pcf-subnet-public-zone1-cidr-range=$gcp_terraform_subnet_pcf_zone1_public" \
    -var "pcf-subnet-private-zone2-cidr-range=$gcp_terraform_subnet_pcf_zone2_private" \
    -var "pcf-subnet-public-zone2-cidr-range=$gcp_terraform_subnet_pcf_zone2_public" \
    -var "sys-domain=$pcf_ert_sys_domain" \
    -var "key-json=$gcp_svc_acct_key" \
    pcf-gcp/terraform/pcf
