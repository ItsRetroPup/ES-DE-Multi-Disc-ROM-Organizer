@echo off
setlocal enabledelayedexpansion

echo Processing ROM files for multi-disc games...
echo.

:: Ask user about storage type
echo Is your ES-DE storage on internal or external storage?
echo.
echo 1. Internal Storage
echo 2. External Storage (SD Card)
echo.
set /p storage_choice="Enter your choice (1 or 2): "

:: Set base path based on choice
if "%storage_choice%"=="1" (
    set "android_base=/storage/emulated/0"
    echo Using internal storage path
) else if "%storage_choice%"=="2" (
    echo.
    echo Please enter your SD card ID.
    echo You can find this in a file manager on Android - it looks like "XXXX-XXXX"
    echo Example: 1234-5678
    echo.
    set /p sd_card_id="Enter SD card ID: "
    set "android_base=/storage/!sd_card_id!"
    echo Using external storage path: !android_base!
) else (
    echo Invalid choice. Exiting.
    pause
    exit /b
)

echo.

:: Temporary file to track base names we've already processed
set "processed_file=%temp%\processed_games.txt"
if exist "%processed_file%" del "%processed_file%"

:: Loop through all subdirectories recursively
for /r %%d in (.) do (
    pushd "%%d"
    
    :: Get the current folder name (system name like psx, gc, etc.)
    for %%I in (.) do set "system_folder=%%~nxI"
    
    :: Skip if we're in the root directory or in a .m3u folder
    echo !system_folder! | findstr /i "\.m3u$" >nul
    if !errorlevel! neq 0 (
        if not "!system_folder!"=="." (
            echo.
            echo Scanning folder: !system_folder!
            
            :: Loop through all common ROM extensions
            for %%e in (iso cue bin chd pbp zip rvz) do (
                for %%f in (*.%%e) do (
                    set "filename=%%~nf"
                    set "extension=%%~xf"
                    
                    :: Check if filename contains disc indicators
                    echo !filename! | findstr /i /r "disc.*[0-9] disk.*[0-9] cd.*[0-9] (disc.*[0-9]) (disk.*[0-9]) (cd.*[0-9])" >nul
                    
                    if !errorlevel! equ 0 (
                        :: Extract base name (remove disc number part)
                        for /f "tokens=1 delims=()" %%a in ("!filename!") do set "basename=%%a"
                        set "basename=!basename:~0,-1!"
                        
                        :: Create unique identifier with system folder
                        set "unique_id=!system_folder!_!basename!"
                        
                        :: Check if we've already processed this game in this folder
                        findstr /x /c:"!unique_id!" "%processed_file%" >nul 2>&1
                        if !errorlevel! neq 0 (
                            echo   Found multi-disc game: !basename!
                            
                            :: Add to processed list
                            echo !unique_id!>> "%processed_file%"
                            
                            :: Create game folder in current directory
                            set "game_folder=!basename!.m3u"
                            if not exist "!game_folder!" mkdir "!game_folder!"
                            
                            :: Move all discs for this game to its folder
                            move "!basename!*.*" "!game_folder!\" >nul 2>&1
                            
                            :: Create M3U file in the game folder with Unix line endings
                            set "m3u_file=!game_folder!\!basename!.m3u"
                            if exist "!m3u_file!" del "!m3u_file!"
                            
                            :: Create temporary file with content
                            set "temp_m3u=%temp%\temp_m3u_!RANDOM!.txt"
                            
                            :: Determine if this is a Dolphin ROM (rvz, iso for GameCube/Wii)
                            set "use_absolute=0"
                            for %%x in ("!game_folder!\!basename!*.*") do (
                                if /i "%%~xx"==".rvz" set "use_absolute=1"
                            )
                            
                            :: Add all disc files to temporary M3U
                            set "file_count=0"
                            for %%x in ("!game_folder!\!basename!*.*") do (
                                if /i not "%%~xx"==".m3u" (
                                    set /a file_count+=1
                                    if !use_absolute!==1 (
                                        :: Use Android absolute path for Dolphin
                                        echo !android_base!/ROMs/!system_folder!/!game_folder!/%%~nxx>> "!temp_m3u!"
                                    ) else (
                                        :: Use relative path for everything else (i.e. Duckstation etc)
                                        echo %%~nxx>> "!temp_m3u!"
                                    )
                                )
                            )
                            
                            :: Only process if files were found
                            if !file_count! gtr 0 (
                                :: Get full paths for PowerShell
                                set "full_temp_path=!temp_m3u!"
                                set "full_m3u_path=!CD!\!m3u_file!"
                                
                                :: Convert CRLF to LF using PowerShell
                                powershell -NoProfile -Command "$text = Get-Content '!full_temp_path!' -Raw; $text = $text -replace \"`r`n\", \"`n\"; [System.IO.File]::WriteAllText('!full_m3u_path!', $text, [System.Text.Encoding]::UTF8)"
                                
                                echo   Created: !m3u_file! (Unix line endings)
                            ) else (
                                echo   Warning: No ROM files found for !basename!
                            )
                            
                            :: Cleanup temp file
                            if exist "!temp_m3u!" del "!temp_m3u!"
                        )
                    )
                )
            )
        )
    )
    
    popd
)

:: Cleanup
if exist "%processed_file%" del "%processed_file%"

echo.
echo Done! Multi-disc games organized in individual folders. :)
pause