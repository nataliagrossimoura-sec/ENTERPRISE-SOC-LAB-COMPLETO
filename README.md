# ENTERPRISE-SOC-LAB-COMPLETO
# 🔐 Enterprise SOC Lab - Laboratório Completo de Segurança

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Status](https://img.shields.io/badge/Status-Operational-success)](https://github.com/nataliagrossimoura-sec/ENTERPRISE-SOC-LAB-COMPLETO)
[![Platform](https://img.shields.io/badge/Platform-VirtualBox-blue)](https://www.virtualbox.org/)

> **Laboratório profissional de SOC (Security Operations Center) para treinamento em detecção, análise e resposta a incidentes de segurança.**

<div align="center">
  
  ![SOC Lab Architecture](https://img.shields.io/badge/Architecture-Enterprise_Grade-orange)
  ![VMs](https://img.shields.io/badge/VMs-5_Integrated-green)
  ![Tools](https://img.shields.io/badge/Tools-Wazuh_Splunk_Sysmon-blue)
  
</div>

---

## 📋 Sobre o Projeto

O **Enterprise SOC Lab** é um ambiente completo e funcional que simula uma infraestrutura corporativa real de segurança, desenvolvido para capacitação profissional em Blue Team, análise de logs, detecção de ameaças e resposta a incidentes.

**Autora:** Natália Grossi  
**LinkedIn:** [linkedin.com/in/natália-grossi-26bbb8374](https://www.linkedin.com/in/natália-grossi-26bbb8374)  
**Data:** Dezembro/2025  
**Status:** ✅ 100% Operacional

---

## 🎯 Objetivos do Laboratório

- ✅ **Monitoramento Centralizado** - SIEM (Wazuh + Splunk)
- ✅ **Detecção de Ameaças** - Sysmon, regras personalizadas, correlação
- ✅ **Resposta a Incidentes** - Playbooks, contenção, investigação forense
- ✅ **Simulação de Ataques** - Red Team controlado com Kali Linux
- ✅ **Segmentação de Rede** - pfSense, isolamento, NAT
- ✅ **Telemetria Avançada** - Logs de Windows, Linux, rede e aplicações

---

## 🏗️ Arquitetura do Laboratório

### 📐 Diagrama de Rede

```
┌─────────────────────────────────────────────────────────┐
│                    INTERNET (NAT)                       │
│                     10.0.2.0/24                         │
└─────────────────────┬───────────────────────────────────┘
                      │ WAN Interface
                      ↓
            ┌─────────────────────┐
            │   pfSense Firewall  │
            │    192.168.1.1/24   │
            │  ─────────────────  │
            │   • Firewall Rules  │
            │   • NAT & DHCP      │
            │   • DNS Resolver    │
            └──────────┬──────────┘
                       │ LAN Interface
                       │ Internal Network: LAN_SOC
                       │ 192.168.1.0/24
        ┌──────────────┼──────────────┐
        │              │              │
        ↓              ↓              ↓
   ┌────────┐   ┌──────────┐   ┌─────────┐
   │  DC01  │   │  Wazuh   │   │  Kali   │
   │ .51    │   │  .102    │   │  .10    │
   │Windows │   │  Ubuntu  │   │  Linux  │
   │Server  │   │  Server  │   │  Red    │
   └────────┘   └──────────┘   └─────────┘
```

### 🖥️ Componentes

| **VM** | **IP** | **SO** | **Função** | **Recursos** |
|--------|--------|--------|-----------|-------------|
| **pfSense** | 192.168.1.1 | FreeBSD | Firewall/Gateway | 1GB RAM, 1 CPU |
| **DC01** | 192.168.1.51 | Windows Server 2022 | Active Directory + SIEM | 4-6GB RAM, 2 CPU |
| **Wazuh Server** | 192.168.1.102 | Ubuntu Server 22.04 | SIEM Central | 4GB RAM, 2 CPU |
| **Ubuntu Lab** | 192.168.1.101 | Ubuntu Desktop 22.04 | Endpoint Linux | 2GB RAM, 1 CPU |
| **Kali Linux** | 192.168.1.10 | Kali Linux | Red Team | 2GB RAM, 2 CPU |

---

## 🛠️ Stack de Ferramentas

### 🔵 Blue Team

- **[Wazuh](https://wazuh.com/)** - SIEM open-source, detecção de ameaças, compliance
- **[Splunk Enterprise](https://www.splunk.com/)** - Análise avançada de logs
- **[Sysmon](https://learn.microsoft.com/sysinternals/downloads/sysmon)** - Telemetria detalhada do Windows
- **[pfSense](https://www.pfsense.org/)** - Firewall, NAT, DHCP, DNS

### 🔴 Red Team

- **[Kali Linux](https://www.kali.org/)** - Distribuição para testes de penetração
  - Nmap, Metasploit, Hydra, SQLMap, Wireshark

### 📊 Monitoramento

- **Windows Event Logs** - Security, System, Application
- **Sysmon Operational** - Process, Network, File, Registry
- **Linux Logs** - Syslog, Auth.log, Kern.log
- **pfSense Logs** - Firewall, DHCP, DNS

---

## 📚 Documentação Completa

### 📂 Estrutura do Repositório

```
ENTERPRISE-SOC-LAB-COMPLETO/
│
├── 📁 INSTALLATION/               # Guias de instalação
│   ├── INSTALLATION_GUIDE.md      # Guia completo passo a passo
│   ├── PRE-REQUISITES.md          # Requisitos de hardware/software
│   ├── HOST_PREPARATION.md        # Preparação do host
│   └── USE_CASES.md               # Casos de uso práticos
│
├── 📁 SCRIPTS/                    # Scripts de automação
│   ├── setup-sysmon.ps1           # Instalação do Sysmon
│   ├── setup-wazuh-agent.ps1      # Instalação do Wazuh Agent
│   ├── generate-activity.ps1      # Gerador de atividade de teste
│   ├── check-lab-status.ps1       # Verificação do laboratório
│   └── install-wazuh-agent.sh     # Instalação Wazuh Agent (Linux)
│
├── 📁 DOCS/                       # Documentação técnica
│   ├── ARCHITECTURE.md            # Arquitetura detalhada
│   ├── COMMANDS_USED.md           # Referência de comandos
│   ├── LOGS_AND_MONITORING.md     # Guia de logs e monitoramento
│   ├── TROUBLESHOOTING.md         # Solução de problemas
│   ├── PRACTICAL_EXERCISES.md     # Exercícios práticos
│   └── ADVANCED_EXERCISES.md      # Exercícios avançados
│
├── LICENSE-MIT.md                 # Licença MIT
└── README.md                      # Este arquivo
```

---

## 🚀 Início Rápido

### 1️⃣ Pré-requisitos

**Hardware Mínimo:**
- **CPU:** Intel i3 (4 threads) ou equivalente
- **RAM:** 16 GB
- **Disco:** 300 GB SSD livre
- **Rede:** Conexão Ethernet estável

**Software:**
- **Host:** Windows 10/11 atualizado
- **Virtualização:** VirtualBox 7.0+ ([Download](https://www.virtualbox.org/wiki/Downloads))
- **VirtualBox Extension Pack** (obrigatório)

### 2️⃣ Instalação

#### **Método 1: Guia Passo a Passo (Recomendado)**

Siga a documentação completa em ordem:

1. **[PRE-REQUISITES.md](INSTALLATION/PRE-REQUISITES.md)** - Verificar requisitos
2. **[HOST_PREPARATION.md](INSTALLATION/HOST_PREPARATION.md)** - Preparar ambiente
3. **[INSTALLATION_GUIDE.md](INSTALLATION/INSTALLATION_GUIDE.md)** - Instalar todas as VMs

**Tempo estimado:** 8-12 horas

#### **Método 2: Scripts Automatizados (Após Instalação Manual)**

Após instalar as VMs manualmente, use os scripts para acelerar a configuração:

```powershell
# No Windows DC01 - PowerShell como Administrador

# 1. Instalar Sysmon
cd C:\SOC-Lab\Scripts
.\setup-sysmon.ps1

# 2. Instalar Wazuh Agent
.\setup-wazuh-agent.ps1

# 3. Verificar laboratório
.\check-lab-status.ps1

# 4. Gerar atividade de teste
.\generate-activity.ps1 -ActivityType All
```

```bash
# No Ubuntu Lab - Terminal

# 1. Instalar Wazuh Agent
cd ~/scripts
chmod +x install-wazuh-agent.sh
sudo ./install-wazuh-agent.sh
```

### 3️⃣ Verificação Rápida

```powershell
# No Windows DC01

# Testar conectividade
Test-NetConnection 192.168.1.1      # pfSense
Test-NetConnection 192.168.1.102 -Port 1514  # Wazuh

# Verificar serviços
Get-Service Sysmon64
Get-Service wazuh

# Ver logs recentes
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -MaxEvents 10
```

```bash
# No Ubuntu Lab

# Testar conectividade
ping -c 4 192.168.1.1
ping -c 4 192.168.1.102

# Verificar agente
sudo systemctl status wazuh-agent
```

### 4️⃣ Acessar Dashboards

- **Wazuh Dashboard:** https://192.168.1.102  
  - User: `admin`  
  - Password: *(exibido após instalação)*

- **Splunk Enterprise:** http://192.168.1.51:8000  
  - User: `admin`  
  - Password: *(definido na instalação)*

- **pfSense Web UI:** http://192.168.1.1  
  - User: `admin`  
  - Password: `pfsense`

---

## 🎓 Casos de Uso e Exercícios

### 🟢 Nível Básico

1. ✅ **Detectar Failed Logon Attempts** (Brute Force - T1110)
2. ✅ **Processo Suspeito em Diretório Temporário** (T1204)
3. ✅ **Modificação de Registry (Persistence)** (T1547.001)
4. ✅ **Conexão de Rede para IP Externo** (T1071)

### 🟡 Nível Intermediário

5. ✅ **PowerShell com Comando Codificado** (T1059.001 + T1027)
6. ✅ **Service Installation (Backdoor)** (T1543.003)
7. ✅ **Download via Certutil (LOLBin)** (T1105)
8. ✅ **Scheduled Task Creation** (T1053.005)

### 🔴 Nível Avançado

9. ✅ **Pass-the-Hash Attack (Simulado)** (T1550.002)
10. ✅ **Data Exfiltration via DNS Tunneling** (T1048.003)
11. ✅ **Lateral Movement Detection**
12. ✅ **Credential Dumping (LSASS Access)**

📖 **Documentação completa:** [USE_CASES.md](INSTALLATION/USE_CASES.md)

---

## 📊 Fluxo de Segurança (SOC)

```
1. Ataque gerado pelo Kali Linux
         ↓
2. Tráfego passa pelo pfSense (logs)
         ↓
3. Endpoints geram eventos (Sysmon, Security Log)
         ↓
4. Wazuh Agent coleta logs
         ↓
5. Wazuh Manager processa e correlaciona
         ↓
6. Alertas são gerados (regras MITRE ATT&CK)
         ↓
7. Dashboard exibe eventos (Wazuh + Splunk)
         ↓
8. Analista SOC investiga e responde
```

---

## 🧪 Exemplos de Detecção

### Exemplo 1: PowerShell Suspeito

```powershell
# Simular ataque (Windows DC01)
$command = "Write-Host 'Comando malicioso'"
$bytes = [System.Text.Encoding]::Unicode.GetBytes($command)
$encodedCommand = [Convert]::ToBase64String($bytes)
powershell.exe -EncodedCommand $encodedCommand
```

**Detecção no Splunk:**
```spl
index=sysmon EventCode=1 Image="*powershell.exe" 
(CommandLine="*-enc*" OR CommandLine="*-EncodedCommand*")
| table _time, User, CommandLine, ParentImage
```

**Alerta Wazuh:**
- Rule ID: 80100
- Level: 8 (High)
- MITRE: T1059.001

---

### Exemplo 2: Brute Force SSH (Linux)

```bash
# Simular ataque (Kali Linux)
hydra -l admin -P passwords.txt ssh://192.168.1.101
```

**Detecção no Wazuh:**
```
Rule: 5710 - Multiple authentication failures
Level: 10 (Critical)
MITRE: T1110
```

**Query Linux:**
```bash
sudo grep "Failed password" /var/log/auth.log | awk '{print $(NF-3)}' | sort | uniq -c
```

---

## 🛠️ Comandos Úteis

### Windows (PowerShell)

```powershell
# Verificar status geral
.\check-lab-status.ps1

# Ver eventos Sysmon
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -MaxEvents 20

# Processos suspeitos
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" |
  Where-Object {$_.Id -eq 1 -and $_.Message -like "*powershell*"}

# Conexões de rede externas
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" |
  Where-Object {$_.Id -eq 3 -and $_.Message -notlike "*192.168.*"}
```

### Linux (Bash)

```bash
# Verificar agente Wazuh
sudo systemctl status wazuh-agent
sudo tail -f /var/ossec/logs/ossec.log

# Análise de autenticação
grep "Failed password" /var/log/auth.log | awk '{print $(NF-3)}' | sort | uniq -c

# Monitorar logs em tempo real
tail -f /var/log/syslog /var/log/auth.log
```

### Splunk (SPL)

```spl
# Top 10 processos criados
index=sysmon EventCode=1 | stats count by Image | sort -count | head 10

# Detecção de brute force
index=main source=WinEventLog:Security EventCode=4625
| stats count by Account_Name, src_ip
| where count > 10

# Conexões externas
index=sysmon EventCode=3 DestinationIp!=192.168.*
| table _time, Computer, User, Image, DestinationIp, DestinationPort
```

📖 **Referência completa:** [COMMANDS_USED.md](COMMANDS_USED.md)

---

## 🔧 Solução de Problemas

### ❌ VM não recebe IP do DHCP

```powershell
# Windows
ipconfig /release
ipconfig /renew
Get-NetAdapter | Restart-NetAdapter

# Linux
sudo dhclient -r
sudo dhclient
```

### ❌ Wazuh Agent não conecta

```powershell
# Windows
Test-NetConnection 192.168.1.102 -Port 1514
Get-Service wazuh | Restart-Service
Get-Content "C:\Program Files (x86)\ossec-agent\ossec.log" -Tail 20

# Linux
nc -zv 192.168.1.102 1514
sudo systemctl restart wazuh-agent
sudo tail -f /var/ossec/logs/ossec.log
```

### ❌ Sysmon não gera logs

```powershell
Get-Service Sysmon64
cd C:\Sysmon
.\Sysmon64.exe -c sysmonconfig.xml
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -MaxEvents 5
```

📖 **Guia completo:** [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

## 📈 Roadmap Futuro

- [ ] Integração com MISP (Threat Intelligence)
- [ ] Automação de resposta com SOAR
- [ ] Honeypots integrados
- [ ] Machine Learning para detecção de anomalias
- [ ] Dashboard customizado para CTI
- [ ] Integração com TheHive (Case Management)

---

## 🤝 Contribuições

Contribuições são bem-vindas! Para contribuir:

1. Fork o projeto
2. Crie uma branch (`git checkout -b feature/MinhaContribuicao`)
3. Commit suas mudanças (`git commit -m 'Adiciona nova funcionalidade'`)
4. Push para a branch (`git push origin feature/MinhaContribuicao`)
5. Abra um Pull Request

---

## 📄 Licença

Este projeto está sob a licença MIT. Veja [LICENSE-MIT.md](LICENSE-MIT.md) para mais detalhes.

---

## 👥 Autor

**Natália Grossi**  
- LinkedIn: [linkedin.com/in/natália-grossi-26bbb8374](https://www.linkedin.com/in/natália-grossi-26bbb8374)  
- Email: *(adicionar se desejar)*  
- GitHub: [@nataliagrossimoura-sec](https://github.com/nataliagrossimoura-sec)

---

## 🙏 Agradecimentos

- [Wazuh](https://wazuh.com/) pela plataforma SIEM open-source
- [SwiftOnSecurity](https://github.com/SwiftOnSecurity/sysmon-config) pela configuração do Sysmon
- [MITRE ATT&CK](https://attack.mitre.org/) pelo framework de táticas e técnicas
- Comunidade de Segurança da Informação

---

## ⭐ Estatísticas

![GitHub stars](https://img.shields.io/github/stars/nataliagrossimoura-sec/ENTERPRISE-SOC-LAB-COMPLETO?style=social)
![GitHub forks](https://img.shields.io/github/forks/nataliagrossimoura-sec/ENTERPRISE-SOC-LAB-COMPLETO?style=social)
![GitHub watchers](https://img.shields.io/github/watchers/nataliagrossimoura-sec/ENTERPRISE-SOC-LAB-COMPLETO?style=social)

---

<div align="center">
  
  **Se este projeto foi útil, considere dar uma ⭐!**
  
  Desenvolvido com ❤️ para a comunidade de cibersegurança
  
</div>
