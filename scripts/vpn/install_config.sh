#!/bin/bash -e

if openvpn3 configs-list | grep -q omni-farm; then
    echo "VPN session already installed."
    exit 1
fi
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
openvpn3 config-import --name omni-farm --config "$DIR/../../secrets/$1"
openvpn3 configs-list --verbose
