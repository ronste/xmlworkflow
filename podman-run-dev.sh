mkdir -p work/metadata
mkdir -p store

podman run -it --name xmlworkflow -d \
-v ./themes:/root/xmlworkflow/themes \
-v ./work:/root/xmlworkflow/work \
-v ./store:/root/xmlworkflow/store \
-v ./utils:/root/xmlworkflow/utils \
-v ./justfile:/root/xmlworkflow/justfile \
-v ./.env:/root/xmlworkflow/.env \
-v ./utils/mml2chtml-page:/root/xmlworkflow/lib/mml2chtml-page \
-v ./justfiles:/root/xmlworkflow/justfiles \
xmlworkflow:latest