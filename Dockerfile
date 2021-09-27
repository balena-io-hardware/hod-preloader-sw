# avoid alpine 3.13 or later due to this issue on armv7
# https://wiki.alpinelinux.org/wiki/Release_Notes_for_Alpine_3.13.0#time64_requirements
FROM node:14.17.6-alpine3.12 AS build

WORKDIR /usr/src/app

# install dependencies to build balena-cli via npm
# hadolint ignore=DL3018
RUN apk add --no-cache build-base ca-certificates curl git python3 wget linux-headers

ENV NODE_ENV production

COPY package.json ./

# install balena-cli via npm
RUN npm install

FROM node:14.17.6-alpine3.12 AS balena-cli

WORKDIR /usr/src/app

# copy app from build stage
COPY --from=build /usr/src/app/ ./

# update path to include app bin directory
ENV PATH $PATH:/usr/src/app/node_modules/.bin/

# https://github.com/balena-io/balena-cli/blob/master/INSTALL-LINUX.md#additional-dependencies
# hadolint ignore=DL3018
RUN apk add --no-cache avahi bash ca-certificates docker jq openssh

# fail if binaries are missing or won't run
RUN balena --version && dockerd --version && docker --version

# install entrypoint script
COPY entrypoint.sh ./

# extract the list of balena-cli commands and update the entrypoint script
RUN CLI_CMDS=$(jq -r '.commands | keys | map(.[0:index(":")]) | unique | join("\\ ")' < node_modules/balena-cli/oclif.manifest.json); \
    sed -e "s/CLI_CMDS=.*/CLI_CMDS=\"help\\ ${CLI_CMDS}\"/" -i entrypoint.sh && \
    chmod +x entrypoint.sh

ENTRYPOINT [ "/usr/src/app/entrypoint.sh" ]

# default balena-cli command
CMD [ "help" ]

ENV SSH_AUTH_SOCK /ssh-agent
ENV DOCKERD_EXTRA_ARGS ""

# docker data root must be a volume or tmpfs
VOLUME /var/lib/docker

FROM balena-cli

WORKDIR /usr/src/app

# install preload script
COPY preload.sh /usr/src/app/

RUN chmod +x /usr/src/app/preload.sh

CMD [ "/usr/src/app/preload.sh" ]

ENV DOCKERD 1
ENV PRELOAD_DEVICE_TYPE raspberrypi3
ENV PRELOAD_OS_VERSION latest
ENV PRELOAD_RELEASE current
ENV PRELOAD_NETWORK ethernet
ENV PRELOAD_PINNED y
