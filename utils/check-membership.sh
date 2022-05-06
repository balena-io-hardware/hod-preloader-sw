# !/bin/bash

FLEET_ID=$1
AUTH_TOKEN=$2

echo $FLEET_ID
echo $AUTH_TOKEN

OUTPUT=$(curl -X GET \
"https://api.balena-cloud.com/v6/organization" \
-H "Content-Type: application/json" \
-H "Authorization: Bearer ${AUTH_TOKEN}") 

echo $OUTPUT
MEMBERSHIP=$(echo $OUTPUT | jq -c '.d | .[] | .handle' )

echo $MEMBERSHIP | tr " " "\n" > membership.txt  