# 🎯 Exercícios Avançados - Enterprise SOC Lab

**Autora:** Natália Grossi
**LinkedIn:** [https://www.linkedin.com/in/natália-grossi-26bbb8374](https://www.linkedin.com/in/natália-grossi-26bbb8374)
**Data:** Dezembro/2025

Exercícios avançados para aprofundar habilidades de Analista SOC e Blue Team.

---

## 📋 Índice

1. [Caça a Ameaças (Threat Hunting)](#caça-a-ameaças)
2. [Análise Forense Digital](#análise-forense-digital)
3. [Resposta a Incidentes](#resposta-a-incidentes)
4. [Criação de Regras Customizadas](#criação-de-regras-customizadas)
5. [Desafios de CTF](#desafios-de-ctf)

---

## Caça a Ameaças

### 🔹 Exercício 1: Hunting para Living Off The Land Binaries (LOLBins)

**Objetivo:** Detectar uso malicioso de binários legítimos do Windows

**Duração:** 45 minutos

**Conceito:**
Atacantes usam ferramentas nativas do Windows para evitar detecção.

**Binários Suspeitos:**
- certutil.exe (download de arquivos)
- bitsadmin.exe (transferência de arquivos)
- reg.exe (modificação de registry)
- sc.exe (criação de serviços)
- schtasks.exe (tarefas agendadas)

**Cenário de Ataque:**

```powershell
# No Windows DC01 (simular atividade suspeita)

# 1. Uso de certutil para download
certutil.exe -urlcache -f http://example.com/file.txt C:\Users\Public\file.txt

# 2. Uso de bitsadmin
bitsadmin /transfer myDownloadJob /download /priority normal http://example.com/test.txt C:\Users\Public\test.txt

# 3. Exportar registry
reg.exe export HKLM\SOFTWARE\Microsoft\Windows C:\Users\Public\backup.reg

# 4. Criar tarefa agendada suspeita
schtasks /create /tn "WindowsUpdate" /tr "powershell.exe -enc <base64>" /sc daily /st 10:00
```

**Detecção no Sysmon:**

```spl
# Splunk Query
index=sysmon EventCode=1
    (Image="*certutil.exe" CommandLine="*-urlcache*" OR
     Image="*bitsadmin.exe" CommandLine="*/transfer*" OR
     Image="*reg.exe" CommandLine="*export*" OR
     Image="*schtasks.exe" CommandLine="*/create*")
| table _time, User, Image, CommandLine, ParentImage
| sort -_time
```

**Perguntas de Análise:**
1. Qual processo iniciou o LOLBin?
2. Qual usuário executou o comando?
3. Qual a linha de comando completa?
4. Há padrão de horário na execução?
5. Houve conexão de rede subsequente?

**Criação de Regra Wazuh:**

```xml
<rule id="80110" level="8">
  <if_group>sysmon_event1</if_group>
  <field name="win.eventdata.image">.*certutil.exe</field>
  <field name="win.eventdata.commandLine">.*-urlcache.*</field>
  <description>Certutil usado para download (possível LOLBin abuse)</description>
  <mitre>
    <id>T1105</id> <!-- Ingress Tool Transfer -->
  </mitre>
</rule>
```

---

### 🔹 Exercício 2: Hunting para Credential Dumping

**Objetivo:** Detectar tentativas de extração de credenciais

**Duração:** 40 minutos

**Técnicas Comuns:**
- lsass.exe memory dump
- reg.exe SAM export
- Mimikatz execution
- Task Manager memory dump

**Indicadores para Buscar:**

**1. Acesso ao LSASS:**

```spl
# Splunk
index=sysmon EventCode=10
    TargetImage="C:\\Windows\\System32\\lsass.exe"
| table _time, User, SourceImage, TargetImage, GrantedAccess
```

**2. Exportação de SAM/SYSTEM:**

```spl
index=sysmon EventCode=1
    Image="*reg.exe"
    (CommandLine="*save*HKLM\\sam*" OR CommandLine="*save*HKLM\\system*")
```

**3. Processos suspeitos acessando LSASS:**

```powershell
# PowerShell - Listar processos com handles para LSASS
Get-Process | Where-Object {
    $_.Modules.ModuleName -contains "lsass.exe" -or
    $_.Name -eq "lsass"
}
```

**Simulação (CUIDADO - Apenas em lab isolado):**

```powershell
# Criar dump de LSASS (gera alerta)
# ATENÇÃO: Apenas para fins educacionais!

# Via Task Manager (Sysmon Event 10)
# Abrir Task Manager → Details → lsass.exe → Create Dump File
# (Fazer manualmente, não por script)
```

**Detecção:**

```spl
index=sysmon EventCode=10
| eval AccessType=case(
    GrantedAccess="0x1410", "Read/Query",
    GrantedAccess="0x1010", "Query/VM Read",
    GrantedAccess="0x1438", "Full Access",
    1=1, "Other: ".GrantedAccess
)
| stats count by SourceImage, TargetImage, AccessType, User
| where TargetImage like "%lsass.exe%"
| sort -count
```

---

### 🔹 Exercício 3: Hunting para Lateral Movement

**Objetivo:** Detectar movimento lateral na rede

**Duração:** 50 minutos

**Indicadores:**

**1. Logon Type 3 (Network) de máquinas incomuns:**

```powershell
# Analisar logons remotos
Get-EventLog -LogName Security -InstanceId 4624 |
    Where-Object {$_.ReplacementStrings[8] -eq 3} |
    Select-Object TimeGenerated, 
        @{N='User';E={$_.ReplacementStrings[5]}},
        @{N='SourceIP';E={$_.ReplacementStrings[18]}},
        @{N='LogonType';E={$_.ReplacementStrings[8]}}
```

**2. PSExec ou similares:**

```spl
index=sysmon EventCode=1
    (Image="*psexec.exe" OR
     Image="*psexesvc.exe" OR
     CommandLine="*\\\\*\\ADMIN$*" OR
     CommandLine="*\\\\*\\C$*")
| table _time, Computer, User, Image, CommandLine
```

**3. RDP de máquinas internas:**

```spl
index=main source=WinEventLog:Security EventCode=4624 Logon_Type=10
| stats count by Account_Name, src_ip, Computer
| where src_ip like "192.168.%"
```

**Simulação:**

```powershell
# No Windows DC01
# Simular acesso remoto usando PsExec

# Baixar PsExec (Sysinternals)
# https://live.sysinternals.com/PsExec.exe

# Executar comando remoto (se tiver outra VM Windows)
# .\PsExec.exe \\OUTRA-VM -u Administrator -p Senha cmd /c ipconfig
```

**Análise:**
1. Mapear todas as conexões de rede do último mês
2. Identificar conexões incomuns
3. Verificar se há padrão temporal
4. Correlacionar com criação de processos

---

## Análise Forense Digital

### 🔹 Exercício 4: Timeline Reconstruction

**Objetivo:** Reconstruir linha do tempo de um incidente

**Duração:** 60 minutos

**Cenário:**
Um processo malicioso foi executado. Reconstrua TUDO que aconteceu.

**Etapas:**

**1. Identificar evento inicial:**

```spl
# Splunk - Buscar processo suspeito
index=sysmon EventCode=1
    (Image="*\\temp\\*" OR Image="*\\AppData\\*")
| table _time, User, Image, CommandLine, ParentImage, ParentCommandLine
| sort _time
```

**2. Expandir contexto (antes e depois):**

```spl
# Eventos 5 minutos antes e depois
index=sysmon earliest=-1h latest=now
    Computer="DC01"
| transaction Computer maxspan=10m
| table _time, EventCode, Image, CommandLine
| sort _time
```

**3. Buscar persistência:**

```spl
index=sysmon EventCode=13
    (TargetObject="*\\Run\\*" OR TargetObject="*\\RunOnce\\*")
| table _time, Image, TargetObject, Details
```

**4. Verificar conexões de rede:**

```spl
index=sysmon EventCode=3
    Image="<PROCESSO_SUSPEITO>"
| table _time, DestinationIp, DestinationPort
```

**5. Arquivos criados:**

```spl
index=sysmon EventCode=11
    Image="<PROCESSO_SUSPEITO>"
| table _time, TargetFilename
```

**Deliverable:**
Criar documento com:
- Timeline completa (hora exata de cada evento)
- Diagrama de processo (parent → child)
- IOCs identificados (IPs, arquivos, registry keys)
- Técnicas MITRE ATT&CK mapeadas

---

### 🔹 Exercício 5: Memory Forensics (Conceitual)

**Objetivo:** Entender análise de memória

**Duração:** 30 minutos

**Conceito:**
Análise de dump de memória para identificar artefatos.

**Ferramentas:**
- Volatility (Linux)
- Rekall (Python)

**Passos (Conceitual - sem dump real):**

**1. Criar dump de memória:**

```powershell
# Via Task Manager
# lsass.exe → Create Dump File

# Ou via ProcDump (Sysinternals)
.\procdump.exe -ma lsass.exe lsass.dmp
```

**2. Analisar com Volatility (em Linux):**

```bash
# Identificar profile
volatility -f memory.dmp imageinfo

# Listar processos
volatility -f memory.dmp --profile=Win10x64 pslist

# Listar conexões de rede
volatility -f memory.dmp --profile=Win10x64 netscan

# Extrair processos suspeitos
volatility -f memory.dmp --profile=Win10x64 procdump -p <PID> -D output/

# Buscar por strings
strings memory.dmp | grep -i password
```

**Questões:**
1. Quais processos estavam rodando?
2. Havia injeção de código?
3. Quais DLLs foram carregadas?
4. Havia hooks ou rootkits?

---

## Resposta a Incidentes

### 🔹 Exercício 6: Incident Response Playbook

**Objetivo:** Executar playbook completo de IR

**Duração:** 90 minutos

**Cenário:**
Alerta: "PowerShell com comando codificado detectado no DC01"

**Fase 1: Preparation (5 min)**

- [ ] Verificar se ferramentas estão disponíveis
- [ ] Revisar procedimentos de IR
- [ ] Notificar time (se aplicável)

**Fase 2: Identification (15 min)**

```powershell
# 1. Confirmar o alerta
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" |
    Where-Object {$_.Id -eq 1 -and $_.Message -like "*-enc*"} |
    Select-Object -First 1 |
    Format-List *

# 2. Identificar processo
$suspectPID = <PID_DO_EVENTO>
Get-Process -Id $suspectPID -ErrorAction SilentlyContinue

# 3. Coletar contexto
Get-Process -Id $suspectPID | Select-Object *
```

**Fase 3: Containment (20 min)**

```powershell
# 1. Isolar processo (se ainda rodando)
Stop-Process -Id $suspectPID -Force

# 2. Bloquear IP suspeito (se houver conexão)
New-NetFirewallRule -DisplayName "Block-Malicious-IP" `
    -Direction Outbound `
    -Action Block `
    -RemoteAddress <IP_SUSPEITO>

# 3. Desabilitar conta comprometida (se aplicável)
Disable-ADAccount -Identity <USERNAME>

# 4. Snapshot da VM
# VirtualBox → Snapshots → Take Snapshot
```

**Fase 4: Eradication (15 min)**

```powershell
# 1. Remover arquivos maliciosos
Remove-Item -Path <CAMINHO_SUSPEITO> -Force

# 2. Limpar registry
Remove-ItemProperty -Path <REG_PATH> -Name <VALUE>

# 3. Remover persistência
Get-ScheduledTask | Where-Object {$_.TaskName -like "*suspeito*"} | Unregister-ScheduledTask
```

**Fase 5: Recovery (15 min)**

```powershell
# 1. Restaurar serviços
Start-Service <SERVICE_NAME>

# 2. Re-habilitar conta (após resetar senha)
Set-ADAccountPassword -Identity <USERNAME> -Reset
Enable-ADAccount -Identity <USERNAME>

# 3. Verificar integridade
sfc /scannow
```

**Fase 6: Lessons Learned (20 min)**

Criar documento com:
1. **Resumo Executivo**
2. **Timeline do Incidente**
3. **IOCs Identificados**
4. **Ações Tomadas**
5. **Recomendações**
6. **Melhorias para Detecção**

---

## Criação de Regras Customizadas

### 🔹 Exercício 7: Criar Regra Wazuh para Ataque Específico

**Objetivo:** Desenvolver regra de detecção customizada

**Duração:** 40 minutos

**Tarefa:**
Criar regra para detectar "Kerberoasting" (T1558.003)

**Conceito:**
Atacante solicita Service Tickets para extrair hashes.

**Indicador:**
Event ID 4769 com:
- Ticket Encryption Type = 0x17 (RC4)
- Service Name não termina em $
- Múltiplas requisições em curto período

**Regra Wazuh:**

```xml
<!-- /var/ossec/etc/rules/local_rules.xml -->

<!-- Detecção de Kerberoasting -->
<rule id="80120" level="8">
  <if_sid>60103</if_sid> <!-- Windows Event 4769 -->
  <field name="win.eventdata.ticketEncryptionType">0x17</field>
  <field name="win.eventdata.serviceName" type="pcre2">(?!.*\$$)</field>
  <description>Possível Kerberoasting detectado (Service Ticket Request com RC4)</description>
  <mitre>
    <id>T1558.003</id>
  </mitre>
</rule>

<!-- Múltiplas requisições (frequency) -->
<rule id="80121" level="10" frequency="5" timeframe="60">
  <if_matched_sid>80120</if_matched_sid>
  <same_source_ip />
  <description>Múltiplas tentativas de Kerberoasting do mesmo IP</description>
  <mitre>
    <id>T1558.003</id>
  </mitre>
</rule>
```

**Testar Regra:**

```bash
# No Wazuh Manager
sudo /var/ossec/bin/wazuh-logtest

# Colar evento de teste e verificar se ativa a regra
```

**Validar:**
1. Gerar Event ID 4769 com RC4
2. Verificar se alerta aparece no Dashboard
3. Ajustar level se necessário

---

### 🔹 Exercício 8: Criar Dashboard Splunk Customizado

**Objetivo:** Dashboard de SOC Analyst

**Duração:** 45 minutos

**Painéis a Criar:**

**1. Top 10 Eventos de Segurança (24h)**

```spl
index=main source=WinEventLog:Security earliest=-24h
| stats count by EventCode
| sort -count
| head 10
| lookup event_codes.csv EventCode OUTPUT Description
```

**2. Processos Suspeitos**

```spl
index=sysmon EventCode=1 earliest=-1h
    (Image="*\\temp\\*" OR Image="*\\AppData\\*")
| table _time, Computer, User, Image, CommandLine
| sort -_time
```

**3. Conexões Externas**

```spl
index=sysmon EventCode=3 DestinationIp!=192.168.* earliest=-1h
| stats count by Image, DestinationIp, DestinationPort
| sort -count
```

**4. Timeline de Alertas**

```spl
index=main (EventCode=4625 OR EventCode=4688 OR EventCode=4720) earliest=-24h
| timechart span=1h count by EventCode
```

**5. Top Users com Atividade**

```spl
index=main earliest=-24h
| stats count by User
| sort -count
| head 10
```

---

## Desafios de CTF

### 🔹 Desafio 1: "The Hidden Payload"

**Objetivo:** Encontrar payload oculto no sistema

**Pistas:**
1. Um processo rodou com nome de serviço legítimo
2. Criou arquivo em C:\Windows\Temp
3. Estabeleceu conexão para 1.2.3.4:443
4. Modificou registry para persistência

**Tarefas:**
- [ ] Identificar processo malicioso
- [ ] Encontrar arquivo dropado
- [ ] Capturar registry key de persistência
- [ ] Identificar C2 IP
- [ ] Mapear para MITRE ATT&CK

---

### 🔹 Desafio 2: "Privilege Escalation Hunt"

**Objetivo:** Detectar escalação de privilégio

**Cenário:**
Usuário normal conseguiu executar comando como SYSTEM.

**Investigar:**
- Event ID 4688 (Process Creation)
- Event ID 4672 (Special Privileges Assigned)
- Sysmon Event 1
- Parent/Child process relationship

---

### 🔹 Desafio 3: "Data Exfiltration"

**Objetivo:** Detectar exfiltração de dados

**Indicadores:**
- Arquivo grande (.zip) criado
- Upload via PowerShell ou certutil
- Conexão externa prolongada
- Bandwidth incomum

**Splunk Hunt:**

```spl
index=sysmon EventCode=11 TargetFilename="*.zip"
| join type=inner Computer [
    search index=sysmon EventCode=3 DestinationIp!=192.168.*
]
| table _time, Computer, User, TargetFilename, DestinationIp
```

---

## 📝 Checklist de Progresso

### Caça a Ameaças
- [ ] LOLBins hunting
- [ ] Credential dumping detection
- [ ] Lateral movement detection

### Forense
- [ ] Timeline reconstruction
- [ ] Memory forensics (conceitual)

### Resposta a Incidentes
- [ ] Incident Response playbook executado
- [ ] Documentação de IR criada

### Regras Customizadas
- [ ] Regra Wazuh para Kerberoasting
- [ ] Dashboard Splunk customizado

### Desafios
- [ ] The Hidden Payload resolvido
- [ ] Privilege Escalation detectado
- [ ] Data Exfiltration identificado

---

## 🎓 Recursos Adicionais

- **MITRE ATT&CK Navigator:** https://mitre-attack.github.io/attack-navigator/
- **Splunk Boss of the SOC:** https://www.splunk.com/en_us/blog/conf-splunklive/bots.html
- **Blue Team Labs Online:** https://blueteamlabs.online/
- **CyberDefenders:** https://cyberdefenders.org/

---

**Parabéns por completar os exercícios avançados! 🎉**

Você agora possui habilidades de:
- Threat Hunting proativo
- Análise forense digital
- Resposta estruturada a incidentes
- Criação de detecções customizadas
- Pensamento analítico de SOC Tier 2/3
