mkdir -p work/metadata
mkdir -p store

podman run -it --name xmlworkflow -d \
-v ./work:/root/xmlworkflow/work \
-v ./store:/root/xmlworkflow/store \
xmlworkflow:latest