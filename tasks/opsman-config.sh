#!/bin/bash
set -e

#############################################################
#################### GCP Auth  & functions ##################
#############################################################
    echo $gcp_svc_acct_key > /tmp/blah
    gcloud auth activate-service-account --key-file /tmp/blah
    rm -rf /tmp/blah

    gcloud config set project $gcp_proj_id
    gcloud config set compute/region $gcp_region_1

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

### Get Opsman IP Address ###
opsmanip=$(gcloud compute addresses list | grep $gcp_terraform_prefix--opsmgr | awk '{print$3}')

### Config Opsman Local Auth ###
curl -k -X POST -H "Content-Type: application/json" \
-d '{ "setup": {
    "decryption_passphrase": "P1v0t4l!",
    "decryption_passphrase_confirmation":"P1v0t4l!",
    "eula_accepted": "true",
    "identity_provider": "internal",
    "admin_user_name": "admin",
    "admin_password": "P1v0t4l!",
    "admin_password_confirmation": "P1v0t4l!"
  } }' \
"https://$opsmanip/api/v0/setup"
