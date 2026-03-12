@echo off
setlocal

set "batfilenam=%~nx0"
for %%I in ("%~dp0..") do set "ROOTDIR=%%~fI"
if "%ROOTDIR:~-1%"=="\" set "ROOTDIR=%ROOTDIR:~0,-1%"
set "CONFIG_FILE=%ROOTDIR%\_internal\config.bat"
set "NEW_KEEP=%~1"
set "NEW_DIR=%~2"

if not defined NEW_KEEP set /p NEW_KEEP=[%batfilenam%] Enter backup retention count: 
if not defined NEW_KEEP (
  echo [%batfilenam%] Error: Retention count is required.
  exit /b 4
)

echo %NEW_KEEP%| findstr /r "^[0-9][0-9]*$" >nul
if not %ERRORLEVEL%==0 (
  echo [%batfilenam%] Error: Retention count must be a non-negative integer.
  exit /b 4
)

if not defined NEW_DIR set /p NEW_DIR=[%batfilenam%] Enter backup directory ^(leave empty to keep current^): 

powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOTDIR%\_internal\scripts\update-config.ps1" -ConfigFile "%CONFIG_FILE%" -SettingName "WSL_BACKUP_KEEP" -SettingValue "%NEW_KEEP%"
if not %ERRORLEVEL%==0 (
  echo [%batfilenam%] Error: Failed to update backup retention in _internal\config.bat
  exit /b %ERRORLEVEL%
)

if defined NEW_DIR (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOTDIR%\_internal\scripts\update-config.ps1" -ConfigFile "%CONFIG_FILE%" -SettingName "WSL_BACKUP_DIR" -SettingValue "%NEW_DIR%"
)
if not %ERRORLEVEL%==0 (
  echo [%batfilenam%] Error: Failed to update _internal\config.bat
  exit /b %ERRORLEVEL%
)

echo [%batfilenam%] Backup retention updated: %NEW_KEEP%
if defined NEW_DIR echo [%batfilenam%] Backup directory updated: %NEW_DIR%
exit /b 0
