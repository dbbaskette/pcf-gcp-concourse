#!/bin/bash
set -e
echo "Executing Terraform ...."

export PATH=/opt/terraform/terraform:$PATH

/opt/terraform/terraform plan \
  -var "gcp_proj_id=$gcp_proj_id" \
  -var "gcp_region=$gcp_region" \
  -var "gcp_terraform_prefix=$gcp_terraform_prefix" \
  -var "gcp_terraform_subnet_bosh=$gcp_terraform_subnet_bosh" \
  -var "gcp_zone_1=$gcp_zone_1" \
  -var "gcp_zone_2=$gcp_zone_2" \
  -var "gcp_zone_3=$gcp_zone_3" \
  -var "gcp_terraform_subnet_concourse=$gcp_terraform_subnet_concourse" \
  -var "gcp_terraform_subnet_vault=$gcp_terraform_subnet_vault" \
  -var "gcp_terraform_subnet_pcf_zone1=$gcp_terraform_subnet_pcf_zone1" \
  -var "gcp_terraform_subnet_pcf_zone2=$gcp_terraform_subnet_pcf_zone2" \
  -var "pcf_ert_sys_domain=$pcf_ert_sys_domain" \
  -var "gcp_svc_acct_key=$gcp_svc_acct_key" \
  pcf-gcp-concourse/terraform/pcf

  /opt/terraform/terraform apply \
    -var "gcp_proj_id=$gcp_proj_id" \
    -var "gcp_region=$gcp_region" \
    -var "gcp_terraform_prefix=$gcp_terraform_prefix" \
    -var "gcp_terraform_subnet_bosh=$gcp_terraform_subnet_bosh" \
    -var "gcp_zone_1=$gcp_zone_1" \
    -var "gcp_zone_2=$gcp_zone_2" \
    -var "gcp_zone_3=$gcp_zone_3" \
    -var "gcp_terraform_subnet_concourse=$gcp_terraform_subnet_concourse" \
    -var "gcp_terraform_subnet_vault=$gcp_terraform_subnet_vault" \
    -var "gcp_terraform_subnet_pcf_zone1=$gcp_terraform_subnet_pcf_zone1" \
    -var "gcp_terraform_subnet_pcf_zone2=$gcp_terraform_subnet_pcf_zone2" \
    -var "pcf_ert_sys_domain=$pcf_ert_sys_domain" \
    -var "gcp_svc_acct_key=$gcp_svc_acct_key" \
    pcf-gcp-concourse/terraform/pcf
