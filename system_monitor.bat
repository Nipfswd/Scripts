@echo off
title Elite System Monitor v5.0
mode con: cols=160 lines=50
color 0A
setlocal EnableDelayedExpansion

:: === CONFIGURATION ===
set "LOG_DIR=%~dp0logs"
set "MAX_LOG_SIZE=10485760"
set "CSV_FILE=%LOG_DIR%\system_monitor.csv"
set "CPU_ALERT=85"
set "RAM_ALERT=90"
set "TEMP_ALERT=75"
set "DISK_ALERT=10"
set "EMAIL_ALERT=admin@example.com"
set "SMTP_SERVER=smtp.example.com"
set "SMTP_PORT=587"
set "SMTP_USER=user@example.com"
set "SMTP_PASS=password"
set "SLACK_WEBHOOK=https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
set "PROMETHEUS_PUSHGATEWAY=http://localhost:9091/metrics/job/elite_system_monitor"
set "RETENTION_DAYS=30"

:: === INITIALIZATION ===
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
if not exist "%CSV_FILE%" (
    echo Timestamp,CPU%%,RAM%%,TempC,NetInKB,NetOutKB,GPUUsage%%,DiskFree%% >> "%CSV_FILE%"
)

:loop
cls
set "ts=%date% %time%"
for /f "tokens=2 delims==" %%T in ('wmic os get LocalDateTime /value') do set datetime=%%T
set datetime=%datetime:~0,4%-%datetime:~4,2%-%datetime:~6,2%_%datetime:~8,2%-%datetime:~10,2%-%datetime:~12,2%
set "logfile=%LOG_DIR%\monitor_%datetime%.txt"

:: === SYSTEM METRICS ===
for /f "delims=" %%A in ('powershell -NoProfile -Command ^
"try {
  $os = Get-CimInstance Win32_OperatingSystem;
  $cpu = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue;
  $ramUsed = ($os.TotalVisibleMemorySize - $os.FreePhysicalMemory)/1MB;
  $ramTotal = $os.TotalVisibleMemorySize/1MB;
  $ramPct = ($ramUsed / $ramTotal) * 100;
  $temp = (Get-CimInstance root/wmi MSAcpi_ThermalZoneTemperature).CurrentTemperature;
  $tempC = ($temp - 2732) / 10;
  '{0:F1},{1:F1},{2:F1}' -f $cpu, $ramPct, $tempC
} catch { '0,0,0' }"') do set "metrics=%%A"
for /f "tokens=1,2,3 delims=," %%C in ("%metrics%") do (
    set "CPU=%%C"
    set "RAM=%%D"
    set "TEMP=%%E"
)

:: === NETWORK METRICS ===
for /f "delims=" %%N in ('powershell -NoProfile -Command ^
"try {
  $net = Get-NetAdapterStatistics | Where-Object { $_.ReceivedBytes -gt 0 } | Select-Object -First 1;
  '{0},{1}' -f ($net.ReceivedBytes/1KB), ($net.SentBytes/1KB);
} catch { '0,0' }"') do set "NET=%%N"
for /f "tokens=1,2 delims=," %%I in ("%NET%") do (
    set "NetIn=%%I"
    set "NetOut=%%J"
)

:: === DISK METRICS ===
set "DiskAlertText="
set "DiskFreePct=100"
for /f "delims=" %%D in ('powershell -NoProfile -Command ^
"Get-WmiObject Win32_LogicalDisk -Filter \"DriveType=3\" | ForEach-Object {
  $pct = ($_.FreeSpace / $_.Size) * 100;
  if ($pct -lt %DISK_ALERT%) {
    Write-Output \"ALERT: Drive $($_.DeviceID) has low space ($([math]::Round($pct,2))%%)\";
  }
  Write-Output $([math]::Round($pct,0));
}"') do set "DiskFreePct=%%D"

:: === GPU MONITORING ===
set "GPUUsage=0"
if exist "C:\Program Files\NVIDIA Corporation\NVSMI\nvidia-smi.exe" (
    for /f "tokens=1,* delims=," %%G in ('"C:\Program Files\NVIDIA Corporation\NVSMI\nvidia-smi.exe" --query-gpu=utilization.gpu --format=csv,noheader,nounits') do set "GPUUsage=%%G"
)

:: === PROCESS MONITORING ===
echo === Top CPU-consuming processes === >> "%logfile%"
powershell -NoProfile -Command "Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 Name, CPU | Format-Table -AutoSize" >> "%logfile%"

:: === PUSH TO PROMETHEUS ===
powershell -NoProfile -Command ^
"try {
  \$metrics = @'
system_cpu_percent %CPU%
system_ram_percent %RAM%
system_temp_celsius %TEMP%
system_net_in_kb %NetIn%
system_net_out_kb %NetOut%
system_gpu_usage %GPUUsage%
system_disk_free_pct %DiskFreePct%
'@;
  Invoke-RestMethod -Method Post -Uri '%PROMETHEUS_PUSHGATEWAY%' -Body \$metrics -ContentType 'text/plain';
} catch { Write-Output 'Pushgateway failed' }"

:: === LOG TO CSV ===
echo %ts%,%CPU%,%RAM%,%TEMP%,%NetIn%,%NetOut%,%GPUUsage%,%DiskFreePct% >> "%CSV_FILE%"

:: === DISPLAY ===
call :DrawBar CPU %CPU%
call :DrawBar RAM %RAM%
call :DrawBar GPU %GPUUsage%
echo Temp: %TEMP%C
echo Net In: %NetIn% KB | Net Out: %NetOut% KB
echo Disk Free: %DiskFreePct%%% 

:: === ALERTING ===
call :CheckAlert CPU %CPU% %CPU_ALERT%
call :CheckAlert RAM %RAM% %RAM_ALERT%
call :CheckAlert TEMP %TEMP% %TEMP_ALERT%
if defined DiskAlertText echo !DiskAlertText! >> "%logfile%"

echo Press Ctrl+C to exit.
timeout /t 10 >nul
goto loop

:DrawBar
setlocal
set "label=%~1"
set /a val=%~2, bars=(val*50)/100
set "bar="
for /L %%i in (1,1,!bars!) do set "bar=!bar!#"
echo !label!: [!bar!] !val!%%
endlocal & goto :eof

:CheckAlert
setlocal
set "name=%~1"
set "val=%~2"
set "thr=%~3"
if %val% GEQ %thr% (
    echo ALERT: %name% exceeded threshold (%val% >= %thr%)
    powershell -NoProfile -Command ^
    "Send-MailMessage -To '%EMAIL_ALERT%' -From '%SMTP_USER%' -Subject 'ALERT: %name% on %COMPUTERNAME%' -Body 'Value: %val%' -SmtpServer '%SMTP_SERVER%' -Port %SMTP_PORT% -UseSsl -Credential (New-Object PSCredential('%SMTP_USER%', (ConvertTo-SecureString '%SMTP_PASS%' -AsPlainText -Force)))"
    if defined SLACK_WEBHOOK (
        powershell -NoProfile -Command ^
        "Invoke-RestMethod -Uri '%SLACK_WEBHOOK%' -Method POST -Body ('{"text":"ALERT: %name% is at %val% on %COMPUTERNAME%"}') -ContentType 'application/json'"
    )
)
endlocal & goto :eof
