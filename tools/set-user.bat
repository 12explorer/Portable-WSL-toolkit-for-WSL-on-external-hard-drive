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

powershell -NoProfile -Command "^$p='%CONFIG_FILE%'; ^$n='%NEW_USER%'; ^$c=Get-Content -LiteralPath ^$p -Raw; ^$c=[regex]::Replace(^$c,'(?m)^set \"WSL_USER=.*\"$','set \"WSL_USER=' + ^$n + '\"'); Set-Content -LiteralPath ^$p -Value ^$c -Encoding ASCII"
if not %ERRORLEVEL%==0 (
  echo [%batfilenam%] Error: Failed to update _internal\config.bat
  exit /b %ERRORLEVEL%
)

echo [%batfilenam%] Default user updated: %NEW_USER%
exit /b 0
