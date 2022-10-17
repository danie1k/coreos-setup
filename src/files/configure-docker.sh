#!/usr/bin/env bash
set -e

# Grafana Loki logging driver
# ----------------------------------------------------------------------------
# https://grafana.com/docs/loki/latest/clients/docker-driver/
if /usr/bin/docker plugin list | grep loki >/dev/null 2>&1; then
  /usr/bin/logger "Upgrading grafana/loki Docker driver"
  /usr/bin/docker plugin disable loki --force
  /usr/bin/docker plugin upgrade loki grafana/loki-docker-driver:latest --grant-all-permissions
  /usr/bin/docker plugin enable loki
else
  /usr/bin/logger "Installing grafana/loki Docker driver"
  /usr/bin/docker plugin install grafana/loki-docker-driver:latest --alias loki --grant-all-permissions
fi

/usr/bin/logger "Configuring Docker daemon"
# https://grafana.com/docs/loki/latest/clients/docker-driver/configuration/
cat << EOF > /etc/docker/daemon.json
{
  "debug": false,
  "log-driver": "loki",
  "log-opts": {
    "loki-url": "{{docker.loki.url}}",
    "loki-batch-size": "{{docker.loki.batch_size}}",
    "no-file": "true",
    "max-size": "1m",
    "loki-external-labels": "job=docker,container={% raw %}{{.Name}}{% endraw %},hostname={{core.hostname}}"
  }
}
EOF


# The "Internal" network
# ----------------------------------------------------------------------------
if ! /usr/bin/docker network inspect "{{docker.internal_network_name}}" >/dev/null 2>&1; then
  /usr/bin/logger "Creating '{{docker.internal_network_name}}' Docker network"

  /usr/bin/docker network create \
    --driver bridge \
    --internal \
    "{{docker.internal_network_name}}"
else
  /usr/bin/logger "Docker network '{{docker.internal_network_name}}' already exists"
fi


# The "External" network
# ----------------------------------------------------------------------------
if ! /usr/bin/docker network inspect "{{docker.external_network_name}}" >/dev/null 2>&1; then
  /usr/bin/logger "Creating '{{docker.external_network_name}}' Docker network"

  /usr/bin/docker network create \
    --driver bridge \
    "{{docker.external_network_name}}"
else
  /usr/bin/logger "Docker network '{{docker.external_network_name}}' already exists"
fi
