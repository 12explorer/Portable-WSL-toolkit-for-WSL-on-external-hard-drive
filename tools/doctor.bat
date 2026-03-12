@echo off
setlocal EnableDelayedExpansion

set "batfilenam=%~nx0"
for %%I in ("%~dp0..") do set "ROOTDIR=%%~fI"
if "%ROOTDIR:~-1%"=="\" set "ROOTDIR=%ROOTDIR:~0,-1%"
set "BASEDIR=%ROOTDIR%"

set "WSL_DISTRO=%~1"
set "WSL_USER=%~2"

if not defined WSL_DISTRO (
  if exist "%ROOTDIR%\_internal\config.bat" call "%ROOTDIR%\_internal\config.bat"
)

if not defined WSL_DISTRO (
  echo [%batfilenam%] Error: Missing distro name.
  echo [%batfilenam%] Usage: %batfilenam% ^<DistroName^> [UnixUser]
  exit /b 4
)

set /a fail=0
echo [%batfilenam%] Checking portable WSL setup...

where wsl.exe >nul 2>nul
if %ERRORLEVEL%==0 (
  echo [%batfilenam%] [OK] wsl.exe exists
) else (
  echo [%batfilenam%] [FAIL] wsl.exe not found in PATH
  set /a fail+=1
)

where reg.exe >nul 2>nul
if %ERRORLEVEL%==0 (
  echo [%batfilenam%] [OK] reg.exe exists
) else (
  echo [%batfilenam%] [FAIL] reg.exe not found in PATH
  set /a fail+=1
)

where wt.exe >nul 2>nul
if %ERRORLEVEL%==0 (
  echo [%batfilenam%] [OK] wt.exe exists ^(tab merge available^)
) else (
  echo [%batfilenam%] [WARN] wt.exe not found ^(will fallback to console^)
)

if exist "%BASEDIR%\ext4.vhdx" (
  for %%F in ("%BASEDIR%\ext4.vhdx") do set "vhdsize=%%~zF"
  echo [%batfilenam%] [OK] ext4.vhdx exists, size=!vhdsize! bytes
) else if exist "%BASEDIR%\rootfs\root" (
  echo [%batfilenam%] [OK] WSL1 rootfs detected
) else (
  echo [%batfilenam%] [FAIL] No ext4.vhdx or rootfs found under "%BASEDIR%"
  set /a fail+=1
)

call :IsDistroRegistered "%WSL_DISTRO%"
if %ERRORLEVEL%==0 (
  echo [%batfilenam%] [OK] Distro registered: %WSL_DISTRO%
) else (
  echo [%batfilenam%] [WARN] Distro not registered: %WSL_DISTRO%
  echo [%batfilenam%] [INFO] Run run.bat to auto-register.
)

if defined WSL_USER (
  echo [%batfilenam%] [INFO] Config user: %WSL_USER%
)

if %fail%==0 (
  echo [%batfilenam%] Result: PASS
  exit /b 0
) else (
  echo [%batfilenam%] Result: FAIL ^(%fail% critical item^)
  exit /b 2
)

:IsDistroRegistered
  setlocal EnableDelayedExpansion
  set "target=%~1"
  set "found="
  for /f "usebackq delims=" %%D in (`wsl.exe -l -q 2^>nul`) do (
    if /I "%%D"=="!target!" set "found=1"
  )
  if defined found (
    endlocal & exit /b 0
  ) else (
    endlocal & exit /b 1
  )
