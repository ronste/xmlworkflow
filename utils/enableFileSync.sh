#!/bin/bash
# run this script in the backgroud to enable synchronization of files between theme directories and work/media directory while editing a theme
# use `jobs` and `fg <job number>` from the same terminal to stop the script

# Arrays of source and destination files
SOURCE_FILES=(
    "/root/xmlworkflow/themes/berlinup/css/jats_html.css"
    # "/path/to/source/file2.txt"
    # "/path/to/source/file3.txt"
)

DESTINATION_FILES=(
    "/root/xmlworkflow/work/media/jats_html.css"
    # "/path/to/destination/file2.txt"
    # "/path/to/destination/file3.txt"
)

# Check if the number of source and destination files match
if [ ${#SOURCE_FILES[@]} -ne ${#DESTINATION_FILES[@]} ]; then
    echo "Error: The number of source and destination files must match."
    exit 1
fi

# Function to monitor and sync a single file
monitor_and_sync() {
    local SOURCE="$1"
    local DESTINATION="$2"

    while true; do
        inotifywait -e modify "$SOURCE"
        echo "Detected change in: $SOURCE"  # Debug message
        rsync -u "$SOURCE" "$DESTINATION" 
    done
}

# Start monitoring each file in the background
for i in "${!SOURCE_FILES[@]}"; do
    echo "Watching ${SOURCE_FILES[$i]} ..."
    monitor_and_sync "${SOURCE_FILES[$i]}" "${DESTINATION_FILES[$i]}" &
done

# Wait for all background processes to finish
wait