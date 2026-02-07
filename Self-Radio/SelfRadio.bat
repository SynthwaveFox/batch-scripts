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
cls
echo ==== Update script ====
echo This will download the latest version of this script from GitHub.
set /p CONFIRM=Download and install update now? [y/N]:
if /I NOT "%CONFIRM%"=="y" goto :MainMenu

set "UPDATE_URL=https://raw.githubusercontent.com/SynthwaveFox/batch-scripts/refs/heads/main/Self-Radio/SelfRadio.bat"
set "NEWFILE=%TEMP%\SelfRadio_new.bat"
set "UPDATER=%TEMP%\SelfRadio_updater.bat"

echo Downloading latest version...
powershell -NoProfile -Command ^
    "try { (New-Object System.Net.WebClient).DownloadFile('%UPDATE_URL%', '%NEWFILE%'); exit 0 } catch { exit 1 }"

if errorlevel 1 (
    echo Download failed.
    pause
    goto :MainMenu
)

REM Build the updater helper. Note: %% used so the helper receives %1 at runtime.
(
    echo @echo off
    echo rem small delay so parent can exit
    echo rem try timeout first, fallback to ping
    echo timeout /t 2 /nobreak >nul 2^>nul || ping -n 3 127.0.0.1 ^>nul
    echo rem Attempt to move downloaded file over the original script (argument passed as %%1)
    echo if exist "%NEWFILE%" move /Y "%NEWFILE%" "%%~1" ^>nul 2^>nul
    echo rem Launch the new script
    echo start "" "%%~1"
    echo rem try to delete this updater helper
    echo del "%%~f0" ^>nul 2^>nul
) > "%UPDATER%"

REM Launch the updater and pass this script's full path as the argument
start "" "%UPDATER%" "%~f0"

echo Update started. Restarting with latest version...
exit /B
