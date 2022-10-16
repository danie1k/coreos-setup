#!/usr/bin/env bash
set -e

if ! /usr/bin/docker network inspect "{{docker.internal_network_name}}" >/dev/null 2>&1; then
  logger "Creating '{{docker.internal_network_name}}' Docker network"

  /usr/bin/docker network create \
    --driver bridge \
    --internal \
    "{{docker.internal_network_name}}"
else
  logger "Docker network '{{docker.internal_network_name}}' already exists"
fi

if ! /usr/bin/docker network inspect "{{docker.external_network_name}}" >/dev/null 2>&1; then
  logger "Creating '{{docker.external_network_name}}' Docker network"

  /usr/bin/docker network create \
    --driver bridge \
    "{{docker.external_network_name}}"
else
  logger "Docker network '{{docker.external_network_name}}' already exists"
fi
