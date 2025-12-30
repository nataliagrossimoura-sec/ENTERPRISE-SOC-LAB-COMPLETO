<#
.SYNOPSIS
    Script automatizado para instalação do Wazuh Agent no Windows
    
.DESCRIPTION
    Baixa e instala o Wazuh Agent configurando automaticamente
    a conexão com o Wazuh Manager
    
.PARAMETER ManagerIP
    Endereço IP do Wazuh Manager (padrão: 192.168.1.102)
    
.PARAMETER AgentName
    Nome do agente (padrão: hostname do computador)
    
.NOTES
    Autor: Natália Grossi
    Projeto: Enterprise SOC Lab
    Requer: PowerShell 5.1+, Execução como Administrador
    
.EXAMPLE
    .\setup-wazuh-agent.ps1
    .\setup-wazuh-agent.ps1 -ManagerIP "192.168.1.102" -AgentName "DC01"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$ManagerIP = "192.168.1.102",
    
    [Parameter(Mandatory=$false)]
    [string]$AgentName = $env:COMPUTERNAME
)

# Verificar se está rodando como Administrador
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "Este script precisa ser executado como Administrador!"
    Write-Host "Clique com botão direito no PowerShell e selecione 'Executar como Administrador'" -ForegroundColor Yellow
    Exit 1
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Instalação do Wazuh Agent            " -ForegroundColor Cyan
Write-Host "  Enterprise SOC Lab                   " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configurações
$wazuhVersion = "4.8.0"
$wazuhUrl = "https://packages.wazuh.com/4.x/windows/wazuh-agent-$wazuhVersion-1.msi"
$installerPath = "$env:TEMP\wazuh-agent.msi"
$installDir = "C:\Program Files (x86)\ossec-agent"

Write-Host "Configurações:" -ForegroundColor Yellow
Write-Host "  Manager IP:  $ManagerIP"
Write-Host "  Agent Name:  $AgentName"
Write-Host "  Version:     $wazuhVersion"
Write-Host ""

# Verificar se já está instalado
Write-Host "[1/6] Verificando instalação existente..." -ForegroundColor Green
$service = Get-Service -Name "wazuh" -ErrorAction SilentlyContinue

if ($service) {
    Write-Host "      Wazuh Agent já está instalado!" -ForegroundColor Yellow
    $response = Read-Host "      Deseja reinstalar? (S/N)"
    
    if ($response -ne "S" -and $response -ne "s") {
        Write-Host "      Instalação cancelada." -ForegroundColor Yellow
        Exit 0
    }
    
    # Desinstalar versão existente
    Write-Host "      Desinstalando versão existente..." -ForegroundColor Yellow
    Stop-Service -Name "wazuh" -ErrorAction SilentlyContinue
    
    $product = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "*Wazuh*" }
    if ($product) {
        $product.Uninstall() | Out-Null
        Start-Sleep -Seconds 5
    }
}

# Verificar conectividade
Write-Host ""
Write-Host "[2/6] Verificando conectividade..." -ForegroundColor Green

# Internet
try {
    $null = Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet
    Write-Host "      ✓ Conexão com internet OK" -ForegroundColor Gray
} catch {
    Write-Warning "      ! Sem conexão com internet"
}

# Manager
try {
    $result = Test-NetConnection -ComputerName $ManagerIP -Port 1514 -WarningAction SilentlyContinue
    if ($result.TcpTestSucceeded) {
        Write-Host "      ✓ Manager acessível ($ManagerIP:1514)" -ForegroundColor Gray
    } else {
        Write-Host "      ! Manager não acessível no momento" -ForegroundColor Yellow
        Write-Host "      Continuando instalação..." -ForegroundColor Yellow
    }
} catch {
    Write-Host "      ! Não foi possível testar conexão com Manager" -ForegroundColor Yellow
}

# Baixar instalador
Write-Host ""
Write-Host "[3/6] Baixando Wazuh Agent..." -ForegroundColor Green
Write-Host "      URL: $wazuhUrl" -ForegroundColor Gray

try {
    # Desabilitar barra de progresso para velocidade
    $ProgressPreference = 'SilentlyContinue'
    
    Invoke-WebRequest -Uri $wazuhUrl -OutFile $installerPath -UseBasicParsing
    
    # Verificar download
    if (Test-Path $installerPath) {
        $fileSize = (Get-Item $installerPath).Length / 1MB
        Write-Host "      ✓ Download concluído ($($fileSize.ToString('0.00')) MB)" -ForegroundColor Gray
    } else {
        throw "Arquivo não foi baixado"
    }
} catch {
    Write-Error "Falha ao baixar instalador: $_"
    Exit 1
}

# Instalar Wazuh Agent
Write-Host ""
Write-Host "[4/6] Instalando Wazuh Agent..." -ForegroundColor Green
Write-Host "      Aguarde, isso pode levar 1-2 minutos..." -ForegroundColor Gray

try {
    $msiArgs = @(
        "/i"
        $installerPath
        "/q"
        "/norestart"
        "WAZUH_MANAGER=`"$ManagerIP`""
        "WAZUH_AGENT_NAME=`"$AgentName`""
        "WAZUH_REGISTRATION_SERVER=`"$ManagerIP`""
    )
    
    $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $msiArgs -Wait -PassThru
    
    if ($process.ExitCode -eq 0) {
        Write-Host "      ✓ Instalação concluída" -ForegroundColor Gray
    } else {
        throw "MSI retornou código de erro: $($process.ExitCode)"
    }
} catch {
    Write-Error "Falha na instalação: $_"
    Exit 1
}

# Aguardar serviço estar disponível
Start-Sleep -Seconds 5

# Verificar serviço
Write-Host ""
Write-Host "[5/6] Verificando instalação..." -ForegroundColor Green

$service = Get-Service -Name "wazuh" -ErrorAction SilentlyContinue

if ($service) {
    Write-Host "      ✓ Serviço Wazuh criado" -ForegroundColor Gray
    
    # Iniciar serviço se não estiver rodando
    if ($service.Status -ne "Running") {
        Write-Host "      Iniciando serviço..." -ForegroundColor Gray
        Start-Service -Name "wazuh"
        Start-Sleep -Seconds 3
        
        $service = Get-Service -Name "wazuh"
    }
    
    if ($service.Status -eq "Running") {
        Write-Host "      ✓ Serviço está rodando" -ForegroundColor Green
    } else {
        Write-Warning "      ! Serviço não está rodando"
        Write-Host "      Tente: Start-Service -Name wazuh" -ForegroundColor Yellow
    }
} else {
    Write-Error "      ✗ Serviço Wazuh não encontrado"
    Exit 1
}

# Verificar arquivos instalados
if (Test-Path $installDir) {
    Write-Host "      ✓ Arquivos instalados em: $installDir" -ForegroundColor Gray
} else {
    Write-Warning "      ! Diretório de instalação não encontrado"
}

# Configurar firewall
Write-Host ""
Write-Host "[6/6] Configurando firewall..." -ForegroundColor Green

try {
    # Permitir comunicação com Manager
    New-NetFirewallRule -DisplayName "Wazuh Agent" `
        -Direction Outbound `
        -Action Allow `
        -Protocol TCP `
        -RemotePort 1514,1515 `
        -ErrorAction SilentlyContinue | Out-Null
    
    Write-Host "      ✓ Regra de firewall criada" -ForegroundColor Gray
} catch {
    Write-Host "      ! Não foi possível criar regra de firewall" -ForegroundColor Yellow
}

# Limpar arquivo temporário
if (Test-Path $installerPath) {
    Remove-Item $installerPath -Force
}

# Informações finais
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Instalação Concluída!                " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Informações do Agente:" -ForegroundColor Yellow
Write-Host "  Manager:      $ManagerIP"
Write-Host "  Agent Name:   $AgentName"
Write-Host "  Install Dir:  $installDir"
Write-Host "  Config File:  $installDir\ossec.conf"
Write-Host "  Log File:     $installDir\ossec.log"
Write-Host ""
Write-Host "Comandos úteis:" -ForegroundColor Yellow
Write-Host "  Ver status:    Get-Service -Name wazuh"
Write-Host "  Ver logs:      Get-Content `"$installDir\ossec.log`" -Tail 50 -Wait"
Write-Host "  Reiniciar:     Restart-Service -Name wazuh"
Write-Host "  Parar:         Stop-Service -Name wazuh"
Write-Host ""

# Verificar logs de conexão
Write-Host "Verificando conexão com Manager..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

$logFile = "$installDir\ossec.log"
if (Test-Path $logFile) {
    $recentLogs = Get-Content $logFile -Tail 20
    
    if ($recentLogs -match "Connected to the server") {
        Write-Host "✓ Agente conectado ao Manager!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Acesse o Wazuh Dashboard em https://$ManagerIP" -ForegroundColor Green
        Write-Host "para verificar o agente na lista." -ForegroundColor Green
    } else {
        Write-Host "! Agente ainda conectando..." -ForegroundColor Yellow
        Write-Host "Aguarde 1-2 minutos e verifique os logs:" -ForegroundColor Yellow
        Write-Host "  Get-Content `"$logFile`" -Tail 20" -ForegroundColor Cyan
    }
} else {
    Write-Host "! Arquivo de log não encontrado ainda" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Instalação finalizada!" -ForegroundColor Green
Write-Host ""

# Opcional: Abrir log em tempo real
$openLog = Read-Host "Deseja abrir o log em tempo real? (S/N)"
if ($openLog -eq "S" -or $openLog -eq "s") {
    Get-Content "$installDir\ossec.log" -Tail 20 -Wait
}
