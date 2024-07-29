#!/bin/bash -e

if openvpn3 sessions-list | grep -q omni-farm; then
    echo "VPN session already connected."
    exit 1
fi
openvpn3 session-start --config omni-farm
openvpn3 sessions-list
