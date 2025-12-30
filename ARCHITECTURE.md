# 🏗️ Arquitetura Detalhada — Enterprise SOC Lab

**Autora:** Natália Grossi
**LinkedIn:** [https://www.linkedin.com/in/natália-grossi-26bbb8374](https://www.linkedin.com/in/natália-grossi-26bbb8374)
**Data:** Dezembro/2025
**Status:** ✅ Ambiente 100% operacional

---

## 📐 Visão Geral da Arquitetura

O *Enterprise SOC Lab* implementa uma arquitetura de segurança em camadas, simulando um ambiente corporativo real com foco em **monitoramento, detecção, resposta a incidentes e testes ofensivos controlados**.

Todo o ambiente opera em **rede isolada**, com **segmentação lógica**, **telemetria centralizada**, **correlação de eventos** e **monitoramento contínuo**.

---

## 🌐 Topologia de Rede

### Diagrama Lógico

```
┌─────────────────────────────────────────────────────────┐
│                    INTERNET (NAT)                       │
│                    10.0.2.0/24                          │
└─────────────────────┬───────────────────────────────────┘
                      │
                      │ WAN Interface
                      ↓
        ┌─────────────────────────────┐
        │       pfSense Firewall      │
        │       192.168.1.1/24        │
        │                             │
        │  - Firewall Rules           │
        │  - NAT                      │
        │  - DHCP Server              │
        │  - DNS Resolver             │
        └─────────────┬───────────────┘
                      │ LAN Interface
                      │ Internal Network: LAN_SOC
                      │ 192.168.1.0/24
                      │
        ┌─────────────┴───────────────────────────┐
        │                                         │
        │          INTERNAL LAN_SOC               │
        │          192.168.1.0/24                 │
        │                                         │
        └─┬────────┬────────┬────────┬───────────┘
          │        │        │        │
          ↓        ↓        ↓        ↓
    ┌─────────┐ ┌──────┐ ┌──────┐ ┌───────┐
    │  DC01   │ │Wazuh │ │Ubuntu│ │ Kali  │
    │ .51     │ │.102  │ │ Lab  │ │ .10   │
    │         │ │      │ │ .101 │ │       │
    │Windows  │ │Ubuntu│ │Ubuntu│ │Kali   │
    │Server   │ │Server│ │       │ │Linux  │
    └─────────┘ └──────┘ └──────┘ └───────┘
```

---

## 🌐 Segmentação de Rede

| Segmento | Range          | Função               | Gateway     |
| -------- | -------------- | -------------------- | ----------- |
| WAN      | 10.0.2.0/24    | Acesso externo (NAT) | VirtualBox  |
| LAN_SOC  | 192.168.1.0/24 | Rede interna segura  | 192.168.1.1 |

> 🔒 Rede totalmente isolada da rede física do host.

---

## 🧱 Componentes do Laboratório

### 🔴 1. pfSense — Firewall & Gateway

**Funções:**

* Firewall
* NAT
* DHCP
* Roteamento

**Configuração:**

* WAN: 10.0.2.15
* LAN: 192.168.1.1/24
* DHCP: 192.168.1.10 – 192.168.1.200

**Regras:**

* LAN → ANY (permitido)
* WAN → LAN (bloqueado)
* Anti-lockout habilitado

**Status:** ✅ Operacional

---

### 🔵 2. Windows Server 2022 — DC01 (Blue Team)

**IP:** 192.168.1.51
**Domínio:** lab.local

**Serviços:**

* Active Directory (AD DS)
* DNS
* Splunk Enterprise
* Sysmon
* Wazuh Agent

**Funções:**

* Centralização de logs
* Telemetria avançada
* Monitoramento de eventos

---

### 🟢 3. Ubuntu Server — Wazuh Manager

**IP:** 192.168.1.102

**Componentes:**

* Wazuh Manager
* Wazuh Indexer (OpenSearch)
* Wazuh Dashboard

**Portas:**

* 1514 (Agents)
* 1515 (Registration)
* 55000 (API)
* 9200 (Indexer)
* 5601 (Dashboard)

---

### 🟡 4. Ubuntu Lab — Endpoint Monitorado

**IP:** 192.168.1.101

**Funções:**

* Testes operacionais
* Geração de logs
* Execução de scripts

**Monitoramento:**

* FIM
* Rootcheck
* SCA

---

### 🔴 5. Kali Linux — Red Team

**IP:** 192.168.1.10

**Funções:**

* Simulação de ataques
* Validação de detecções
* Geração de tráfego malicioso

**Ferramentas:**

* Nmap
* Metasploit
* Hydra
* SQLMap
* Wireshark

> ⚠️ Kali **possui agente Wazuh ativo**, integrado ao SOC.

---

## 🔄 Fluxo de Segurança (SOC)

1. Ataque gerado pelo Kali
2. Tráfego passa pelo pfSense
3. Endpoints geram eventos
4. Wazuh Agent coleta logs
5. Wazuh Manager processa e correlaciona
6. Alertas são gerados
7. Dashboard exibe eventos
8. Analista SOC investiga

---

## 🧪 Casos de Uso Validados

| Caso                | Status |
| ------------------- | ------ |
| Execução PowerShell | ✅      |
| Port Scan (Nmap)    | ✅      |
| Coleta Sysmon       | ✅      |
| Comunicação Wazuh   | ✅      |
| SCA Linux           | ✅      |
| Rootcheck           | ✅      |

---

## 🧰 Ferramentas Utilizadas

| Categoria     | Ferramentas         |
| ------------- | ------------------- |
| SIEM          | Wazuh, Splunk       |
| Monitoramento | Sysmon, Wazuh Agent |
| Rede          | pfSense             |
| Ataque        | Kali Linux          |
| Análise       | Wireshark, tcpdump  |
| Virtualização | VirtualBox          |

---

## 🧠 MITRE ATT&CK (Exemplos)

| Técnica           | ID        | Origem  |
| ----------------- | --------- | ------- |
| Network Scanning  | T1046     | Kali    |
| PowerShell        | T1059.001 | Windows |
| Credential Access | T1110     | Kali    |
| System Discovery  | T1082     | Linux   |
| Persistence       | T1547     | Windows |

---

## 🧾 Status Final do Laboratório

| Componente     | Status |
| -------------- | ------ |
| pfSense        | ✅      |
| Windows Server | ✅      |
| Wazuh Server   | ✅      |
| Ubuntu Lab     | ✅      |
| Kali Linux     | ✅      |
| Comunicação    | ✅      |
| Segurança      | ✅      |

---

## 🏁 Conclusão

Este laboratório representa um **ambiente corporativo realista**, pronto para:

* Demonstração profissional
* Estudos avançados em SOC
* Simulações de ataque e defesa
* Portfólio técnico

Arquitetura sólida, segura e escalável.

---

📌 **Autora:** Natália Grossi
🔗 **LinkedIn:** [https://www.linkedin.com/in/natália-grossi-26bbb8374](https://www.linkedin.com/in/natália-grossi-26bbb8374)
