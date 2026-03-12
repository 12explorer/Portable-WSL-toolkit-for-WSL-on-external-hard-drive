@echo off
setlocal EnableDelayedExpansion

set "batfilenam=%~nx0"
for %%I in ("%~dp0..") do set "ROOTDIR=%%~fI"
if "%ROOTDIR:~-1%"=="\" set "ROOTDIR=%ROOTDIR:~0,-1%"
set "CONFIG_FILE=%ROOTDIR%\_internal\config.bat"
set "CONFIG_BACKUP=%ROOTDIR%\_internal\config.before-rename.bat"

set "NEW_DISTRO=%~1"
set "OLD_DISTRO=%~2"
set "WSL_USER="

if exist "%CONFIG_FILE%" call "%CONFIG_FILE%"

if not defined OLD_DISTRO set "OLD_DISTRO=%WSL_DISTRO%"

if not defined OLD_DISTRO (
  echo [%batfilenam%] Error: Current distro name is not set in _internal\config.bat
  exit /b 4
)

if not defined NEW_DISTRO (
  set /p NEW_DISTRO=[%batfilenam%] Enter new distro name: 
)

if not defined NEW_DISTRO (
  echo [%batfilenam%] Error: New distro name is required.
  exit /b 4
)

call :HasSpaceChar %NEW_DISTRO%
if %ERRORLEVEL%==1 (
  echo [%batfilenam%] Error: New distro name must NOT contain spaces.
  exit /b 4
)

if /I "%NEW_DISTRO%"=="%OLD_DISTRO%" (
  echo [%batfilenam%] New name is the same as current name. Nothing to do.
  exit /b 0
)

call :IsDistroRegistered "%NEW_DISTRO%"
if %ERRORLEVEL%==0 (
  echo [%batfilenam%] Error: Target distro name already exists: %NEW_DISTRO%
  exit /b 4
)

if exist "%ROOTDIR%\stop.bat" (
  call "%ROOTDIR%\stop.bat" %OLD_DISTRO% >nul 2>nul
)

call :DeleteRegistryEntry "%OLD_DISTRO%" "%ROOTDIR%"
if %ERRORLEVEL% GEQ 2 (
  echo [%batfilenam%] Error: Failed to remove old registry entry.
  exit /b %ERRORLEVEL%
)
if %ERRORLEVEL%==1 (
  echo [%batfilenam%] Warning: Old registry entry was not found for this project path.
)

if not exist "%CONFIG_FILE%" (
  echo [%batfilenam%] Error: _internal\config.bat not found.
  exit /b 4
)

copy /y "%CONFIG_FILE%" "%CONFIG_BACKUP%" >nul
powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOTDIR%\_internal\scripts\update-config.ps1" -ConfigFile "%CONFIG_FILE%" -SettingName "WSL_DISTRO" -SettingValue "%NEW_DISTRO%"
if not %ERRORLEVEL%==0 (
  echo [%batfilenam%] Error: Failed to update _internal\config.bat
  exit /b %ERRORLEVEL%
)

if defined WSL_USER (
  call "%ROOTDIR%\_internal\scripts\register.bat" %NEW_DISTRO% %WSL_USER% --no-launch
) else (
  call "%ROOTDIR%\_internal\scripts\register.bat" %NEW_DISTRO% "" --no-launch
)
if not %ERRORLEVEL%==0 (
  set "REGISTER_RC=!ERRORLEVEL!"
  echo [%batfilenam%] Error: Failed to register new distro name.
  if exist "%CONFIG_BACKUP%" copy /y "%CONFIG_BACKUP%" "%CONFIG_FILE%" >nul
  echo [%batfilenam%] _internal\config.bat has been restored from backup.
  if defined WSL_USER (
    call "%ROOTDIR%\_internal\scripts\register.bat" %OLD_DISTRO% %WSL_USER% --no-launch >nul 2>nul
  ) else (
    call "%ROOTDIR%\_internal\scripts\register.bat" %OLD_DISTRO% "" --no-launch >nul 2>nul
  )
  if !ERRORLEVEL!==0 (
    echo [%batfilenam%] Old distro registration has been restored.
  ) else (
    echo [%batfilenam%] Warning: Failed to restore old distro registration automatically.
  )
  exit /b !REGISTER_RC!
)

wsl.exe --set-default %NEW_DISTRO% >nul 2>nul

echo [%batfilenam%] Rename completed.
echo [%batfilenam%] Old name: %OLD_DISTRO%
echo [%batfilenam%] New name: %NEW_DISTRO%
exit /b 0

:IsDistroRegistered
  setlocal
  set "target=%~1"
  powershell -NoProfile -Command "$target=$env:target; $items=Get-ChildItem -LiteralPath 'Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss' -ErrorAction SilentlyContinue; $match=$items | Where-Object { try { (Get-ItemProperty -LiteralPath $_.PSPath -ErrorAction Stop).DistributionName -eq $target } catch { $false } } | Select-Object -First 1; if ($match) { exit 0 } else { exit 1 }"
  set "rc=%ERRORLEVEL%"
  endlocal & exit /b %rc%

:DeleteRegistryEntry
  setlocal
  set "target=%~1"
  set "base=%~2"
  powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOTDIR%\_internal\scripts\remove-lxss-entry.ps1" -DistributionName "%target%" -BasePath "%base%"
  set "rc=%ERRORLEVEL%"
  endlocal & exit /b %rc%

:HasSpaceChar
  setlocal & set "input=%*"
  if not defined input exit /b 1

  set "input=%input:"=#%"
  set count=0
  for %%i in (%input%) do (
    set /A count=count+1
  )
  if %count%==1 (
    exit /b 0
  ) else (
    exit /b 1
  )
