# !/bin/bash

FLEET_ID=$1
AUTH_TOKEN=$2

echo $FLEET_ID
echo $AUTH_TOKEN

OUTPUT=$(curl -X GET \
"https://api.balena-cloud.com/v6/application?\$filter=is_directly_accessible_by__user/any(dau:1%20eq%201)" \
-H "Content-Type: application/json" \
-H "Authorization: Bearer ${AUTH_TOKEN}") 

FLEETS=$(echo $OUTPUT | jq -c '.d | .[] | .slug' )

echo $FLEETS | tr " " "\n" > fleets.txt 