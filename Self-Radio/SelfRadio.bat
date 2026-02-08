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
echo == Version 1.2 ==
echo ==== Main Menu ===
echo 1. Download Self-Radio Music from YouTube
echo 2. Coming Soon
echo 3. Installed Songs
echo 4. Exit
echo 5. Update script from web
CHOICE /C 12345 /N /M "Please enter your choice [1,2,3,4,5]:"

REM --- Process the choice. Remember to check ERRORLEVEL from HIGHEST to LOWEST ---
IF ERRORLEVEL 5 GOTO :SelfUpdate
IF ERRORLEVEL 4 GOTO :ExitScript
IF ERRORLEVEL 3 GOTO :InstalledSongs
IF ERRORLEVEL 2 GOTO :ManualInstall
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
    cls
    echo ====
    echo File: %%F

    set /p ARTIST=Artist:
    set /p TITLE=Title:

    REM write tags and loudness normalize using ffmpeg loudnorm filter; output to a temp file
    ffmpeg -y -i "%%F" -map 0 -c copy -metadata artist="!ARTIST!" -metadata title="!TITLE!" "%%~nF.tmp.mp3" -filter:a loudnorm=I=-16:TP=-1.0:LRA=11

    if exist "%%~nF.tmp.mp3" (
        move /Y "%%~nF.tmp.mp3" "%%F" >nul
    )

REM --- run mp3gain in Track mode (-r) and auto-lower to avoid clipping
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

:InstalledSongs
cls
echo ==== Installed Songs ====
if not exist "%SELF_RADIO_DIR%" (
    echo No songs installed yet.
    PAUSE
    GOTO :MainMenu
)

echo Listing songs in "%SELF_RADIO_DIR%":
echo.

rem build numbered list into dynamic vars FILE1, FILE2, ...
setlocal EnableDelayedExpansion
set /a IDX=0
for /f "delims=" %%F in ('dir /b /a:-d "%SELF_RADIO_DIR%\*.mp3" 2^>nul') do (
    set /a IDX+=1
    set "FILE!IDX!=%%F"
    echo !IDX!. %%F
)

if %IDX% equ 0 (
    endlocal
    echo No mp3 files found.
    PAUSE
    GOTO :MainMenu
)

echo.
set /p "CHOICE=Enter the number of the song to re-tag (or press ENTER to return): "
if "%CHOICE%"=="" (
    endlocal
    GOTO :MainMenu
)

rem validate numeric range
for /f "delims=0123456789" %%x in ("%CHOICE%") do (
    echo Invalid input. Only numbers allowed.
    endlocal
    PAUSE
    GOTO :InstalledSongs
)

if %CHOICE% lss 1 if %CHOICE% gtr %IDX% (
    echo Invalid selection.
    endlocal
    PAUSE
    GOTO :InstalledSongs
)

rem call the per-file process with the full path using delayed expansion
call :ProcessFile "%SELF_RADIO_DIR%\!FILE%CHOICE%!"

endlocal
GOTO :MainMenu

:ProcessFile
rem Called as: call :ProcessFile "C:\full\path\to\the file.mp3"
set "INFILE=%~1"
if not exist "%INFILE%" (
    echo File not found: "%INFILE%"
    goto :eof
)

echo.
echo Retagging: "%INFILE%"

rem show current artist/title (if ffprobe available)
where ffprobe >nul 2>&1
if not errorlevel 1 (
    echo Current tags:
    ffprobe -v error -show_entries format_tags=title,artist -of default=noprint_wrappers=1:nokey=1 "%INFILE%"
    echo.
)

set "ARTIST="
set "TITLE="
set /p "ARTIST=Artist: "
set /p "TITLE=Title: "
if "%TITLE%"=="" set "TITLE=%~n1"

rem form temp filename next to original
set "TMPTAG=%~dpn1.retag.tmp.mp3"

echo Writing tags to temporary file: "%TMPTAG%"
ffmpeg -y -i "%INFILE%" -map 0 -c copy -metadata artist="%ARTIST%" -metadata title="%TITLE%" "%TMPTAG%"

if exist "%TMPTAG%" (
    echo Replacing original with tagged file...
    move /Y "%TMPTAG%" "%INFILE%"
    if errorlevel 1 (
        echo Failed to replace original. Please check permissions.
        pause
        goto :eof
    )
    echo Tags written successfully.
) else (
    echo ERROR: Tagged temp file was not created. ffmpeg likely failed.
    echo (Run this script from an open cmd window to see ffmpeg errors.)
    pause
)

goto :eof



:ManualInstall
cls
GOTO :MainMenu

:ExitScript
ECHO.
ECHO Exiting the script.
EXIT /B

:: ---------- Self update helper ----------
:SelfUpdate
call "%~dp0UpdateScript.bat"
