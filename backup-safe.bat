@echo off
setlocal

set "ROOTDIR=%~dp0"
if "%ROOTDIR:~-1%"=="\" set "ROOTDIR=%ROOTDIR:~0,-1%"
set "WSL_DISTRO="
set "WSL_BACKUP_DIR="
if exist "%ROOTDIR%\_internal\config.bat" call "%ROOTDIR%\_internal\config.bat"

call "%ROOTDIR%\_internal\scripts\backup.bat" %WSL_DISTRO% %WSL_BACKUP_DIR% --safe
exit /b %ERRORLEVEL%
