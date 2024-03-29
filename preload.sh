#!/usr/bin/env bash

set -eu

# keep container running after exit
trap 'tail -f /dev/null' EXIT

echo "balena CLI:"
balena version
docker version

mkdir -p /images

# keep the filenames somewhat unique
target_img="${PRELOAD_FLEET_SLUG/\//-/}"
target_img="${target_img}-${PRELOAD_DEVICE_TYPE}"
target_img="${target_img}-${PRELOAD_OS_VERSION}"
target_img="${target_img}-${PRELOAD_RELEASE}"
target_img="/images/${target_img//[^[:alnum:]_-]}.img"

# balena login with api key
echo "Logging in..."
balena login --token "${CLI_API_KEY}"

# download the specified os version
echo "Downloading OS version '${PRELOAD_OS_VERSION}' for device '${PRELOAD_DEVICE_TYPE}'..."
balena os download "${PRELOAD_DEVICE_TYPE}" \
    --version "${PRELOAD_OS_VERSION}" \
    --output "${target_img}" \
    --debug

if [ -n "${IMAGE_MD5SUM:-}" ]
then
    echo "Verifying the OS image md5sum '${IMAGE_MD5SUM}'..."
    md5sum /root/.balena/cache/* | tee /dev/stderr | grep -q "${IMAGE_MD5SUM}" || true
    md5sum "${target_img}" | tee /dev/stderr | grep -q "${IMAGE_MD5SUM}" || { echo "${target_img} failed verification!" ; exit 1 ; }
fi

# configure the downloaded os
echo "Configuring OS image with '${PRELOAD_NETWORK}'..."
balena os configure "${target_img}" \
    --fleet "${PRELOAD_FLEET_SLUG}" \
    --config-network "${PRELOAD_NETWORK}" \
    --config-wifi-ssid "${PRELOAD_WIFI_SSID:-}" \
    --config-wifi-key "${PRELOAD_WIFI_KEY:-}" \
    --device-type "${PRELOAD_DEVICE_TYPE}" \
    --debug

# preload the fleet containers and optionally pin the release
echo "Preloading image with release '${PRELOAD_RELEASE}'..."
case ${PRELOAD_PINNED} in
y)
    balena preload "${target_img}" \
        --fleet "${PRELOAD_FLEET_SLUG}" \
        --commit "${PRELOAD_RELEASE}" \
        --pin-device-to-release \
        --debug
    ;;
n)
    balena preload "${target_img}" \
        --fleet "${PRELOAD_FLEET_SLUG}" \
        --commit "${PRELOAD_RELEASE}" \
        --debug
    ;;
*)
    echo "PRELOAD_PINNED must be 'y' or 'n'"
    exit 1
    ;;
esac

echo "Preload complete!"
echo "Images can be downloaded via file server on port 80."
