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

# Function to backup files, directories, and defaults
backup() {
    echo "Starting backup process..."

    # Ensure the backup directory exists
    mkdir -p "$backupDir"

    # Backup each specified path
    for path in "${paths[@]}"; do
        fullPath="$libraryDir/$path"
        if [ -e "$fullPath" ]; then
            # Create the same structure in the backup directory
            mkdir -p "$(dirname "$backupDir/$path")"
            echo "Backing up $path..."
            cp -R "$fullPath" "$(dirname "$backupDir/$path")"
        fi
    done

    # Backup defaults
    echo "Backing up defaults..."
    defaults read com.ggs.midico > "$backupDir/midico_defaults.plist"

    echo "Backup completed."
}

# Function to restore files, directories, and defaults
restore() {
    echo "Starting restore process..."

    # Restore each specified path
    for path in "${paths[@]}"; do
        backupPath="$backupDir/$path"
        if [ -e "$backupPath" ]; then
            echo "Restoring $path..."
            cp -R "$backupPath" "$libraryDir/$(dirname "$path")"
        fi
    done

    # Restore defaults
    if [ -f "$backupDir/midico_defaults.plist" ]; then
        echo "Restoring defaults..."
        defaults import com.ggs.midico "$backupDir/midico_defaults.plist"
    fi

    echo "Restore completed."
}

# Main script logic
if [ "$1" == "--restore" ]; then
    restore
else
    backup
fi