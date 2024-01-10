# Получение пути к службе Zabbix Agent
$zabbixService = Get-Service -Name "Zabbix Agent"

if ($zabbixService -ne $null) {
    $zabbixPath = (Get-WmiObject -Class Win32_Service | Where-Object { $_.Name -eq "Zabbix Agent" }).PathName
    $zabbixBinaryPath = $zabbixPath -replace '"','' | Split-Path -Parent

    if ($zabbixBinaryPath -ne $null) {
        $configFilePath = Join-Path -Path $zabbixBinaryPath -ChildPath "zabbix_agentd.conf"


# Установка пути к текущему расположению Zabbix Agent 4
#$oldAgentPath = "C:\Windows\zabbix-agent"

# Путь к загрузке новой версии Zabbix Agent 6
$newAgentDownloadURL = "https://cdn.zabbix.com/zabbix/binaries/stable/6.0/6.0.24/zabbix_agent-6.0.24-windows-amd64-openssl.zip"
$newAgentZipPath = "C:\Temp\zabbix_agent-6.0.24-windows-amd64-openssl.zip"
$newAgentExtractPath = "C:\Temp\zabbix_agent_6"

# Новые значения для замены в конфигурационном файле
$newServerValue = "10.15.253.253"

# Путь к файлу конфигурации Zabbix Agent
$configFilePath = "C:\Windows\zabbix-agent\zabbix_agentd.conf"

# Скачивание новой версии Zabbix Agent 6
Invoke-WebRequest -Uri $newAgentDownloadURL -OutFile $newAgentZipPath

# Распаковка архива с новой версией Zabbix Agent 6
Expand-Archive -Path $newAgentZipPath -DestinationPath $newAgentExtractPath

# Остановка Zabbix Agent 4
Stop-Service -Name "Zabbix Agent"

Start-Sleep -Seconds 5

# Копирование новой версии Zabbix Agent 6 в каталог назначения
Copy-Item -Path "$newAgentExtractPath\bin\zabbix_agentd.exe" -Destination "$oldAgentPath\zabbix_agentd.exe" -Force
Copy-Item -Path "$newAgentExtractPath\bin\zabbix_get.exe" -Destination "$oldAgentPath\zabbix_get.exe" -Force
Copy-Item -Path "$newAgentExtractPath\bin\zabbix_sender.exe" -Destination "$oldAgentPath\zabbix_sender.exe" -Force

# Замена значений в конфигурационном файле
$content = Get-Content $configFilePath
$newContent = $content -replace 'Server=.+', "Server=$newServerValue" `
                      -replace 'ServerActive=.+', "ServerActive=$newServerValue"

# Добавление новых строк в конец файла
$newContent += "DenyKey=system.run[*]"
$newContent += "UserParameter=win.description,powershell -NoProfile -ExecutionPolicy Bypass -Command `"`$desc = (Get-CimInstance -ClassName Win32_OperatingSystem).Description; [Console]::OutputEncoding = [System.Text.Encoding]::UTF8; Write-Output `$desc`""


$newContent | Set-Content $configFilePath

# Запуск Zabbix Agent 6
Start-Service -Name "Zabbix Agent"
   } else {
        Write-Host "Не удалось определить путь к исполняемым файлам Zabbix Agent."
    }
} else {
    Write-Host "Служба Zabbix Agent не найдена."
}
Remove-Item -Path C:\Temp\zabbix* -Recurse