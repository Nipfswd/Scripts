@echo off
setlocal

echo System Cleanup Tool - Starting...

:: 1. Delete user temp files
echo Deleting user temp files...
del /s /q "%TEMP%\*.*" 2>nul
for /d %%d in ("%TEMP%\*") do rd /s /q "%%d" 2>nul

:: 2. Delete Windows temp files (requires admin)
echo Deleting Windows temp files...
del /s /q "C:\Windows\Temp\*.*" 2>nul
for /d %%d in ("C:\Windows\Temp\*") do rd /s /q "%%d" 2>nul

:: 3. Empty Recycle Bin
echo Emptying Recycle Bin...
powershell.exe -NoProfile -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue"

:: 4. Clear Windows Logs (Event Logs)
echo Clearing Windows Event Logs...
for /f "tokens=*" %%G in ('wevtutil el') do (
    echo Clearing log: %%G
    wevtutil cl "%%G" >nul 2>&1
)

:: 5. Clear browser caches (basic)
echo Clearing browser caches...

:: Chrome cache
if exist "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache" (
    echo Deleting Chrome cache...
    rmdir /s /q "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache"
)

:: Edge cache
if exist "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Cache" (
    echo Deleting Edge cache...
    rmdir /s /q "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Cache"
)

:: Firefox cache (profile folder detection is complex, we do default path)
for /d %%P in ("%APPDATA%\Mozilla\Firefox\Profiles\*") do (
    if exist "%%P\cache2" (
        echo Deleting Firefox cache...
        rmdir /s /q "%%P\cache2"
    )
)

echo Cleanup complete!
pause
endlocal
