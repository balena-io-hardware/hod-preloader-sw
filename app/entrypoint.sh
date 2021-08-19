#!/bin/bash

set -eu

teardown() {
    sig=$?
    echo "$0: caught signal ${sig}!"
    pkill dockerd
    exit ${sig}
}

trap "teardown" TERM INT QUIT EXIT

# start dockerd if env var is set
if [ "${DOCKERD:-}" = "1" ]
then
    for path in $(echo "${DOCKER_HOST}" | xargs -n1 | sed -nr 's/unix:\/\/(.+)/\1/p') "${DOCKER_EXEC_ROOT}" "${DOCKER_PIDFILE}"
    do
        test -e "${path}" || continue
        rm -rv "${path}" || true
    done

    dockerd_args=()
    dockerd_args+=(--host="${DOCKER_HOST}")
    dockerd_args+=(--pidfile="${DOCKER_PIDFILE}")
    dockerd_args+=(--log-driver="${DOCKER_LOG_DRIVER}")
    dockerd_args+=(--data-root="${DOCKER_DATA_ROOT}")
    dockerd_args+=(--exec-root="${DOCKER_EXEC_ROOT}")
    dockerd_args+=(--dns="${DOCKER_DNS1}")
    dockerd_args+=(--dns="${DOCKER_DNS2}")
    readarray -O 8 -t dockerd_args <<< "${DOCKER_EXTRA_ARGS}"

    echo "Docker daemon args: ${dockerd_args[*]}"
    dockerd "${dockerd_args[@]}" 2>&1 | tee "${DOCKER_LOGFILE}" &

    while ! grep -q 'API listen on' "${DOCKER_LOGFILE}"
    do
        pgrep dockerd >/dev/null || exit 1
        sleep 2
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
