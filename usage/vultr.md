```bash
#!/bin/bash

readonly VULTR_API_KEY="B44SKSTH5KDF2EJJX3FRPZLTM4F53NY6MJXQ"
readonly API_BASE_URL="https://api.vultr.com/v2"
```
# 列出 instance
```bash
instance_id=$(curl -s "$API_BASE_URL/instances" -H "Authorization: Bearer $VULTR_API_KEY" | jq -r '.instances[] | .id') && echo $instance_id
```

# destroy 
```bash
if [[ ! -z "$instance_id" ]];then
    echo "Destroying instance $instance_id..."
    http_code=$(curl -s -w "%{http_code}" -o /tmp/vultr_destroy.json \
        -X DELETE \
        -H "Authorization: Bearer $VULTR_API_KEY" \
        "$API_BASE_URL/instances/$instance_id")

    [[ "$http_code" == "204" ]] && echo "Instance $instance_id destroyed successfully." || jq . /tmp/vultr_destroy.json
fi
```

# deploy
```bash
region=${1:-nrt} # curl -s -X GET "${API_BASE_URL}/regions" -H "Authorization: Bearer ${VULTR_API_KEY}" | jq '.regions[]'
plan=${2:-vc2-1c-1gb} # curl -s -X GET "${API_BASE_URL}/plans" -H "Authorization: Bearer ${VULTR_API_KEY}" | jq '.plans[] | .id'
os_id=${3:-535} # curl -s -X GET "${API_BASE_URL}/os" -H "Authorization: Bearer ${VULTR_API_KEY}" | jq '.os[] | .id ,.name'
backups=${4:-disabled} 

payload=$(jq -n \
    --arg region "$region" \
    --arg plan "$plan" \
    --argjson os_id "$os_id" \
    --arg backups "$backups" \
    '{region: $region, plan: $plan, os_id: $os_id, backups: $backups}')

echo "Deploying $payload ..."
curl -s "$API_BASE_URL/instances" \
    -X POST \
    -H "Authorization: Bearer $VULTR_API_KEY" \
    -H "Content-Type: application/json" \
    --data "$payload" | jq .
```
