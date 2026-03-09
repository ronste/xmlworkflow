#!/bin/bash

# Set default value
containername=${1:-"sspworkflow:latest"}
mode=${2:-"production"}


# Function to display help message
display_help() {
    echo "Usage: sspworkflow-run-prod <container-name> <mode>"
    echo "If no parameter is provided, the default container name is 'sspworkflow:latest'."
    echo "Parameter mode can be one of 'production' (default value), 'devtheme' or 'dev'. This parameter determines which folders will be bind mounted. (feature under development)"
}

# Check if help option is provided
if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    display_help
    return 0
fi

mkdir -p work/metadata
mkdir -p store
mkdir -p themes

if command -v podman &> /dev/null
then
    podman run -it --name $1 -d \
        -v ./work:/root/sspworkflow/work \
        # -v ./themes:/root/sspworkflow/themes \ # Don't bind themes folder, as they would not be available inside the container anymore
        -v ./store:/root/sspworkflow/store \
        {containername}
        # binding for full dev mode needs to bind all folders individually (otherwise lib folder will not be available):
        # podman run -it --name sspworkflow -d -v .:/root/sspworkflow sspworkflow:latest
elif command -v docker &> /dev/null
then
    docker run -it --name $1 -d \
        -v ./work:/root/sspworkflow/work \
        # -v ./themes:/root/sspworkflow/themes \
        -v ./store:/root/sspworkflow/store \
        {containername}
else
    echo "Neither Podman nor Docker is installed. Please install one of them to run the container."
fi
