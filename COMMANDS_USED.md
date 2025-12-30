# 💻 Comandos Utilizados - Enterprise SOC Lab

**Autora:** Natália Grossi
**LinkedIn:** [https://www.linkedin.com/in/natália-grossi-26bbb8374](https://www.linkedin.com/in/natália-grossi-26bbb8374)
**Data:** Dezembro/2025

Referência completa de comandos Linux e PowerShell usados no laboratório SOC.

---

## 📑 Índice

1. [Comandos Linux](#comandos-linux)
2. [Comandos PowerShell](#comandos-powershell)
3. [Consultas Splunk (SPL)](#consultas-splunk-spl)
4. [Comandos Wazuh](#comandos-wazuh)
5. [Comandos de Rede](#comandos-de-rede)
6. [Análise de Logs](#análise-de-logs)

---

## Comandos Linux

### Navegação e Arquivos

```bash
# Listar arquivos detalhadamente
ls -la

# Listar com tamanho legível
ls -lh

# Ordenar por tamanho
ls -lS

# Ordenar por data de modificação
ls -lt

# Mudar diretório
cd /caminho/para/diretorio
cd ~  # Home do usuário
cd -  # Voltar ao diretório anterior

# Mostrar diretório atual
pwd

# Criar diretórios
mkdir nome_pasta
mkdir -p /caminho/completo/para/pasta  # Criar recursivo

# Remover diretórios
rmdir pasta_vazia
rm -rf pasta_com_conteudo  # CUIDADO: Remove tudo recursivamente

# Copiar arquivos/pastas
cp arquivo.txt backup.txt
cp -r pasta/ pasta_copia/  # Recursivo

# Mover/renomear
mv arquivo_antigo.txt arquivo_novo.txt
mv pasta/ /novo/local/

# Encontrar arquivos
find / -name "*.log" -type f
find . -name "sysmon*" 2>/dev/null
find /var/log -mtime -7  # Modificados nos últimos 7 dias
```

### Visualizar e Editar Arquivos

```bash
# Ver arquivo completo
cat arquivo.log

# Ver com número de linhas
cat -n arquivo.log

# Ver primeiras linhas
head -n 20 arquivo.log

# Ver últimas linhas
tail -n 20 arquivo.log

# Monitorar arquivo em tempo real
tail -f arquivo.log
tail -f /var/log/syslog

# Editor de texto
nano arquivo.txt
vim arquivo.txt

# Contar linhas, palavras, bytes
wc -l arquivo.log  # Linhas
wc -w arquivo.log  # Palavras
wc -c arquivo.log  # Bytes

# Ver tamanho de arquivos
du -h arquivo.log
du -sh /var/log  # Tamanho total da pasta

# Espaço em disco
df -h
```

### Processar Texto e Logs

```bash
# GREP - Buscar padrões
grep "erro" arquivo.log
grep -i "ERRO" arquivo.log  # Case-insensitive
grep -c "erro" arquivo.log  # Contar ocorrências
grep -n "erro" arquivo.log  # Mostrar número da linha
grep -v "info" arquivo.log  # Inverter match (excluir linhas com "info")
grep -r "password" /var/log/  # Busca recursiva

# Buscar múltiplos padrões
grep -E "erro|falha|fail" arquivo.log

# SED - Editar fluxo
sed 's/antigo/novo/' arquivo.log  # Substituir primeira ocorrência
sed 's/antigo/novo/g' arquivo.log  # Substituir todas
sed -n '10,20p' arquivo.log  # Imprimir linhas 10 a 20
sed '/padrão/d' arquivo.log  # Deletar linhas com padrão

# AWK - Processar colunas
awk '{print $1, $3}' arquivo.log  # Imprimir colunas 1 e 3
awk -F':' '{print $1}' /etc/passwd  # Mudar delimitador
awk '{sum+=$2} END {print sum}' numeros.txt  # Somar coluna 2

# Exemplo: Contar IPs únicos em log Apache
awk '{print $1}' /var/log/apache2/access.log | sort | uniq -c | sort -nr

# CUT - Extrair campos
cut -d' ' -f1 arquivo.log  # Campo 1 separado por espaço
cut -c1-10 arquivo.log  # Caracteres 1 a 10

# SORT e UNIQ
sort arquivo.txt  # Ordenar alfabeticamente
sort -n numeros.txt  # Ordenar numericamente
sort -r arquivo.txt  # Ordem reversa
sort | uniq  # Remove duplicatas
sort | uniq -c  # Conta duplicatas
sort | uniq -d  # Mostra apenas duplicatas
```

### Pipes e Redirecionamento

```bash
# Redirecionar saída
echo "texto" > arquivo.txt  # Sobrescrever
echo "texto" >> arquivo.txt  # Adicionar ao final

# Redirecionar erro
comando 2>erros.txt
comando 2>&1  # Stderr para stdout

# Redirecionar entrada
comando < arquivo_entrada.txt

# Pipes (canalizar)
cat arquivo.log | grep "erro"
cat arquivo.log | grep "erro" | wc -l
cat arquivo.log | head -100 | tail -20

# Tee (duplicar saída)
cat arquivo.log | tee copia.log | grep "erro"
```

### Permissões e Propriedade

```bash
# Ver permissões
ls -l arquivo.txt

# CHMOD - Alterar permissões
chmod 755 script.sh
chmod u+x arquivo.sh  # Adicionar execução para usuário
chmod -R 755 pasta/  # Recursivo

# Entender permissões:
# rwxrwxrwx = usuário grupo outros
# r (read) = 4
# w (write) = 2
# x (execute) = 1
# 755 = rwxr-xr-x = 7(4+2+1) 5(4+1) 5(4+1)

# CHOWN - Alterar proprietário
sudo chown usuario:grupo arquivo.txt
sudo chown -R usuario:grupo pasta/
```

### Processos e Monitoramento

```bash
# Listar processos
ps aux
ps aux | grep python

# Top 10 processos por CPU
ps aux --sort=-%cpu | head -10

# Top 10 processos por memória
ps aux --sort=-%mem | head -10

# Monitor em tempo real
top
htop  # Versão melhorada (instalar: sudo apt install htop)

# Processos de um usuário
ps -u username

# Árvore de processos
pstree

# Processos em background
comando &  # Executar em background
jobs  # Listar jobs
fg %1  # Trazer job 1 para foreground
bg %1  # Enviar job 1 para background

# Kill processos
kill PID  # Terminar graciosamente
kill -9 PID  # Forçar encerramento
killall processo  # Matar por nome
pkill -9 processo  # Padrão de nome

# Executar comando com prioridade baixa
nice -n 19 comando
```

### Monitorar Arquivos e Sistemas

```bash
# Monitorar arquivo em tempo real
tail -f /var/log/syslog
tail -f /var/log/auth.log

# Múltiplos arquivos
tail -f /var/log/syslog /var/log/auth.log

# Executar comando periodicamente
watch 'df -h'  # Atualiza a cada 2 segundos
watch -n 5 'netstat -an'  # Atualiza a cada 5 segundos

# Estatísticas do sistema
uptime  # Tempo ligado e load average
free -h  # Memória
vmstat 1  # Estatísticas de VM (a cada 1 segundo)
iostat  # I/O de disco
```

### Wazuh Agent (Linux)

```bash
# Status do agente
sudo systemctl status wazuh-agent

# Iniciar/Parar
sudo systemctl start wazuh-agent
sudo systemctl stop wazuh-agent
sudo systemctl restart wazuh-agent

# Habilitar/Desabilitar boot automático
sudo systemctl enable wazuh-agent
sudo systemctl disable wazuh-agent

# Ver logs do agente
sudo tail -f /var/ossec/logs/ossec.log

# Ver informações do agente
sudo /var/ossec/bin/wazuh-control info

# Testar configuração
sudo /var/ossec/bin/wazuh-control check
```

### Rede Linux

```bash
# Ver interfaces de rede
ip addr show
ifconfig

# Ver rotas
ip route show
route -n

# Testar conectividade
ping -c 4 192.168.1.1
ping -c 10 google.com

# Traceroute
traceroute google.com

# Resolver DNS
nslookup google.com
dig google.com

# Conexões ativas
netstat -an
netstat -tulpn  # TCP/UDP listening
ss -an  # Versão moderna do netstat
ss -tulpn

# Capturar pacotes
sudo tcpdump -i eth0
sudo tcpdump -i eth0 -nn -w captura.pcap
sudo tcpdump -i eth0 tcp port 80

# Ler captura
sudo tcpdump -r captura.pcap

# Filtros tcpdump
sudo tcpdump -i eth0 host 192.168.1.1
sudo tcpdump -i eth0 src 192.168.1.10
sudo tcpdump -i eth0 dst 192.168.1.102
```

---

## Comandos PowerShell

### Navegação e Arquivos

```powershell
# Listar arquivos/diretórios
Get-ChildItem
Get-ChildItem -Recurse
Get-ChildItem -Filter "*.log"
Get-ChildItem -Force  # Incluir ocultos

# Aliases comuns
ls  # Get-ChildItem
dir  # Get-ChildItem
cd  # Set-Location
pwd  # Get-Location

# Criar diretórios
New-Item -ItemType Directory -Path "C:\SOC-Lab"
mkdir C:\pasta  # Alias

# Remover
Remove-Item -Path "C:\arquivo.txt" -Force
Remove-Item -Path "C:\pasta" -Recurse -Force

# Copiar
Copy-Item -Path "arquivo.txt" -Destination "copia.txt"
Copy-Item -Path "pasta" -Destination "copia" -Recurse

# Mover/renomear
Move-Item -Path "antigo.txt" -Destination "novo.txt"

# Encontrar arquivos
Get-ChildItem -Path "C:\" -Filter "*.log" -Recurse -ErrorAction SilentlyContinue
```

### Visualizar Conteúdo

```powershell
# Ler arquivo
Get-Content arquivo.txt

# Primeiras/últimas linhas
Get-Content arquivo.txt | Select-Object -First 20
Get-Content arquivo.txt | Select-Object -Last 20

# Monitorar arquivo em tempo real
Get-Content arquivo.txt -Tail 10 -Wait

# Contar linhas
(Get-Content arquivo.txt | Measure-Object -Line).Lines

# Contar caracteres
(Get-Content arquivo.txt | Measure-Object -Character).Characters

# Ver propriedades
Get-Item arquivo.txt | Select-Object *

# Espaço em disco
Get-Volume
Get-Volume C: | Select-Object *
```

### Pipes e Filtragem

```powershell
# Pipes (|) - canalizar
Get-Process | Where-Object {$_.CPU -gt 10}
Get-Process | Sort-Object CPU -Descending | Select-Object -First 5

# Where-Object - filtrar
Get-ChildItem | Where-Object {$_.Extension -eq ".log"}
Get-Process | Where-Object {$_.Name -like "*chrome*"}

# Select-Object - selecionar propriedades
Get-Process | Select-Object Name, CPU, WorkingSet
Get-Service | Select-Object Name, Status, StartType

# ForEach-Object - iterar
Get-ChildItem *.log | ForEach-Object {Write-Host $_.Name}
1..10 | ForEach-Object {Write-Host "Número: $_"}

# Sort-Object - ordenar
Get-ChildItem | Sort-Object LastWriteTime -Descending
Get-Process | Sort-Object WorkingSet -Descending

# Group-Object - agrupar
Get-Process | Group-Object Name | Select-Object Count, Name
Get-Service | Group-Object Status

# Measure-Object - estatísticas
Get-ChildItem | Measure-Object -Property Length -Sum -Average -Maximum
Get-Process | Measure-Object -Property WorkingSet -Sum
```

### Buscar e Processar Texto

```powershell
# Select-String (equivalente a grep)
Get-Content arquivo.log | Select-String "erro"
Get-Content arquivo.log | Select-String "erro" -CaseSensitive
Select-String -Path "*.log" -Pattern "falha"

# Contar ocorrências
(Get-Content arquivo.log | Select-String "padrão" | Measure-Object).Count

# Expressões regulares
Get-Content arquivo.log | Select-String "^\d{1,3}\.\d{1,3}"  # IPs

# Replace - substituir
(Get-Content arquivo.txt) -replace 'antigo','novo' | Set-Content arquivo.txt

# Split - dividir
"texto1,texto2,texto3" -split ","
$texto = "a-b-c"
$texto -split "-"

# Join - juntar
$array = @("a", "b", "c")
$array -join ","
```

### Variáveis e Operadores

```powershell
# Variáveis
$variavel = "valor"
$numero = 42
$lista = @("item1", "item2", "item3")
$hash = @{chave="valor"; outra="valor2"}

# Acessar elementos
$lista[0]  # Primeiro elemento
$hash["chave"]

# Operadores de comparação
-eq  # igual
-ne  # não igual
-lt  # menor que
-gt  # maior que
-le  # menor ou igual
-ge  # maior ou igual
-like  # padrão com wildcards
-match  # regex
-contains  # array contém

# Exemplos
if ($numero -gt 30) {Write-Host "Maior que 30"}
Get-Process | Where-Object {$_.CPU -gt 5}
"arquivo.log" -match "\.log$"

# Operadores lógicos
-and  # E
-or   # OU
-not  # NÃO
!     # NÃO (alternativa)

# Exemplo
if ($age -gt 18 -and $status -eq "Ativo") {
    Write-Host "Válido"
}
```

### Processos e Serviços

```powershell
# Listar processos
Get-Process
Get-Process -Name "svchost"
Get-Process | Select-Object Name, CPU, WorkingSet | Sort-Object CPU -Descending

# Iniciar processo
Start-Process notepad
Start-Process powershell -ArgumentList "-NoProfile"

# Parar processo
Stop-Process -Name "notepad" -Force
Stop-Process -Id 1234

# Serviços
Get-Service
Get-Service -Name "WinRM"
Get-Service | Where-Object {$_.Status -eq "Running"}

# Iniciar/Parar serviço
Start-Service -Name "WinRM"
Stop-Service -Name "WinRM"
Restart-Service -Name "WinRM"

# Status de serviço específico
Get-Service -Name "wazuh" | Select-Object Status, StartType
```

### Event Viewer e Logs

```powershell
# Listar logs disponíveis
Get-EventLog -List

# Eventos mais recentes
Get-EventLog -LogName "System" -Newest 20
Get-EventLog -LogName "Security" -Newest 50

# Filtrar por Event ID
Get-EventLog -LogName "Security" | Where-Object {$_.EventID -eq 4688}
Get-EventLog -LogName "Security" -InstanceId 4624  # Logon success

# Filtrar por data
$date = (Get-Date).AddDays(-7)
Get-EventLog -LogName "System" -After $date

# Logs do Sysmon
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -MaxEvents 100

# Filtrar Sysmon por Event ID
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" |
    Where-Object {$_.Id -eq 1} |  # Process Creation
    Select-Object TimeCreated, Message -First 10

# Exportar para CSV
Get-EventLog -LogName "Security" -Newest 1000 |
    Export-Csv "C:\Logs\security.csv" -NoTypeInformation

# Buscar texto em eventos
Get-EventLog -LogName "System" |
    Where-Object {$_.Message -like "*erro*"}
```

### Rede Windows

```powershell
# Ver adaptadores de rede
Get-NetAdapter
Get-NetAdapter | Select-Object Name, Status, LinkSpeed

# Ver endereços IP
Get-NetIPAddress
Get-NetIPAddress -AddressFamily IPv4

# Configurar IP estático
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 192.168.1.51 -PrefixLength 24 -DefaultGateway 192.168.1.1

# Configurar DNS
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 192.168.1.1

# Conexões TCP
Get-NetTCPConnection
Get-NetTCPConnection | Where-Object {$_.State -eq "Established"}
Get-NetTCPConnection | Where-Object {$_.LocalPort -eq 443}

# Testar conectividade
Test-NetConnection 192.168.1.1
Test-NetConnection 192.168.1.102 -Port 1514
Test-NetConnection google.com -TraceRoute

# Resolver DNS
Resolve-DnsName google.com
Resolve-DnsName 8.8.8.8

# Rotas
Get-NetRoute
Get-NetRoute -AddressFamily IPv4

# Estatísticas de rede
Get-NetAdapterStatistics
```

### Wazuh Agent (Windows)

```powershell
# Status do serviço
Get-Service -Name wazuh
Get-Service -Name wazuh | Select-Object Status, StartType

# Iniciar/Parar
Start-Service -Name wazuh
Stop-Service -Name wazuh
Restart-Service -Name wazuh

# Ver logs do agente
Get-Content "C:\Program Files (x86)\ossec-agent\ossec.log" -Tail 50 -Wait

# Ver processos relacionados
Get-Process | Where-Object {$_.Name -like "*wazuh*"}
```

### Informações do Sistema

```powershell
# Informações gerais
Get-ComputerInfo
Get-ComputerInfo | Select-Object CsName, OsName, OsVersion

# Nome do computador
$env:COMPUTERNAME
hostname

# Usuário atual
$env:USERNAME
whoami

# Informações de hardware
Get-WmiObject Win32_ComputerSystem
Get-WmiObject Win32_Processor | Select-Object Name, NumberOfCores
Get-WmiObject Win32_PhysicalMemory | Measure-Object Capacity -Sum

# Uptime
(Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
```

### Gerar Atividade de Teste

```powershell
# Criar e deletar processos
Start-Process notepad
Start-Sleep -Seconds 5
Stop-Process -Name notepad -Force

# Criar e deletar arquivos
New-Item -Path "C:\temp\teste.txt" -ItemType File -Force
Remove-Item "C:\temp\teste.txt" -Force

# Criar múltiplos arquivos
1..10 | ForEach-Object {
    New-Item -Path "C:\temp\file$_.txt" -ItemType File
}

# Simular atividade de rede
Test-NetConnection 192.168.1.1
Test-NetConnection google.com
Resolve-DnsName google.com

# Criar usuário local (gera Event ID)
net user teste_usuario SenhaForte123! /add
net user teste_usuario /delete

# Logon/Logoff
logoff  # Sai da sessão atual
```

---

## Consultas Splunk (SPL)

### Buscas Básicas

```spl
# Buscar todos eventos
index=*

# Buscar em index específico
index=main

# Filtrar por host
index=main host=DC01

# Filtrar por source
index=main source=WinEventLog:Security

# Filtrar por sourcetype
index=main sourcetype=WinEventLog:Security

# Buscar texto
index=main "erro"
index=main "failed" OR "failure"
```

### Sysmon no Splunk

```spl
# Todos eventos Sysmon
index=sysmon

# Process Creation (Event ID 1)
index=sysmon EventCode=1

# Network Connection (Event ID 3)
index=sysmon EventCode=3

# File Created (Event ID 11)
index=sysmon EventCode=11

# Registry Value Set (Event ID 13)
index=sysmon EventCode=13

# PowerShell suspeito
index=sysmon EventCode=1 Image="*powershell.exe" CommandLine="*-enc*"

# Processos de diretórios suspeitos
index=sysmon EventCode=1 (Image="*\\temp\\*" OR Image="*\\AppData\\*")
```

### Windows Security Events

```spl
# Logon success (Event ID 4624)
index=main source=WinEventLog:Security EventCode=4624

# Logon failure (Event ID 4625)
index=main source=WinEventLog:Security EventCode=4625

# Account Logon (Event ID 4776)
index=main source=WinEventLog:Security EventCode=4776

# Process Creation (Event ID 4688)
index=main source=WinEventLog:Security EventCode=4688

# Múltiplos Event IDs
index=main source=WinEventLog:Security (EventCode=4624 OR EventCode=4625)
```

### Agregação e Estatísticas

```spl
# Contar eventos por host
index=* | stats count by host

# Top 10 Event IDs
index=main | top limit=10 EventCode

# Contar processos criados
index=sysmon EventCode=1 | stats count by Image

# Agrupar por usuário
index=main source=WinEventLog:Security EventCode=4624 | stats count by Account_Name

# Timeline de eventos
index=sysmon EventCode=1 | timechart count by Image

# Média, soma, máximo
index=* | stats count avg(field) sum(field) max(field)
```

### Filtros Avançados

```spl
# Conectividade externa (não 192.168.x.x)
index=sysmon EventCode=3 DestinationIp!=192.168.*

# PowerShell com comando codificado
index=sysmon EventCode=1 Image="*powershell.exe" CommandLine="*-enc*" OR CommandLine="*-e *"

# Execução de binários do System32 por usuários normais
index=sysmon EventCode=1 Image="C:\\Windows\\System32\\*" User!="NT AUTHORITY\\SYSTEM"

# Múltiplas tentativas de logon falhadas
index=main source=WinEventLog:Security EventCode=4625
| stats count by Account_Name
| where count > 5

# Timeline de ataques
index=main (EventCode=4625 OR EventCode=4624)
| timechart span=5m count by EventCode
```

### Detecção de Ameaças

```spl
# Brute Force detection
index=main source=WinEventLog:Security EventCode=4625
| stats count by Account_Name, src_ip
| where count > 10

# Port Scanning
index=sysmon EventCode=3
| stats dc(DestinationPort) as unique_ports by SourceIp
| where unique_ports > 20

# Suspicious PowerShell
index=sysmon EventCode=1 Image="*powershell.exe"
    (CommandLine="*DownloadString*" OR
     CommandLine="*IEX*" OR
     CommandLine="*Invoke-Expression*" OR
     CommandLine="*-enc*")

# Persistence via Registry
index=sysmon EventCode=13
    (TargetObject="*\\Run\\*" OR
     TargetObject="*\\RunOnce\\*")

# Lateral Movement (RDP)
index=main source=WinEventLog:Security EventCode=4624 Logon_Type=10
| stats count by Account_Name, src_ip
```

---

## Comandos Wazuh

### Via Dashboard API

```bash
# Listar todos agentes
curl -k -X GET "https://192.168.1.102:55000/agents?pretty=true" -H "Authorization: Bearer $TOKEN"

# Status de agente específico
curl -k -X GET "https://192.168.1.102:55000/agents/001?pretty=true" -H "Authorization: Bearer $TOKEN"

# Reiniciar agente
curl -k -X PUT "https://192.168.1.102:55000/agents/001/restart?pretty=true" -H "Authorization: Bearer $TOKEN"
```

### Wazuh Manager (linha de comando)

```bash
# Listar agentes
sudo /var/ossec/bin/agent_control -l

# Info de agente específico
sudo /var/ossec/bin/agent_control -i 001

# Ver regras ativas
sudo /var/ossec/bin/wazuh-logtest

# Teste de regras
sudo /var/ossec/bin/wazuh-logtest -U "001:ossec:teste"

# Reiniciar Manager
sudo systemctl restart wazuh-manager

# Ver logs
sudo tail -f /var/ossec/logs/ossec.log
sudo tail -f /var/ossec/logs/alerts/alerts.log
```

---

## Comandos de Rede

### Análise de Pacotes

```bash
# Capturar pacotes (Linux)
sudo tcpdump -i eth0 -nn -w captura.pcap
sudo tcpdump -i eth0 tcp port 80
sudo tcpdump -i eth0 host 192.168.1.10

# Ler captura
sudo tcpdump -r captura.pcap

# Wireshark (filtros de exibição)
ip.addr == 192.168.1.10
tcp.port == 443
http.request.method == "GET"
dns.qry.name contains "google"
```

```powershell
# Capturar pacotes (Windows - requer Wireshark)
tshark -i "Ethernet" -w captura.pcap
tshark -i "Ethernet" -f "tcp port 80"

# Ler captura
tshark -r captura.pcap
```

### Port Scanning

```bash
# Nmap (do Kali Linux)
nmap 192.168.1.51
nmap -sS 192.168.1.0/24  # SYN scan
nmap -sV 192.168.1.51  # Version detection
nmap -p- 192.168.1.51  # Todas as portas
nmap -A 192.168.1.51  # Scan agressivo

# Scan rápido top ports
nmap -F 192.168.1.51
```

---

## Análise de Logs

### Exemplos Práticos

**Analisar logs do Wazuh para detectar padrões:**

```bash
# Contar alertas por severidade
cat /var/ossec/logs/alerts/alerts.log | grep -o "level='[0-9]*'" | sort | uniq -c

# Top 10 regras ativadas
cat /var/ossec/logs/alerts/alerts.log | grep "rule id" | sort | uniq -c | sort -nr | head -10

# Alertas de um agente específico
grep "agent name='DC01'" /var/ossec/logs/alerts/alerts.log
```

**Analisar Event Viewer exports:**

```powershell
# Importar CSV do Event Viewer
$events = Import-Csv "C:\Logs\security.csv"

# Contar por Event ID
$events | Group-Object EventID | Select-Object Count, Name | Sort-Object Count -Descending

# Filtrar eventos específicos
$events | Where-Object {$_.EventID -eq 4624} | Select-Object TimeGenerated, Message
```

**Pipeline completo de análise:**

```bash
# Linux: Análise de auth.log para detectar tentativas de SSH
cat /var/log/auth.log | \
    grep "Failed password" | \
    awk '{print $(NF-3)}' | \  # Extrair IP
    sort | uniq -c | \  # Contar
    sort -nr | \  # Ordenar
    head -10  # Top 10
```

```powershell
# Windows: Análise de falhas de logon
Get-EventLog -LogName Security -InstanceId 4625 -Newest 1000 |
    Group-Object -Property {$_.ReplacementStrings[5]} |  # IP de origem
    Select-Object Count, Name |
    Sort-Object Count -Descending |
    Select-Object -First 10
```

---

## 🎯 Conclusão

Esta referência cobre os comandos mais utilizados no Enterprise SOC Lab.


**Dica:** Pratique estes comandos regularmente para desenvolver muscle memory e agilidade na análise de incidentes.
