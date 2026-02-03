# ES-DE Multi-Disc ROM Organizer

A cross-platform script that automatically organizes multi-disc ROM files for ES-DE (EmulationStation Desktop Edition) on Android devices. The script detects multi-disc games, creates organized folder structures, and generates M3U playlist files with proper Unix line endings for compatibility with Android emulators.

## Features

- **Cross-Platform**: Works on Windows, Mac, and Linux
- **Recursive Scanning**: Automatically scans through all subdirectories to find multi-disc ROMs
- **Multi-System Support**: Works with PSX, GameCube, Wii, and other multi-disc systems
- **Automatic Organization**: Creates individual folders for each multi-disc game
- **M3U Generation**: Automatically creates M3U playlist files for seamless disc switching
- **Android Compatibility**: Generates files with Unix line endings (LF) for Android devices
- **Path Configuration**: Supports both internal storage and external SD card storage
- **Emulator Support**: 
  - DuckStation (PSX): Uses relative paths
  - Dolphin (GameCube/Wii): Uses absolute Android paths

## Supported File Formats

- `.iso` - ISO disc images
- `.cue` - Cue sheet files
- `.bin` - Binary disc images
- `.chd` - Compressed Hunks of Data
- `.pbp` - PlayStation Portable EBOOT files
- `.zip` - Compressed archives
- `.rvz` - Dolphin compressed format (GameCube/Wii)

## Requirements

### Windows
- Windows operating system
- PowerShell (included in Windows)

### Mac/Linux
- Bash shell (pre-installed on most systems)
- `find` and `grep` commands (pre-installed)

### All Platforms
- ROMs organized in system-specific folders (e.g., `psx`, `gc`, `wii`)

## Installation & Usage

### Windows

1. **Download**: Get `organize_multidisc_roms.bat`
2. **Organize Your ROMs**: Ensure your ROMs are in system-specific folders:
```
   ROMs/
   ├── psx/
   │   ├── Final Fantasy VII (Disc 1).bin
   │   ├── Final Fantasy VII (Disc 2).bin
   │   └── Final Fantasy VII (Disc 3).bin
   └── gc/
       ├── Resident Evil (Disc 1).rvz
       └── Resident Evil (Disc 2).rvz
```
3. **Run**: 
   - Place the `.bat` file in your ROMs directory
   - Double-click to run
   - Follow the prompts

### Mac/Linux

1. **Download**: Get `organize_multidisc_roms.sh`
2. **Make Executable**:
```bash
   chmod +x organize_multidisc_roms.sh
```
3. **Organize Your ROMs**: Same structure as Windows above
4. **Run**:
```bash
   ./organize_multidisc_roms.sh
```
   Or navigate to your ROMs directory and run:
```bash
   cd /path/to/your/ROMs
   /path/to/organize_multidisc_roms.sh
```

### Storage Configuration

When prompted:
- **Option 1**: Internal Storage (`/storage/emulated/0`)
- **Option 2**: External Storage (SD Card - requires SD card ID)

### Finding Your SD Card ID

**On Android:**
- Open a file manager app
- Navigate to external storage
- The path will show something like `/storage/1234-5678/`
- The `1234-5678` part is your SD card ID

## How It Works

### Detection
The script looks for disc indicators in filenames:
- `Disc 1`, `Disc 2`, etc.
- `Disk 1`, `Disk 2`, etc.
- `CD 1`, `CD 2`, etc.
- Supports variations with parentheses: `(Disc 1)`, `(Disk 2)`, etc.

### Organization
For each multi-disc game found, the script:
1. Creates a folder named `[Game Name].m3u`
2. Moves all disc files into this folder
3. Generates an M3U playlist file inside the folder

### Example Output Structure
```
ROMs/
└── psx/
    └── Final Fantasy VII.m3u/
        ├── Final Fantasy VII (Disc 1).bin
        ├── Final Fantasy VII (Disc 2).bin
        ├── Final Fantasy VII (Disc 3).bin
        └── Final Fantasy VII.m3u
```

### M3U File Contents

**For DuckStation (PSX games):**
```
Final Fantasy VII (Disc 1).bin
Final Fantasy VII (Disc 2).bin
Final Fantasy VII (Disc 3).bin
```

**For Dolphin (GameCube/Wii games):**
```
/storage/emulated/0/ROMs/gc/Resident Evil.m3u/Resident Evil (Disc 1).rvz
/storage/emulated/0/ROMs/gc/Resident Evil.m3u/Resident Evil (Disc 2).rvz
```

## ES-DE Configuration

After running the script, your multi-disc games will appear in ES-DE as single entries. When you launch a game:
- ES-DE will use the M3U file
- The emulator will load the first disc automatically
- You can switch discs using the emulator's disc change feature

## Troubleshooting

### Script skips certain folders
- The script automatically skips folders ending in `.m3u` to avoid reprocessing
- Make sure your ROM files have disc indicators in their filenames

### Wrong SD card path
- Double-check your SD card ID in your Android file manager
- The format should be `XXXX-XXXX` (e.g., `1234-5678`)

### M3U files not working in emulator
- Ensure files have Unix line endings (the script handles this automatically)
- For Dolphin issues, verify the absolute path matches your Android storage location

### Files already organized
- If you need to re-run the script, delete the `.m3u` folders first
- The script won't process files that have already been moved

### Mac/Linux: Permission denied
- Make sure the script is executable: `chmod +x organize_multidisc_roms.sh`
- You may need to run with appropriate permissions if your ROMs directory requires it

### Mac/Linux: Script not found
- Use `./organize_multidisc_roms.sh` when running from the current directory
- Or provide the full path: `/path/to/organize_multidisc_roms.sh`

## Technical Details

### Line Ending Conversion

**Windows Version:**
Uses PowerShell to convert Windows line endings (CRLF) to Unix line endings (LF):
```powershell
$text = $text -replace "`r`n", "`n"
```

**Mac/Linux Version:**
Creates files with Unix line endings (LF) natively - no conversion needed.

### Path Types
- **Relative paths**: Used for DuckStation (PSX) - better compatibility with ES-DE's content URI system
- **Absolute paths**: Used for Dolphin (GameCube/Wii) - required for proper disc detection

## Repository Structure
```
.
├── organize_multidisc_roms.bat    # Windows version
├── organize_multidisc_roms.sh     # Mac/Linux version
└── README.md                       # This file
```

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

This project is released under the MIT License. Feel free to use, modify, and distribute as needed.

## Acknowledgments

- Designed for use with [ES-DE](https://es-de.org/) on Android
- Supports [DuckStation](https://www.duckstation.org/) for PSX emulation
- Supports [Dolphin Emulator](https://dolphin-emu.org/) for GameCube/Wii emulation

## Changelog

### Version 1.0
- Initial release
- Windows batch script
- Mac/Linux bash script
- Recursive folder scanning
- M3U generation with Unix line endings
- Support for internal and external storage
- Dual path support (relative for PSX, absolute for GameCube/Wii)

---

**Note**: Always backup your ROM files before running any organizational scripts!
