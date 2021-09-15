#!/usr/bin/env bash

set -eu

# start dockerd if env var is set
if [ "${DOCKERD:-}" = "1" ]
then
    # remove default pid, log, host, and exec root
    rm -rv /var/run/docker* 2>/dev/null || true

    readarray -t dockerd_args <<< "${DOCKERD_EXTRA_ARGS}"

    echo "Starting Docker daemon with args: ${dockerd_args[*]}"

    # shellcheck disable=SC2068,SC2086
    dockerd ${dockerd_args[@]} &

    until docker info >/dev/null 2>&1
    do
      sleep 1
      pgrep dockerd >/dev/null || exit 1
    done
fi

# load private ssh key if one is provided
if [ -n "${SSH_PRIVATE_KEY:-}" ]
then
    # if an ssh agent socket was not provided, start our own agent
    [ -e "${SSH_AUTH_SOCK}" ] || eval "$(ssh-agent -s)"
    echo "${SSH_PRIVATE_KEY}" | tr -d '\r' | ssh-add -
fi

# space-separated list of balena CLI commands (filled in through `sed`
# in a Dockerfile RUN instruction)
CLI_CMDS="help"

# treat the provided command as a balena CLI arg...
# 1. if the first word matches a known entry in CLI_CMDS
# 2. OR if the first character is a hyphen (eg. -h or --debug)
if echo "${CLI_CMDS}" | grep -qr "\b${1}\b" || [ "${1:0:1}" = "-" ]
then
    exec balena "$@"
else
    exec "$@"
fi
