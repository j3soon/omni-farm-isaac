#!/bin/bash -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$DIR/../.."
docker build -f Dockerfile.isaac_sim -t j3soon/omni-farm-isaac-sim:local .
