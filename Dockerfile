FROM nvcr.io/nvidia/isaac-sim:4.1.0
COPY thirdparty/omnicli /omnicli
COPY scripts/docker/run.sh /run.sh
