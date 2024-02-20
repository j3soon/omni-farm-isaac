#!/bin/bash -e

openvpn3 session-manage --disconnect --config omni-farm
openvpn3 sessions-list
