# 🎯 Casos de Uso - Enterprise SOC Lab

Casos de uso práticos e cenários reais para treinar detecção e resposta a incidentes.

---

## 📋 Índice

1. [Casos de Uso Básicos](#casos-de-uso-básicos)
2. [Casos de Uso Intermediários](#casos-de-uso-intermediários)
3. [Casos de Uso Avançados](#casos-de-uso-avançados)
4. [Cenários de Resposta a Incidentes](#cenários-de-resposta-a-incidentes)

---

## Casos de Uso Básicos

### 🔹 Caso 1: Detecção de Failed Logon Attempts

**Cenário:**
Usuário errou senha 5 vezes seguidas ao tentar fazer login.

**MITRE ATT&CK:** T1110 (Brute Force)

**Simulação:**
```powershell
# No Windows DC01
# Tentar login com senha errada 5 vezes
runas /user:Administrator notepad
# Digitar senha errada
# Repetir 5 vezes
```

**Detecção:**

**Event Viewer:**
- Event ID: 4625 (Failed Logon)
- Filtrar: Logon Type 2 ou 3

**Splunk Query:**
```spl
index=main source=WinEventLog:Security EventCode=4625
| stats count by Account_Name, src_ip
| where count >= 5
| sort -count
```

**Wazuh Dashboard:**
- Security Events → Filtrar por rule.id: 5710
- Verificar múltiplas ocorrências

**Resposta:**
1. Identificar se é tentativa de brute force ou erro legítimo
2. Verificar IP de origem
3. Se malicioso: bloquear IP, resetar senha
4. Notificar usuário

---

### 🔹 Caso 2: Novo Processo Criado em Diretório Suspeito

**Cenário:**
Processo executável criado em C:\Users\Public\ ou C:\Windows\Temp\

**MITRE ATT&CK:** T1204 (User Execution)

**Simulação:**
```powershell
# Copiar notepad para diretório suspeito
Copy-Item C:\Windows\System32\notepad.exe C:\Users\Public\suspicious.exe

# Executar
C:\Users\Public\suspicious.exe

# Limpar
Remove-Item C:\Users\Public\suspicious.exe -Force
```

**Detecção:**

**Sysmon Event ID 1:**
```spl
index=sysmon EventCode=1
    (Image="C:\\Users\\Public\\*" OR Image="C:\\Windows\\Temp\\*")
| table _time, User, Image, CommandLine, ParentImage
```

**Wazuh:**
- Buscar eventos Sysmon com path suspeito
- Verificar processo pai

**Análise:**
1. Processo legítimo em local suspeito?
2. Quem criou o arquivo?
3. De onde foi baixado?
4. Hash do arquivo (VirusTotal)

---

### 🔹 Caso 3: Modificação de Chave de Registro (Persistence)

**Cenário:**
Malware adiciona entrada em Run key para persistência.

**MITRE ATT&CK:** T1547.001 (Registry Run Keys)

**Simulação:**
```powershell
# Adicionar chave de Run
$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
Set-ItemProperty -Path $regPath -Name "WindowsUpdate" -Value "C:\Users\Public\malware.exe"

# Verificar
Get-ItemProperty -Path $regPath

# Limpar
Remove-ItemProperty -Path $regPath -Name "WindowsUpdate"
```

**Detecção:**

**Sysmon Event ID 13:**
```spl
index=sysmon EventCode=13
    (TargetObject="*\\Run\\*" OR TargetObject="*\\RunOnce\\*")
| table _time, Image, TargetObject, Details
```

**Resposta:**
1. Identificar processo que modificou registry
2. Verificar executável referenciado
3. Remover chave maliciosa
4. Escanear sistema

---

### 🔹 Caso 4: Conexão de Rede para IP Externo

**Cenário:**
PowerShell estabeleceu conexão para IP externo suspeito.

**MITRE ATT&CK:** T1071 (Application Layer Protocol)

**Simulação:**
```powershell
# Testar conexão externa
Test-NetConnection 1.2.3.4 -Port 443

# Ou simular download
Invoke-WebRequest -Uri "http://example.com/file.txt" -OutFile "C:\Temp\test.txt"
```

**Detecção:**

**Sysmon Event ID 3:**
```spl
index=sysmon EventCode=3 DestinationIp!=192.168.* DestinationIp!=127.0.0.1
| table _time, Image, DestinationIp, DestinationPort
| where Image like "%powershell%"
```

**Análise:**
1. IP de destino legítimo?
2. Porta usada (80, 443, outras?)
3. Volume de dados transferidos
4. Processo que iniciou conexão

---

## Casos de Uso Intermediários

### 🔹 Caso 5: PowerShell Execution com Comando Codificado

**Cenário:**
Atacante executa comando PowerShell codificado em Base64.

**MITRE ATT&CK:** T1059.001 (PowerShell) + T1027 (Obfuscated Files)

**Simulação:**
```powershell
# Criar comando codificado
$command = "Write-Host 'Este é um comando codificado'"
$bytes = [System.Text.Encoding]::Unicode.GetBytes($command)
$encodedCommand = [Convert]::ToBase64String($bytes)

# Executar
powershell.exe -EncodedCommand $encodedCommand
```

**Detecção:**

**Sysmon Event ID 1:**
```spl
index=sysmon EventCode=1 Image="*powershell.exe"
    (CommandLine="*-enc*" OR CommandLine="*-EncodedCommand*" OR CommandLine="*-e *")
| table _time, User, CommandLine, ParentImage
```

**Decodificar comando:**
```powershell
# Pegar string Base64 do log
$encoded = "<STRING_BASE64_DO_LOG>"
$bytes = [Convert]::FromBase64String($encoded)
[System.Text.Encoding]::Unicode.GetString($bytes)
```

**Resposta:**
1. Decodificar comando
2. Analisar intenção
3. Identificar origem (processo pai)
4. Bloquear execução futura

---

### 🔹 Caso 6: Service Installation (Backdoor)

**Cenário:**
Atacante instala serviço malicioso para persistência.

**MITRE ATT&CK:** T1543.003 (Create or Modify System Process: Windows Service)

**Simulação:**
```powershell
# Criar serviço de teste (requer admin)
New-Service -Name "WindowsUpdateService" `
    -BinaryPathName "C:\Windows\System32\calc.exe" `
    -DisplayName "Windows Update Service" `
    -StartupType Automatic

# Verificar
Get-Service -Name "WindowsUpdateService"

# Limpar
Stop-Service -Name "WindowsUpdateService" -Force
Remove-Service -Name "WindowsUpdateService"
```

**Detecção:**

**Event ID 4697 (Service Installed):**
```spl
index=main source=WinEventLog:Security EventCode=4697
| table _time, Service_Name, Service_File_Name, Account_Name
```

**Análise:**
1. Nome do serviço legítimo?
2. Executável em local suspeito?
3. Quem instalou (usuário/processo)?
4. Startup type automático?

---

### 🔹 Caso 7: File Download via Certutil (LOLBin)

**Cenário:**
Uso de certutil.exe para download de arquivo malicioso.

**MITRE ATT&CK:** T1105 (Ingress Tool Transfer)

**Simulação:**
```powershell
# Download usando certutil
certutil.exe -urlcache -f http://example.com/file.txt C:\Users\Public\downloaded.txt

# Limpar
Remove-Item C:\Users\Public\downloaded.txt -Force
certutil.exe -urlcache -f http://example.com/file.txt delete
```

**Detecção:**

```spl
index=sysmon EventCode=1 Image="*certutil.exe"
    CommandLine="*-urlcache*"
| table _time, User, CommandLine, ParentImage
```

**Resposta:**
1. Verificar URL de origem
2. Analisar arquivo baixado
3. Identificar processo que chamou certutil
4. Bloquear certutil para usuários normais

---

### 🔹 Caso 8: Scheduled Task Creation

**Cenário:**
Tarefa agendada criada para executar payload periodicamente.

**MITRE ATT&CK:** T1053.005 (Scheduled Task/Job: Scheduled Task)

**Simulação:**
```powershell
# Criar tarefa agendada suspeita
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-Command Write-Host 'teste'"
$trigger = New-ScheduledTaskTrigger -Daily -At 10:00AM
Register-ScheduledTask -TaskName "SystemMaintenance" -Action $action -Trigger $trigger

# Verificar
Get-ScheduledTask -TaskName "SystemMaintenance"

# Limpar
Unregister-ScheduledTask -TaskName "SystemMaintenance" -Confirm:$false
```

**Detecção:**

**Sysmon Event ID 1 (schtasks.exe):**
```spl
index=sysmon EventCode=1 Image="*schtasks.exe"
    CommandLine="*/create*"
| table _time, User, CommandLine, ParentImage
```

**Event ID 4698 (Scheduled Task Created):**
```spl
index=main source=WinEventLog:Security EventCode=4698
| table _time, Task_Name, Account_Name
```

---

## Casos de Uso Avançados

### 🔹 Caso 9: Pass-the-Hash Attack (Simulado)

**Cenário:**
Tentativa de usar hash NTLM para autenticação lateral.

**MITRE ATT&CK:** T1550.002 (Use Alternate Authentication Material: Pass the Hash)

**Indicadores:**
- Logon Type 3 (Network) com NTLM
- Múltiplas tentativas de acesso a recursos de rede
- Conta administrativa usada de estação não usual

**Detecção:**
```spl
index=main source=WinEventLog:Security EventCode=4624 Logon_Type=3
| stats count by Account_Name, src_ip, Workstation_Name
| where count > 10
```

**Análise:**
1. Usuário legítimo fazendo muitas conexões?
2. IP de origem esperado?
3. Horário de trabalho normal?

---

### 🔹 Caso 10: Data Exfiltration via DNS Tunneling

**Cenário:**
Dados sendo exfiltrados via queries DNS.

**MITRE ATT&CK:** T1048.003 (Exfiltration Over Alternative Protocol: DNS)

**Indicadores:**
- Alto volume de queries DNS
- Queries para domínios suspeitos
- Subdomínios muito longos ou codificados

**Detecção:**

**Sysmon Event ID 22 (DNS Query):**
```spl
index=sysmon EventCode=22 
| stats count by QueryName, Image
| where count > 100
| sort -count
```

**Análise:**
1. Domínio legítimo?
2. Volume anormal de queries?
3. Padrão nos subdomínios?
4. Processo fazendo queries?

---

## Cenários de Resposta a Incidentes

### 🔹 Cenário IR1: Ransomware Detected

**Alertas:**
- Múltiplos arquivos .encrypted criados
- Processo desconhecido criando arquivos
- Note de resgate (ransom note) detectado

**Resposta:**

**Fase 1: Contenção Imediata**
```powershell
# 1. Isolar máquina da rede
Disable-NetAdapter -Name "Ethernet" -Confirm:$false

# 2. Identificar processo malicioso
Get-Process | Where-Object {$_.StartTime -gt (Get-Date).AddMinutes(-10)} | Select-Object Name, Id, Path

# 3. Matar processo
Stop-Process -Id <PID> -Force

# 4. Snapshot da VM (preservar evidência)
```

**Fase 2: Investigação**
- Identificar primeiro arquivo criptografado
- Buscar processo que iniciou criptografia
- Verificar persistência
- Coletar IOCs

**Fase 3: Erradicação**
- Remover executável malicioso
- Limpar persistência
- Restaurar arquivos de backup

---

### 🔹 Cenário IR2: Compromised Account

**Alertas:**
- Login de conta administrativa de IP incomum
- Horário fora do expediente
- Múltiplas falhas seguidas de sucesso

**Resposta:**

```powershell
# 1. Desabilitar conta
Disable-ADAccount -Identity <USERNAME>

# 2. Forçar logoff de todas as sessões
quser
logoff <SESSION_ID>

# 3. Resetar senha
Set-ADAccountPassword -Identity <USERNAME> -Reset

# 4. Revisar atividades da conta
Get-EventLog -LogName Security -InstanceId 4624,4625,4672 | 
    Where-Object {$_.Message -like "*<USERNAME>*"}
```

---

### 🔹 Cenário IR3: Web Shell Detected

**Alertas:**
- Arquivo .aspx ou .php suspeito em webroot
- Conexões de rede saindo de processo w3wp.exe
- Comandos do sistema sendo executados pelo IIS

**Resposta:**

1. **Isolar servidor web**
2. **Identificar web shell:**
   ```powershell
   Get-ChildItem C:\inetpub\wwwroot -Recurse -Include *.aspx, *.php |
       Where-Object {$_.LastWriteTime -gt (Get-Date).AddDays(-1)}
   ```
3. **Analisar logs IIS**
4. **Remover web shell**
5. **Patch vulnerabilidade explorada**

---

## 📊 Matriz de Casos de Uso

| Caso | Dificuldade | MITRE ID | Tempo | Ferramentas |
|------|-------------|----------|-------|-------------|
| Failed Logon | ⭐ Básico | T1110 | 10min | Event Viewer, Splunk |
| Processo Suspeito | ⭐ Básico | T1204 | 15min | Sysmon, Wazuh |
| Registry Persistence | ⭐⭐ Médio | T1547 | 20min | Sysmon, Splunk |
| Conexão Externa | ⭐⭐ Médio | T1071 | 15min | Sysmon |
| PowerShell Encoded | ⭐⭐ Médio | T1059 | 25min | Sysmon, Splunk |
| Service Install | ⭐⭐⭐ Avançado | T1543 | 30min | Event Viewer |
| Certutil LOLBin | ⭐⭐ Médio | T1105 | 20min | Sysmon |
| Scheduled Task | ⭐⭐⭐ Avançado | T1053 | 30min | Event Viewer, Sysmon |
| Pass-the-Hash | ⭐⭐⭐⭐ Expert | T1550 | 45min | Event Viewer, Splunk |
| DNS Tunneling | ⭐⭐⭐⭐ Expert | T1048 | 60min | Sysmon, pfSense |

---

## 🎯 Exercícios Práticos

### Exercício 1: Simule todos os casos básicos (1-4)
- Execute cada simulação
- Detecte no Wazuh E Splunk
- Documente os Event IDs encontrados
- Crie queries Splunk para cada um

### Exercício 2: Crie playbook de resposta
- Escolha 3 casos de uso
- Documente passo a passo de resposta
- Inclua comandos específicos
- Defina critérios de escalação

### Exercício 3: Mapear para MITRE ATT&CK
- Para cada caso, identifique:
  - Tática
  - Técnica
  - Subtécnica (se houver)
  - Procedimento
  - Detecção
  - Mitigação

---

## 📚 Próximos Passos

Após completar estes casos de uso:

1. Executar [exercícios práticos](11-exercicios-praticos.md)
2. Avançar para [exercícios avançados](12-exercicios-avancados.md)
3. Criar seus próprios casos de uso
4. Documentar detecções no GitHub

---

**Bom treinamento! 🚀**
