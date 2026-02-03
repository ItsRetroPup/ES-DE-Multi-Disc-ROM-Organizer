#!/bin/bash

echo "Processing ROM files for multi-disc games..."
echo

# Ask user about storage type
echo "Is your ES-DE storage on internal or external storage?"
echo
echo "1. Internal Storage"
echo "2. External Storage (SD Card)"
echo
read -p "Enter your choice (1 or 2): " storage_choice

# Set base path based on choice
if [ "$storage_choice" == "1" ]; then
    android_base="/storage/emulated/0"
    echo "Using internal storage path"
elif [ "$storage_choice" == "2" ]; then
    echo
    echo "Please enter your SD card ID."
    echo "You can find this in a file manager on Android - it looks like \"XXXX-XXXX\""
    echo "Example: 1234-5678"
    echo
    read -p "Enter SD card ID: " sd_card_id
    android_base="/storage/$sd_card_id"
    echo "Using external storage path: $android_base"
else
    echo "Invalid choice. Exiting."
    exit 1
fi

echo

# Temporary file to track base names we've already processed
processed_file=$(mktemp)

# Function to process files in a directory
process_directory() {
    local dir="$1"
    local system_folder=$(basename "$dir")
    
    # Skip if we're in a .m3u folder
    if [[ "$system_folder" == *.m3u ]]; then
        return
    fi
    
    echo
    echo "Scanning folder: $system_folder"
    
    # Loop through all common ROM extensions
    for ext in iso cue bin chd pbp zip rvz; do
        # Use find to get files with current extension
        while IFS= read -r file; do
            [ -e "$file" ] || continue
            
            filename=$(basename "$file" ".$ext")
            
            # Check if filename contains disc indicators
            if echo "$filename" | grep -qi -E "(disc|disk|cd).*[0-9]|\(disc.*[0-9]\)|\(disk.*[0-9]\)|\(cd.*[0-9]\)"; then
                # Extract base name (remove disc number part)
                basename_game=$(echo "$filename" | sed -E 's/[[:space:]]*\(?(disc|disk|cd)[[:space:]]*[0-9]+\)?[[:space:]]*$//' | sed 's/[[:space:]]*$//')
                
                # Create unique identifier with system folder
                unique_id="${system_folder}_${basename_game}"
                
                # Check if we've already processed this game in this folder
                if ! grep -Fxq "$unique_id" "$processed_file" 2>/dev/null; then
                    echo "  Found multi-disc game: $basename_game"
                    
                    # Add to processed list
                    echo "$unique_id" >> "$processed_file"
                    
                    # Create game folder in current directory
                    game_folder="${basename_game}.m3u"
                    mkdir -p "$dir/$game_folder"
                    
                    # Move all discs for this game to its folder
                    mv "$dir/$basename_game"*.* "$dir/$game_folder/" 2>/dev/null
                    
                    # Create M3U file in the game folder
                    m3u_file="$dir/$game_folder/${basename_game}.m3u"
                    > "$m3u_file"  # Create empty file
                    
                    # Determine if this is a Dolphin ROM (rvz files)
                    use_absolute=0
                    for disc_file in "$dir/$game_folder/$basename_game"*.*; do
                        [ -e "$disc_file" ] || continue
                        if [[ "${disc_file,,}" == *.rvz ]]; then
                            use_absolute=1
                            break
                        fi
                    done
                    
                    # Add all disc files to M3U
                    file_count=0
                    for disc_file in "$dir/$game_folder/$basename_game"*.*; do
                        [ -e "$disc_file" ] || continue
                        disc_filename=$(basename "$disc_file")
                        
                        # Skip the m3u file itself
                        if [[ "${disc_filename,,}" != *.m3u ]]; then
                            ((file_count++))
                            if [ $use_absolute -eq 1 ]; then
                                # Use Android absolute path for Dolphin
                                echo "$android_base/ROMs/$system_folder/$game_folder/$disc_filename" >> "$m3u_file"
                            else
                                # Use relative path for DuckStation
                                echo "$disc_filename" >> "$m3u_file"
                            fi
                        fi
                    done
                    
                    if [ $file_count -gt 0 ]; then
                        echo "  Created: $game_folder/${basename_game}.m3u (Unix line endings)"
                    else
                        echo "  Warning: No ROM files found for $basename_game"
                    fi
                fi
            fi
        done < <(find "$dir" -maxdepth 1 -type f -iname "*.$ext")
    done
}

# Find all subdirectories and process them
find . -type d | while IFS= read -r dir; do
    process_directory "$dir"
done

# Cleanup
rm -f "$processed_file"

echo
echo "Done! Multi-disc games organized in individual folders with Unix line endings."