<#
.SYNOPSIS
    Script de verificação completa do Enterprise SOC Lab
    
.DESCRIPTION
    Verifica status de todos os componentes do laboratório:
    - Conectividade de rede
    - Serviços rodando
    - Logs sendo gerados
    - Agentes conectados
    
.NOTES
    Autor: Natália Grossi
    Projeto: Enterprise SOC Lab
#>

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Verificação do SOC Lab                " -ForegroundColor Cyan
Write-Host "  Enterprise SOC Lab                   " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$results = @{
    Network = @()
    Services = @()
    Logs = @()
    Issues = @()
}

# Função para check OK/FAIL
function Write-Check {
    param(
        [string]$Item,
        [bool]$Status,
        [string]$Details = ""
    )
    
    $symbol = if ($Status) { "✓" } else { "✗" }
    $color = if ($Status) { "Green" } else { "Red" }
    
    Write-Host "  $symbol $Item" -ForegroundColor $color
    if ($Details) {
        Write-Host "    $Details" -ForegroundColor Gray
    }
    
    return $Status
}

# 1. VERIFICAÇÃO DE REDE
Write-Host "[1/4] Verificando Conectividade de Rede..." -ForegroundColor Yellow
Write-Host ""

# Gateway (pfSense)
$gateway = Test-NetConnection -ComputerName 192.168.1.1 -WarningAction SilentlyContinue
$results.Network += Write-Check "Gateway (pfSense)" $gateway.PingSucceeded "192.168.1.1"

# Wazuh Manager
$wazuh = Test-NetConnection -ComputerName 192.168.1.102 -Port 1514 -WarningAction SilentlyContinue
$results.Network += Write-Check "Wazuh Manager" $wazuh.TcpTestSucceeded "192.168.1.102:1514"

# Splunk (se em outro servidor)
$splunkLocal = Test-NetConnection -ComputerName localhost -Port 8000 -WarningAction SilentlyContinue
if ($splunkLocal.TcpTestSucceeded) {
    $results.Network += Write-Check "Splunk Local" $true "localhost:8000"
}

# Internet
$internet = Test-NetConnection -ComputerName 8.8.8.8 -WarningAction SilentlyContinue
$results.Network += Write-Check "Internet" $internet.PingSucceeded "8.8.8.8"

# DNS
try {
    $dns = Resolve-DnsName google.com -ErrorAction Stop
    $results.Network += Write-Check "DNS Resolution" $true "google.com → $($dns[0].IPAddress)"
} catch {
    $results.Network += Write-Check "DNS Resolution" $false
    $results.Issues += "DNS não está funcionando"
}

# 2. VERIFICAÇÃO DE SERVIÇOS
Write-Host ""
Write-Host "[2/4] Verificando Serviços..." -ForegroundColor Yellow
Write-Host ""

# Sysmon
$sysmon = Get-Service -Name "Sysmon64" -ErrorAction SilentlyContinue
if ($sysmon) {
    $running = $sysmon.Status -eq "Running"
    $results.Services += Write-Check "Sysmon64" $running "Status: $($sysmon.Status)"
    if (-not $running) {
        $results.Issues += "Sysmon64 não está rodando"
    }
} else {
    $results.Services += Write-Check "Sysmon64" $false "Serviço não encontrado"
    $results.Issues += "Sysmon64 não está instalado"
}

# Wazuh Agent
$wazuhAgent = Get-Service -Name "wazuh" -ErrorAction SilentlyContinue
if ($wazuhAgent) {
    $running = $wazuhAgent.Status -eq "Running"
    $results.Services += Write-Check "Wazuh Agent" $running "Status: $($wazuhAgent.Status)"
    if (-not $running) {
        $results.Issues += "Wazuh Agent não está rodando"
    }
} else {
    $results.Services += Write-Check "Wazuh Agent" $false "Serviço não encontrado"
    $results.Issues += "Wazuh Agent não está instalado"
}

# Splunk
$splunk = Get-Service -Name "Splunkd" -ErrorAction SilentlyContinue
if ($splunk) {
    $running = $splunk.Status -eq "Running"
    $results.Services += Write-Check "Splunk Enterprise" $running "Status: $($splunk.Status)"
    if (-not $running) {
        $results.Issues += "Splunk não está rodando"
    }
} else {
    # Tentar SplunkForwarder
    $splunkFwd = Get-Service -Name "SplunkForwarder" -ErrorAction SilentlyContinue
    if ($splunkFwd) {
        $running = $splunkFwd.Status -eq "Running"
        $results.Services += Write-Check "Splunk Forwarder" $running "Status: $($splunkFwd.Status)"
    } else {
        $results.Services += Write-Check "Splunk" $false "Nenhum serviço Splunk encontrado"
    }
}

# Windows Event Log
$eventLog = Get-Service -Name "EventLog" -ErrorAction SilentlyContinue
if ($eventLog) {
    $running = $eventLog.Status -eq "Running"
    $results.Services += Write-Check "Windows Event Log" $running "Status: $($eventLog.Status)"
}

# 3. VERIFICAÇÃO DE LOGS
Write-Host ""
Write-Host "[3/4] Verificando Geração de Logs..." -ForegroundColor Yellow
Write-Host ""

# Security Log
try {
    $securityEvents = Get-EventLog -LogName Security -Newest 1 -ErrorAction Stop
    $lastEvent = $securityEvents.TimeGenerated
    $minutesAgo = ((Get-Date) - $lastEvent).TotalMinutes
    
    if ($minutesAgo -lt 10) {
        $results.Logs += Write-Check "Security Event Log" $true "Último evento: $($minutesAgo.ToString('0')) min atrás"
    } else {
        $results.Logs += Write-Check "Security Event Log" $false "Último evento: $($minutesAgo.ToString('0')) min atrás"
        $results.Issues += "Security logs não estão sendo gerados recentemente"
    }
} catch {
    $results.Logs += Write-Check "Security Event Log" $false "Erro ao acessar logs"
    $results.Issues += "Não foi possível acessar Security Event Log"
}

# Sysmon Log
try {
    $sysmonEvents = Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -MaxEvents 1 -ErrorAction Stop
    $lastEvent = $sysmonEvents.TimeCreated
    $minutesAgo = ((Get-Date) - $lastEvent).TotalMinutes
    
    if ($minutesAgo -lt 10) {
        $results.Logs += Write-Check "Sysmon Operational" $true "Último evento: $($minutesAgo.ToString('0')) min atrás"
    } else {
        $results.Logs += Write-Check "Sysmon Operational" $false "Último evento: $($minutesAgo.ToString('0')) min atrás"
        $results.Issues += "Sysmon não está gerando eventos recentemente"
    }
} catch {
    $results.Logs += Write-Check "Sysmon Operational" $false "Erro ao acessar logs"
    $results.Issues += "Não foi possível acessar Sysmon logs"
}

# Wazuh Agent Log
$wazuhLogPath = "C:\Program Files (x86)\ossec-agent\ossec.log"
if (Test-Path $wazuhLogPath) {
    $logFile = Get-Item $wazuhLogPath
    $minutesAgo = ((Get-Date) - $logFile.LastWriteTime).TotalMinutes
    
    if ($minutesAgo -lt 10) {
        $results.Logs += Write-Check "Wazuh Agent Log" $true "Atualizado: $($minutesAgo.ToString('0')) min atrás"
        
        # Verificar se está conectado
        $logContent = Get-Content $wazuhLogPath -Tail 100
        if ($logContent -match "Connected to the server") {
            Write-Host "    ✓ Agente conectado ao Manager" -ForegroundColor Green
        } else {
            Write-Host "    ! Verificar conexão com Manager" -ForegroundColor Yellow
            $results.Issues += "Wazuh Agent pode não estar conectado ao Manager"
        }
    } else {
        $results.Logs += Write-Check "Wazuh Agent Log" $false "Não atualizado recentemente"
        $results.Issues += "Wazuh Agent não está enviando dados"
    }
} else {
    $results.Logs += Write-Check "Wazuh Agent Log" $false "Arquivo de log não encontrado"
}

# 4. INFORMAÇÕES DO SISTEMA
Write-Host ""
Write-Host "[4/4] Informações do Sistema..." -ForegroundColor Yellow
Write-Host ""

$computerInfo = Get-ComputerInfo | Select-Object CsName, OsName, OsVersion, OsArchitecture

Write-Host "  Hostname:        $($computerInfo.CsName)"
Write-Host "  SO:              $($computerInfo.OsName)"
Write-Host "  Versão:          $($computerInfo.OsVersion)"
Write-Host "  Arquitetura:     $($computerInfo.OsArchitecture)"

$networkInfo = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -ne "127.0.0.1" } | Select-Object -First 1
if ($networkInfo) {
    Write-Host "  IP:              $($networkInfo.IPAddress)"
    Write-Host "  Interface:       $($networkInfo.InterfaceAlias)"
}

# RESUMO FINAL
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Resumo da Verificação                " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$totalChecks = $results.Network.Count + $results.Services.Count + $results.Logs.Count
$passedChecks = ($results.Network + $results.Services + $results.Logs | Where-Object {$_ -eq $true}).Count
$percentage = [math]::Round(($passedChecks / $totalChecks) * 100, 0)

Write-Host "Status Geral: " -NoNewline
if ($percentage -ge 80) {
    Write-Host "✓ EXCELENTE" -ForegroundColor Green
} elseif ($percentage -ge 60) {
    Write-Host "⚠ BOM (com ressalvas)" -ForegroundColor Yellow
} else {
    Write-Host "✗ PRECISA DE ATENÇÃO" -ForegroundColor Red
}

Write-Host ""
Write-Host "Estatísticas:"
Write-Host "  Total de verificações:  $totalChecks"
Write-Host "  Verificações OK:        $passedChecks"
Write-Host "  Verificações FAIL:      $($totalChecks - $passedChecks)"
Write-Host "  Taxa de sucesso:        $percentage%"
Write-Host ""

# Mostrar problemas encontrados
if ($results.Issues.Count -gt 0) {
    Write-Host "⚠ Problemas Encontrados:" -ForegroundColor Yellow
    $results.Issues | ForEach-Object {
        Write-Host "  • $_" -ForegroundColor Yellow
    }
    Write-Host ""
}

# Recomendações
Write-Host "Próximas ações:" -ForegroundColor Cyan

if ($results.Issues.Count -eq 0) {
    Write-Host "  ✓ Lab está completamente funcional!" -ForegroundColor Green
    Write-Host "  ✓ Pronto para exercícios e testes" -ForegroundColor Green
    Write-Host ""
    Write-Host "Sugestões:"
    Write-Host "  1. Gerar atividade de teste: .\generate-activity.ps1"
    Write-Host "  2. Verificar eventos no Wazuh Dashboard: https://192.168.1.102"
    Write-Host "  3. Analisar logs no Splunk: http://localhost:8000"
} else {
    Write-Host "  1. Corrigir os problemas listados acima"
    Write-Host "  2. Executar este script novamente após correções"
    Write-Host "  3. Consultar TROUBLESHOOTING.md se necessário"
}

Write-Host ""
Write-Host "Verificação concluída em $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Gray
Write-Host ""
