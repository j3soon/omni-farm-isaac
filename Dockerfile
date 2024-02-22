FROM nvcr.io/nvidia/isaac-sim:2023.1.1
COPY thirdparty/omnicli /omnicli
COPY scripts/docker/run.sh /run.sh
