# 🔧 Scripts - Enterprise SOC Lab

Coleção de scripts automatizados para instalação, configuração e testes do laboratório SOC.

---

## 📋 Índice

1. [Scripts Windows (PowerShell)](#scripts-windows-powershell)
2. [Scripts Linux (Bash)](#scripts-linux-bash)
3. [Como Usar](#como-usar)
4. [Requisitos](#requisitos)
5. [Solução de Problemas](#solução-de-problemas)

---

## Scripts Windows (PowerShell)

### 🟦 1. setup-sysmon.ps1

**Descrição:** Instalação automatizada do Sysmon com configuração reforçada

**Funcionalidades:**
- Download automático do Sysmon64.exe
- Download da configuração SwiftOnSecurity
- Instalação ou atualização do Sysmon
- Configuração de auditoria avançada do Windows
- Verificação de instalação

**Uso:**
```powershell
# Abrir PowerShell como Administrador
cd C:\SOC-Lab\Scripts
.\setup-sysmon.ps1
```

**O que faz:**
1. Cria diretório C:\Sysmon
2. Baixa Sysmon64.exe de live.sysinternals.com
3. Baixa sysmonconfig.xml do GitHub (SwiftOnSecurity)
4. Instala Sysmon com configuração
5. Habilita auditoria detalhada (auditpol)
6. Verifica serviço e logs

**Pós-instalação:**
```powershell
# Ver status
Get-Service Sysmon64

# Ver logs
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -MaxEvents 10

# Atualizar configuração
cd C:\Sysmon
.\Sysmon64.exe -c sysmonconfig.xml
```

---

### 🟦 2. setup-wazuh-agent.ps1

**Descrição:** Instalação automatizada do Wazuh Agent no Windows

**Funcionalidades:**
- Download do instalador Wazuh Agent
- Instalação silenciosa com parâmetros
- Configuração automática do Manager
- Verificação de conectividade
- Configuração de firewall

**Uso:**
```powershell
# Com parâmetros padrão
.\setup-wazuh-agent.ps1

# Com parâmetros customizados
.\setup-wazuh-agent.ps1 -ManagerIP "192.168.1.102" -AgentName "DC01"
```

**Parâmetros:**
- `-ManagerIP` : Endereço do Wazuh Manager (padrão: 192.168.1.102)
- `-AgentName` : Nome do agente (padrão: hostname do computador)

**O que faz:**
1. Verifica instalação existente
2. Baixa Wazuh Agent 4.8.0
3. Instala via msiexec
4. Configura endereço do Manager
5. Inicia serviço
6. Cria regra de firewall
7. Verifica conexão

**Pós-instalação:**
```powershell
# Ver status
Get-Service -Name wazuh

# Ver logs
Get-Content "C:\Program Files (x86)\ossec-agent\ossec.log" -Tail 20

# Reiniciar
Restart-Service -Name wazuh
```

---

### 🟦 3. generate-activity.ps1

**Descrição:** Gerador de atividade de teste para validar detecções

**Funcionalidades:**
- Geração de processos
- Criação e modificação de arquivos
- Modificação de registry
- Atividade de rede
- Execução de PowerShell (incluindo comandos codificados)

**Uso:**
```powershell
# Gerar todos os tipos de atividade
.\generate-activity.ps1 -ActivityType All

# Gerar apenas um tipo específico
.\generate-activity.ps1 -ActivityType Process
.\generate-activity.ps1 -ActivityType File
.\generate-activity.ps1 -ActivityType Registry
.\generate-activity.ps1 -ActivityType Network
.\generate-activity.ps1 -ActivityType PowerShell
```

**Tipos de Atividade:**

**Process:**
- Inicia e encerra notepad.exe
- Inicia e encerra calc.exe
- Executa cmd.exe
- Cria processo PowerShell filho

**File:**
- Cria 10 arquivos de teste em C:\Temp\SOC-Test
- Modifica arquivos
- Cria arquivo ZIP
- Deleta arquivos

**Registry:**
- Cria chave HKCU:\Software\SOC-Lab-Test
- Adiciona valores
- Modifica valores
- Deleta valores
- Testa acesso a Run keys

**Network:**
- Pinga gateway
- Testa conectividade externa
- Resolve DNS
- Testa portas específicas
- Simula download

**PowerShell:**
- Executa comandos básicos
- Pipeline complexo
- **Comando codificado em base64 (gera alerta)**
- Invoke-Expression
- Script blocks

**Eventos Gerados:**
- Sysmon Event ID 1 (Process Creation)
- Sysmon Event ID 3 (Network Connection)
- Sysmon Event ID 11 (File Created)
- Sysmon Event ID 13 (Registry Value Set)
- Windows Security Event ID 4688 (Process Creation)

---

### 🟦 4. check-lab-status.ps1

**Descrição:** Verificação completa do status do laboratório

**Funcionalidades:**
- Verifica conectividade de rede
- Verifica serviços rodando
- Verifica geração de logs
- Exibe informações do sistema
- Identifica problemas
- Fornece recomendações

**Uso:**
```powershell
.\check-lab-status.ps1
```

**O que verifica:**

**Rede:**
- Gateway (pfSense) - 192.168.1.1
- Wazuh Manager - 192.168.1.102:1514
- Splunk Local - localhost:8000
- Conectividade internet
- Resolução DNS

**Serviços:**
- Sysmon64
- Wazuh Agent
- Splunk Enterprise / Forwarder
- Windows Event Log

**Logs:**
- Security Event Log (último evento)
- Sysmon Operational (último evento)
- Wazuh Agent Log (conectividade)

**Sistema:**
- Hostname
- Sistema Operacional
- Versão e arquitetura
- Endereço IP

**Output:**
- Status geral (%, Excelente/Bom/Precisa Atenção)
- Lista de problemas encontrados
- Recomendações de ação

---

## Scripts Linux (Bash)

### 🟩 1. install-wazuh-agent.sh

**Descrição:** Instalação automatizada do Wazuh Agent no Ubuntu/Debian

**Funcionalidades:**
- Adiciona repositório Wazuh
- Instala Wazuh Agent
- Configura Manager automaticamente
- Inicia e habilita serviço
- Verifica conectividade

**Uso:**
```bash
# Tornar executável
chmod +x install-wazuh-agent.sh

# Executar com sudo
sudo ./install-wazuh-agent.sh
```

**O que faz:**
1. Verifica conexão de internet
2. Testa conectividade com Manager
3. Adiciona chave GPG do Wazuh
4. Adiciona repositório apt
5. Instala wazuh-agent
6. Configura /var/ossec/etc/ossec.conf
7. Inicia serviço
8. Verifica logs de conexão

**Configuração Automática:**
- Manager: 192.168.1.102
- Agent Name: hostname do sistema

**Pós-instalação:**
```bash
# Ver status
sudo systemctl status wazuh-agent

# Ver logs
sudo tail -f /var/ossec/logs/ossec.log

# Reiniciar
sudo systemctl restart wazuh-agent
```

---

## Como Usar

### Pré-requisitos Gerais

**Windows:**
- Windows 10/11 ou Windows Server 2019/2022
- PowerShell 5.1 ou superior
- Executar como Administrador
- Conexão com internet

**Linux:**
- Ubuntu 20.04+ ou Debian 10+
- Bash 4.0+
- Sudo/root access
- Conexão com internet

### Fluxo de Instalação Recomendado

**1. No Windows DC01:**

```powershell
# 1. Instalar Sysmon
.\setup-sysmon.ps1

# 2. Instalar Wazuh Agent
.\setup-wazuh-agent.ps1

# 3. Gerar atividade de teste
.\generate-activity.ps1 -ActivityType All

# 4. Verificar status
.\check-lab-status.ps1
```

**2. No Ubuntu Lab:**

```bash
# 1. Instalar Wazuh Agent
sudo ./install-wazuh-agent.sh

# 2. Verificar status
sudo systemctl status wazuh-agent

# 3. Ver logs
sudo tail -f /var/ossec/logs/ossec.log
```

---

## Requisitos

### Conectividade

Todos os scripts assumem:
- Wazuh Manager em: `192.168.1.102`
- pfSense Gateway em: `192.168.1.1`
- Acesso à internet para downloads

Se seu lab usa IPs diferentes, edite os scripts.

### Permissões

**Windows:**
- Executar PowerShell como Administrador
- Política de execução: `Set-ExecutionPolicy RemoteSigned`

```powershell
# Verificar política
Get-ExecutionPolicy

# Ajustar se necessário
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Linux:**
- Executar com sudo
- Scripts devem ser executáveis: `chmod +x script.sh`

---

## Solução de Problemas

### ❌ "Script não pode ser carregado" (PowerShell)

**Erro:**
```
O arquivo script.ps1 não pode ser carregado porque a execução de scripts está desabilitada neste sistema.
```

**Solução:**
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

---

### ❌ "Permission denied" (Linux)

**Solução:**
```bash
# Tornar executável
chmod +x script.sh

# Executar com sudo
sudo ./script.sh
```

---

### ❌ Download falha (ambos)

**Causas:**
- Sem conexão com internet
- Firewall bloqueando
- URL mudou

**Solução:**
```powershell
# Windows - Testar conectividade
Test-NetConnection google.com
Test-NetConnection packages.wazuh.com

# Linux
ping -c 4 google.com
curl -I https://packages.wazuh.com
```

---

### ❌ Wazuh Agent não conecta

**Verificar:**

```powershell
# Windows
Test-NetConnection 192.168.1.102 -Port 1514

# Verificar logs
Get-Content "C:\Program Files (x86)\ossec-agent\ossec.log" -Tail 50
```

```bash
# Linux
nc -zv 192.168.1.102 1514

# Verificar logs
sudo tail -f /var/ossec/logs/ossec.log
```

**Firewall bloqueando?**
- Abrir portas 1514/1515 TCP no Manager
- Criar regra no Windows Firewall no cliente

---

## 📊 Matriz de Compatibilidade

| Script | Windows 10/11 | Server 2019/2022 | Ubuntu 20.04+ | Debian 10+ |
|--------|---------------|------------------|---------------|------------|
| setup-sysmon.ps1 | ✅ | ✅ | ❌ | ❌ |
| setup-wazuh-agent.ps1 | ✅ | ✅ | ❌ | ❌ |
| generate-activity.ps1 | ✅ | ✅ | ❌ | ❌ |
| check-lab-status.ps1 | ✅ | ✅ | ❌ | ❌ |
| install-wazuh-agent.sh | ❌ | ❌ | ✅ | ✅ |

---

## 📝 Logs dos Scripts

### Windows

Scripts criam logs em:
```
C:\Temp\
C:\Sysmon\
C:\Program Files (x86)\ossec-agent\ossec.log
```

### Linux

Scripts registram em:
```
/var/log/syslog
/var/ossec/logs/ossec.log
```

---

## 🔒 Segurança

**Atenção:**
- Scripts devem ser executados APENAS em ambiente de laboratório
- Não usar em produção sem revisão completa
- Alguns scripts geram atividade suspeita (para fins de teste)
- `generate-activity.ps1` cria alertas propositalmente

---

## 🛠️ Customização

Todos os scripts podem ser editados para seu ambiente:

**Variáveis comuns para ajustar:**

```powershell
# Windows
$ManagerIP = "192.168.1.102"  # IP do Wazuh Manager
$wazuhVersion = "4.8.0"        # Versão do Wazuh

# Linux
WAZUH_MANAGER="192.168.1.102"
```

---

## 📚 Referências

- [Wazuh Documentation](https://documentation.wazuh.com/)
- [Sysmon Documentation](https://learn.microsoft.com/sysinternals/downloads/sysmon)
- [PowerShell Best Practices](https://docs.microsoft.com/powershell/scripting/developer/cmdlet/cmdlet-development-guidelines)

---

## 🤝 Contribuições

Melhorias e correções são bem-vindas!

Para reportar problemas:
1. Descrever o erro detalhadamente
2. Incluir output do script
3. Incluir sistema operacional e versão
4. Incluir passos para reproduzir

