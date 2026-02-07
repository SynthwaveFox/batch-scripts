@echo off
REM Update-SelfRadio.bat  -- place this next to SelfRadio.bat and mp3gain.exe
setlocal EnableExtensions EnableDelayedExpansion

REM --- CONFIG ---
set "TARGET_NAME=SelfRadio.bat"
set "UPDATE_URL=https://raw.githubusercontent.com/SynthwaveFox/batch-scripts/refs/heads/main/Self-Radio/SelfRadio.bat"
set "SCRIPT_TITLE=Phoenix's Self-Radio Downloader"
REM ----------------

set "SCRIPT_DIR=%~dp0"
set "TARGET=%SCRIPT_DIR%%TARGET_NAME%"
set "NEWFILE=%SCRIPT_DIR%SelfRadio.bat"
set "BACKUP=%SCRIPT_DIR%%TARGET_NAME%.backup.%DATE:~10,4%%DATE:~4,2%%DATE:~7,2%_%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%.bat"
set "LOG=%TEMP%\SelfRadio_replace.log"

cls
echo ==== SelfRadio Updater ====
echo Will download the latest SelfRadio.bat from:
echo    %UPDATE_URL%
echo and replace:
echo    %TARGET%
echo.
set /p CONFIRM=Proceed with update? [y/N]:
if /I NOT "%CONFIRM%"=="y" goto :eof

if exist "%NEWFILE%" del "%NEWFILE%" >nul 2>&1
if exist "%LOG%" del "%LOG%" >nul 2>&1

echo Downloading...
powershell -NoProfile -Command ^
  "try { (New-Object System.Net.WebClient).DownloadFile('%UPDATE_URL%', '%NEWFILE%'); exit 0 } catch { exit 1 }"
if errorlevel 1 (
    echo Download failed. Aborting.
    if exist "%NEWFILE%" del "%NEWFILE%" >nul 2>&1
    pause
    goto :eof
)

echo Downloaded to: "%NEWFILE%"
echo.

REM Backup if target exists (best-effort)
if exist "%TARGET%" (
    echo Backing up current script:
    echo    %BACKUP%
    move /Y "%TARGET%" "%BACKUP%" >nul 2>&1
    if errorlevel 1 (
        echo Warning: could not move original to backup (it may be in use). Continuing and will attempt direct replace.
    ) else (
        echo Backup done.
    )
)

REM Attempt immediate replace
echo Attempting immediate replacement...
move /Y "%NEWFILE%" "%TARGET%" >nul 2>&1
if not errorlevel 1 (
    echo Replacement successful.
    echo Launching updated script...
    start "" "%TARGET%"
    echo Done.
    pause
    goto :eof
)

echo Immediate replace failed. The target file is likely in use (running or locked).
echo Searching for running processes that look like the script (by window title)...

REM Find processes by MainWindowTitle containing the script title
set "FOUNDLIST="
for /f "usebackq delims=" %%P in (`powershell -NoProfile -Command ^
    "Get-Process | Where-Object { \$_.MainWindowTitle -and \$_.MainWindowTitle -like '*%SCRIPT_TITLE%*' } | Select-Object Id,ProcessName,MainWindowTitle | ForEach-Object { \"{0}|{1}|{2}\" -f \$_.Id, \$_.ProcessName, (\$_.MainWindowTitle -replace '\r|\n',' ') }"`) do (
    echo %%P
    echo %%P>>"%LOG%"
    set "FOUNDLIST=1"
)

REM Fallback: also try to find processes by command line containing the script name (if the above didn't find anything)
if not defined FOUNDLIST (
    echo No window-title matches found; checking processes by command line...
    for /f "usebackq delims=" %%Q in (`powershell -NoProfile -Command ^
        "Get-CimInstance Win32_Process | Where-Object { \$_.CommandLine -and \$_.CommandLine -match '(?i)%TARGET_NAME%' } | Select-Object ProcessId,Name,CommandLine | ForEach-Object { \"{0}|{1}|{2}\" -f \$_.ProcessId, \$_.Name, (\$_.CommandLine -replace '\r|\n',' ') }"`) do (
        echo %%Q
        echo %%Q>>"%LOG%"
        set "FOUNDLIST=1"
    )
)

if not defined FOUNDLIST (
    echo No matching processes found for window title or commandline. The file may be locked by Explorer, AV, or another service.
    echo Check %LOG% for details, close any apps that might have the file open (Explorer preview panes, editors) and re-run this updater.
    echo.
    pause
    goto :eof
)

echo.
set /p KILLCONF=Do you want to terminate the listed process(es) so the updater can replace the file? [y/N]:
if /I NOT "%KILLCONF%"=="y" (
    echo Aborting replacement. Close the listed processes and rerun the updater.
    pause
    goto :eof
)

REM Kill found processes (by PID)
echo Terminating processes...
for /f "usebackq tokens=1,2,3 delims=|" %%A in ('type "%LOG%"') do (
    set "PID=%%A"
    if defined PID (
        echo Killing PID %%A (%%B) ...
        taskkill /PID %%A /F >nul 2>&1
        echo %%DATE%% %%TIME%% - killed PID %%A (%%B) >> "%LOG%"
    )
)

REM Retry replace, with a short retry loop
echo Retrying replacement...
set "TRIES=0"
:RETRY_MOVE
set /a TRIES+=1
move /Y "%NEWFILE%" "%TARGET%" >nul 2>&1
if not errorlevel 1 (
    echo Replacement successful on attempt %TRIES%.
    echo Launching updated script...
    start "" "%TARGET%"
    echo Done.
    pause
    goto :eof
)
if %TRIES% GEQ 30 (
    echo Replacement failed after %TRIES% attempts.
    echo The downloaded file remains at:
    echo    %NEWFILE%
    echo See %LOG% for the processes that were terminated and retry manually after ensuring no handles remain.
    pause
    goto :eof
)
timeout /t 1 /nobreak >nul
goto :RETRY_MOVE
