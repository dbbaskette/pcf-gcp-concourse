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
gcloud config set compute/region $gcp_region
gcloud config set compute/zone $gcp_zone_1_1

# Wipe all GCP Instances for given prefix within Zone ##MG Todo: Serial processing is slow,  look for a quicker way to wipe Instances
echo "Will delete all compute/instances objects with the prefix=$gcp_proj_id in zone=$gcp_zone_1"
for i in $(gcloud compute instances list | grep $gcp_terraform_prefix | awk '{print $1}'); do

	 echo "Deleting Instance:$i ..."
	 gcloud compute instances delete $i --quiet --zone $gcp_zone_1 --delete-disks all

done
echo "All compute/instances with the prefix=$gcp_proj_id in zone=$gcp_zone_1 have been wiped !!!"

# Wipe Created network and all associated objects (Routes, Firewall Rules, routes)
echo "Will delete all compute/networks objects with the prefix=$gcp_proj_id in zone=$gcp_zone_1"
declare -a COMPONENT=(
"firewall-rules"
"routes"
"forwarding-rules"
"subnets"
"networks"
)

for z in ${COMPONENT[@]}; do
	echo "Will delete all $z objects with the prefix=$gcp_proj_id in zone=$gcp_zone_1"
	if [[ $z == "subnets" ]]; then z="networks $z"; fi
	for i in $(gcloud compute $z list  | grep $gcp_terraform_prefix | grep -v default | awk '{print $1}'); do
   echo "Deleting $z:$i ..."
	 if [[ $z == "subnets" ]]; then
		 	echo "using gcloud cli beta function to delete subnet..."
	    gcloud beta compute networks $z delete $i --region $gcp_region --quiet
	 else
		 	gcloud compute $z delete $i --quiet;
	 fi
  done
done
echo "All compute/networks objects with the prefix=$gcp_proj_id in zone=$gcp_zone_1 have been wiped !!!"

#################### GCP End   ##########################
