@echo off
setlocal EnableDelayedExpansion

set "batfilenam=%~nx0"
set "ThisWslDistributionName=%~1"
set "UnixUser=%~2"

if not defined ThisWslDistributionName (
  echo [%batfilenam%] Need a DistributionName as parameter.
  echo [%batfilenam%] Examples:
  echo [%batfilenam%]     %batfilenam% Ubuntu-22.04
  echo [%batfilenam%]     %batfilenam% Ubuntu-22.04 bob
  exit /b 4
)

if not "%~3"=="" (
  echo [%batfilenam%] Error: Only one or two parameters are allowed.
  exit /b 4
)

call :HasSpaceChar %ThisWslDistributionName%
if %ERRORLEVEL%==1 (
  echo [%batfilenam%] Error: DistributionName must NOT contain spaces.
  exit /b 4
)

if defined UnixUser (
  call :HasSpaceChar %UnixUser%
  if %ERRORLEVEL%==1 (
    echo [%batfilenam%] Error: UnixUser must NOT contain spaces.
    exit /b 4
  )
  set "_u_param=-u %UnixUser%"
) else (
  set "_u_param="
)

call :IsDistroRegistered "%ThisWslDistributionName%"
if not %ERRORLEVEL%==0 (
  echo [%batfilenam%] Distro not found. Registering via register.bat ...
  call "%~dp0register.bat" %ThisWslDistributionName% %UnixUser%
  exit /b %ERRORLEVEL%
)

set "wsl_launch_cmd=wsl.exe -d %ThisWslDistributionName% %_u_param% --cd ~"

set "in_wt="
if defined WT_SESSION set "in_wt=1"

set "has_wt="
where wt.exe >nul 2>nul
if %ERRORLEVEL%==0 set "has_wt=1"

if not defined in_wt if defined has_wt (
  echo [%batfilenam%] Launching WSL in existing Windows Terminal window ^(new tab^).
  wt -w 0 nt --title "WSL - %ThisWslDistributionName%" %wsl_launch_cmd%
  if %ERRORLEVEL%==0 exit /b 0
  echo [%batfilenam%] Warning: wt.exe launch failed, fallback to current console.
)

echo [%batfilenam%] EXEC: %wsl_launch_cmd%
call %wsl_launch_cmd%
exit /b %ERRORLEVEL%

:IsDistroRegistered
  setlocal
  set "target=%~1"
  powershell -NoProfile -Command "$target=$env:target; $items=Get-ChildItem -LiteralPath 'Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss' -ErrorAction SilentlyContinue; $match=$items | Where-Object { try { (Get-ItemProperty -LiteralPath $_.PSPath -ErrorAction Stop).DistributionName -eq $target } catch { $false } } | Select-Object -First 1; if ($match) { exit 0 } else { exit 1 }"
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
