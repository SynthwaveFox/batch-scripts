@echo off
echo ==== Phoenix's Self-Radio Downloader Script ====
title Phoenix's Self-Radio Downloader

echo Initializing...

where yt-dlp.exe >nul 2>nul
if %errorlevel% equ 0 (
    echo yt-dlp is installed.
    echo Updating yt-dlp...
    yt-dlp -U
) else (
    echo yt-dlp is not installed.
    pause
)

echo Checking for ffmpeg...
where ffmpeg.exe >nul 2>nul
if %errorlevel% equ 0 (
    echo ffmpeg is installed.
) else (
    echo ffmpeg is not installed.
    pause
)
echo Initialization complete.
GOTO :MainMenu

:: Menu
:MainMenu
cls
echo ==== Main Menu ===
echo 1. Download Self-Radio Music from YouTube
echo 2. List Installed Songs
echo 3. Launch GTA V Enhanced
echo 4. Exit

    CHOICE /C 1234 /N /M "Please enter your choice [1,2,3,4]: "
    
    REM --- Process the choice. Remember to check ERRORLEVEL from HIGHEST to LOWEST ---
    IF ERRORLEVEL 4 GOTO :ExitScript
    IF ERRORLEVEL 3 GOTO :Option3
    IF ERRORLEVEL 2 GOTO :Option2
    IF ERRORLEVEL 1 GOTO :Option1

:Option1
    cls
    echo ==== Download Self-Radio Music ====
    echo Please enter the YouTube video or playlist URL for Self-Radio:
    set /p url=URL: 
    echo Downloading and converting to MP3...
    yt-dlp --extract-audio --audio-format mp3 --audio-quality 0 -o "Self-Radio\%%(title)s.%%(ext)s" %url%
    echo Download complete!
    PAUSE
    GOTO :MainMenu

:Option2
    cls
    echo ==== Installed Songs ====
    if not exist "Self-Radio" (
        echo No songs installed yet.
    ) else (
        dir /b "Self-Radio"
    )
    ECHO Goodbye!
    PAUSE
    GOTO :MainMenu

:ExitScript
    ECHO.
    ECHO Exiting the script.
    EXIT /B