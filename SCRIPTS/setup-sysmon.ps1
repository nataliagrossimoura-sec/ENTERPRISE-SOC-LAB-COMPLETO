<#
.SYNOPSIS
    Script automatizado para instalação e configuração do Sysmon
    
.DESCRIPTION
    Este script baixa e instala o Sysmon com configuração reforçada
    do repositório SwiftOnSecurity/sysmon-config
    
.NOTES
    Autor: Natália Grossi
    Projeto: Enterprise SOC Lab
    Requer: PowerShell 5.1+, Execução como Administrador
#>

# Verificar se está rodando como Administrador
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "Este script precisa ser executado como Administrador!"
    Write-Host "Clique com botão direito no PowerShell e selecione 'Executar como Administrador'" -ForegroundColor Yellow
    Exit 1
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Instalação Automatizada do Sysmon    " -ForegroundColor Cyan
Write-Host "  Enterprise SOC Lab                   " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configurações
$sysmonDir = "C:\Sysmon"
$sysmonUrl = "https://live.sysinternals.com/Sysmon64.exe"
$configUrl = "https://raw.githubusercontent.com/SwiftOnSecurity/sysmon-config/master/sysmonconfig-export.xml"
$sysmonExe = "$sysmonDir\Sysmon64.exe"
$configFile = "$sysmonDir\sysmonconfig.xml"

# Criar diretório
Write-Host "[1/5] Criando diretório Sysmon..." -ForegroundColor Green
if (-not (Test-Path $sysmonDir)) {
    New-Item -ItemType Directory -Path $sysmonDir -Force | Out-Null
    Write-Host "      Diretório criado: $sysmonDir" -ForegroundColor Gray
} else {
    Write-Host "      Diretório já existe" -ForegroundColor Gray
}

# Baixar Sysmon
Write-Host ""
Write-Host "[2/5] Baixando Sysmon64.exe..." -ForegroundColor Green
try {
    # Desabilitar barra de progresso para velocidade
    $ProgressPreference = 'SilentlyContinue'
    
    Invoke-WebRequest -Uri $sysmonUrl -OutFile $sysmonExe -UseBasicParsing
    Write-Host "      Download concluído: Sysmon64.exe" -ForegroundColor Gray
    
    # Verificar integridade
    $fileHash = Get-FileHash $sysmonExe -Algorithm SHA256
    Write-Host "      SHA256: $($fileHash.Hash)" -ForegroundColor Gray
} catch {
    Write-Error "Falha ao baixar Sysmon: $_"
    Exit 1
}

# Baixar configuração
Write-Host ""
Write-Host "[3/5] Baixando configuração do Sysmon..." -ForegroundColor Green
try {
    Invoke-WebRequest -Uri $configUrl -OutFile $configFile -UseBasicParsing
    Write-Host "      Download concluído: sysmonconfig.xml" -ForegroundColor Gray
    
    # Mostrar estatísticas do config
    $configContent = Get-Content $configFile
    $ruleCount = ($configContent | Select-String -Pattern "<Rule " -AllMatches).Matches.Count
    Write-Host "      Regras configuradas: $ruleCount" -ForegroundColor Gray
} catch {
    Write-Error "Falha ao baixar configuração: $_"
    Exit 1
}

# Verificar se Sysmon já está instalado
Write-Host ""
Write-Host "[4/5] Verificando instalação existente..." -ForegroundColor Green
$sysmonService = Get-Service -Name "Sysmon64" -ErrorAction SilentlyContinue

if ($sysmonService) {
    Write-Host "      Sysmon já está instalado" -ForegroundColor Yellow
    Write-Host "      Atualizando configuração..." -ForegroundColor Yellow
    
    # Atualizar configuração
    & $sysmonExe -c $configFile
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "      Configuração atualizada com sucesso!" -ForegroundColor Green
    } else {
        Write-Error "Falha ao atualizar configuração"
        Exit 1
    }
} else {
    # Instalar Sysmon
    Write-Host "      Instalando Sysmon..." -ForegroundColor Green
    
    try {
        & $sysmonExe -accepteula -i $configFile
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "      Sysmon instalado com sucesso!" -ForegroundColor Green
        } else {
            Write-Error "Falha na instalação do Sysmon"
            Exit 1
        }
    } catch {
        Write-Error "Erro ao executar instalador: $_"
        Exit 1
    }
}

# Verificar instalação
Write-Host ""
Write-Host "[5/5] Verificando instalação..." -ForegroundColor Green

# Verificar serviço
$service = Get-Service -Name "Sysmon64" -ErrorAction SilentlyContinue
if ($service -and $service.Status -eq "Running") {
    Write-Host "      ✓ Serviço Sysmon64 está rodando" -ForegroundColor Green
} else {
    Write-Warning "      ! Serviço Sysmon64 não está rodando"
}

# Verificar driver
$driver = Get-WmiObject Win32_SystemDriver | Where-Object { $_.Name -eq "SysmonDrv" }
if ($driver) {
    Write-Host "      ✓ Driver SysmonDrv carregado" -ForegroundColor Green
} else {
    Write-Warning "      ! Driver SysmonDrv não encontrado"
}

# Verificar Event Log
try {
    $recentEvents = Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -MaxEvents 5 -ErrorAction Stop
    Write-Host "      ✓ Event Log funcional ($($recentEvents.Count) eventos recentes)" -ForegroundColor Green
} catch {
    Write-Warning "      ! Nenhum evento Sysmon encontrado ainda (normal em instalação nova)"
}

# Estatísticas finais
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Instalação Concluída!                " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Informações do Sysmon:" -ForegroundColor Yellow
Write-Host "  Versão: " -NoNewline
& $sysmonExe -v
Write-Host "  Diretório: $sysmonDir"
Write-Host "  Config: $configFile"
Write-Host "  Event Log: Microsoft-Windows-Sysmon/Operational"
Write-Host ""
Write-Host "Comandos úteis:" -ForegroundColor Yellow
Write-Host "  Ver status:       Get-Service Sysmon64"
Write-Host "  Ver logs:         Get-WinEvent -LogName 'Microsoft-Windows-Sysmon/Operational' -MaxEvents 20"
Write-Host "  Atualizar config: Sysmon64.exe -c sysmonconfig.xml"
Write-Host "  Desinstalar:      Sysmon64.exe -u"
Write-Host ""

# Habilitar auditoria avançada
Write-Host "Configurando auditoria avançada..." -ForegroundColor Green
try {
    auditpol /set /subcategory:"Process Creation" /success:enable /failure:enable | Out-Null
    auditpol /set /subcategory:"Logon" /success:enable /failure:enable | Out-Null
    auditpol /set /subcategory:"Logoff" /success:enable /failure:enable | Out-Null
    auditpol /set /subcategory:"Account Logon" /success:enable /failure:enable | Out-Null
    Write-Host "  ✓ Auditoria configurada" -ForegroundColor Green
} catch {
    Write-Warning "  ! Falha ao configurar auditoria: $_"
}

Write-Host ""
Write-Host "Para ver eventos em tempo real:" -ForegroundColor Cyan
Write-Host '  Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -MaxEvents 10 | Format-Table TimeCreated, Id, Message -Wrap' -ForegroundColor Gray
Write-Host ""
Write-Host "Instalação finalizada!" -ForegroundColor Green
Write-Host ""
