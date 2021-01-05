#!/bin/bash

set -eux

# on any kind of exit code, sleep forever
trap 'tail -f /dev/null' EXIT

# keep the filenames somewhat unique
target_img="/images/balena-preload-${PRELOAD_APP_NAME}"
target_img="${target_img}-${CONFIG_DEVICE_TYPE}"
target_img="${target_img}-${DOWNLOAD_OS_VERSION/+/-}"
target_img="${target_img}-${PRELOAD_APP_RELEASE}"
target_img="${target_img}.img"

# balena login with api key
balena login --token "${CLI_API_KEY}"

# verify the app exists and has at least one release
balena app "${PRELOAD_APP_NAME}" | grep -q COMMIT

# download the specified os version
balena os download "${CONFIG_DEVICE_TYPE}" \
    --version "${DOWNLOAD_OS_VERSION}" \
    --output "${target_img}" \
    --debug

# configure the downloaded os
balena os configure "${target_img}" \
    --app "${PRELOAD_APP_NAME}" \
    --config-network "${CONFIG_NETWORK}" \
    --config-wifi-ssid "${CONFIG_WIFI_SSID:-}" \
    --config-wifi-key "${CONFIG_WIFI_KEY:-}" \
    --device-type "${CONFIG_DEVICE_TYPE}" \
    --debug

# preload the app containers and optionally pin the release
case ${PRELOAD_APP_PINNED} in
y)
    balena preload "${target_img}" \
        --app "${PRELOAD_APP_NAME}" \
        --commit "${PRELOAD_APP_RELEASE}" \
        --pin-device-to-release \
        --debug
    ;;
n)
    balena preload "${target_img}" \
        --app "${PRELOAD_APP_NAME}" \
        --commit "${PRELOAD_APP_RELEASE}" \
        --debug
    ;;
*)
    echo "PRELOAD_APP_PINNED must be 'y' or 'n'"
    exit 1
    ;;
esac
