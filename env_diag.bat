@echo off
setlocal enabledelayedexpansion

:: Define log file
set "LOGFILE=%~dp0env_diagnostics_%date:~10,4%-%date:~4,2%-%date:~7,2%.txt"

echo Environment Diagnostics Toolkit
echo ===============================

echo Starting diagnostics on %date% at %time%
echo.

echo --- Environment Diagnostics Report --- > "%LOGFILE%"
echo Report generated on %date% at %time% >> "%LOGFILE%"
echo. >> "%LOGFILE%"

:: System Information
echo [SYSTEM INFORMATION] >> "%LOGFILE%"
echo -------------------- >> "%LOGFILE%"
systeminfo | findstr /v /c:"^$" >> "%LOGFILE%"
echo. >> "%LOGFILE%"

:: Windows Version & Updates
echo [WINDOWS VERSION & UPDATES] >> "%LOGFILE%"
echo --------------------------- >> "%LOGFILE%"
ver >> "%LOGFILE%"
echo. >> "%LOGFILE%"

echo Installed updates (last 5): >> "%LOGFILE%"
powershell -Command "Get-HotFix | Select-Object -Last 5 | Format-Table -AutoSize" >> "%LOGFILE%" 2>nul
echo. >> "%LOGFILE%"

:: CPU & RAM info
echo [CPU & MEMORY] >> "%LOGFILE%"
echo ------------- >> "%LOGFILE%"
wmic cpu get name,MaxClockSpeed,NumberOfCores,NumberOfLogicalProcessors >> "%LOGFILE%"
wmic OS get TotalVisibleMemorySize,FreePhysicalMemory >> "%LOGFILE%"
echo. >> "%LOGFILE%"

:: Disk usage
echo [DISK USAGE] >> "%LOGFILE%"
echo ---------- >> "%LOGFILE%"
wmic logicaldisk get caption,size,freespace,filesystem >> "%LOGFILE%"
echo. >> "%LOGFILE%"

:: Network Information
echo [NETWORK CONFIGURATION] >> "%LOGFILE%"
echo --------------------- >> "%LOGFILE%"
ipconfig /all >> "%LOGFILE%"
echo. >> "%LOGFILE%"

echo [NETWORK TESTS] >> "%LOGFILE%"
echo ------------- >> "%LOGFILE%"
echo Pinging google.com... >> "%LOGFILE%"
ping -n 4 google.com >> "%LOGFILE%"
echo. >> "%LOGFILE%"

:: Installed Programs
echo [INSTALLED PROGRAMS] >> "%LOGFILE%"
echo ------------------- >> "%LOGFILE%"
powershell -Command "Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion | Where-Object { $_.DisplayName } | Sort-Object DisplayName | Format-Table -AutoSize" >> "%LOGFILE%" 2>nul
echo. >> "%LOGFILE%"

:: Running Services
echo [RUNNING SERVICES] >> "%LOGFILE%"
echo ---------------- >> "%LOGFILE%"
sc query state= all | findstr /i "SERVICE_NAME STATE" >> "%LOGFILE%"
echo. >> "%LOGFILE%"

echo Diagnostics complete! Log saved to:
echo %LOGFILE%

pause
endlocal
