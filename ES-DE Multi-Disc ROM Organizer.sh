#!/bin/bash

echo "Processing ROM files for multi-disc games..."
echo ""

# Ask user about storage type
echo "Is your ES-DE storage on internal or external storage?"
echo ""
echo "1. Internal Storage"
echo "2. External Storage (SD Card)"
echo ""
read -p "Enter your choice (1 or 2): " storage_choice

# Set base path based on choice
if [ "$storage_choice" == "1" ]; then
    android_base="/storage/emulated/0"
    echo "Using internal storage path"
elif [ "$storage_choice" == "2" ]; then
    echo ""
    echo "Please enter your SD card ID."
    echo "You can find this in a file manager on Android - it looks like \"XXXX-XXXX\""
    echo "Example: 1234-5678"
    echo ""
    read -p "Enter SD card ID: " sd_card_id
    android_base="/storage/$sd_card_id"
    echo "Using external storage path: $android_base"
else
    echo "Invalid choice. Exiting."
    exit 1
fi

echo ""

# Temporary file to track base names we've already processed
processed_file=$(mktemp)
trap "rm -f $processed_file" EXIT

# Find all directories and process them
find . -type d | while read -r dir; do
    # Skip the current directory itself
    [ "$dir" == "." ] && continue
    
    # Get the system folder name
    system_folder=$(basename "$dir")
    
    # Skip if we're in a .m3u folder
    if [[ "$system_folder" == *.m3u ]]; then
        continue
    fi
    
    echo ""
    echo "Scanning folder: $system_folder"
    
    # Change to the directory
    cd "$dir" || continue
    
    # Loop through all common ROM extensions
    for extension in iso cue bin chd pbp zip rvz; do
        shopt -s nullglob
        for file in *."$extension"; do
            shopt -u nullglob
            
            filename="${file%.*}"
            
            # Check if filename contains disc indicators
            if echo "$filename" | grep -iE "(disc|disk|cd).*[0-9]|\(disc.*[0-9]\)|\(disk.*[0-9]\)|\(cd.*[0-9]\)" > /dev/null; then
                # Extract base name (remove disc number part and trim)
                basename=$(echo "$filename" | sed -E 's/[[:space:]]*\(?(disc|disk|cd)[[:space:]]*[0-9]+\)?.*//I' | sed 's/[[:space:]]*$//')
                
                # Create unique identifier with system folder
                unique_id="${system_folder}_${basename}"
                
                # Check if we've already processed this game in this folder
                if ! grep -Fxq "$unique_id" "$processed_file" 2>/dev/null; then
                    echo "  Found multi-disc game: $basename"
                    
                    # Add to processed list
                    echo "$unique_id" >> "$processed_file"
                    
                    # Create game folder in current directory
                    game_folder="${basename}.m3u"
                    mkdir -p "$game_folder"
                    
                    # Move all discs for this game to its folder
                    mv "$basename"*.* "$game_folder/" 2>/dev/null
                    
                    # Create M3U file in the game folder with Unix line endings
                    m3u_file="$game_folder/${basename}.m3u"
                    > "$m3u_file"  # Create empty file
                    
                    # Determine if this is a Dolphin ROM (rvz, iso for GameCube/Wii)
                    use_absolute=0
                    for romfile in "$game_folder/$basename"*.*; do
                        [ ! -e "$romfile" ] && continue
                        ext_lower=$(echo "${romfile##*.}" | tr '[:upper:]' '[:lower:]')
                        if [ "$ext_lower" == "rvz" ]; then
                            use_absolute=1
                            break
                        fi
                    done
                    
                    # Add all disc files to M3U
                    for romfile in "$game_folder/$basename"*.*; do
                        [ ! -e "$romfile" ] && continue
                        
                        ext=$(echo "${romfile##*.}" | tr '[:upper:]' '[:lower:]')
                        if [ "$ext" != "m3u" ]; then
                            if [ $use_absolute -eq 1 ]; then
                                # Use Android absolute path for Dolphin
                                echo "$android_base/ROMs/$system_folder/$game_folder/$(basename "$romfile")" >> "$m3u_file"
                            else
                                # Use relative path for everything else
                                echo "$(basename "$romfile")" >> "$m3u_file"
                            fi
                        fi
                    done
                    
                    echo "  Created: $m3u_file (Unix line endings)"
                fi
            fi
        done
    done
    
    # Return to original directory
    cd - > /dev/null || exit
done

echo ""
echo "Done! Multi-disc games organized in individual folders. :)"
