#!/bin/bash

/usr/bin/docker pull danie1k/cloudflared:latest

# Privileged mode is required for binding to local socket to work due to SELINUX
# https://github.com/portainer/portainer/issues/849
/usr/bin/docker run \
  --cpus 0.25 \
  --detach \
  --memory 128m \
  --name cloudflared \
  --network '{{docker.internal_network_name}}' \
  --restart always \
  --volume '{{data_dir}}/cloudflared/token':/argo/token:Z \
  danie1k/cloudflared:latest

/usr/bin/docker network connect '{{docker.external_network_name}}' cloudflared
