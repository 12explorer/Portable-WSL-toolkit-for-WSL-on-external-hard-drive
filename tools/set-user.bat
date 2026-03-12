@echo off
setlocal

set "batfilenam=%~nx0"
for %%I in ("%~dp0..") do set "ROOTDIR=%%~fI"
if "%ROOTDIR:~-1%"=="\" set "ROOTDIR=%ROOTDIR:~0,-1%"
set "CONFIG_FILE=%ROOTDIR%\_internal\config.bat"
set "NEW_USER=%~1"

if not defined NEW_USER set /p NEW_USER=[%batfilenam%] Enter new default Linux user: 
if not defined NEW_USER (
  echo [%batfilenam%] Error: User name is required.
  exit /b 4
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOTDIR%\_internal\scripts\update-config.ps1" -ConfigFile "%CONFIG_FILE%" -SettingName "WSL_USER" -SettingValue "%NEW_USER%"
if not %ERRORLEVEL%==0 (
  echo [%batfilenam%] Error: Failed to update _internal\config.bat
  exit /b %ERRORLEVEL%
)

echo [%batfilenam%] Default user updated: %NEW_USER%
exit /b 0
