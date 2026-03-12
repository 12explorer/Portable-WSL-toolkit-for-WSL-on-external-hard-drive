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

powershell -NoProfile -Command "^$p='%CONFIG_FILE%'; ^$k='%NEW_KEEP%'; ^$d='%NEW_DIR%'; ^$c=Get-Content -LiteralPath ^$p -Raw; ^$c=[regex]::Replace(^$c,'(?m)^set \"WSL_BACKUP_KEEP=.*\"$','set \"WSL_BACKUP_KEEP=' + ^$k + '\"'); if (^$d) { ^$c=[regex]::Replace(^$c,'(?m)^set \"WSL_BACKUP_DIR=.*\"$','set \"WSL_BACKUP_DIR=' + ^$d.Replace('\\','\\\\') + '\"') }; Set-Content -LiteralPath ^$p -Value ^$c -Encoding ASCII"
if not %ERRORLEVEL%==0 (
  echo [%batfilenam%] Error: Failed to update _internal\config.bat
  exit /b %ERRORLEVEL%
)

echo [%batfilenam%] Backup retention updated: %NEW_KEEP%
if defined NEW_DIR echo [%batfilenam%] Backup directory updated: %NEW_DIR%
exit /b 0
