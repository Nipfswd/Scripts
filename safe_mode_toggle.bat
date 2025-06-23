@echo off
setlocal

:: Check if running as admin
openfiles >nul 2>&1
if %errorlevel% NEQ 0 (
    echo Please run this script as Administrator.
    pause
    exit /b 1
)

echo Safe Mode Boot Toggle
echo ====================

:: Check current safeboot state
bcdedit /enum | findstr /i safeboot >nul
if %errorlevel%==0 (
    set "state=enabled"
) else (
    set "state=disabled"
)

echo Current Safe Mode Boot: %state%
echo.
echo Choose an option:
echo 1. Enable Safe Mode Boot
echo 2. Disable Safe Mode Boot
echo 3. Exit
set /p choice=Enter your choice (1-3): 

if "%choice%"=="1" goto enable
if "%choice%"=="2" goto disable
if "%choice%"=="3" goto end

echo Invalid choice!
pause
goto :eof

:enable
echo Enabling Safe Mode Boot...
:: Set safeboot minimal on current default boot entry
for /f "tokens=3" %%a in ('bcdedit /enum | findstr /i "default"') do (
    set "default_guid=%%a"
)
bcdedit /set %default_guid% safeboot minimal

echo Safe Mode boot enabled!
echo Reboot your PC to boot into Safe Mode.
pause
goto end

:disable
echo Disabling Safe Mode Boot...
for /f "tokens=3" %%a in ('bcdedit /enum | findstr /i "default"') do (
    set "default_guid=%%a"
)
bcdedit /deletevalue %default_guid% safeboot

echo Safe Mode boot disabled!
pause
goto end

:end
endlocal
