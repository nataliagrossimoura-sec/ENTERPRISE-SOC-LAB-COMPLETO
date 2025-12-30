<#
.SYNOPSIS
    Script para gerar atividade de teste no SOC Lab
    
.DESCRIPTION
    Gera diversos tipos de eventos para testar detecção:
    - Processos
    - Arquivos
    - Registry
    - Rede
    - PowerShell
    
.PARAMETER ActivityType
    Tipo de atividade: All, Process, File, Registry, Network, PowerShell
    
.NOTES
    Autor: Natália Grossi
    Projeto: Enterprise SOC Lab
    Uso: .\generate-activity.ps1 -ActivityType All
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("All", "Process", "File", "Registry", "Network", "PowerShell")]
    [string]$ActivityType = "All"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Gerador de Atividade de Teste        " -ForegroundColor Cyan
Write-Host "  Enterprise SOC Lab                   " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Função para exibir progresso
function Write-Activity {
    param([string]$Message, [string]$Color = "Green")
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $Message" -ForegroundColor $Color
}

# 1. ATIVIDADE DE PROCESSOS
function Generate-ProcessActivity {
    Write-Activity "Gerando atividade de processos..." "Yellow"
    
    # Abrir e fechar notepad
    Write-Activity "  Iniciando notepad.exe..."
    Start-Process notepad
    Start-Sleep -Seconds 2
    Write-Activity "  Encerrando notepad.exe..."
    Stop-Process -Name notepad -Force -ErrorAction SilentlyContinue
    
    # Abrir e fechar calc
    Write-Activity "  Iniciando calc.exe..."
    Start-Process calc
    Start-Sleep -Seconds 2
    Write-Activity "  Encerrando calc.exe..."
    Stop-Process -Name Calculator* -Force -ErrorAction SilentlyContinue
    
    # Executar cmd.exe com comando
    Write-Activity "  Executando cmd.exe..."
    Start-Process cmd.exe -ArgumentList "/c echo teste > nul" -WindowStyle Hidden -Wait
    
    # PowerShell child process
    Write-Activity "  Executando PowerShell child process..."
    Start-Process powershell -ArgumentList "-NoProfile", "-Command", "Write-Host 'Teste'" -WindowStyle Hidden -Wait
    
    Write-Activity "✓ Atividade de processos concluída" "Green"
}

# 2. ATIVIDADE DE ARQUIVOS
function Generate-FileActivity {
    Write-Activity "Gerando atividade de arquivos..." "Yellow"
    
    # Criar diretório temporário
    $testDir = "C:\Temp\SOC-Test"
    if (-not (Test-Path $testDir)) {
        Write-Activity "  Criando diretório $testDir..."
        New-Item -ItemType Directory -Path $testDir -Force | Out-Null
    }
    
    # Criar múltiplos arquivos
    Write-Activity "  Criando 10 arquivos de teste..."
    1..10 | ForEach-Object {
        $fileName = "$testDir\testfile$_.txt"
        "Conteúdo de teste $(Get-Date)" | Out-File $fileName
    }
    
    # Modificar arquivos
    Write-Activity "  Modificando arquivos..."
    Get-ChildItem "$testDir\*.txt" | ForEach-Object {
        "Modificação: $(Get-Date)" | Add-Content $_.FullName
    }
    
    # Criar arquivo ZIP
    Write-Activity "  Criando arquivo compactado..."
    if (Get-Command Compress-Archive -ErrorAction SilentlyContinue) {
        Compress-Archive -Path "$testDir\*.txt" -DestinationPath "$testDir\backup.zip" -Force
    }
    
    # Deletar alguns arquivos
    Write-Activity "  Deletando 5 arquivos..."
    Get-ChildItem "$testDir\*.txt" | Select-Object -First 5 | Remove-Item -Force
    
    Write-Activity "✓ Atividade de arquivos concluída" "Green"
}

# 3. ATIVIDADE DE REGISTRY
function Generate-RegistryActivity {
    Write-Activity "Gerando atividade de registry..." "Yellow"
    
    # Caminho de teste (HKCU não requer admin)
    $regPath = "HKCU:\Software\SOC-Lab-Test"
    
    # Criar chave
    Write-Activity "  Criando chave de registro..."
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }
    
    # Criar valores
    Write-Activity "  Criando valores de registro..."
    Set-ItemProperty -Path $regPath -Name "TestValue1" -Value "Teste1" -Force
    Set-ItemProperty -Path $regPath -Name "TestValue2" -Value 123 -Force
    Set-ItemProperty -Path $regPath -Name "TestDate" -Value (Get-Date).ToString() -Force
    
    # Modificar valor
    Write-Activity "  Modificando valores..."
    Set-ItemProperty -Path $regPath -Name "TestValue1" -Value "Modificado" -Force
    
    # Deletar valor
    Write-Activity "  Deletando valor..."
    Remove-ItemProperty -Path $regPath -Name "TestValue2" -ErrorAction SilentlyContinue
    
    # Simular persistence (NÃO cria realmente, apenas testa path)
    Write-Activity "  Testando acesso a Run keys..."
    $runPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    if (Test-Path $runPath) {
        Get-ItemProperty -Path $runPath -ErrorAction SilentlyContinue | Out-Null
    }
    
    # Limpar chave de teste
    Write-Activity "  Limpando chave de teste..."
    Remove-Item -Path $regPath -Recurse -Force -ErrorAction SilentlyContinue
    
    Write-Activity "✓ Atividade de registry concluída" "Green"
}

# 4. ATIVIDADE DE REDE
function Generate-NetworkActivity {
    Write-Activity "Gerando atividade de rede..." "Yellow"
    
    # Teste de conexão local
    Write-Activity "  Testando conexão com gateway..."
    Test-NetConnection 192.168.1.1 -WarningAction SilentlyContinue | Out-Null
    
    # Teste de conexão externa
    Write-Activity "  Testando conexão com Google DNS..."
    Test-NetConnection 8.8.8.8 -WarningAction SilentlyContinue | Out-Null
    
    # Resolução DNS
    Write-Activity "  Resolvendo DNS..."
    Resolve-DnsName google.com -ErrorAction SilentlyContinue | Out-Null
    Resolve-DnsName github.com -ErrorAction SilentlyContinue | Out-Null
    
    # Teste de porta específica
    Write-Activity "  Testando portas específicas..."
    Test-NetConnection google.com -Port 443 -WarningAction SilentlyContinue | Out-Null
    
    # Download de arquivo (simulado)
    Write-Activity "  Simulando download..."
    try {
        $null = Invoke-WebRequest -Uri "https://www.example.com" -UseBasicParsing -TimeoutSec 5 -ErrorAction SilentlyContinue
    } catch {
        # Esperado falhar, apenas gera tráfego
    }
    
    Write-Activity "✓ Atividade de rede concluída" "Green"
}

# 5. ATIVIDADE DE POWERSHELL
function Generate-PowerShellActivity {
    Write-Activity "Gerando atividade de PowerShell..." "Yellow"
    
    # Comando básico
    Write-Activity "  Executando comandos PowerShell..."
    Get-Process | Select-Object -First 5 | Out-Null
    Get-Service | Select-Object -First 5 | Out-Null
    
    # Comando com pipeline
    Write-Activity "  Executando pipeline complexo..."
    Get-ChildItem C:\Windows | Where-Object {$_.PSIsContainer} | Select-Object -First 5 | Out-Null
    
    # Codificação base64 (para teste de detecção)
    Write-Activity "  Testando comando codificado..."
    $command = "Write-Host 'Teste de comando codificado'"
    $bytes = [System.Text.Encoding]::Unicode.GetBytes($command)
    $encodedCommand = [Convert]::ToBase64String($bytes)
    
    # Executar comando codificado (para gerar alerta)
    Write-Activity "  Executando comando codificado (deve gerar alerta)..."
    Start-Process powershell -ArgumentList "-NoProfile", "-EncodedCommand", $encodedCommand -WindowStyle Hidden -Wait
    
    # Invoke-Expression (suspeito)
    Write-Activity "  Testando Invoke-Expression..."
    $expr = "Get-Date"
    Invoke-Expression $expr | Out-Null
    
    # Script block
    Write-Activity "  Executando script block..."
    $scriptBlock = { Get-ComputerInfo | Select-Object CsName, OsName }
    Invoke-Command -ScriptBlock $scriptBlock | Out-Null
    
    Write-Activity "✓ Atividade de PowerShell concluída" "Green"
}

# EXECUTAR ATIVIDADES
Write-Host "Tipo de atividade selecionado: $ActivityType" -ForegroundColor Cyan
Write-Host ""

$startTime = Get-Date

switch ($ActivityType) {
    "All" {
        Generate-ProcessActivity
        Start-Sleep -Seconds 2
        Generate-FileActivity
        Start-Sleep -Seconds 2
        Generate-RegistryActivity
        Start-Sleep -Seconds 2
        Generate-NetworkActivity
        Start-Sleep -Seconds 2
        Generate-PowerShellActivity
    }
    "Process" { Generate-ProcessActivity }
    "File" { Generate-FileActivity }
    "Registry" { Generate-RegistryActivity }
    "Network" { Generate-NetworkActivity }
    "PowerShell" { Generate-PowerShellActivity }
}

$endTime = Get-Date
$duration = $endTime - $startTime

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Geração de Atividade Concluída!      " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Resumo:" -ForegroundColor Yellow
Write-Host "  Tipo:     $ActivityType"
Write-Host "  Início:   $($startTime.ToString('HH:mm:ss'))"
Write-Host "  Fim:      $($endTime.ToString('HH:mm:ss'))"
Write-Host "  Duração:  $($duration.TotalSeconds.ToString('0.00')) segundos"
Write-Host ""
Write-Host "Próximos passos:" -ForegroundColor Yellow
Write-Host "  1. Verificar eventos no Event Viewer"
Write-Host "  2. Verificar logs do Sysmon:"
Write-Host "     Get-WinEvent -LogName 'Microsoft-Windows-Sysmon/Operational' -MaxEvents 20"
Write-Host "  3. Verificar alertas no Wazuh Dashboard:"
Write-Host "     https://192.168.1.102"
Write-Host "  4. Buscar eventos no Splunk:"
Write-Host "     index=sysmon | head 50"
Write-Host ""
Write-Host "Eventos esperados:" -ForegroundColor Cyan
Write-Host "  • Sysmon Event ID 1 (Process Creation)"
Write-Host "  • Sysmon Event ID 3 (Network Connection)"
Write-Host "  • Sysmon Event ID 11 (File Created)"
Write-Host "  • Sysmon Event ID 13 (Registry Value Set)"
Write-Host "  • Windows Security Event ID 4688 (Process Creation)"
Write-Host ""

# Oferecer visualização de logs
$viewLogs = Read-Host "Deseja ver os últimos eventos do Sysmon? (S/N)"
if ($viewLogs -eq "S" -or $viewLogs -eq "s") {
    Write-Host ""
    Write-Host "Últimos 10 eventos do Sysmon:" -ForegroundColor Yellow
    Write-Host ""
    
    Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -MaxEvents 10 |
        Select-Object TimeCreated, Id, Message |
        Format-Table -Wrap
}
