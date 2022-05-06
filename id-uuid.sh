# !/bin/bash

device=$(curl -X GET \
"https://api.balena-cloud.com/v6/device($1)" \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $2")

output=$(echo $device | jq -c '.d | .[] | .uuid' )
