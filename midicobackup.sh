#!/bin/bash

# Base directories for backup and application settings
backupDir=~/MidiCoSettingsBackup
libraryDir=~/Library

# Application-specific paths relative to ~/Library
paths=(
    "Caches/com.ggs.midico"
    "Containers/com.ggs.midico"
    "Preferences/com.ggs.MidiCo.plist"
    "Application Support/com.ggs.midico"
    "Saved Application State/com.ggs.midico.savedState"
)

# Function to validate the backup name
validate_name() {
    local name=$1
    if [[ ! "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo "Error: Backup name must be alphanumeric and can only contain hyphens and underscores, with no spaces."
        exit 1
    fi
}

# Function to backup files, directories, and defaults
backup() {
    local name=$1
    validate_name "$name"
    local timestamp
    timestamp=$(date +"%Y%m%d_%H%M%S")
    local backupSubDir="$backupDir/${name}_${timestamp}"
    local archiveName="${name}_${timestamp}.tar.gz"

    echo "Starting backup process..."

    # Ensure the backup subdirectory exists
    mkdir -p "$backupSubDir"

    # Backup each specified path
    for path in "${paths[@]}"; do
        fullPath="$libraryDir/$path"
        if [ -e "$fullPath" ]; then
            # Create the same structure in the backup subdirectory
            mkdir -p "$(dirname "$backupSubDir/$path")"
            echo "Backing up $path..."
            cp -R "$fullPath" "$(dirname "$backupSubDir/$path")"
        fi
    done

    # Backup defaults
    echo "Backing up defaults..."
    defaults read com.ggs.midico >"$backupSubDir/midico_defaults.plist"

    # Compress the backup directory into a tar.gz archive
    echo "Compressing backup..."
    tar -czf "$backupDir/$archiveName" -C "$backupDir" "$(basename "$backupSubDir")"

    # Remove the uncompressed backup directory
    rm -rf "$backupSubDir"

    echo "Backup completed."
    echo "Backup archive created: $backupDir/$archiveName" # Print the backup archive filename
}

# Function to restore files, directories, and defaults
restore() {
    local name=$1
    validate_name "$name"
    local archiveName="$backupDir/$name.tar.gz"
    local tempDir="$backupDir/temp_restore"

    echo "Starting restore process..."

    # Ensure the temporary directory exists
    mkdir -p "$tempDir"

    # Extract the archive to the temporary directory
    echo "Extracting backup..."
    tar -xzf "$archiveName" -C "$tempDir"

    local backupSubDir
    backupSubDir="$tempDir/$(basename "$name" .tar.gz)"

    # Restore each specified path
    for path in "${paths[@]}"; do
        backupPath="$backupSubDir/$path"
        if [ -e "$backupPath" ]; then
            echo "Restoring $path..."
            cp -R "$backupPath" "$libraryDir/$(dirname "$path")"
        fi
    done

    # Restore defaults
    if [ -f "$backupSubDir/midico_defaults.plist" ]; then
        echo "Restoring defaults..."
        defaults import com.ggs.midico "$backupSubDir/midico_defaults.plist"
    fi

    # Clean up the temporary directory
    rm -rf "$tempDir"

    echo "Restore completed."
}

# Main script logic
if [ "$1" == "--restore" ]; then
    if [ -z "$2" ]; then
        echo "Error: Please provide the name of the backup to restore."
        exit 1
    fi
    restore "$2"
else
    if [ -z "$1" ]; then
        echo "Error: Please provide a name for the backup."
        exit 1
    fi
    backup "$1"
fi
