# 🖥️ Preparação do Ambiente Host - Enterprise SOC Lab

Preparação completa do computador físico antes de instalar as VMs.

---

## Passo 1: Atualizar Sistema Operacional

### Windows Update

```powershell
# Abrir PowerShell como Administrador (Win + X → PowerShell Admin)

# Verificar atualizações disponíveis
Get-WindowsUpdate

# Instalar todas atualizações (se módulo PSWindowsUpdate instalado)
Install-WindowsUpdate -AcceptAll

# OU usar interface gráfica:
# Settings → Update & Security → Check for updates
```

**Manual:**
1. Win + I (Configurações)
2. Update & Security
3. Check for updates
4. Install all
5. **Reiniciar se necessário**

---

## Passo 2: Criar Estrutura de Diretórios

### Via PowerShell (Recomendado)

```powershell
# Criar pasta principal
New-Item -Path "C:\SOC-Lab" -ItemType Directory -Force

# Criar subpastas
$folders = @(
    "VMs",
    "ISOs",
    "Snapshots",
    "Configs",
    "Scripts",
    "Logs",
    "Documentacao",
    "GitHub"
)

foreach ($folder in $folders) {
    New-Item -Path "C:\SOC-Lab\$folder" -ItemType Directory -Force
}

# Verificar estrutura criada
Get-ChildItem C:\SOC-Lab
```

### Via Explorer (Alternativa)

1. Abrir Explorer (Win + E)
2. Navegar para C:\
3. Criar pasta: `SOC-Lab`
4. Dentro de SOC-Lab, criar:
   - VMs
   - ISOs
   - Snapshots
   - Configs
   - Scripts
   - Logs
   - Documentacao
   - GitHub

### Estrutura Final

```
C:\SOC-Lab\
├── VMs\                # Arquivos das VMs
├── ISOs\               # Arquivos ISO
├── Snapshots\          # Backups das VMs
├── Configs\            # Arquivos de configuração
├── Scripts\            # Scripts PowerShell e Bash
├── Logs\               # Amostras de logs
├── Documentacao\       # Documentos e notas
└── GitHub\             # Clone do repositório
```

---

## Passo 3: Mover ISOs para Pasta Correta

```powershell
# Se baixou ISOs na pasta Downloads, mover para C:\SOC-Lab\ISOs\

# Exemplo:
Move-Item "$env:USERPROFILE\Downloads\pfSense-*.iso" "C:\SOC-Lab\ISOs\"
Move-Item "$env:USERPROFILE\Downloads\SERVER_EVAL*.iso" "C:\SOC-Lab\ISOs\"
Move-Item "$env:USERPROFILE\Downloads\ubuntu-*.iso" "C:\SOC-Lab\ISOs\"
Move-Item "$env:USERPROFILE\Downloads\kali-*.iso" "C:\SOC-Lab\ISOs\"

# Verificar
Get-ChildItem "C:\SOC-Lab\ISOs\"
```

---

## Passo 4: Instalar VirtualBox

### Download

1. Acessar: https://www.virtualbox.org/wiki/Downloads
2. Clicar em: **Windows hosts**
3. Salvar arquivo: `VirtualBox-7.x.x-xxxxxx-Win.exe`

### Instalação

```powershell
# Via PowerShell (se instalador na pasta Downloads)
cd $env:USERPROFILE\Downloads
.\VirtualBox-*.exe
```

**OU usar interface gráfica:**

1. Executar instalador baixado
2. Next → Next → Install
3. **Importante:** Aceitar instalação de drivers de rede quando solicitado
4. Finish

### Verificar Instalação

```powershell
# Verificar se VBoxManage está disponível
& "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" --version
```

Deve exibir: `7.x.x rxxxxxx`

---

## Passo 5: Instalar VirtualBox Extension Pack

**Essencial para:**
- USB 2.0/3.0 support
- Remote Desktop Protocol (RDP)
- Host webcam passthrough
- Disk encryption

### Download

1. Mesma página: https://www.virtualbox.org/wiki/Downloads
2. Clicar em: **All supported platforms** (Extension Pack)
3. Baixar: `Oracle_VM_VirtualBox_Extension_Pack-7.x.x.vbox-extpack`

### Instalação

**Método 1 - Duplo clique:**
1. Duplo-clique no arquivo `.vbox-extpack`
2. VirtualBox abrirá automaticamente
3. Install → Aceitar termos → OK

**Método 2 - Via VirtualBox:**
1. Abrir VirtualBox
2. File → Preferences (ou Ctrl+G)
3. Extensions
4. Clicar no ícone **+** (Add)
5. Selecionar arquivo `.vbox-extpack`
6. Install → Aceitar termos

### Verificar

1. VirtualBox → File → Preferences → Extensions
2. Deve aparecer: **Oracle VM VirtualBox Extension Pack**
3. Status: Active

---

## Passo 6: Configurar VirtualBox

### 1. Pasta Padrão de VMs

```
VirtualBox → File → Preferences → General
Default Machine Folder: C:\SOC-Lab\VMs
```

### 2. Configurações de Rede

**Host-Only Network (Opcional - para uso futuro):**

1. File → Tools → Network Manager
2. Aba: **Host-only Networks**
3. Criar (se não existir): VirtualBox Host-Only Ethernet Adapter
4. Configurar:
   - IPv4 Address: 192.168.56.1
   - IPv4 Network Mask: 255.255.255.0
   - DHCP Server: Disabled

**Internal Network:**
- Será configurado individualmente em cada VM
- Nome: **LAN_SOC**

### 3. Configurações Gerais

```
File → Preferences → General
Default Machine Folder: C:\SOC-Lab\VMs

File → Preferences → Input
Virtual Machine:
  - Host Key Combination: Right Ctrl (padrão)

File → Preferences → Display
Maximum Guest Screen Size: Hint
  - Width: 1920
  - Height: 1080
```

---

## Passo 7: Otimizar Windows para Virtualização

### Desabilitar Serviços Desnecessários

```powershell
# Desabilitar Windows Search (opcional - melhora performance)
Stop-Service -Name "WSearch" -Force
Set-Service -Name "WSearch" -StartupType Disabled

# Desabilitar Superfetch (opcional)
Stop-Service -Name "SysMain" -Force
Set-Service -Name "SysMain" -StartupType Disabled
```

**Atenção:** Só faça isso se tiver certeza. Pode impactar funcionalidades do Windows.

### Configurar Plano de Energia

1. Control Panel → Power Options
2. Selecionar: **High Performance**
3. Change plan settings
4. Put the computer to sleep: **Never**
5. Turn off the display: 30 minutes (ou Never)

### Desabilitar Hibernação (Libera espaço)

```powershell
# Desabilitar hibernação (libera ~16GB se 16GB RAM)
powercfg -h off
```

---

## Passo 8: Verificar Virtualização Habilitada na BIOS

### Verificar se está Habilitado

```powershell
# Verificar suporte a virtualização
Get-ComputerInfo | Select-Object CsProcessors, HyperVisorPresent, HyperVRequirementVirtualizationFirmwareEnabled

# Se retornar "True" em VirtualizationFirmwareEnabled, está OK
```

**OU usar Task Manager:**
1. Ctrl + Shift + Esc (Task Manager)
2. Aba: Performance
3. CPU
4. Verificar: **Virtualization: Enabled**

### Se Estiver Desabilitado

**Precisa habilitar na BIOS:**

1. Reiniciar PC
2. Pressionar F2, F10, Delete ou Esc (depende do fabricante) para entrar na BIOS
3. Procurar por:
   - **Intel:** Intel VT-x ou Virtualization Technology
   - **AMD:** AMD-V ou SVM Mode
4. Enable
5. Save & Exit

**Fabricantes comuns:**
- Dell: F2
- HP: F10 ou Esc
- Lenovo: F1 ou F2
- ASUS: Delete ou F2

---

## Passo 9: Configurar Firewall do Windows

### Permitir VirtualBox

```powershell
# Criar regra para VirtualBox
New-NetFirewallRule -DisplayName "VirtualBox" `
    -Direction Inbound `
    -Program "C:\Program Files\Oracle\VirtualBox\VirtualBox.exe" `
    -Action Allow

New-NetFirewallRule -DisplayName "VirtualBox Manager" `
    -Direction Inbound `
    -Program "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" `
    -Action Allow
```

**OU via interface:**
1. Control Panel → Windows Defender Firewall
2. Advanced settings
3. Inbound Rules → New Rule
4. Program → Browse → VirtualBox.exe
5. Allow the connection → Finish

---

## Passo 10: Instalar Ferramentas Adicionais

### Notepad++ (Editor de Texto)

```powershell
# Via Chocolatey (se tiver instalado)
choco install notepadplusplus -y

# OU baixar de: https://notepad-plus-plus.org/
```

### 7-Zip (Compactador)

```powershell
# Via Chocolatey
choco install 7zip -y

# OU baixar de: https://www.7-zip.org/
```

### Git (Controle de Versão - para GitHub)

```powershell
# Via Chocolatey
choco install git -y

# OU baixar de: https://git-scm.com/download/win
```

---

## Passo 11: Verificação Final

### Checklist Pré-Instalação

```powershell
# Script de verificação rápida
Write-Host "=== Verificação de Pré-requisitos ===" -ForegroundColor Cyan

# 1. Estrutura de pastas
if (Test-Path "C:\SOC-Lab") {
    Write-Host "✓ Pasta C:\SOC-Lab existe" -ForegroundColor Green
} else {
    Write-Host "✗ Pasta C:\SOC-Lab NÃO existe" -ForegroundColor Red
}

# 2. VirtualBox
if (Test-Path "C:\Program Files\Oracle\VirtualBox\VirtualBox.exe") {
    Write-Host "✓ VirtualBox instalado" -ForegroundColor Green
    & "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" --version
} else {
    Write-Host "✗ VirtualBox NÃO instalado" -ForegroundColor Red
}

# 3. ISOs
$isos = Get-ChildItem "C:\SOC-Lab\ISOs\*.iso" -ErrorAction SilentlyContinue
Write-Host "✓ ISOs encontradas: $($isos.Count)" -ForegroundColor Green

# 4. Espaço em disco
$drive = Get-Volume -DriveLetter C
$freeGB = [math]::Round($drive.SizeRemaining / 1GB, 2)
if ($freeGB -gt 300) {
    Write-Host "✓ Espaço livre: $freeGB GB (suficiente)" -ForegroundColor Green
} else {
    Write-Host "⚠ Espaço livre: $freeGB GB (recomendado 300+ GB)" -ForegroundColor Yellow
}

# 5. RAM
$ram = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
if ($ram -ge 16) {
    Write-Host "✓ RAM Total: $ram GB (suficiente)" -ForegroundColor Green
} else {
    Write-Host "⚠ RAM Total: $ram GB (recomendado 16+ GB)" -ForegroundColor Yellow
}

# 6. Virtualização
$virt = (Get-ComputerInfo).HyperVRequirementVirtualizationFirmwareEnabled
if ($virt) {
    Write-Host "✓ Virtualização habilitada na BIOS" -ForegroundColor Green
} else {
    Write-Host "✗ Virtualização NÃO habilitada (habilitar na BIOS)" -ForegroundColor Red
}
```

### Checklist Manual

- [ ] Windows atualizado e reiniciado
- [ ] Estrutura de pastas criada (C:\SOC-Lab\)
- [ ] ISOs movidas para C:\SOC-Lab\ISOs\
- [ ] VirtualBox instalado
- [ ] Extension Pack instalado
- [ ] Pasta padrão de VMs configurada
- [ ] Virtualização habilitada na BIOS
- [ ] Ferramentas adicionais instaladas
- [ ] 300+ GB livres em disco
- [ ] Script de verificação executado com sucesso

---

## Estatísticas do Ambiente

```powershell
# Resumo do ambiente preparado
Write-Host "`n=== Estatísticas do Ambiente ===" -ForegroundColor Cyan
Write-Host "Hostname:        $(hostname)"
Write-Host "SO:              $((Get-CimInstance Win32_OperatingSystem).Caption)"
Write-Host "RAM:             $([math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)) GB"
Write-Host "CPU:             $((Get-CimInstance Win32_Processor).Name)"
Write-Host "Espaço C:        $([math]::Round((Get-Volume -DriveLetter C).SizeRemaining / 1GB, 2)) GB livre"
Write-Host "VirtualBox:      $((& 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe' --version))"
Write-Host "Pasta VMs:       C:\SOC-Lab\VMs"
```

---

## Problemas Comuns

### ❌ VirtualBox não instala

**Erro:** "Installation failed"

**Solução:**
1. Desinstalar versão antiga (se houver)
2. Reiniciar PC
3. Desabilitar antivírus temporariamente
4. Instalar novamente

### ❌ Extension Pack falha

**Erro:** "Failed to install extension pack"

**Solução:**
1. Desinstalar Extension Pack antigo
2. Fechar VirtualBox completamente
3. Instalar novamente

### ❌ Virtualização desabilitada

**Solução:** Ver Passo 8 - Habilitar na BIOS

---

## Próximos Passos

Ambiente preparado! Agora:

1. Seguir para [03-downloads-e-isos.md](03-downloads-e-isos.md)
2. Ou ir direto para [04-configuracao-rede.md](04-configuracao-rede.md)
3. Começar instalação das VMs

**Tempo gasto nesta etapa:** ~1-2 horas  
**Próxima etapa:** Configuração de rede e instalação de VMs
