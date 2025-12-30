# 📊 Logs e Monitoramento - Enterprise SOC Lab

**Autora:** Natália Grossi
**LinkedIn:** [https://www.linkedin.com/in/natália-grossi-26bbb8374](https://www.linkedin.com/in/natália-grossi-26bbb8374)
**Data:** Dezembro/2025

Guia completo sobre coleta, análise e monitoramento de logs no laboratório SOC.

---

## 📑 Índice

1. [Visão Geral da Coleta](#visão-geral-da-coleta)
2. [Logs do Windows](#logs-do-windows)
3. [Logs do Linux](#logs-do-linux)
4. [Logs de Rede](#logs-de-rede)
5. [Wazuh - Coleta e Correlação](#wazuh---coleta-e-correlação)
6. [Splunk - Análise Profunda](#splunk---análise-profunda)
7. [Alertas e Notificações](#alertas-e-notificações)
8. [Dashboards Essenciais](#dashboards-essenciais)
9. [Retenção e Armazenamento](#retenção-e-armazenamento)

---

## Visão Geral da Coleta

### Pipeline de Logs

```
┌─────────────────────────────────────────────────────────┐
│                   FONTES DE LOGS                        │
└─────────────────────────────────────────────────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
   [Windows DC01]    [Ubuntu Lab]     [pfSense]
   • Sysmon          • Syslog         • Firewall
   • Security        • Auth.log       • DHCP
   • System          • Kern.log       • DNS
   • Application     • Audit          
        │                 │                 │
        └─────────────────┼─────────────────┘
                          ↓
            ┌─────────────────────────────┐
            │    AGENTES DE COLETA        │
            ├─────────────────────────────┤
            │ • Wazuh Agent (DC01)        │
            │ • Wazuh Agent (Ubuntu)      │
            │ • Splunk Forwarder (DC01)   │
            └─────────────┬───────────────┘
                          ↓
        ┌─────────────────┴─────────────────┐
        │                                   │
   [Wazuh Manager]               [Splunk Enterprise]
   192.168.1.102:1514            192.168.1.51:9997
        │                                   │
        ↓                                   ↓
   [Wazuh Indexer]               [Splunk Indexer]
   Elasticsearch                  Internal DB
        │                                   │
        ↓                                   ↓
   [Wazuh Dashboard]             [Splunk Web UI]
   https://192.168.1.102         http://192.168.1.51:8000
```

### Estatísticas de Volume (Estimado)

| Fonte | Eventos/Hora | Tamanho/Dia | Retenção |
|-------|-------------|-------------|----------|
| **Windows Security** | 500-1000 | 50-100 MB | 30 dias |
| **Sysmon** | 2000-5000 | 200-500 MB | 30 dias |
| **Linux Syslog** | 100-500 | 10-50 MB | 30 dias |
| **pfSense** | 50-200 | 5-20 MB | 15 dias |
| **Total** | ~3000-7000 | ~300-700 MB | - |

---

## Logs do Windows

### 1. Windows Security Event Log

**Localização:** `C:\Windows\System32\winevt\Logs\Security.evtx`

**Event IDs Críticos:**

| Event ID | Descrição | Severidade | Uso |
|----------|-----------|------------|-----|
| **4624** | Logon bem-sucedido | Info | Baseline de acesso |
| **4625** | Falha de logon | Warning | Brute force detection |
| **4634** | Logoff | Info | Duração de sessões |
| **4648** | Logon usando credenciais explícitas | Medium | Lateral movement |
| **4672** | Privilégios especiais atribuídos | High | Escalation de privilégio |
| **4688** | Novo processo criado | Info | Process tracking |
| **4697** | Serviço instalado | Medium | Persistence |
| **4720** | Conta de usuário criada | Medium | Account creation |
| **4732** | Membro adicionado a grupo | High | Group changes |
| **4776** | Account logon attempt | Warning | Domain authentication |

**Visualizar:**

```powershell
# Ver eventos mais recentes
Get-EventLog -LogName Security -Newest 50

# Filtrar por Event ID
Get-EventLog -LogName Security -InstanceId 4624 -Newest 100

# Exportar para análise
Get-EventLog -LogName Security -After (Get-Date).AddDays(-1) |
    Export-Csv C:\Logs\security-last24h.csv -NoTypeInformation

# Contar por Event ID
Get-EventLog -LogName Security |
    Group-Object EventID |
    Select-Object Count, Name |
    Sort-Object Count -Descending
```

**Configuração de Auditoria:**

```powershell
# Habilitar auditoria detalhada
auditpol /set /subcategory:"Logon" /success:enable /failure:enable
auditpol /set /subcategory:"Logoff" /success:enable
auditpol /set /subcategory:"Account Logon" /success:enable /failure:enable
auditpol /set /subcategory:"Account Management" /success:enable /failure:enable
auditpol /set /subcategory:"Process Creation" /success:enable /failure:enable
auditpol /set /subcategory:"Process Termination" /success:enable
auditpol /set /subcategory:"Object Access" /success:enable /failure:enable

# Verificar configuração
auditpol /get /category:*
```

---

### 2. Sysmon Operational Log

**Localização:** `Microsoft-Windows-Sysmon/Operational`

**Event IDs Essenciais:**

| Event ID | Nome | Descrição | Detecção |
|----------|------|-----------|----------|
| **1** | Process Creation | Processo iniciado | Malware execution |
| **2** | File Creation Time | Timestamp alterado | Anti-forensics |
| **3** | Network Connection | Conexão TCP/UDP | C2 communication |
| **5** | Process Terminated | Processo encerrado | Process tracking |
| **6** | Driver Loaded | Driver carregado | Rootkit detection |
| **7** | Image Loaded | DLL carregada | DLL injection |
| **8** | CreateRemoteThread | Thread remota | Process injection |
| **10** | Process Access | Acesso a processo | Credential dumping |
| **11** | File Created | Arquivo criado | Dropped files |
| **12** | Registry Object Added/Deleted | Registro criado/deletado | Persistence |
| **13** | Registry Value Set | Valor de registro alterado | Configuration changes |
| **15** | File Stream Created | NTFS stream criado | Hidden data |
| **22** | DNS Query | Query DNS | DNS tunneling |

**Visualizar:**

```powershell
# Ver eventos Sysmon
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -MaxEvents 100

# Filtrar por Event ID
Get-WinEvent -FilterHashtable @{
    LogName='Microsoft-Windows-Sysmon/Operational'
    ID=1
} -MaxEvents 50

# Process Creation com PowerShell
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" |
    Where-Object {$_.Id -eq 1} |
    Where-Object {$_.Message -like "*powershell*"} |
    Select-Object TimeCreated, Message |
    Format-List

# Network connections externas
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" |
    Where-Object {$_.Id -eq 3} |
    Where-Object {$_.Message -notlike "*192.168.*"} |
    Select-Object TimeCreated, Message |
    Format-List
```

**Análise Específica:**

```powershell
# 1. Detectar execução de scripts
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" |
    Where-Object {$_.Id -eq 1 -and ($_.Message -like "*powershell*" -or $_.Message -like "*cmd.exe*")} |
    Select-Object TimeCreated, @{N='Process';E={($_.Message -split "`n")[2]}} |
    Format-Table -AutoSize

# 2. Detectar DLLs não assinadas
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" |
    Where-Object {$_.Id -eq 7 -and $_.Message -like "*Signature: n/a*"} |
    Select-Object TimeCreated, Message |
    Format-List

# 3. Registry persistence
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" |
    Where-Object {$_.Id -eq 13 -and ($_.Message -like "*\Run\*" -or $_.Message -like "*\RunOnce\*")} |
    Select-Object TimeCreated, Message |
    Format-List
```

---

### 3. System e Application Logs

**System Log:**
```powershell
# Erros críticos do sistema
Get-EventLog -LogName System -EntryType Error -Newest 50

# Serviços iniciados/parados
Get-EventLog -LogName System -Source "Service Control Manager" -Newest 100
```

**Application Log:**
```powershell
# Erros de aplicação
Get-EventLog -LogName Application -EntryType Error -Newest 50

# Crashes de aplicação
Get-EventLog -LogName Application -Source "Application Error" -Newest 20
```

---

### 4. PowerShell Logs

**Script Block Logging:**

```powershell
# Habilitar logging avançado
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" -Name "EnableScriptBlockLogging" -Value 1

# Ver logs PowerShell
Get-WinEvent -LogName "Microsoft-Windows-PowerShell/Operational" |
    Where-Object {$_.Id -eq 4104} |
    Select-Object TimeCreated, Message |
    Format-List
```

---

## Logs do Linux

### 1. Syslog

**Localização:** `/var/log/syslog`

**Análise:**

```bash
# Ver últimas linhas
tail -f /var/log/syslog

# Buscar erros
grep -i "error" /var/log/syslog

# Contar por tipo
grep -oP '(?<=: )\w+' /var/log/syslog | sort | uniq -c | sort -nr

# Erros nas últimas 24h
grep -i "error" /var/log/syslog | grep "$(date --date='1 day ago' '+%b %d')"
```

---

### 2. Auth Log

**Localização:** `/var/log/auth.log`

**Análise de Autenticação:**

```bash
# Ver tentativas de SSH
grep "sshd" /var/log/auth.log

# Falhas de autenticação
grep "Failed password" /var/log/auth.log

# Contar IPs com falhas
grep "Failed password" /var/log/auth.log | awk '{print $(NF-3)}' | sort | uniq -c | sort -nr

# Logins bem-sucedidos
grep "Accepted" /var/log/auth.log

# Uso de sudo
grep "sudo" /var/log/auth.log | tail -20

# Tentativas de sudo negadas
grep "sudo.*not allowed" /var/log/auth.log
```

---

### 3. Kern Log

**Localização:** `/var/log/kern.log`

**Análise:**

```bash
# Erros de kernel
grep -i "error" /var/log/kern.log

# Problemas de hardware
grep -i "hardware" /var/log/kern.log

# Segfaults
grep "segfault" /var/log/kern.log
```

---

### 4. Wazuh Agent Log

**Localização:** `/var/ossec/logs/ossec.log`

**Monitorar:**

```bash
# Ver logs em tempo real
sudo tail -f /var/ossec/logs/ossec.log

# Verificar conexão com Manager
grep "Connected to the server" /var/ossec/logs/ossec.log

# Erros de agente
grep "ERROR" /var/ossec/logs/ossec.log

# Alertas gerados
sudo tail -f /var/ossec/logs/alerts/alerts.log
```

---

## Logs de Rede

### 1. pfSense Firewall Logs

**Acesso:** pfSense Web UI → Status → System Logs → Firewall

**Análise via CLI:**

```bash
# SSH no pfSense (admin/senha)
# Logs em tempo real
clog -f /var/log/filter.log

# Últimas 50 linhas
clog /var/log/filter.log | tail -50

# Filtrar bloqueios
clog /var/log/filter.log | grep "block"

# Contar por IP origem
clog /var/log/filter.log | awk '{print $8}' | sort | uniq -c | sort -nr | head -10
```

---

### 2. DHCP Leases

**Acesso:** pfSense Web UI → Status → DHCP Leases

**Via CLI:**

```bash
# Ver leases ativos
cat /var/dhcpd/var/db/dhcpd.leases
```

---

### 3. DNS Logs

**Acesso:** pfSense Web UI → Status → System Logs → DNS Resolver

**Análise:**

```bash
# Queries DNS
clog /var/log/resolver.log | tail -50

# Top domains consultados
clog /var/log/resolver.log | grep "query" | awk '{print $6}' | sort | uniq -c | sort -nr | head -10
```

---

## Wazuh - Coleta e Correlação

### Arquivos de Configuração

**Agente Windows:** `C:\Program Files (x86)\ossec-agent\ossec.conf`

**Agente Linux:** `/var/ossec/etc/ossec.conf`

### Exemplo de Configuração - Windows

```xml
<ossec_config>
  <client>
    <server>
      <address>192.168.1.102</address>
      <port>1514</port>
      <protocol>tcp</protocol>
    </server>
  </client>

  <!-- Windows Security Event Log -->
  <localfile>
    <location>Security</location>
    <log_format>eventchannel</log_format>
  </localfile>

  <!-- Windows System Event Log -->
  <localfile>
    <location>System</location>
    <log_format>eventchannel</log_format>
  </localfile>

  <!-- Sysmon -->
  <localfile>
    <location>Microsoft-Windows-Sysmon/Operational</location>
    <log_format>eventchannel</log_format>
  </localfile>

  <!-- PowerShell -->
  <localfile>
    <location>Microsoft-Windows-PowerShell/Operational</location>
    <log_format>eventchannel</log_format>
  </localfile>
</ossec_config>
```

### Exemplo de Configuração - Linux

```xml
<ossec_config>
  <client>
    <server>
      <address>192.168.1.102</address>
      <port>1514</port>
      <protocol>tcp</protocol>
    </server>
  </client>

  <!-- Syslog -->
  <localfile>
    <log_format>syslog</log_format>
    <location>/var/log/syslog</location>
  </localfile>

  <!-- Auth -->
  <localfile>
    <log_format>syslog</log_format>
    <location>/var/log/auth.log</location>
  </localfile>

  <!-- Kernel -->
  <localfile>
    <log_format>syslog</log_format>
    <location>/var/log/kern.log</location>
  </localfile>
</ossec_config>
```

### Regras Customizadas

**Localização Manager:** `/var/ossec/etc/rules/local_rules.xml`

**Exemplo:**

```xml
<!-- Detectar PowerShell com comando codificado -->
<rule id="80100" level="8">
  <if_group>sysmon_event1</if_group>
  <field name="win.eventdata.image">.*powershell.exe</field>
  <field name="win.eventdata.commandLine">.*-enc.*|.*-e .*|.*-EncodedCommand.*</field>
  <description>PowerShell com comando codificado detectado</description>
  <mitre>
    <id>T1059.001</id>
  </mitre>
</rule>

<!-- Detectar múltiplas falhas de SSH -->
<rule id="80101" level="10" frequency="5" timeframe="300">
  <if_matched_sid>5710</if_matched_sid>
  <same_source_ip />
  <description>Múltiplas tentativas de SSH falhadas do mesmo IP</description>
  <mitre>
    <id>T1110</id>
  </mitre>
</rule>

<!-- Detectar persistence via Registry -->
<rule id="80102" level="8">
  <if_group>sysmon_event13</if_group>
  <field name="win.eventdata.targetObject">.*\\Run\\.*|.*\\RunOnce\\.*</field>
  <description>Modificação em chave de inicialização automática</description>
  <mitre>
    <id>T1547.001</id>
  </mitre>
</rule>
```

### Queries Úteis no Dashboard

**1. Top 10 Alertas:**
```
rule.level: [7 TO 15]
```

**2. Eventos por agente:**
```
agent.name: "DC01"
```

**3. Técnicas MITRE ATT&CK:**
```
rule.mitre.id: *
```

**4. Alertas de alta severidade:**
```
rule.level: >= 10
```

---

## Splunk - Análise Profunda

### Inputs Configurados

**Windows DC01:** `C:\Program Files\Splunk\etc\system\local\inputs.conf`

```ini
[monitor://C:\Windows\System32\winevt\Logs\Security.evtx]
disabled = false
index = main
sourcetype = WinEventLog:Security

[monitor://C:\Windows\System32\winevt\Logs\System.evtx]
disabled = false
index = main
sourcetype = WinEventLog:System

[WinEventLog://Microsoft-Windows-Sysmon/Operational]
disabled = false
index = sysmon
sourcetype = XmlWinEventLog:Microsoft-Windows-Sysmon/Operational
```

### Searches Essenciais

**1. Baseline de Processos:**
```spl
index=sysmon EventCode=1
| stats count by Image
| sort -count
| head 50
```

**2. Conexões de Rede Externas:**
```spl
index=sysmon EventCode=3 DestinationIp!=192.168.*
| table _time, Computer, User, Image, DestinationIp, DestinationPort
| sort -_time
```

**3. Detecção de Brute Force:**
```spl
index=main source=WinEventLog:Security EventCode=4625
| stats count by Account_Name, src_ip
| where count > 10
| sort -count
```

**4. Process Tree:**
```spl
index=sysmon EventCode=1
| eval parent_process=ParentImage
| eval child_process=Image
| table _time, Computer, User, parent_process, child_process, CommandLine
```

**5. PowerShell Suspeito:**
```spl
index=sysmon EventCode=1 Image="*powershell.exe"
    (CommandLine="*DownloadString*" OR
     CommandLine="*IEX*" OR
     CommandLine="*Invoke-Expression*" OR
     CommandLine="*-enc*")
| table _time, Computer, User, CommandLine
```

---

## Alertas e Notificações

### Wazuh - Integração com Email

**Configuração:** `/var/ossec/etc/ossec.conf`

```xml
<global>
  <email_notification>yes</email_notification>
  <smtp_server>smtp.gmail.com</smtp_server>
  <email_from>soc@empresa.com</email_from>
  <email_to>analista@empresa.com</email_to>
  <email_maxperhour>12</email_maxperhour>
</global>

<email_alerts>
  <email_to>analista@empresa.com</email_to>
  <level>10</level>
  <do_not_delay />
</email_alerts>
```

### Splunk - Alertas

**Criar Alerta:**
1. Search & Reporting
2. Criar query
3. Save As → Alert
4. Trigger conditions: Number of results > X
5. Actions: Email, Webhook, Script

**Exemplo de Alerta:**
```spl
index=main source=WinEventLog:Security EventCode=4625
| stats count by Account_Name
| where count > 10
```

---

## Dashboards Essenciais

### Dashboard 1: Security Overview

**Painéis:**
- Total de eventos (últimas 24h)
- Eventos por severidade (pie chart)
- Timeline de alertas (line chart)
- Top 5 agentes com mais alertas
- Top 10 regras ativadas

### Dashboard 2: Authentication Monitoring

**Painéis:**
- Logins bem-sucedidos vs falhados
- Top usuários com falhas
- Mapa geográfico de IPs (se aplicável)
- Timeline de autenticações

### Dashboard 3: Process Monitoring

**Painéis:**
- Processos criados (últimas 24h)
- Top processos
- Processos de locais suspeitos
- PowerShell executions

### Dashboard 4: Network Monitoring

**Painéis:**
- Conexões externas
- Top destination IPs
- Top destination ports
- DNS queries

---

## Retenção e Armazenamento

### Políticas Recomendadas

| Tipo de Log | Retenção Wazuh | Retenção Splunk | Backup |
|-------------|----------------|-----------------|--------|
| **Critical Alerts** | 90 dias | 90 dias | Sim |
| **Security Events** | 30 dias | 30 dias | Sim |
| **Sysmon** | 30 dias | 30 dias | Não |
| **System/Application** | 15 dias | 15 dias | Não |
| **Network Logs** | 15 dias | 15 dias | Não |

### Gerenciar Espaço

**Wazuh:**
```bash
# Verificar uso de disco
du -sh /var/ossec/logs/
du -sh /var/lib/wazuh-indexer/

# Limpar logs antigos (cuidado!)
find /var/ossec/logs/archives/ -mtime +30 -delete
```

**Splunk:**
```powershell
# Verificar uso
Get-ChildItem "C:\Program Files\Splunk\var\lib\splunk\" -Recurse | 
    Measure-Object -Property Length -Sum

# Configurar retenção
# Via Web UI: Settings → Indexes → Edit → Max Days (30)
```

---

## 🎯 Checklist de Monitoramento

- [ ] Todos os agentes Wazuh conectados
- [ ] Splunk recebendo logs do DC01
- [ ] Sysmon gerando eventos
- [ ] pfSense logging habilitado
- [ ] Alertas críticos configurados
- [ ] Dashboards criados
- [ ] Política de retenção definida
- [ ] Backup de configurações realizado

---

## 📚 Referências

- [Wazuh Ruleset Documentation](https://documentation.wazuh.com/current/user-manual/ruleset/index.html)
- [Splunk Search Reference](https://docs.splunk.com/Documentation/Splunk/latest/SearchReference)
- [Sysmon Configuration](https://github.com/SwiftOnSecurity/sysmon-config)
- [Windows Event IDs](https://www.ultimatewindowssecurity.com/securitylog/encyclopedia/)
