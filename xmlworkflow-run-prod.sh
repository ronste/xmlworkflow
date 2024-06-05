#!/bin/bash

# Set default value
param=${1:-"xmlworkflow"}

# Function to display help message
display_help() {
    echo "Usage: xmlworkflow-run-prod <container-name>"
    echo "If no parameter is provided, the default container name is 'xmlworkflow'."
}

# Check if help option is provided
if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    display_help
    return 0
fi

mkdir -p work/metadata
mkdir -p store

if command -v podman &> /dev/null
then
    podman run -it --name $1 -d \
        -v ./work:/root/xmlworkflow/work \
        -v ./store:/root/xmlworkflow/store \
        xmlworkflow:latest
elif command -v docker &> /dev/null
then
    docker run -it --name $1 -d \
        -v ./work:/root/xmlworkflow/work \
        -v ./store:/root/xmlworkflow/store \
        xmlworkflow:latest
else
    echo "Neither Podman nor Docker is installed. Please install one of them to run the container."
fi
