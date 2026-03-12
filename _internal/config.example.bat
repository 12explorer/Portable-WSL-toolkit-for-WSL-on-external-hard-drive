@echo off
if not defined ROOTDIR (
  for %%I in ("%~dp0..") do set "ROOTDIR=%%~fI"
  if "%ROOTDIR:~-1%"=="\" set "ROOTDIR=%ROOTDIR:~0,-1%"
)

set "WSL_DISTRO=<YOUR_DISTRO_NAME>"
set "WSL_USER=<YOUR_LINUX_USER>"
set "WSL_BACKUP_DIR=%ROOTDIR%\backup"
set "WSL_BACKUP_KEEP=3"
set "WSL_RESTORE_DIR=%ROOTDIR%\restored"
