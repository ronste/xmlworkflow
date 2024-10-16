#!/bin/bash

# Set default value
containername=${1:-"xmlworkflow:latest"}
mode=${2:-"production"}


# Function to display help message
display_help() {
    echo "Usage: xmlworkflow-run-prod <container-name> <mode>"
    echo "If no parameter is provided, the default container name is 'xmlworkflow:latest'."
    echo "Parameter mode can be one of 'production' (default value), 'devtheme' or 'dev'. This parameter determines which folders will be bind mounted. (feature under development)"
}

# Check if help option is provided
if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    display_help
    return 0
fi

mkdir -p work/metadata
mkdir -p store
mkdir -p theme

if command -v podman &> /dev/null
then
    podman run -it --name $1 -d \
        -v ./work:/root/xmlworkflow/work \
        -v ./store:/root/xmlworkflow/store \
        {containername}
        # binding for full dev mode needs to bind all folders individually (otherwise lib folder will not be available):
        # podman run -it --name xmlworkflow -d -v .:/root/xmlworkflow xmlworkflow:latest
elif command -v docker &> /dev/null
then
    docker run -it --name $1 -d \
        -v ./work:/root/xmlworkflow/work \
        -v ./store:/root/xmlworkflow/store \
        {containername}
else
    echo "Neither Podman nor Docker is installed. Please install one of them to run the container."
fi
