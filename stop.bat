@echo off
setlocal

set "batfilenam=%~nx0"
set "ROOTDIR=%~dp0"
if "%ROOTDIR:~-1%"=="\" set "ROOTDIR=%ROOTDIR:~0,-1%"
set "mode=%~1"
set "WSL_DISTRO=%~1"

if /I "%mode%"=="--all" (
  echo [%batfilenam%] Stopping all WSL instances...
  wsl.exe --shutdown
  exit /b %ERRORLEVEL%
)

set "WSL_USER=%~2"
if not defined WSL_DISTRO (
  if exist "%ROOTDIR%\_internal\config.bat" call "%ROOTDIR%\_internal\config.bat"
)

if not defined WSL_DISTRO (
  echo [%batfilenam%] Error: Missing distro name.
  echo [%batfilenam%] Usage:
  echo [%batfilenam%]   %batfilenam% ^<DistroName^>
  echo [%batfilenam%]   %batfilenam% --all
  exit /b 4
)

echo [%batfilenam%] Stopping distro: %WSL_DISTRO%
echo [%batfilenam%] Flushing filesystem buffers with sync...
wsl.exe -d %WSL_DISTRO% --cd / sync >nul 2>nul
wsl.exe --terminate %WSL_DISTRO%
exit /b %ERRORLEVEL%
