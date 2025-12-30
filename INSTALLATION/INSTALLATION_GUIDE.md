# 🚀 Guia Completo de Instalação - Enterprise SOC Lab

Este guia contém **instruções passo a passo** para construir o laboratório SOC completo do zero.

**Tempo estimado total:** 8-12 horas

---

## 📋 Índice

1. [Pré-requisitos](#1-pré-requisitos)
2. [Preparação do Ambiente Host](#2-preparação-do-ambiente-host)
3. [Download de ISOs e Ferramentas](#3-download-de-isos-e-ferramentas)
4. [Configuração do VirtualBox](#4-configuração-do-virtualbox)
5. [Instalação do pfSense](#5-instalação-do-pfsense)
6. [Instalação do Windows Server (DC01)](#6-instalação-do-windows-server-dc01)
7. [Instalação do Wazuh Server](#7-instalação-do-wazuh-server)
8. [Instalação do Ubuntu Lab](#8-instalação-do-ubuntu-lab)
9. [Instalação do Kali Linux](#9-instalação-do-kali-linux)
10. [Configuração dos Agentes Wazuh](#10-configuração-dos-agentes-wazuh)
11. [Instalação do Splunk](#11-instalação-do-splunk)
12. [Instalação do Sysmon](#12-instalação-do-sysmon)
13. [Verificação Final](#13-verificação-final)

---

## 1. Pré-requisitos

### 1.1 Hardware do Host

**Mínimo:**
- CPU: Intel i3 (4 threads)
- RAM: 16 GB
- SSD: 300 GB livres

**Recomendado:**
- CPU: Intel i5/i7 (8+ threads)
- RAM: 24-32 GB
- SSD: 500 GB - 1 TB

### 1.2 Software do Host

- Windows 10/11 atualizado
- VirtualBox 7.0+ ([Download](https://www.virtualbox.org/wiki/Downloads))
- VirtualBox Extension Pack
- Navegador web atualizado

### 1.3 ISOs Necessárias

| ISO | Link | Tamanho Aprox. |
|-----|------|----------------|
| pfSense CE | [Download](https://www.pfsense.org/download/) | ~600 MB |
| Windows Server 2022 | [Evaluation](https://www.microsoft.com/evalcenter) | ~5 GB |
| Ubuntu Server 22.04 LTS | [Download](https://ubuntu.com/download/server) | ~2 GB |
| Ubuntu Desktop 22.04 LTS | [Download](https://ubuntu.com/download/desktop) | ~4 GB |
| Kali Linux | [Download](https://www.kali.org/get-kali/) | ~3-4 GB |

### 1.4 Ferramentas Adicionais

- Splunk Enterprise (.msi) - [Download](https://www.splunk.com/download)
- Sysmon - [Download](https://learn.microsoft.com/sysinternals/downloads/sysmon)
- Wazuh Agent Windows (.msi) - [Download via Wazuh Dashboard]
- Wireshark - [Download](https://www.wireshark.org/download.html)

---

## 2. Preparação do Ambiente Host

### 2.1 Atualizar Sistema Operacional

```powershell
# Abrir PowerShell como Administrador
# Executar Windows Update
Get-WindowsUpdate -Install -AcceptAll

# Reiniciar se necessário
Restart-Computer
```

### 2.2 Criar Estrutura de Diretórios

```powershell
# Criar pasta principal
New-Item -Path "C:\SOC-Lab" -ItemType Directory

# Criar subpastas
$folders = @(
    "VMs",
    "ISOs",
    "Snapshots",
    "Configs",
    "Scripts",
    "Logs",
    "Documentacao"
)

foreach ($folder in $folders) {
    New-Item -Path "C:\SOC-Lab\$folder" -ItemType Directory
}

# Verificar estrutura
Get-ChildItem C:\SOC-Lab
```

### 2.3 Baixar ISOs

Baixar todas as ISOs listadas em 1.3 e salvar em `C:\SOC-Lab\ISOs\`

---

## 3. Download de ISOs e Ferramentas

### 3.1 pfSense

1. Acessar: https://www.pfsense.org/download/
2. Configurações:
   - **Architecture:** AMD64 (64-bit)
   - **Installer:** ISO Installer
   - **Mirror:** Selecionar mais próximo
3. Baixar e salvar em `C:\SOC-Lab\ISOs\pfsense.iso`

### 3.2 Windows Server 2022

1. Acessar: https://www.microsoft.com/evalcenter
2. Buscar por "Windows Server 2022"
3. Baixar versão **Evaluation (180 dias)**
4. Salvar em `C:\SOC-Lab\ISOs\WindowsServer2022.iso`

### 3.3 Ubuntu Server 22.04 LTS

1. Acessar: https://ubuntu.com/download/server
2. Baixar **Ubuntu Server 22.04.x LTS**
3. Salvar em `C:\SOC-Lab\ISOs\ubuntu-server-22.04.iso`

### 3.4 Ubuntu Desktop 22.04 LTS

1. Acessar: https://ubuntu.com/download/desktop
2. Baixar **Ubuntu Desktop 22.04.x LTS**
3. Salvar em `C:\SOC-Lab\ISOs\ubuntu-desktop-22.04.iso`

### 3.5 Kali Linux

1. Acessar: https://www.kali.org/get-kali/
2. Baixar **Kali Linux Installer (64-bit)**
3. Salvar em `C:\SOC-Lab\ISOs\kali-linux.iso`

---

## 4. Configuração do VirtualBox

### 4.1 Instalar VirtualBox

```powershell
# Executar instalador do VirtualBox
# Aceitar configurações padrão
# Instalar drivers de rede quando solicitado
```

### 4.2 Instalar Extension Pack

1. Baixar Extension Pack: https://www.virtualbox.org/wiki/Downloads
2. Abrir VirtualBox
3. **File → Preferences → Extensions**
4. Clicar em **+** e selecionar Extension Pack baixado
5. Aceitar termos

### 4.3 Configurar Pasta Padrão de VMs

1. **File → Preferences → General**
2. **Default Machine Folder:** `C:\SOC-Lab\VMs`
3. Clicar **OK**

### 4.4 Criar Rede Internal Network

**Observação:** A rede Internal Network é configurada individualmente em cada VM.

Nome da rede: **LAN_SOC**

---

## 5. Instalação do pfSense

**Tempo estimado:** 1 hora

### 5.1 Criar Máquina Virtual

1. Abrir VirtualBox
2. Clicar em **New** (Novo)
3. Configurações:
   - **Name:** `pfSense`
   - **Type:** BSD
   - **Version:** FreeBSD (64-bit)
   - **Memory:** 1024 MB (1 GB)
   - **Hard disk:** Create a virtual hard disk now
4. **Create**

### 5.2 Configurar Disco

1. **Disk size:** 10 GB
2. **Hard disk file type:** VDI
3. **Storage on physical hard disk:** Dynamically allocated
4. **Create**

### 5.3 Configurar VM

1. Selecionar VM **pfSense** → **Settings**

**System:**
- **Boot Order:** Hard Disk, Optical
- Desmarcar **Floppy**

**Storage:**
- Controller: IDE → Empty → Click em ícone de disco
- **Choose a disk file:** Selecionar `C:\SOC-Lab\ISOs\pfsense.iso`

**Network:**
- **Adapter 1:**
  - Enable Network Adapter: ✅
  - Attached to: **NAT**
- **Adapter 2:**
  - Enable Network Adapter: ✅
  - Attached to: **Internal Network**
  - Name: **LAN_SOC**

5. **OK**

### 5.4 Iniciar e Instalar

1. Iniciar VM **pfSense**
2. Aguardar boot
3. Pressionar **Enter** para aceitar copyright
4. **Install pfSense** → Enter
5. **Keymap:** Accept default (ou Brazilian Portuguese)
6. **Partitioning:** Auto (ZFS) → Enter
7. **Select:** Stripe → Enter
8. **Select disk:** `ada0` → Space → OK
9. **Confirm:** YES
10. Aguardar instalação (2-5 min)
11. **Reboot** → Enter
12. Remover ISO quando solicitado

### 5.5 Configuração Inicial

Após reboot:

```
Should VLANs be set up now? → n (Enter)

Enter the WAN interface name: → em0 (Enter)
Enter the LAN interface name: → em1 (Enter)

Proceed? → y (Enter)
```

### 5.6 Configurar IP da LAN

```
Enter an option: → 2 (Set interface IP address)

Enter the number of the interface: → 2 (LAN - em1)

Configure IPv4 address via DHCP? → n

Enter the new LAN IPv4 address: → 192.168.1.1
Enter the new LAN IPv4 subnet bit count: → 24

Configure IPv4 address via DHCP6? → n
Enter the new LAN IPv6 address: → (deixar em branco, Enter)

Enable DHCP server on LAN? → y
Enter the start address: → 192.168.1.10
Enter the end address: → 192.168.1.200

Revert to HTTP as the webConfigurator protocol? → n
```

✅ **pfSense configurado!**

---

## 6. Instalação do Windows Server (DC01)

**Tempo estimado:** 2 horas

### 6.1 Criar Máquina Virtual

1. VirtualBox → **New**
2. Configurações:
   - **Name:** `DC01`
   - **Type:** Microsoft Windows
   - **Version:** Windows 2022 (64-bit)
   - **Memory:** 4096 MB (4 GB) - ou 6144 MB se disponível
   - **Hard disk:** Create a virtual hard disk now
3. **Create**

### 6.2 Configurar Disco

1. **Disk size:** 60 GB
2. **Hard disk file type:** VDI
3. **Storage:** Dynamically allocated
4. **Create**

### 6.3 Configurar VM

Selecionar **DC01** → **Settings**

**System → Processor:**
- **Processor(s):** 2 CPUs

**Storage:**
- Controller: IDE → Empty → Anexar ISO do Windows Server 2022

**Network → Adapter 1:**
- Enable Network Adapter: ✅
- Attached to: **Internal Network**
- Name: **LAN_SOC**

**OK**

### 6.4 Instalar Windows Server

1. Iniciar VM **DC01**
2. Pressionar qualquer tecla para boot do DVD
3. **Language:** Portuguese (Brazil) ou English
4. **Install now**
5. **Select edition:** Windows Server 2022 Standard Evaluation **(Desktop Experience)**
6. **Accept license**
7. **Custom: Install Windows only**
8. Selecionar disco → **Next**
9. Aguardar instalação (10-15 min)
10. Criar senha de Administrator (forte!)
11. Pressionar Ctrl+Alt+Del para login
12. Fazer login com senha criada

### 6.5 Configurar Rede (Opcional - DHCP funciona)

Se preferir IP estático:

```powershell
# Abrir PowerShell como Administrador

# Verificar adaptador
Get-NetAdapter

# Configurar IP estático
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 192.168.1.51 -PrefixLength 24 -DefaultGateway 192.168.1.1

# Configurar DNS
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 192.168.1.1

# Verificar
Get-NetIPAddress
Test-NetConnection 192.168.1.1
```

### 6.6 Renomear Computador

```powershell
Rename-Computer -NewName "DC01" -Restart
```

✅ **Windows Server instalado!**

---

## 7. Instalação do Wazuh Server

**Tempo estimado:** 1.5 horas

### 7.1 Criar Máquina Virtual

1. VirtualBox → **New**
2. Configurações:
   - **Name:** `wazuh-server`
   - **Type:** Linux
   - **Version:** Ubuntu (64-bit)
   - **Memory:** 4096 MB (4 GB)
   - **Hard disk:** Create
3. **Create**

### 7.2 Configurar Disco

1. **Size:** 40 GB
2. **Type:** VDI
3. **Storage:** Dynamically allocated
4. **Create**

### 7.3 Configurar VM

Selecionar **wazuh-server** → **Settings**

**System → Processor:**
- **Processor(s):** 2 CPUs

**Storage:**
- Anexar ISO do Ubuntu Server 22.04

**Network → Adapter 1:**
- Attached to: **Internal Network**
- Name: **LAN_SOC**

**OK**

### 7.4 Instalar Ubuntu Server

1. Iniciar VM
2. **Language:** English
3. **Update to the new installer:** Continue without updating (ou atualizar)
4. **Keyboard:** English (US) ou Portuguese (Brazilian)
5. **Type of install:** Ubuntu Server
6. **Network:** Aguardar DHCP (192.168.1.x)
7. **Proxy:** Deixar em branco
8. **Mirror:** Default
9. **Storage:** Use entire disk
10. **Confirm:** Continue
11. **Profile:**
    - Your name: `soc`
    - Server name: `wazuh-server`
    - Username: `soc`
    - Password: (criar senha forte)
12. **SSH:** Install OpenSSH server ✅
13. **Featured snaps:** Nenhum
14. Aguardar instalação
15. **Reboot Now**
16. Remover ISO e pressionar Enter

### 7.5 Atualizar Sistema

```bash
# Login com usuário criado

# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar ferramentas básicas
sudo apt install net-tools curl wget -y

# Verificar IP
ip addr show
```

### 7.6 Instalar Wazuh Stack (All-in-One)

```bash
# Baixar script de instalação
curl -sO https://packages.wazuh.com/4.8/wazuh-install.sh

# Executar instalação all-in-one
sudo bash wazuh-install.sh --all-in-one
```

**Aguardar instalação:** 15-30 minutos

**IMPORTANTE:** Ao final da instalação, serão exibidas as credenciais:

```
User: admin
Password: (SALVAR ESTA SENHA!)
```

### 7.7 Acessar Dashboard

1. No Windows Server (DC01), abrir navegador
2. Acessar: `https://192.168.1.102`
3. Aceitar certificado auto-assinado
4. Login com credenciais exibidas

✅ **Wazuh Server instalado!**

---

## 8. Instalação do Ubuntu Lab

**Tempo estimado:** 45 minutos

### 8.1 Criar Máquina Virtual

1. VirtualBox → **New**
2. **Name:** `ubuntu-lab`
3. **Type:** Linux
4. **Version:** Ubuntu (64-bit)
5. **Memory:** 2048 MB (2 GB)
6. **Hard disk:** Create → 20 GB
7. **Create**

### 8.2 Configurar VM

**Storage:** Anexar ISO Ubuntu Desktop 22.04

**Network:** Internal Network → **LAN_SOC**

### 8.3 Instalar Ubuntu Desktop

1. Iniciar VM
2. **Try or Install Ubuntu** → Enter
3. **Language:** Portuguese ou English
4. **Install Ubuntu**
5. **Keyboard:** Portuguese (Brazil) ou English (US)
6. **Normal installation**
7. **Erase disk and install Ubuntu**
8. **Continue**
9. **Timezone:** São Paulo (ou sua região)
10. **Your name:** `lab`
11. **Computer name:** `ubuntu-lab`
12. **Username:** `lab`
13. **Password:** (criar senha)
14. Aguardar instalação
15. **Restart Now**

### 8.4 Atualizar e Instalar Ferramentas

```bash
# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar ferramentas úteis
sudo apt install net-tools tcpdump htop vim curl wget -y

# Verificar conectividade
ping -c 4 192.168.1.1
ping -c 4 google.com
```

✅ **Ubuntu Lab instalado!**

---

## 9. Instalação do Kali Linux

**Tempo estimado:** 1 hora

### 9.1 Criar Máquina Virtual

1. VirtualBox → **New**
2. **Name:** `Kali-Linux`
3. **Type:** Linux
4. **Version:** Debian (64-bit)
5. **Memory:** 2048 MB (2 GB)
6. **Hard disk:** Create → 30 GB
7. **Create**

### 9.2 Configurar VM

**System → Processor:** 2 CPUs (se disponível)

**Storage:** Anexar ISO Kali Linux

**Network:** Internal Network → **LAN_SOC**

### 9.3 Instalar Kali Linux

1. Iniciar VM
2. **Graphical install**
3. **Language:** English
4. **Location:** Brazil (ou sua região)
5. **Keymap:** American English
6. **Hostname:** `kali`
7. **Domain:** Deixar em branco
8. **Full name:** `Red Team`
9. **Username:** `kali`
10. **Password:** (criar senha)
11. **Partition:** Guided - use entire disk
12. **Select disk:** Único disponível
13. **All files in one partition**
14. **Finish partitioning**
15. **Yes** (write changes)
16. Aguardar instalação base
17. **Use network mirror:** Yes
18. **Proxy:** Deixar em branco
19. Aguardar download de pacotes
20. **Install GRUB:** Yes
21. **Device:** /dev/sda
22. **Continue** para reboot

### 9.4 Atualizar Sistema

```bash
# Login com usuário criado

# Atualizar repositórios
sudo apt update

# Atualizar sistema
sudo apt upgrade -y

# Instalar ferramentas úteis
sudo apt install nmap metasploit-framework hydra nikto -y

# Verificar IP
ip addr show
```

✅ **Kali Linux instalado!**

---

## 10. Configuração dos Agentes Wazuh

### 10.1 Instalar Agente no Windows (DC01)

1. No Wazuh Dashboard (`https://192.168.1.102`)
2. **Menu → Agents → Deploy new agent**
3. Selecionar:
   - **Operating system:** Windows
   - **Server address:** `192.168.1.102`
   - **Agent name:** `DC01`
4. Copiar comando exibido:

```powershell
# No Windows DC01 (PowerShell como Admin)
Invoke-WebRequest -Uri https://packages.wazuh.com/4.x/windows/wazuh-agent-4.8.0-1.msi -OutFile wazuh-agent.msi

msiexec /i wazuh-agent.msi /q WAZUH_MANAGER="192.168.1.102" WAZUH_AGENT_NAME="DC01"

# Iniciar serviço
NET START WazuhSvc

# Verificar status
Get-Service -Name wazuh
```

### 10.2 Instalar Agente no Ubuntu Lab

```bash
# No Ubuntu Lab

# Baixar e adicionar chave GPG
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && chmod 644 /usr/share/keyrings/wazuh.gpg

# Adicionar repositório
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | sudo tee -a /etc/apt/sources.list.d/wazuh.list

# Atualizar
sudo apt update

# Instalar agente
sudo WAZUH_MANAGER="192.168.1.102" apt install wazuh-agent -y

# Iniciar e habilitar
sudo systemctl daemon-reload
sudo systemctl enable wazuh-agent
sudo systemctl start wazuh-agent

# Verificar status
sudo systemctl status wazuh-agent
```

### 10.3 Verificar Agentes no Dashboard

1. Acessar Wazuh Dashboard
2. **Menu → Agents**
3. Verificar que aparecem:
   - ✅ DC01 (Windows)
   - ✅ ubuntu-lab (Linux)

---

## 11. Instalação do Splunk

**No Windows DC01**

**Tempo estimado:** 1 hora

### 11.1 Baixar Splunk Enterprise

1. Acessar: https://www.splunk.com/download
2. Criar conta gratuita
3. Baixar **Splunk Enterprise for Windows (64-bit)**
4. Salvar em Desktop ou C:\Temp

### 11.2 Instalar Splunk

1. Executar instalador `.msi`
2. **Next**
3. Aceitar **License Agreement**
4. **Customize Options:**
   - Installation Directory: `C:\Program Files\Splunk`
5. **Next**
6. **Username:** `admin`
7. **Password:** (criar senha forte - mínimo 8 caracteres)
8. **Next**
9. **Install**
10. Aguardar instalação
11. **Finish** (marcar "Launch browser")

### 11.3 Configuração Inicial

1. Navegador abrirá em `http://localhost:8000`
2. Login:
   - Username: `admin`
   - Password: (senha criada na instalação)
3. Tour inicial (pode pular)
4. **Let's get started!**

### 11.4 Configurar Recebimento de Dados

```powershell
# Abrir PowerShell como Admin
cd "C:\Program Files\Splunk\bin"

# Configurar para receber dados na porta 9997
.\splunk enable listen 9997 -auth admin:<sua_senha>

# Verificar
.\splunk list inputstatus -auth admin:<sua_senha>
```

✅ **Splunk Enterprise instalado!**

---

## 12. Instalação do Sysmon

**No Windows DC01**

**Tempo estimado:** 30 minutos

### 12.1 Baixar Sysmon

1. Acessar: https://learn.microsoft.com/sysinternals/downloads/sysmon
2. Baixar **Sysmon** (Download Sysmon)
3. Extrair para `C:\Sysmon`

### 12.2 Baixar Configuração do Sysmon

```powershell
# PowerShell como Admin
cd C:\Sysmon

# Baixar config recomendada
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/SwiftOnSecurity/sysmon-config/master/sysmonconfig-export.xml" -OutFile "sysmonconfig.xml"
```

### 12.3 Instalar Sysmon

```powershell
# Na pasta C:\Sysmon
.\Sysmon64.exe -accepteula -i sysmonconfig.xml

# Verificar instalação
Get-Service Sysmon64

# Verificar logs
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -MaxEvents 10
```

### 12.4 Configurar Auditoria Detalhada

```powershell
# Habilitar auditoria avançada
auditpol /set /subcategory:"Process Creation" /success:enable /failure:enable
auditpol /set /subcategory:"Logon" /success:enable /failure:enable
auditpol /set /subcategory:"Logoff" /success:enable /failure:enable
auditpol /set /subcategory:"Account Logon" /success:enable /failure:enable

# Verificar
auditpol /get /category:*
```

✅ **Sysmon instalado e configurado!**

---

## 13. Verificação Final

### 13.1 Checklist de Instalação

- [ ] pfSense operacional (acesso web: `http://192.168.1.1`)
- [ ] Windows DC01 conectado à rede (192.168.1.51 ou DHCP)
- [ ] Wazuh Server acessível (`https://192.168.1.102`)
- [ ] Ubuntu Lab conectado
- [ ] Kali Linux conectado
- [ ] Agentes Wazuh ativos (DC01 + Ubuntu Lab)
- [ ] Splunk acessível (`http://192.168.1.51:8000`)
- [ ] Sysmon gerando logs no DC01

### 13.2 Teste de Conectividade

**No Windows DC01:**

```powershell
# Testar Gateway
Test-NetConnection 192.168.1.1

# Testar Wazuh Server
Test-NetConnection 192.168.1.102 -Port 1514

# Testar Internet
Test-NetConnection google.com

# Ver processos ativos (Sysmon deve aparecer)
Get-Process | Where-Object {$_.Name -like "*sysmon*"}
```

**No Ubuntu Lab:**

```bash
# Testar conectividade
ping -c 4 192.168.1.1
ping -c 4 192.168.1.102
ping -c 4 google.com

# Verificar agente Wazuh
sudo systemctl status wazuh-agent
```

### 13.3 Verificar Logs no Wazuh Dashboard

1. Acessar `https://192.168.1.102`
2. **Menu → Agents**
3. Clicar em **DC01**
4. Verificar eventos recebidos
5. Clicar em **ubuntu-lab**
6. Verificar eventos recebidos

### 13.4 Verificar Logs no Splunk

1. Acessar `http://192.168.1.51:8000`
2. **Settings → Data Inputs**
3. Verificar se porta 9997 está listada

### 13.5 Gerar Atividade de Teste

**No Windows DC01:**

```powershell
# Gerar eventos de teste
Start-Process notepad
Start-Sleep -Seconds 5
Stop-Process -Name notepad -Force

# Criar arquivo
New-Item -Path "C:\temp\test.txt" -ItemType File -Force
Remove-Item "C:\temp\test.txt" -Force

# Verificar no Event Viewer
eventvwr.msc
# Applications and Services Logs → Microsoft → Windows → Sysmon → Operational
```

---

## 🎉 Instalação Concluída!

Seu **Enterprise SOC Lab** está completo e funcional!

### Próximos Passos:

1. Explorar Wazuh Dashboard
2. Criar dashboards no Splunk
3. Executar exercícios práticos
4. Simular ataques do Kali
5. Analisar logs coletados
6. Criar regras de detecção personalizadas

