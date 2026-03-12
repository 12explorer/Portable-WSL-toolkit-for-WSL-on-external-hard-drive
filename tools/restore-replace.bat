@echo off
setlocal

for %%I in ("%~dp0..") do set "ROOTDIR=%%~fI"
if "%ROOTDIR:~-1%"=="\" set "ROOTDIR=%ROOTDIR:~0,-1%"
set "WSL_DISTRO="
set "WSL_RESTORE_DIR="
set "WSL_USER="
if exist "%ROOTDIR%\_internal\config.bat" call "%ROOTDIR%\_internal\config.bat"

if not defined WSL_DISTRO (
  echo [restore-replace.bat] Error: WSL_DISTRO is not set in _internal\config.bat
  exit /b 4
)

call "%ROOTDIR%\_internal\scripts\restore.bat" %WSL_DISTRO% "" "%WSL_RESTORE_DIR%\%WSL_DISTRO%" --replace %WSL_USER%
exit /b %ERRORLEVEL%
