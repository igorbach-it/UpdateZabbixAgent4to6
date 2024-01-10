# Установка пути к текущему расположению Zabbix Agent
$oldAgentPath = "C:\Windows\zabbix-agent"
$configFilePath = Join-Path -Path $oldAgentPath -ChildPath "zabbix_agentd.conf"

# Проверка наличия файла конфигурации
if (-not (Test-Path $configFilePath)) {
    Write-Host "Файл конфигурации Zabbix Agent не найден."
    exit
}

# Путь к загрузке новой версии Zabbix Agent 6
$newAgentDownloadURL = "https://cdn.zabbix.com/zabbix/binaries/stable/6.0/6.0.24/zabbix_agent-6.0.24-windows-amd64-openssl.zip"
$newAgentZipPath = "C:\Temp\zabbix_agent-6.0.24-windows-amd64-openssl.zip"
$newAgentExtractPath = "C:\Temp\zabbix_agent_6"

# Скачивание новой версии Zabbix Agent 6
Invoke-WebRequest -Uri $newAgentDownloadURL -OutFile $newAgentZipPath

# Проверка успешности скачивания
if (-not (Test-Path $newAgentZipPath)) {
    Write-Host "Не удалось скачать файл Zabbix Agent."
    exit
}

# Распаковка архива с новой версией Zabbix Agent 6
Expand-Archive -Path $newAgentZipPath -DestinationPath $newAgentExtractPath

# Проверка наличия распакованных файлов
if (-not (Test-Path "$newAgentExtractPath\bin\zabbix_agentd.exe")) {
    Write-Host "Не удалось распаковать файлы Zabbix Agent."
    exit
}

# Остановка Zabbix Agent
Stop-Service -Name "Zabbix Agent" -ErrorAction SilentlyContinue
Start-Sleep -Seconds 5

# Копирование новой версии Zabbix Agent в каталог назначения
Copy-Item -Path "$newAgentExtractPath\bin\zabbix_agentd.exe" -Destination "$oldAgentPath\zabbix_agentd.exe" -Force
Copy-Item -Path "$newAgentExtractPath\bin\zabbix_get.exe" -Destination "$oldAgentPath\zabbix_get.exe" -Force
Copy-Item -Path "$newAgentExtractPath\bin\zabbix_sender.exe" -Destination "$oldAgentPath\zabbix_sender.exe" -Force

# Новые значения для замены в конфигурационном файле
$newServerValue = "10.15.251.252"
$content = Get-Content $configFilePath

$newContent = $content -replace 'Server=.+', "Server=$newServerValue" `
                      -replace 'ServerActive=.+', "ServerActive=$newServerValue"

# Проверка и добавление новых строк в конец файла, если они отсутствуют
$denyKey = "DenyKey=system.run[*]"
$userParameter = "UserParameter=win.description,powershell -NoProfile -ExecutionPolicy Bypass -Command `"`$desc = (Get-CimInstance -ClassName Win32_OperatingSystem).Description; [Console]::OutputEncoding = [System.Text.Encoding]::UTF8; Write-Output `$desc`""

if (-not $content.Contains($denyKey)) {
    $newContent += "`r`n" + $denyKey
}

if (-not $content.Contains($userParameter)) {
    $newContent += "`r`n" + $userParameter
}

$newContent | Set-Content $configFilePath

# Запуск Zabbix Agent
Start-Service -Name "Zabbix Agent" -ErrorAction SilentlyContinue

# Удаление временных файлов
Remove-Item -Path C:\Temp\zabbix* -Recurse -Force
