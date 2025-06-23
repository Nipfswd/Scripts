@echo off
setlocal enabledelayedexpansion

echo Retrieving saved Wi-Fi profiles and passwords...
echo.

:: Get list of profiles
for /f "tokens=*" %%a in ('netsh wlan show profiles ^| findstr "All User Profile"') do (
    set "line=%%a"
    :: Extract profile name (SSID)
    for /f "tokens=4* delims=: " %%b in ("!line!") do (
        set "ssid=%%c"
        call :trim ssid ssid
        echo SSID: !ssid!

        :: Get profile details including key
        netsh wlan show profile name="!ssid!" key=clear | findstr "Key Content"
        echo.
    )
)

pause
goto :eof

:trim
:: Trim leading and trailing spaces from %2, store result in variable named %1
setlocal enabledelayedexpansion
set "str=%~2"
:: Remove leading spaces
:trimloop1
if "!str:~0,1!"==" " set "str=!str:~1!" & goto trimloop1
:: Remove trailing spaces
:trimloop2
if "!str:~-1!"==" " set "str=!str:~0,-1!" & goto trimloop2
endlocal & set "%~1=%str%"
goto :eof
