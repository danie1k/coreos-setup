#!/bin/bash

/usr/bin/docker pull portainer/portainer-ee:alpine

# Privileged mode is required for binding to local socket to work due to SELINUX
# https://github.com/portainer/portainer/issues/849
/usr/bin/docker run \
  --cpus 0.25 \
  --detach \
  --log-driver loki \
  --memory 128m \
  --name portainer \
  --network '{{docker.internal_network_name}}' \
  --privileged \
  --restart always \
  --user '{{docker.user.uid}}:{{docker.user.gid}}' \
  --volume '{{data_dir}}/portainer':/data \
  --volume /var/run/docker.sock:/var/run/docker.sock \
  portainer/portainer-ee:alpine
