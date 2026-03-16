@echo off
setlocal EnableDelayedExpansion

set "batfilenam=%~nx0"
for %%I in ("%~dp0..\..") do set "ROOTDIR=%%~fI"
if "%ROOTDIR:~-1%"=="\" set "ROOTDIR=%ROOTDIR:~0,-1%"
set "WSL_DISTRO=%~1"
set "BACKUP_DIR=%~2"
set "MODE=%~3"

if not defined WSL_DISTRO (
  if exist "%ROOTDIR%\_internal\config.bat" call "%ROOTDIR%\_internal\config.bat"
)

if not defined BACKUP_DIR (
  if defined WSL_BACKUP_DIR (
    set "BACKUP_DIR=%WSL_BACKUP_DIR%"
  ) else (
    set "BACKUP_DIR=%ROOTDIR%\backup"
  )
)

call :ResolvePath "%BACKUP_DIR%" BACKUP_DIR

if not defined WSL_BACKUP_KEEP set "WSL_BACKUP_KEEP=5"

if not defined WSL_DISTRO (
  echo [%batfilenam%] Error: Missing distro name.
  echo [%batfilenam%] Usage: %batfilenam% ^<DistroName^> [BackupDir] [--safe]
  exit /b 4
)

where wsl.exe >nul 2>nul
if not %ERRORLEVEL%==0 (
  echo [%batfilenam%] Error: wsl.exe not found.
  exit /b 4
)

call :IsDistroRegistered "%WSL_DISTRO%"
if not %ERRORLEVEL%==0 (
  echo [%batfilenam%] Error: Distro not registered: %WSL_DISTRO%
  exit /b 4
)

if /I "%MODE%"=="--safe" (
  echo [%batfilenam%] Safe mode: terminating distro before export...
  wsl.exe --terminate %WSL_DISTRO% >nul 2>nul
)

if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"
if not exist "%BACKUP_DIR%" (
  echo [%batfilenam%] Error: Cannot create backup directory: %BACKUP_DIR%
  exit /b 4
)

for /f %%T in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "TS=%%T"
if not defined TS (
  echo [%batfilenam%] Error: Cannot generate timestamp.
  exit /b 4
)

set "OUT=%BACKUP_DIR%\%WSL_DISTRO%_!TS!.tar"

echo [%batfilenam%] Exporting distro: %WSL_DISTRO%
echo [%batfilenam%] Output file: !OUT!
wsl.exe --export %WSL_DISTRO% "!OUT!"
if not %ERRORLEVEL%==0 (
  echo [%batfilenam%] Error: Export failed.
  exit /b %ERRORLEVEL%
)

for %%F in ("!OUT!") do set "OUT_SIZE=%%~zF"
echo [%batfilenam%] Backup done. Size=!OUT_SIZE! bytes

call :PruneOldBackups "%BACKUP_DIR%" "%WSL_DISTRO%" %WSL_BACKUP_KEEP%
exit /b 0

:IsDistroRegistered
  setlocal
  set "target=%~1"
  powershell -NoProfile -Command "$target=$env:target; $items=Get-ChildItem -LiteralPath 'Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss' -ErrorAction SilentlyContinue; $match=$items | Where-Object { try { (Get-ItemProperty -LiteralPath $_.PSPath -ErrorAction Stop).DistributionName -eq $target } catch { $false } } | Select-Object -First 1; if ($match) { exit 0 } else { exit 1 }"
  set "rc=%ERRORLEVEL%"
  endlocal & exit /b %rc%

:PruneOldBackups
  setlocal
  set "dir=%~1"
  set "distro=%~2"
  set "keep=%~3"
  if not defined keep set "keep=5"

  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0prune-backups.ps1" -Directory "%dir%" -Distro "%distro%" -Keep %keep%
  echo [%batfilenam%] Keep latest %keep% backups for %distro%.
  endlocal & exit /b 0

:ResolvePath
  setlocal
  set "p=%~1"
  if not defined p endlocal & set "%~2=" & exit /b 0

  set "abs="
  if "%p:~1,1%"==":" (
    set "abs=%p%"
  ) else if "%p:~0,2%"=="\\" (
    set "abs=%p%"
  ) else (
    set "abs=%ROOTDIR%\%p%"
  )

  for %%I in ("%abs%") do set "abs=%%~fI"
  if "%abs:~-1%"=="\" set "abs=%abs:~0,-1%"

  endlocal & set "%~2=%abs%" & exit /b 0
