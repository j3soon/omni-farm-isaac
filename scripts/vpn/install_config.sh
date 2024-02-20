#!/bin/bash -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
openvpn3 config-import --name omni-farm --config "$DIR/../../secrets/client.ovpn"
openvpn3 configs-list --verbose
