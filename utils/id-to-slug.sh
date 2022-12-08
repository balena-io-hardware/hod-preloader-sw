# !/bin/bash

FLEET_ID=$1
AUTH_TOKEN=$2

echo $FLEET_ID
echo $AUTH_TOKEN

# curl -X GET \
# "https://api.balena-cloud.com/v6/application(${FLEET_ID})" \
# -H "Content-Type: application/json" \
# -H "Authorization: Bearer ${AUTH_TOKEN}" 

OUTPUT=$(curl -X GET \
"https://api.balena-cloud.com/v6/application?\$filter=is_directly_accessible_by__user/any(dau:1%20eq%201)" \
-H "Content-Type: application/json" \
-H "Authorization: Bearer ${AUTH_TOKEN}") 

echo $OUTPUT

FLEETS=$(echo $OUTPUT | jq -c '.d | .[] | .slug' )
ID=$(echo $OUTPUT | jq -c '.d | .[] | .id' )

echo $FLEETS | tr " " "\n" > fleets.txt 
echo $ID | tr " " "\n" > id.txt 