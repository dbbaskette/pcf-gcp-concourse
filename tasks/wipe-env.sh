#!/bin/bash
set -e


if [ $arg_wipe == "wipe" ];
        then
                echo "Wiping Environment...."
        else
                echo "Need Args [0]=wipe "
                echo "Example: ./p1-0-wipe-env.sh wipe ..."
                exit 1
fi


#############################################################
#################### GCP Auth  & functions ##################
#############################################################
echo $gcp_svc_acct_key > /tmp/blah
gcloud auth activate-service-account --key-file /tmp/blah
rm -rf /tmp/blah

gcloud config set project $gcp_proj_id
gcloud config set compute/region $gcp_region


# Wipe all GCP Instances for given prefix within Zone ##MG Todo: Serial processing is slow,  look for a quicker way to wipe Instances
declare -a ZONE=(
$gcp_zone_1
$gcp_zone_2
)

for y in ${ZONE[@]}; do
	echo "----------------------------------------------------------------------------------------------"
  echo "Will delete all compute/instances objects with the prefix=$gcp_terraform_prefix in:"
	echo "project=$gcp_proj_id"
	echo "region=$gcp_region"
	echo "zone=$y"
	echo "----------------------------------------------------------------------------------------------"
  #for i in $(gcloud compute instances list --filter "tags.items[0]~${gcp_terraform_prefix}-instance OR tags.items[1]~${gcp_terraform_prefix}-instance OR tags.items[2]~${gcp_terraform_prefix}-instance" | grep $y | awk '{print $1}'); do
  MY_CMD="gcloud compute instances list --flatten tags.items[] --format json | jq '.[] | select ((.tags.items == \"$gcp_terraform_prefix-instance\" ) and (.zone == \"$y\")) | .name'"
  echo $MY_CMD
  for i in $($MY_CMD); do
  	 echo "Deleting Instance:$i ..."
  	 gcloud compute instances delete $i --quiet --zone $y --delete-disks all

  done
	echo "=============================================================================================="
  echo "All compute/instances with the prefix=$gcp_terraform_prefix in zone=$y have been wiped !!!"
	echo "=============================================================================================="
done


# Wipe Created network and all associated objects (routes,firewall-rules,forwarding-rules,subnets,networks,target-pools,etc...)
echo "Will delete all compute/networks objects with the prefix=$gcp_proj_id in zone=$gcp_zone_1"
declare -a COMPONENT=(
"firewall-rules"
"routes"
"forwarding-rules"
"subnets"
"networks"
"target-pools"
"http-health-checks"
"https-health-checks"
"addresses"
)

for z in ${COMPONENT[@]}; do
	echo "----------------------------------------------------------------------------------------------"
	echo "Will delete all $z objects with the prefix=$gcp_terraform_prefix in region=$gcp_region"
	echo "----------------------------------------------------------------------------------------------"
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
echo "=============================================================================================="
echo "All compute/networks objects with the prefix=$gcp_terraform_prefix in region=$gcp_region have been wiped !!!"
echo "=============================================================================================="

#Wipe Images ,  this pretty much means we want a deicated project
echo "----------------------------------------------------------------------------------------------"
echo "Will delete all compute/images stemcell objects where project=$gcp_proj_id"
echo "----------------------------------------------------------------------------------------------"
  for x in $(gcloud compute images list | grep $gcp_proj_id | grep stemcell | awk '{print $1}'); do

  	 echo "Deleting Image:$x ..."
  	 echo gcloud compute images delete $x --quiet

  done
echo "=============================================================================================="
echo "All compute/images stemcell objects where project=$gcp_proj_id have been wiped !!!"
echo "=============================================================================================="



#################### GCP End   ##########################
