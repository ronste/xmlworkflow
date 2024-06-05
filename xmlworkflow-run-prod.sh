mkdir -p work/metadata
mkdir -p store

#!/bin/bash

if command -v podman &> /dev/null
then
    podman run -it --name xmlworkflow -d \
        -v ./work:/root/xmlworkflow/work \
        -v ./store:/root/xmlworkflow/store \
        xmlworkflow:latest
elif command -v docker &> /dev/null
then
    docker run -it --name xmlworkflow -d \
        -v ./work:/root/xmlworkflow/work \
        -v ./store:/root/xmlworkflow/store \
        xmlworkflow:latest
else
    echo "Neither Podman nor Docker is installed. Please install one of them to run the container."
fi