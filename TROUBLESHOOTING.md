# 🔧 Troubleshooting - Solução de Problemas

Guia completo para resolver problemas comuns no Enterprise SOC Lab.

---

## 📑 Índice

1. [Problemas de Rede](#problemas-de-rede)
2. [Problemas com VMs](#problemas-com-vms)
3. [Problemas do Wazuh](#problemas-do-wazuh)
4. [Problemas do Splunk](#problemas-do-splunk)
5. [Problemas do Sysmon](#problemas-do-sysmon)
6. [Problemas do pfSense](#problemas-do-pfsense)
7. [Problemas de Performance](#problemas-de-performance)

---

## Problemas de Rede

### ❌ VM não recebe IP do DHCP

**Sintomas:**
- VM sem endereço IP
- Comando `ipconfig` ou `ip addr` mostra apenas loopback
- Não consegue pingar o gateway (192.168.1.1)

**Causas Possíveis:**
1. VM não está na rede Internal Network correta
2. pfSense DHCP desabilitado
3. Cabo de rede desconectado (no VirtualBox)

**Soluções:**

```powershell
# Windows - Verificar adaptador
Get-NetAdapter

# Se desabilitado, habilitar
Enable-NetAdapter -Name "Ethernet"

# Renovar IP
ipconfig /release
ipconfig /renew
```

```bash
# Linux - Verificar interface
ip link show

# Se down, levantar
sudo ip link set enp0s3 up

# Renovar IP (DHCP)
sudo dhclient -r  # Release
sudo dhclient     # Renew
```

**Verificar VirtualBox:**
1. VM → Settings → Network
2. Adapter 1 → Attached to: **Internal Network**
3. Name: **LAN_SOC**
4. Cable Connected: ✅

**Verificar pfSense DHCP:**
1. Acessar `http://192.168.1.1` (de outra VM que funcione)
2. Services → DHCP Server
3. Enable: ✅
4. Range: 192.168.1.10 - 192.168.1.200

---

### ❌ VM tem IP mas não acessa internet

**Sintomas:**
- `ping 192.168.1.1` funciona
- `ping 8.8.8.8` ou `ping google.com` falha
- DNS não resolve

**Soluções:**

**1. Verificar gateway:**

```powershell
# Windows
Test-NetConnection 192.168.1.1
Get-NetRoute -AddressFamily IPv4

# Se gateway incorreto, configurar
Set-NetIPInterface -InterfaceAlias "Ethernet" -Dhcp Disabled
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 192.168.1.X -PrefixLength 24 -DefaultGateway 192.168.1.1
```

```bash
# Linux
ping -c 4 192.168.1.1
ip route show

# Se gateway incorreto
sudo ip route add default via 192.168.1.1
```

**2. Verificar DNS:**

```powershell
# Windows
Resolve-DnsName google.com
Get-DnsClientServerAddress

# Configurar DNS
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 192.168.1.1,8.8.8.8
```

```bash
# Linux
nslookup google.com
cat /etc/resolv.conf

# Adicionar DNS
sudo nano /etc/resolv.conf
# Adicionar linha:
nameserver 192.168.1.1
```

**3. Verificar NAT do pfSense:**
1. pfSense Web UI → Firewall → NAT
2. Outbound → Mode: Automatic

---

### ❌ VMs não se comunicam entre si

**Sintomas:**
- `ping 192.168.1.51` (de outra VM) falha
- Todas VMs têm IP na mesma rede
- Gateway responde

**Soluções:**

**1. Verificar Firewall local:**

```powershell
# Windows - Desabilitar temporariamente para teste
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

# Re-habilitar depois
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
```

```bash
# Linux - Verificar firewall
sudo ufw status

# Desabilitar temporariamente
sudo ufw disable

# Re-habilitar
sudo ufw enable
```

**2. Verificar se todas VMs estão na mesma Internal Network:**
- Todas devem ter: **Internal Network → LAN_SOC**

---

## Problemas com VMs

### ❌ VM lenta ou travando

**Causas:**
- RAM insuficiente no host
- Muitas VMs rodando simultaneamente
- Disco HDD (não SSD)
- CPU sobrecarregada

**Soluções:**

**1. Reduzir VMs simultâneas:**
- Desligue VMs que não está usando no momento
- Priorize: pfSense + DC01 + Wazuh Server

**2. Ajustar alocação de RAM:**

Recomendações conservadoras para 16GB host:
- pfSense: 1 GB
- DC01: 3 GB (reduzir de 4-6)
- Wazuh Server: 3 GB (reduzir de 4)
- Ubuntu Lab: 1.5 GB
- Kali: 1.5 GB

**3. Usar SSD:**
- Mover VMs para SSD se possível

**4. Snapshots:**
- Evite ter muitos snapshots ativos
- Delete snapshots antigos

```powershell
# VirtualBox - Gerenciar snapshots via GUI
# VM → Snapshots → Delete
```

---

### ❌ VM não inicia

**Sintomas:**
- Erro ao iniciar VM
- Tela preta
- Boot loop

**Soluções:**

**1. Verificar logs do VirtualBox:**
```
C:\Users\<usuario>\.VirtualBox\Logs\
```

**2. Verificar disco:**
- Settings → Storage → Verificar se disco VDI está anexado

**3. Verificar ISO:**
- Se estiver tentando instalar, verificar se ISO está correta

**4. Restaurar snapshot:**
- Se tinha snapshot funcionando, restaure

**5. Recriar VM:**
- Última opção: Export/Import ou recriar do zero

---

## Problemas do Wazuh

### ❌ Agente não conecta ao Manager

**Sintomas:**
- Dashboard não mostra agente
- Status do agente: "Never connected" ou "Disconnected"

**Diagnóstico:**

```powershell
# Windows
Get-Service -Name wazuh
Get-Content "C:\Program Files (x86)\ossec-agent\ossec.log" -Tail 50

# Testar conectividade
Test-NetConnection 192.168.1.102 -Port 1514
```

```bash
# Linux
sudo systemctl status wazuh-agent
sudo tail -f /var/ossec/logs/ossec.log

# Testar conectividade
nc -zv 192.168.1.102 1514
```

**Soluções:**

**1. Verificar endereço do Manager:**

```xml
<!-- Windows: C:\Program Files (x86)\ossec-agent\ossec.conf -->
<!-- Linux: /var/ossec/etc/ossec.conf -->

<client>
  <server>
    <address>192.168.1.102</address>
    <port>1514</port>
    <protocol>tcp</protocol>
  </server>
</client>
```

**2. Reiniciar agente:**

```powershell
# Windows
Restart-Service -Name wazuh
```

```bash
# Linux
sudo systemctl restart wazuh-agent
```

**3. Verificar firewall do Manager:**

```bash
# No Wazuh Server
sudo ufw status
sudo ufw allow 1514/tcp
sudo ufw allow 1515/tcp
sudo ufw allow 55000/tcp
```

**4. Reconfigurar agente:**

```bash
# No Wazuh Server - Registrar agente manualmente
sudo /var/ossec/bin/agent_control -l  # Listar agentes

# Remover agente problemático
sudo /var/ossec/bin/manage_agents
# Opção: (r) Remove agent
# ID do agente para remover
```

No agent (Windows ou Linux), reinstalar:

```powershell
# Windows - Desinstalar e reinstalar
msiexec /x wazuh-agent.msi
# Baixar novamente e instalar com comando correto
```

---

### ❌ Wazuh Dashboard não carrega

**Sintomas:**
- `https://192.168.1.102` não abre
- Erro de conexão ou timeout
- Certificado inválido

**Soluções:**

**1. Verificar serviços:**

```bash
# No Wazuh Server
sudo systemctl status wazuh-manager
sudo systemctl status wazuh-indexer
sudo systemctl status wazuh-dashboard

# Se algum está parado, iniciar
sudo systemctl start wazuh-dashboard
```

**2. Verificar portas:**

```bash
sudo netstat -tlnp | grep -E '443|1514|1515|9200|55000'
```

**3. Reiniciar stack completa:**

```bash
sudo systemctl restart wazuh-manager
sudo systemctl restart wazuh-indexer
sudo systemctl restart wazuh-dashboard

# Aguardar 2-3 minutos para serviços subirem
```

**4. Verificar logs:**

```bash
sudo tail -f /var/ossec/logs/ossec.log
sudo tail -f /var/log/wazuh-indexer/wazuh-cluster.log
```

**5. Aceitar certificado auto-assinado:**
- No navegador, aceitar o risco de segurança
- Chrome: "Advanced" → "Proceed to 192.168.1.102 (unsafe)"

---

### ❌ Nenhum evento aparece no Dashboard

**Sintomas:**
- Agentes conectados (status Active)
- Dashboard vazio, sem eventos

**Soluções:**

**1. Gerar atividade de teste:**

```powershell
# Windows
Start-Process notepad
Stop-Process -Name notepad -Force

# Criar arquivo
New-Item -Path "C:\temp\test.txt" -ItemType File -Force
```

```bash
# Linux
touch /tmp/testfile
rm /tmp/testfile
```

**2. Verificar coleta de logs:**

```bash
# No Wazuh Server
sudo tail -f /var/ossec/logs/archives/archives.log
# Deve mostrar eventos chegando
```

**3. Verificar configuração do agente:**

```xml
<!-- Verificar se localfile está configurado -->
<localfile>
  <log_format>eventchannel</log_format>
  <location>Security</location>
</localfile>
```

**4. Forçar restart do agente:**

```powershell
# Windows
Restart-Service -Name wazuh
```

---

## Problemas do Splunk

### ❌ Splunk não inicia

**Sintomas:**
- `http://localhost:8000` ou `http://192.168.1.51:8000` não abre
- Serviço Splunk parado

**Soluções:**

**1. Verificar serviço:**

```powershell
Get-Service -Name Splunk*

# Se parado, iniciar
Start-Service -Name SplunkForwarder
# ou
Start-Service -Name Splunkd
```

**2. Iniciar via CLI:**

```powershell
cd "C:\Program Files\Splunk\bin"
.\splunk start
```

**3. Verificar logs:**

```powershell
Get-Content "C:\Program Files\Splunk\var\log\splunk\splunkd.log" -Tail 50
```

**4. Verificar porta 8000:**

```powershell
Get-NetTCPConnection | Where-Object {$_.LocalPort -eq 8000}
```

**5. Resetar senha de admin:**

```powershell
cd "C:\Program Files\Splunk\bin"
.\splunk edit user admin -password novasenha -auth admin:senhaantiga
```

---

### ❌ Splunk não recebe logs

**Sintomas:**
- Splunk abre normalmente
- Search não retorna dados
- Index vazio

**Soluções:**

**1. Verificar data inputs:**

```powershell
# Via CLI
cd "C:\Program Files\Splunk\bin"
.\splunk list inputstatus

# Via Web UI
Settings → Data Inputs → Files & Directories
Settings → Data Inputs → TCP
```

**2. Configurar inputs manualmente:**

```powershell
# Arquivo: C:\Program Files\Splunk\etc\system\local\inputs.conf

[monitor://C:\Windows\System32\winevt\Logs\Security.evtx]
disabled = false
index = main
sourcetype = WinEventLog:Security

[monitor://C:\Windows\System32\winevt\Logs\System.evtx]
disabled = false
index = main
sourcetype = WinEventLog:System
```

**3. Adicionar via Web UI:**
1. Settings → Add Data
2. Monitor → Files & Directories
3. Browse → Selecionar: `C:\Windows\System32\winevt\Logs\`
4. Selecionar logs desejados
5. Sourcetype: Automatic
6. Index: main
7. Review → Submit

**4. Verificar Splunk Forwarder (se aplicável):**

```powershell
# Verificar outputs.conf
Get-Content "C:\Program Files\SplunkUniversalForwarder\etc\system\local\outputs.conf"

# Deve ter:
[tcpout]
defaultGroup = default-autolb-group

[tcpout:default-autolb-group]
server = 192.168.1.51:9997

# Reiniciar forwarder
Restart-Service -Name SplunkForwarder
```

---

## Problemas do Sysmon

### ❌ Sysmon não está gerando logs

**Sintomas:**
- Event Viewer não mostra logs em `Microsoft-Windows-Sysmon/Operational`
- Get-WinEvent retorna vazio

**Soluções:**

**1. Verificar se Sysmon está instalado e rodando:**

```powershell
Get-Service -Name Sysmon64

# Se não existe
Get-Service | Where-Object {$_.Name -like "*sysmon*"}
```

**2. Verificar instalação:**

```powershell
# Verificar se executável existe
Test-Path "C:\Windows\Sysmon64.exe"
# ou
Test-Path "C:\Windows\SysWOW64\Sysmon.exe"
```

**3. Reinstalar Sysmon:**

```powershell
cd C:\Sysmon

# Desinstalar
.\Sysmon64.exe -u

# Reinstalar
.\Sysmon64.exe -accepteula -i sysmonconfig.xml

# Verificar
Get-Service Sysmon64
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -MaxEvents 10
```

**4. Gerar eventos de teste:**

```powershell
# Criar processo (Event ID 1)
Start-Process notepad
Stop-Process -Name notepad

# Criar arquivo (Event ID 11)
New-Item -Path "C:\temp\testfile.txt" -ItemType File -Force

# Verificar logs
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -MaxEvents 5 |
    Select-Object TimeCreated, Id, Message
```

---

## Problemas do pfSense

### ❌ Não consigo acessar interface web do pfSense

**Sintomas:**
- `http://192.168.1.1` não carrega
- Timeout ou conexão recusada

**Soluções:**

**1. Verificar IP da VM que está tentando acessar:**
- Deve estar na rede 192.168.1.0/24
- Testar `ping 192.168.1.1`

**2. Acessar via console do pfSense:**
1. Abrir VM pfSense no VirtualBox
2. Login: `admin` / `pfsense`
3. Menu option 2 → Set interface IP
4. Verificar se LAN está em 192.168.1.1

**3. Verificar se webConfigurator está habilitado:**
- Console pfSense → Option 8 (Shell)
```bash
pfctl -d  # Desabilita firewall temporariamente
# Testar acesso web
pfctl -e  # Re-habilita firewall
```

**4. Resetar configurações (último recurso):**
- Console pfSense → Option 4 (Reset to factory defaults)

---

## Problemas de Performance

### ❌ Host físico muito lento

**Sintomas:**
- Mouse travando
- VMs extremamente lentas
- CPU/RAM em 100%

**Soluções:**

**1. Verificar recursos:**

```powershell
# Ver uso de CPU/RAM
Get-Process | Sort-Object CPU -Descending | Select-Object -First 10
Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 10
```

**2. Desligar VMs não essenciais:**
- Manter apenas pfSense + DC01 + Wazuh Server
- Desligar Ubuntu Lab e Kali temporariamente

**3. Reduzir alocação de RAM das VMs:**
- DC01: Reduzir de 6GB para 3GB
- Wazuh Server: Reduzir de 4GB para 3GB

**4. Usar snapshots ao invés de múltiplas VMs:**
- Salvar estado e desligar VM
- Quando precisar, restaurar snapshot

**5. Fechar aplicações no host:**
- Navegadores com muitas abas
- IDEs pesadas
- Jogos ou streaming

**6. Verificar disco:**
```powershell
# Verificar se SSD tem espaço
Get-Volume
```

---

### ❌ VMs com I/O alto (disco lento)

**Soluções:**

**1. Converter discos para SSD:**
- Mover diretório `C:\SOC-Lab\VMs\` para SSD

**2. Otimizar discos virtuais:**
```powershell
# VBoxManage compact
cd "C:\Program Files\Oracle\VirtualBox\"
.\VBoxManage.exe list hdds  # Listar discos
.\VBoxManage.exe modifymedium disk "C:\SOC-Lab\VMs\DC01\DC01.vdi" --compact
```

**3. Desabilitar indexação Windows nas VMs:**
```powershell
# Dentro da VM Windows
Get-Service -Name "WSearch" | Stop-Service
Set-Service -Name "WSearch" -StartupType Disabled
```

---

## 🆘 Comandos de Diagnóstico Geral

### Checklist Rápido

```powershell
# Windows DC01 - Verificação Completa
Test-NetConnection 192.168.1.1  # Gateway
Test-NetConnection 192.168.1.102 -Port 1514  # Wazuh Manager
Test-NetConnection google.com  # Internet
Get-Service | Where-Object {$_.Name -like "*wazuh*" -or $_.Name -like "*splunk*" -or $_.Name -like "*sysmon*"}
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -MaxEvents 5
```

```bash
# Linux - Verificação Completa
ping -c 4 192.168.1.1  # Gateway
ping -c 4 192.168.1.102  # Wazuh Manager
ping -c 4 google.com  # Internet
sudo systemctl status wazuh-agent
sudo tail -f /var/ossec/logs/ossec.log
```

---

## 📞 Ainda com Problemas?

Se nenhuma solução acima resolveu:

1. **Verificar logs detalhados:**
   - VirtualBox: `C:\Users\<user>\.VirtualBox\Logs\`
   - Wazuh: `/var/ossec/logs/ossec.log`
   - Splunk: `C:\Program Files\Splunk\var\log\splunk\splunkd.log`

2. **Consultar comunidades:**
   - [Wazuh Google Group](https://groups.google.com/g/wazuh)
   - [Splunk Answers](https://community.splunk.com/)
   - [r/homelab](https://reddit.com/r/homelab)

3. **Reinstalação limpa:**
   - Fazer backup de configs importantes
   - Deletar VM problemática
   - Recriar seguindo [INSTALLATION.md](INSTALLATION.md)

4. **Criar issue no GitHub:**
   - Descrever problema detalhadamente
   - Incluir logs relevantes
   - Listar passos já tentados
