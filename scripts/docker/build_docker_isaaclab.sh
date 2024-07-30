#!/bin/bash -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$DIR/../.."
docker build -f Dockerfile.isaaclab -t j3soon/omni-farm-isaaclab:local .
