#!/bin/bash

# Set default value
container_image=${1:-"sspworkflow:latest"}
mode=${2:-"production"}
container_name="${container_image%%:*}"


# Function to display help message
display_help() {
    echo "Usage: sspworkflow-run-prod <container-name> <mode>"
    echo "If no parameter is provided, the default container name is 'sspworkflow:latest'."
    echo "Parameter mode can be one of 'production' (default value), 'devtheme' or 'dev'. This parameter determines which folders will be bind mounted. (feature under development)"
}

# Check if help option is provided
if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    display_help
    exit 0
fi

mkdir -p work/metadata
mkdir -p store

if command -v podman &> /dev/null
then
    if podman container exists "$container_name"
    then
        podman start "$container_name" > /dev/null
    else
        podman run -it --name "$container_name" -d \
            -v ./work:/root/sspworkflow/work \
            -v ./store:/root/sspworkflow/store \
            "$container_image" > /dev/null
    fi
elif command -v docker &> /dev/null
then
    if docker container inspect "$container_name" > /dev/null 2>&1
    then
        docker start "$container_name" > /dev/null
    else
        docker run -it --name "$container_name" -d \
            -v ./work:/root/sspworkflow/work \
            -v ./store:/root/sspworkflow/store \
            "$container_image" > /dev/null
    fi
else
    echo "Neither Podman nor Docker is installed. Please install one of them to run the container."
fi
