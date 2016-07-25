#!/bin/bash
#set -e


if [ $arg_wipe == "wipe" ];
        then
                echo "Wiping Environment...."
        else
                echo "Need Args [0]=wipe "
                echo "Example: ./p1-0-wipe-env.sh wipe ..."
                exit 1
fi


#################### GCP Begin ##########################
## Stopid Reqs ...
## Create a svc account & enable the API by hand


echo $gcp_svc_acct_key > /tmp/blah

gcloud auth activate-service-account --key-file /tmp/blah
rm -rf /tmp/blah

gcloud config set project $gcp_proj_id

for i in $(gcloud compute instances list | grep c0-run1 | awk '{print $1}'); do

	 echo "Deleteing Instance:$i ..."
	 gcloud compute instances delete $i --quite --zone $gcp_zone --delete-disks all;

done

#################### GCP End   ##########################
