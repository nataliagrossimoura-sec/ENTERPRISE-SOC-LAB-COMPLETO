# 🧪 Exercícios Práticos - Enterprise SOC Lab

**Autora:** Natália Grossi
**LinkedIn:** [https://www.linkedin.com/in/natália-grossi-26bbb8374](https://www.linkedin.com/in/natália-grossi-26bbb8374)
**Data:** Dezembro/2025

Exercícios hands-on para desenvolver habilidades de Analista SOC, detecção de ameaças e resposta a incidentes.

---

## 📋 Índice

1. [Exercícios de Detecção](#exercícios-de-detecção)
2. [Exercícios de Análise](#exercícios-de-análise)
3. [Exercícios de Resposta](#exercícios-de-resposta)
4. [Desafios Avançados](#desafios-avançados)

---

## Exercícios de Detecção

### 🔹 Exercício 1: Detectar Port Scan com Nmap

**Objetivo:** Detectar escaneamento de rede usando Wazuh e Splunk

**Duração:** 15 minutos

**Passos:**

1. **No Kali Linux, executar Nmap:**
```bash
# Port scan SYN stealth
nmap -sS 192.168.1.51

# Port scan completo
nmap -p- 192.168.1.51

# Service version detection
nmap -sV 192.168.1.51
```

2. **Detectar no Wazuh Dashboard:**
   - Acessar `https://192.168.1.102`
   - Menu → Security Events
   - Filtrar por `rule.id: 5710` ou buscar "port scan"
   - Analisar: Source IP, Target, Timestamp

3. **Detectar no Splunk:**
```spl
index=sysmon EventCode=3
| stats dc(DestinationPort) as unique_ports by SourceIp
| where unique_ports > 20
| sort -unique_ports
```

4. **Análise de pfSense Logs:**
   - pfSense Web UI → Status → System Logs → Firewall
   - Buscar múltiplas tentativas de conexão do IP do Kali

**Perguntas de Análise:**
- Quantas portas foram escaneadas?
- Qual a duração do scan?
- Quais portas estavam abertas?
- O firewall bloqueou alguma tentativa?

---

### 🔹 Exercício 2: Detectar Execução de PowerShell Suspeito

**Objetivo:** Identificar comando PowerShell codificado (técnica T1059.001)

**Duração:** 10 minutos

**Passos:**

1. **No Windows DC01, executar PowerShell suspeito:**
```powershell
# Executar como usuário normal (não admin)

# Comando codificado em base64
$command = "Write-Host 'Teste de comando codificado'"
$bytes = [System.Text.Encoding]::Unicode.GetBytes($command)
$encodedCommand = [Convert]::ToBase64String($bytes)

# Executar
powershell.exe -EncodedCommand $encodedCommand
```

2. **Detectar no Sysmon (Event Viewer):**
   - Event Viewer → Applications and Services Logs → Microsoft → Windows → Sysmon → Operational
   - Filtrar Event ID 1 (Process Creation)
   - Buscar: `Image contém powershell.exe` e `CommandLine contém -enc`

3. **Detectar no Wazuh:**
   - Security Events
   - Buscar rule relacionada a PowerShell
   - Verificar campos: `win.eventdata.image` e `win.eventdata.commandLine`

4. **Query Splunk:**
```spl
index=sysmon EventCode=1 Image="*powershell.exe"
    (CommandLine="*-enc*" OR CommandLine="*-e *" OR CommandLine="*-EncodedCommand*")
| table _time, Computer, User, CommandLine
```

**Análise MITRE ATT&CK:**
- Tática: Execution
- Técnica: T1059.001 (PowerShell)
- Subtécnica: Encoded Commands

---

### 🔹 Exercício 3: Brute Force SSH (Linux)

**Objetivo:** Detectar tentativa de força bruta em serviço SSH

**Duração:** 20 minutos

**Pré-requisito:** SSH habilitado no Ubuntu Lab

1. **No Ubuntu Lab, habilitar SSH:**
```bash
sudo apt install openssh-server -y
sudo systemctl start ssh
sudo systemctl enable ssh
```

2. **No Kali Linux, executar Hydra:**
```bash
# Criar lista de usuários
echo "lab" > users.txt
echo "admin" >> users.txt
echo "root" >> users.txt

# Criar lista de senhas (simples para teste)
echo "password" > passwords.txt
echo "123456" >> passwords.txt
echo "admin" >> passwords.txt
# Adicionar senha correta do lab no final
echo "SuaSenhaReal" >> passwords.txt

# Executar brute force
hydra -L users.txt -P passwords.txt ssh://192.168.1.101 -t 4
```

3. **Detectar no Ubuntu Lab:**
```bash
# Ver tentativas no auth.log
sudo grep "Failed password" /var/log/auth.log | tail -20

# Contar tentativas por IP
sudo grep "Failed password" /var/log/auth.log | awk '{print $(NF-3)}' | sort | uniq -c
```

4. **Detectar no Wazuh Dashboard:**
   - Security Events
   - Buscar: `rule.description: "authentication failed"`
   - Agent: ubuntu-lab
   - Timeline de tentativas

5. **Query Splunk (se configurado para receber syslog):**
```spl
index=linux sourcetype=syslog "Failed password"
| stats count by src_ip, user
| where count > 5
| sort -count
```

**Mitigação:**
```bash
# Bloquear IP atacante via iptables
sudo iptables -A INPUT -s 192.168.1.10 -j DROP

# Ou usar fail2ban (recomendado)
sudo apt install fail2ban -y
```

---

### 🔹 Exercício 4: Detectar Download Suspeito

**Objetivo:** Identificar conexão de rede para download de payload

**Duração:** 15 minutos

**Passos:**

1. **No Windows DC01, simular download:**
```powershell
# Executar PowerShell como usuário normal

# Simular download de arquivo suspeito
$url = "https://www.example.com/suspicious.exe"
$output = "C:\Users\Public\suspicious.exe"

# Usar Invoke-WebRequest (gera Event ID 3 no Sysmon)
Invoke-WebRequest -Uri $url -OutFile $output -ErrorAction SilentlyContinue

# Deletar depois
Remove-Item $output -Force -ErrorAction SilentlyContinue
```

2. **Detectar no Sysmon:**
   - Event ID 3 (Network Connection)
   - Filtrar: `DestinationIp` para IP externo (não 192.168.x.x)
   - Verificar: `Image` (powershell.exe), `DestinationPort` (443)

3. **Query Splunk:**
```spl
index=sysmon EventCode=3 Image="*powershell.exe" DestinationIp!=192.168.*
| table _time, Computer, User, Image, DestinationIp, DestinationPort
| sort -_time
```

4. **Detectar no Wazuh:**
   - Buscar eventos Sysmon Event ID 3
   - Filtrar conexões externas de powershell.exe

**Análise:**
- Por que é suspeito?
  - PowerShell fazendo conexão externa
  - Download para diretório público
  - URL desconhecida

---

### 🔹 Exercício 5: Persistence via Registry

**Objetivo:** Detectar criação de chave de inicialização automática no registro

**Duração:** 10 minutos

**Passos:**

1. **No Windows DC01, criar persistence:**
```powershell
# Como usuário normal

# Adicionar chave de Run no registro (HKCU - não requer admin)
$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$name = "TestPersistence"
$value = "C:\Windows\System32\notepad.exe"

New-ItemProperty -Path $regPath -Name $name -Value $value -PropertyType String -Force

# Verificar
Get-ItemProperty -Path $regPath | Select-Object TestPersistence

# Remover depois
Remove-ItemProperty -Path $regPath -Name $name
```

2. **Detectar no Sysmon:**
   - Event ID 13 (Registry Value Set)
   - Filtrar: `TargetObject` contém `\Run\` ou `\RunOnce\`

3. **Query Splunk:**
```spl
index=sysmon EventCode=13
    (TargetObject="*\\Run\\*" OR TargetObject="*\\RunOnce\\*")
| table _time, Computer, User, Image, TargetObject, Details
```

4. **Wazuh Detection:**
   - Buscar eventos Sysmon 13
   - Verificar modificações em chaves de persistência

**MITRE ATT&CK:**
- Tática: Persistence
- Técnica: T1547.001 (Registry Run Keys / Startup Folder)

---

## Exercícios de Análise

### 🔹 Exercício 6: Investigar Timeline de Ataque

**Objetivo:** Reconstruir sequência de eventos de um ataque simulado

**Duração:** 30 minutos

**Cenário:**
1. Atacante faz port scan
2. Descobre serviço vulnerável
3. Executa exploit
4. Estabelece persistência
5. Exfiltra dados

**Passos:**

1. **Executar sequência de ataque (no Kali):**
```bash
# 1. Port scan
nmap -sS 192.168.1.51

# 2. Simular descoberta de SMB
nmap -p 445 192.168.1.51
```

2. **No Windows DC01 (simular exploit):**
```powershell
# 3. Simular execução de payload
Start-Process powershell -ArgumentList "-NoProfile","-Command","Write-Host 'Payload executado'"

# 4. Criar persistência
$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
New-ItemProperty -Path $regPath -Name "Backdoor" -Value "C:\Windows\System32\cmd.exe" -Force

# 5. Simular exfiltração (conexão externa)
Test-NetConnection google.com -Port 443
```

3. **Análise no Wazuh:**
   - Filtrar eventos do último 1 hora
   - Agent: DC01
   - Ordenar cronologicamente
   - Identificar cada fase do ataque

4. **Análise no Splunk:**
```spl
index=sysmon host=DC01 earliest=-1h
| table _time, EventCode, Image, CommandLine, DestinationIp, TargetObject
| sort _time
```

5. **Criar Timeline:**
```
Hora    | Evento                  | Evidência
--------|-------------------------|---------------------------
10:15   | Port Scan               | pfSense logs, múltiplas conexões
10:17   | PowerShell executado    | Sysmon Event ID 1
10:18   | Registry modificado     | Sysmon Event ID 13
10:19   | Conexão externa         | Sysmon Event ID 3
```

**Relatório:**
- Reconstruir Kill Chain
- Mapeamento MITRE ATT&CK
- Recomendações de mitigação

---

### 🔹 Exercício 7: Correlação de Eventos

**Objetivo:** Correlacionar eventos de múltiplas fontes

**Duração:** 25 minutos

**Tarefa:**
Analisar falhas de autenticação seguidas de sucesso (possível brute force bem-sucedido)

**Passos:**

1. **Gerar eventos de teste:**
```powershell
# No Windows DC01

# Tentativas falhadas
for ($i=1; $i -le 10; $i++) {
    runas /user:Administrator notepad.exe 2>$null
    # Pressionar Ctrl+C ou esperar timeout
}

# Tentativa bem-sucedida
runas /user:Administrator notepad.exe
# Digitar senha correta
```

2. **Query Splunk para correlação:**
```spl
index=main source=WinEventLog:Security (EventCode=4625 OR EventCode=4624)
| eval event_type=case(EventCode==4625, "Failed", EventCode==4624, "Success")
| stats count by Account_Name, src_ip, event_type
| where event_type=="Failed" OR event_type=="Success"
```

3. **Análise temporal:**
```spl
index=main source=WinEventLog:Security (EventCode=4625 OR EventCode=4624) Account_Name="Administrator"
| timechart count by EventCode
```

4. **Identificar padrão:**
   - X tentativas falhadas → 1 sucesso = Possível brute force

**Alerta sugerido:**
- Criar regra: "> 5 falhas + 1 sucesso em 5 minutos"

---

## Exercícios de Resposta

### 🔹 Exercício 8: Isolar Endpoint Comprometido

**Objetivo:** Procedimento de contenção de incidente

**Duração:** 15 minutos

**Cenário:** Ubuntu Lab foi comprometido e está enviando tráfego suspeito

**Passos de Contenção:**

1. **Identificar tráfego suspeito:**
```bash
# No Ubuntu Lab
sudo netstat -tulpn | grep ESTABLISHED
sudo tcpdump -i enp0s3 -nn -c 20
```

2. **Isolar da rede (opção 1 - firewall local):**
```bash
# Bloquear todo tráfego exceto SSH do SOC
sudo iptables -P INPUT DROP
sudo iptables -P OUTPUT DROP
sudo iptables -P FORWARD DROP

# Permitir apenas loopback
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A OUTPUT -o lo -j ACCEPT

# Permitir SSH do IP do analista (para investigação)
sudo iptables -A INPUT -p tcp -s 192.168.1.0/24 --dport 22 -j ACCEPT
sudo iptables -A OUTPUT -p tcp --sport 22 -j ACCEPT
```

3. **Isolar da rede (opção 2 - pfSense):**
   - pfSense Web UI → Firewall → Rules
   - LAN tab → Add rule
   - Action: Block
   - Source: 192.168.1.101
   - Destination: Any
   - Save & Apply

4. **Capturar memória e disco (forense):**
```bash
# Capturar processos
ps aux > /tmp/processes.txt

# Capturar conexões de rede
netstat -tulpn > /tmp/connections.txt

# Capturar usuários logados
w > /tmp/logged_users.txt

# Copiar logs críticos
sudo cp /var/log/auth.log /tmp/
sudo cp /var/log/syslog /tmp/
```

5. **Snapshot da VM (preservar evidência):**
   - VirtualBox → VM → Snapshots → Take Snapshot
   - Nome: "Incidente-YYYY-MM-DD-HH-MM"

6. **Documentar:**
   - Hora do incidente
   - IOCs identificados (IPs, processos, arquivos)
   - Ações tomadas
   - Próximos passos

---

### 🔹 Exercício 9: Análise Forense Básica

**Objetivo:** Investigar artefatos pós-incidente

**Duração:** 30 minutos

**Cenário:** Windows DC01 teve execução suspeita de malware

**Artefatos a Analisar:**

1. **Prefetch Files (executáveis recentes):**
```powershell
Get-ChildItem C:\Windows\Prefetch\*.pf |
    Select-Object Name, LastWriteTime |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 20
```

2. **UserAssist (programas executados pelo usuário):**
```powershell
# Via registro
$path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\UserAssist\*\Count"
Get-ItemProperty $path | Format-List
```

3. **Eventos de Processo (Sysmon):**
```powershell
# Processos criados na última hora
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -MaxEvents 1000 |
    Where-Object {$_.Id -eq 1 -and $_.TimeCreated -gt (Get-Date).AddHours(-1)} |
    Select-Object TimeCreated, Message |
    Format-Table -Wrap
```

4. **Analisar MFT (Master File Table) - arquivos criados/modificados:**
```powershell
# Arquivos criados/modificados na última 24h
Get-ChildItem C:\ -Recurse -ErrorAction SilentlyContinue |
    Where-Object {$_.LastWriteTime -gt (Get-Date).AddDays(-1)} |
    Select-Object FullName, LastWriteTime, Length |
    Sort-Object LastWriteTime -Descending |
    Export-Csv C:\Temp\recent_files.csv
```

5. **Browser History (se aplicável):**
```powershell
# Chrome history
$chromePath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\History"
if (Test-Path $chromePath) {
    Copy-Item $chromePath -Destination C:\Temp\chrome_history.db
}
```

6. **Criar Relatório:**
```powershell
# Compilar informações
$report = @{
    Hostname = $env:COMPUTERNAME
    Date = Get-Date
    Processes = Get-Process | Select-Object Name, Id, Path
    Services = Get-Service | Where-Object {$_.Status -eq "Running"}
    NetworkConnections = Get-NetTCPConnection | Where-Object {$_.State -eq "Established"}
}

$report | ConvertTo-Json | Out-File C:\Temp\forensic_report.json
```

---

## Desafios Avançados

### 🔹 Desafio 1: Detectar Lateral Movement

**Objetivo:** Identificar movimento lateral usando Psexec ou RDP

**Dificuldade:** ⭐⭐⭐⭐

**Cenário:**
- Atacante compromete DC01
- Usa credenciais para acessar Ubuntu Lab via SSH

**Indicadores:**
- Logon Type 3 (Network) ou Type 10 (RemoteInteractive)
- Novo processo criado por usuário remoto
- Conexão SMB/RDP de endpoint incomum

**Detecção:**
```spl
# Splunk - Logon Type 3 (Network)
index=main source=WinEventLog:Security EventCode=4624 Logon_Type=3
| stats count by Account_Name, src_ip, Computer
| where count > 1
```

```bash
# Linux - SSH de IP incomum
sudo grep "Accepted" /var/log/auth.log | awk '{print $11}' | sort | uniq -c
```

---

### 🔹 Desafio 2: Detectar Data Exfiltration

**Objetivo:** Identificar transferência anormal de dados

**Dificuldade:** ⭐⭐⭐⭐⭐

**Técnicas:**
- Monitorar volume de upload
- Detectar conexões a serviços de file-sharing
- Arquivos sendo compactados antes de envio

**Indicators:**
1. Criação de arquivo .zip grande
2. Upload via PowerShell Invoke-WebRequest
3. Conexão externa prolongada com alto throughput

**Detecção:**
```spl
# Splunk - Sysmon Event 11 (File Created) + Event 3 (Network)
index=sysmon EventCode=11 TargetFilename="*.zip"
| eval file_size_mb=TargetFileSize/1048576
| where file_size_mb > 50
| join Computer [search index=sysmon EventCode=3 DestinationIp!=192.168.*]
```

---

### 🔹 Desafio 3: Caça a Ameaças (Threat Hunting)

**Objetivo:** Buscar proativamente por ameaças desconhecidas

**Dificuldade:** ⭐⭐⭐⭐⭐

**Hipótese:** Há um processo executando com privilégios elevados de forma incomum

**Metodologia:**

1. **Baseline normal:**
```powershell
# Coletar processos "normais" durante 1 semana
Get-Process | Select-Object Name, Path, Company | Export-Csv baseline.csv -Append
```

2. **Buscar anomalias:**
```spl
# Processos sem assinatura digital
index=sysmon EventCode=1 SignatureStatus!="Valid"
| stats count by Image
| sort -count
```

3. **Processos de locais incomuns:**
```spl
index=sysmon EventCode=1
    (Image="*\\AppData\\*" OR
     Image="*\\Temp\\*" OR
     Image="*\\Users\\Public\\*")
| table _time, Computer, User, Image, CommandLine
```

4. **DLLs não assinadas sendo carregadas:**
```spl
index=sysmon EventCode=7 Signed!=true
| stats count by ImageLoaded
| sort -count
```

---

## 📝 Checklist de Conclusão

Após completar os exercícios, você deve ser capaz de:

- [ ] Detectar port scans e network reconnaissance
- [ ] Identificar execução de PowerShell malicioso
- [ ] Reconhecer tentativas de brute force
- [ ] Detectar downloads e conexões suspeitas
- [ ] Identificar técnicas de persistence
- [ ] Correlacionar eventos de múltiplas fontes
- [ ] Reconstruir timeline de ataque
- [ ] Executar procedimentos de contenção
- [ ] Realizar análise forense básica
- [ ] Mapear técnicas para MITRE ATT&CK
- [ ] Criar queries efetivas em Splunk
- [ ] Utilizar Wazuh Dashboard para investigação
- [ ] Documentar incidentes adequadamente

---

## 🎓 Próximos Passos

1. **Praticar regularmente** - Repetir exercícios até dominar
2. **Criar suas próprias regras** - Desenvolver detecções personalizadas
3. **Estudar MITRE ATT&CK** - Entender táticas e técnicas
4. **Participar de CTFs** - Competições de segurança
5. **Ler relatórios de incidentes reais** - Aprender com casos reais

---

## 📚 Recursos Adicionais

- [SANS FOR500](https://www.sans.org/cyber-security-courses/windows-forensic-analysis/)
- [MITRE ATT&CK Navigator](https://mitre-attack.github.io/attack-navigator/)
- [Wazuh Ruleset](https://documentation.wazuh.com/current/user-manual/ruleset/index.html)
- [Splunk Search Tutorial](https://docs.splunk.com/Documentation/Splunk/latest/SearchTutorial)

