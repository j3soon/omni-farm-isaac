#!/bin/bash -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$DIR/../.."
docker build -f Dockerfile.isaac_lab -t j3soon/omni-farm-isaac-lab:local .
