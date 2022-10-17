#!/bin/bash
set -e

# https://github.com/coreos/docs/blob/master/os/hardening-guide.md


# Disable 'sudo' without password for 'core' user
# ----------------------------------------------------------------------------
/usr/bin/logger "Disable 'sudo' without password for 'core' user"
/usr/bin/gpasswd -d core wheel >/dev/null 2>&1 || /usr/bin/true
/usr/bin/gpasswd -d core sudo >/dev/null 2>&1 || /usr/bin/true


# Disable Docker access for 'core' user
# ----------------------------------------------------------------------------
/usr/bin/logger "Disable Docker access for 'core' user"
/usr/bin/gpasswd -d core docker >/dev/null 2>&1 || /usr/bin/true
/usr/bin/gpasswd -a docker docker >/dev/null 2>&1 || /usr/bin/true
