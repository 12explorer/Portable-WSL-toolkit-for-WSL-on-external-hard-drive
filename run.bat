@echo off
setlocal

set "ROOTDIR=%~dp0"
if "%ROOTDIR:~-1%"=="\" set "ROOTDIR=%ROOTDIR:~0,-1%"
set "WSL_DISTRO="
set "WSL_USER="

if exist "%ROOTDIR%\_internal\config.bat" call "%ROOTDIR%\_internal\config.bat"

if not defined WSL_DISTRO (
  echo [run.bat] Error: WSL_DISTRO is not set.
  exit /b 4
)

call "%~dp0_internal\scripts\launch.bat" %WSL_DISTRO% %WSL_USER%
exit /b %ERRORLEVEL%
