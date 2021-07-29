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
    rm -rv "${DOCKER_EXEC_ROOT}" "${DOCKER_PIDFILE}" "${DOCKER_HOST/unix:\/\//}" || true
    dockerd \
        --host="${DOCKER_HOST}" \
        --pidfile="${DOCKER_PIDFILE}" \
        --log-driver="${DOCKER_LOG_DRIVER}" \
        --data-root="${DOCKER_DATA_ROOT}" \
        --exec-root="${DOCKER_EXEC_ROOT}" \
        --dns="${DOCKER_DNS1}" \
        --dns="${DOCKER_DNS2}" \
        2>&1 | tee "${DOCKER_LOGFILE}" &

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
