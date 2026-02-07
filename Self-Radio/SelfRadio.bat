@echo off
echo ==== Phoenix's Self-Radio Downloader Script ====
title Phoenix's Self-Radio Downloader
setlocal EnableExtensions EnableDelayedExpansion

set "SELF_RADIO_DIR=%userprofile%\Documents\Rockstar Games\GTAV Enhanced\User Music"
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

echo Checking for mp3gain...
if exist "%~dp0mp3gain.exe" (
    echo mp3gain is installed.
) else (
    echo mp3gain.exe not found next to this script.
    pause
)

echo Initialization complete.
GOTO :MainMenu

:: Menu
:MainMenu
cls
echo ==== Phoenix's Self-Radio Downloader Script ====
echo == Version 1.1 ==
echo ==== Main Menu ===
echo 1. Download Self-Radio Music from YouTube
echo 2. List Installed Songs
echo 3. Launch GTA V Enhanced
echo 4. Exit
echo 5. Update script from web
CHOICE /C 12345 /N /M "Please enter your choice [1,2,3,4,5]:"

REM --- Process the choice. Remember to check ERRORLEVEL from HIGHEST to LOWEST ---
IF ERRORLEVEL 5 GOTO :SelfUpdate
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
REM download into a temp folder Self-Radio
yt-dlp --restrict-filenames --extract-audio --audio-format mp3 --audio-quality 0 -o "Self-Radio\%%(title).100s.%%(ext)s" %url%

for %%F in ("Self-Radio\*.mp3") do (
    echo.
    echo ====
    echo File: %%F

    set /p ARTIST=Artist:
    set /p TITLE=Title:

    REM write tags and loudness normalize using ffmpeg loudnorm filter; output to a temp file
    ffmpeg -y -i "%%F" -map 0 -c copy -metadata artist="!ARTIST!" -metadata title="!TITLE!" "%%~nF.tmp.mp3" -filter:a loudnorm=I=-16:TP=-1.0:LRA=11

    if exist "%%~nF.tmp.mp3" (
        move /Y "%%~nF.tmp.mp3" "%%F" >nul
    )

REM --- run mp3gain in Track mode (-r) and auto-lower to avoid clipping (-k)
if exist "%~dp0mp3gain.exe" (
    echo === NORMALIZING VOLUME ===
    "%~dp0mp3gain.exe" -r -p -c -d 10 "%%F"
)
)

echo Download complete!
echo Moving files...
move /Y "Self-Radio\*.mp3" "%SELF_RADIO_DIR%"
PAUSE
GOTO :MainMenu

:Option2
cls
echo ==== Installed Songs ====
if not exist "%SELF_RADIO_DIR%" (
    echo No songs installed yet.
) else (
    dir /b "%SELF_RADIO_DIR%"
)
PAUSE
GOTO :MainMenu

:Option3
cls
start "" steam://rungameid/3240220
exit

:ExitScript
ECHO.
ECHO Exiting the script.
EXIT /B

:: ---------- Self update helper ----------
:SelfUpdate
call "%~dp0Update-SelfRadio.bat"
