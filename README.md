# Customer0 PCF+GCP Concourse Pipeline
	
	
- STATUS=Currently in Dev (see image for status)
- MVP will be used for Pivotal Customer0 Solution Validation
- MVP +1 will expand Pivotal Solution Validation testing
- MVP +2 will be portable


	![alt text](https://github.com/pivotal-customer0/pcf-gcp/raw/master/images/C0-mvp-pcfgcp-pipeline.png "Some Foobitty Goodness!")
	
	
To Use the Current WIP Master Pipeline...

`fly -t c0-gcp set-pipeline -p pcf+gcp-v0.0.0 -c pcf-gcp-concourse/pipeline.yml -l /pcf-gcp-concourse/params/mglab.yml`


You will need...

A Concourse Params File (as of Aug 3, 2016):

```
##############################################
### Concourse Objects
##############################################
## Concourse Required Params

# Semver file name to trigger full pipeline builds
# Requires S3 Bucket
semver_file_name: <<somefilename>>
# aws creds for semver s3 bucket
aws_id: <<get-ur-own-aws-id>>
aws_key: <<get-ur-own-aws-secret>>
# github RSA private key for git resources
githubsshkey: |-
  -----BEGIN RSA PRIVATE KEY-----
  <<get-ur-own-github-ssh-key>>
  -----END RSA PRIVATE KEY-----

##############################################
### Bosh & CF Object Params
##############################################
# stemcell
stemcell_version: latest
# Bosh manifest template located in git repo manifests/
bosh_manifest_template: "pcf-gcp-concourse/manifests/bosh-init.template"
bosh_cloud_config_template: "pcf-gcp-concourse/manifests/cloud-config.template"
bosh_director_user: <<get-ur-own-bosh-user>>
bosh_director_password: <<get-ur-own-bosh-passwd>>
bosh_subnet_static_range_1: 10.1.0.4
bosh_subnet_static_range_2: 10.1.0.10
bosh_subnet_reserved_range_1: 10.1.0.1-10.1.0.2
bosh_subnet_reserved_range_2: 10.1.0.60-10.1.0.63
bosh_subnet_DNS_range_1: 169.254.169.254
bosh_subnet_DNS_range_2: 8.8.8.8
# Concourse params
concourse_manifest_template: "pcf-gcp-concourse/manifests/concourse.template"
concourse_subnet_static_range_1: 10.1.1.11
concourse_subnet_static_range_2: 10.1.1.12
concourse_subnet_static_range_3: 10.1.1.13
concourse_subnet_static_range_4: 10.1.1.14
concourse_subnet_reserved_range_1: 10.1.1.1-10.1.1.10
concourse_subnet_reserved_range_2: 10.1.1.64-10.1.1.254
concourse_subnet_DNS_range_1: 169.254.169.254
concourse_subnet_DNS_range_2: 8.8.8.8
concourse_external_url: "<<get-ur-own-url>>"
concourse_basic_auth_username: "<<get-ur-own-cc-user>>"
concourse_basic_auth_password: "<<get-ur-own-cc-password>>"
# PCF - ERT
pcf_ert_version: latest
pcf_pivnet_token: <<get-ur-own-token>>
pcf_ert_sys_domain: <<get-ur-own-pcf-ert-sys-domain>>
pcf_subnet_zone1_static_range_1: "10.1.100.11-10.1.100.50"
pcf_subnet_zone1_reserved_range_1: "10.1.100.1-10.1.100.10"
pcf_subnet_zone1_reserved_range_2: "10.1.103.200-10.1.103.254"
pcf_subnet_zone1_DNS_range_1: 169.254.169.254
pcf_subnet_zone1_DNS_range_2: 8.8.8.8
pcf_subnet_zone2_static_range_1: "10.1.200.11-10.1.200.50"
pcf_subnet_zone2_reserved_range_1: "10.1.200.1-10.1.200.10"
pcf_subnet_zone2_reserved_range_2: "10.1.203.200-10.1.203.254"
pcf_subnet_zone2_DNS_range_1: 169.254.169.254
pcf_subnet_zone2_DNS_range_2: 8.8.8.8

##############################################
### Bosh GCP CPI Specific Params
##############################################
# Wipe Arg(s)
arg_wipe: wipe
### GCP
gcp_proj_id: google.com:pcf-demos
gcp_region: us-east1
gcp_zone_1: us-east1-d
gcp_zone_2: us-east1-c
gcp_svc_acct_key: |
  {
    "type": "service_account",
    "project_id": "google.com:blah",
    "private_key_id": "12345...",
    "private_key": "-----BEGIN PRIVATE KEY-----
get-ur-own-key,
    "client_email": "c0-concourse@customer0.net",
    "client_id": "12345...",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://accounts.google.com/o/oauth2/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/c0-concourse%40customer0.net"
  }
gcp_terraform_prefix: c0-ccdeploy-v1
gcp_terraform_subnet_bosh: "10.1.0.0/24"
gcp_terraform_subnet_bosh_gateway: "10.1.0.1"
gcp_terraform_subnet_bosh_static: "10.1.0.4"
gcp_terraform_subnet_concourse: "10.1.1.0/24"
gcp_terraform_subnet_concourse_gateway: "10.1.1.1"
gcp_terraform_subnet_pcf_zone1: "10.1.100.0/22"
gcp_terraform_subnet_pcf_zone1_gateway: "10.1.100.1"
gcp_terraform_subnet_pcf_zone2: "10.1.200.0/22"
gcp_terraform_subnet_pcf_zone2_gateway: "10.1.200.1"

```