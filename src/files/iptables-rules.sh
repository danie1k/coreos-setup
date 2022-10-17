#!/bin/bash
set -e

# https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/do-more-with-tunnels/secure-server/#os-level-firewall

# Allow localhost to communicate with itself.
/usr/sbin/iptables -A INPUT -i lo -j ACCEPT

# Allow already established connection and related traffic
/usr/sbin/iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow incoming SSH traffic
/usr/sbin/iptables -A INPUT -p tcp --dport '{{core.sshd_port}}' -j ACCEPT

# Drop all other ingress traffic
/usr/sbin/iptables -P INPUT DROP


# TODO: Add docker restrictions
