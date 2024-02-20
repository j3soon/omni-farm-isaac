#!/bin/bash -e

openvpn3 config-remove --config omni-farm --force
openvpn3 configs-list --verbose
