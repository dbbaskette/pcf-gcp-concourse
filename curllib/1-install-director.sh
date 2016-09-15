#Authenticate to OpsMan

uaac target https://$1/uaa --skip-ssl-validation
uaac token owner get opsman admin -s "" -p example-password
export opsman_token=$(uaac context | grep access_token | awk -F ":" '{print$2}' | tr -d ' ')



# Get Bosh Product Guid
bosh_product=$(curl -k -X GET -H "Content-Type: application/json" -H "Authorization: Bearer $opsman_token" \
"https://$1/api/v0/staged/products" | \
jq '.[] | select(.type == "p-bosh") | .guid'  | tr -d '"')


curl -k -v -X GET -H "Content-Type: application/json" -H "Authorization: Bearer $opsman_token" \
"https://$1/api/v0/staged/products/$bosh_product/jobs"
