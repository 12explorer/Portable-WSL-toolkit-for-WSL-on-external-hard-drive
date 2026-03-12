@echo off
setlocal EnableDelayedExpansion

set "batfilenam=%~nx0"
for %%I in ("%~dp0..\..") do set "ROOTDIR=%%~fI"
if "%ROOTDIR:~-1%"=="\" set "ROOTDIR=%ROOTDIR:~0,-1%"
set "WSL_DISTRO=%~1"
set "BACKUP_TAR=%~2"
set "INSTALL_DIR=%~3"
set "MODE=%~4"

if not defined WSL_DISTRO (
  if exist "%ROOTDIR%\_internal\config.bat" call "%ROOTDIR%\_internal\config.bat"
)

if not defined WSL_DISTRO (
  echo [%batfilenam%] Error: Missing distro name.
  echo [%batfilenam%] Usage: %batfilenam% ^<DistroName^> [BackupTar] [InstallDir] [--replace] [UnixUser]
  exit /b 4
)

if not defined WSL_USER set "WSL_USER=%~5"
if not defined WSL_USER set "WSL_USER="

if not defined WSL_BACKUP_DIR set "WSL_BACKUP_DIR=%ROOTDIR%\backup"
if not defined WSL_RESTORE_DIR set "WSL_RESTORE_DIR=%ROOTDIR%\restored"

if not defined BACKUP_TAR call :FindLatestBackup "%WSL_BACKUP_DIR%" "%WSL_DISTRO%"
if defined latest_tar if not defined BACKUP_TAR set "BACKUP_TAR=!latest_tar!"

if not defined BACKUP_TAR (
  echo [%batfilenam%] Error: No backup tar found.
  echo [%batfilenam%] Provide [BackupTar] or place files under %WSL_BACKUP_DIR%.
  exit /b 4
)

if not exist "%BACKUP_TAR%" (
  echo [%batfilenam%] Error: Backup tar not found: %BACKUP_TAR%
  exit /b 4
)

if not defined INSTALL_DIR set "INSTALL_DIR=%WSL_RESTORE_DIR%\%WSL_DISTRO%"

where wsl.exe >nul 2>nul
if not %ERRORLEVEL%==0 (
  echo [%batfilenam%] Error: wsl.exe not found.
  exit /b 4
)

call :IsDistroRegistered "%WSL_DISTRO%"
if %ERRORLEVEL%==0 (
  if /I "%MODE%"=="--replace" (
    echo [%batfilenam%] Existing distro found. Replacing: %WSL_DISTRO%
    wsl.exe --terminate %WSL_DISTRO% >nul 2>nul
    wsl.exe --unregister %WSL_DISTRO%
    if not %ERRORLEVEL%==0 (
      echo [%batfilenam%] Error: Failed to unregister existing distro.
      exit /b %ERRORLEVEL%
    )
  ) else (
    echo [%batfilenam%] Error: Distro already exists: %WSL_DISTRO%
    echo [%batfilenam%] Use --replace as 4th parameter to overwrite.
    exit /b 4
  )
)

if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"
if not exist "%INSTALL_DIR%" (
  echo [%batfilenam%] Error: Cannot create install directory: %INSTALL_DIR%
  exit /b 4
)

echo [%batfilenam%] Importing distro...
echo [%batfilenam%] Distro:      %WSL_DISTRO%
echo [%batfilenam%] Backup tar:  %BACKUP_TAR%
echo [%batfilenam%] Install dir: %INSTALL_DIR%
wsl.exe --import %WSL_DISTRO% "%INSTALL_DIR%" "%BACKUP_TAR%" --version 2
if not %ERRORLEVEL%==0 (
  echo [%batfilenam%] Error: Import failed.
  exit /b %ERRORLEVEL%
)

if defined WSL_USER (
  echo [%batfilenam%] Setting default user in /etc/wsl.conf: %WSL_USER%
  wsl.exe -d %WSL_DISTRO% -u root -- sh -lc "printf '[user]\ndefault=%s\n' '%WSL_USER%' > /etc/wsl.conf"
  if %ERRORLEVEL%==0 (
    wsl.exe --terminate %WSL_DISTRO% >nul 2>nul
    echo [%batfilenam%] Default user configured. Reopen distro to apply.
  ) else (
    echo [%batfilenam%] Warning: Failed to set default user automatically.
    echo [%batfilenam%] You can set it manually inside distro later.
  )
)

echo [%batfilenam%] Restore completed.
echo [%batfilenam%] Next: run run.bat
exit /b 0

:IsDistroRegistered
  setlocal
  set "target=%~1"
  powershell -NoProfile -Command "$target=$env:target; $items=Get-ChildItem -LiteralPath 'Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss' -ErrorAction SilentlyContinue; $match=$items | Where-Object { try { (Get-ItemProperty -LiteralPath $_.PSPath -ErrorAction Stop).DistributionName -eq $target } catch { $false } } | Select-Object -First 1; if ($match) { exit 0 } else { exit 1 }"
  set "rc=%ERRORLEVEL%"
  endlocal & exit /b %rc%

:FindLatestBackup
  setlocal
  set "dir=%~1"
  set "distro=%~2"
  set "latest="

  for /f "usebackq delims=" %%F in (`powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0find-latest-backup.ps1" -Directory "%dir%" -Distro "%distro%"`) do (
    if not defined latest set "latest=%%F"
  )

  endlocal & set "latest_tar=%latest%" & exit /b 0
