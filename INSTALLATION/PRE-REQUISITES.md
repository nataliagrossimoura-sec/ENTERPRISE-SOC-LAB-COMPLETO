# 📋 Pré-requisitos - Enterprise SOC Lab

Requisitos completos para construir o laboratório SOC.

---

## Hardware do Host (Computador Físico)

### Requisitos Mínimos
- **Processador:** Intel Core i3 (4 threads) ou AMD Ryzen 3
- **RAM:** 16 GB
- **Armazenamento:** 300 GB SSD livre
- **Rede:** Conexão Ethernet estável

### Requisitos Recomendados
- **Processador:** Intel Core i5/i7 8ª geração+ ou AMD Ryzen 5+
- **RAM:** 24-32 GB
- **Armazenamento:** 500 GB - 1 TB SSD NVMe
- **Rede:** Ethernet 1 Gbps
- **Monitor:** 1920x1080 ou superior

### Seu Cenário Atual
- CPU: Intel i3
- RAM: 16 GB
- SSD: Disponível
- Status: ✅ Aceita perfeitamente o laboratório

**Observação:** Com 16GB RAM, você consegue rodar 3-4 VMs simultaneamente. Priorize: pfSense + Windows DC01 + Wazuh Server.

---

## Software do Host

### Sistema Operacional
- Windows 10 Pro/Enterprise (versão 21H2 ou superior)
- Windows 11 Pro/Enterprise
- **Atualizado** com todas as atualizações do Windows Update

### Virtualização
- **VirtualBox 7.0+** (gratuito, open-source)
  - Download: https://www.virtualbox.org/wiki/Downloads
  - VirtualBox Extension Pack (obrigatório)
  
**OU**

- **VMware Workstation Pro** (pago, mas mais recursos)
  - Download: https://www.vmware.com/products/workstation-pro.html
  - Versão 17+

**Escolha:** VirtualBox é suficiente e gratuito. Use VMware apenas se já tiver licença.

### Ferramentas Adicionais
- **Navegador moderno:** Chrome, Firefox ou Edge (atualizado)
- **Editor de texto:** Notepad++, VS Code ou similar
- **Ferramenta de diagramas:**
  - Draw.io (web, gratuito): https://app.diagrams.net/
  - Lucidchart (7 dias grátis)
- **7-Zip ou WinRAR:** Para extrair arquivos

---

## ISOs Necessárias

### Sistema Operacional - VMs

| ISO | Tamanho | Link | Uso |
|-----|---------|------|-----|
| **pfSense CE** | ~600 MB | [Download](https://www.pfsense.org/download/) | Firewall/Gateway |
| **Windows Server 2022** | ~5 GB | [Evaluation](https://www.microsoft.com/evalcenter) | DC + SIEM |
| **Ubuntu Server 22.04 LTS** | ~2 GB | [Download](https://ubuntu.com/download/server) | Wazuh Server |
| **Ubuntu Desktop 22.04 LTS** | ~4 GB | [Download](https://ubuntu.com/download/desktop) | Linux Lab |
| **Kali Linux** | ~3-4 GB | [Download](https://www.kali.org/get-kali/) | Red Team |

**Total de ISOs:** ~15-18 GB

### Ferramentas para Download Posterior

Estas ferramentas serão baixadas durante a instalação:

- **Splunk Enterprise** (.msi para Windows)
- **Sysmon** (Sysinternals Suite)
- **Wazuh Agent** (.msi para Windows)
- **Wireshark** (instalador Windows)
- **Gawk** (GNU Awk para Windows)

**Não precisa baixar agora**, os scripts automatizados farão isso.

---

## Rede do Laboratório

### Conceito
- **Rede Interna Isolada:** 192.168.1.0/24
- **Tipo no VirtualBox:** Internal Network (nome: LAN_SOC)
- **Gateway:** pfSense (192.168.1.1)
- **DHCP:** Distribuído pelo pfSense (192.168.1.10 - 192.168.1.200)

### Endereços IP Planejados

| Máquina | IP | Hostname | Função |
|---------|----|---------|---------| 
| pfSense | 192.168.1.1 | pfsense | Firewall/Gateway |
| Windows Server | 192.168.1.51 | DC01 | AD + SIEM |
| Wazuh Server | 192.168.1.102 | wazuh-server | SIEM Central |
| Ubuntu Lab | 192.168.1.101 | ubuntu-lab | Endpoint Linux |
| Kali Linux | 192.168.1.10 | kali | Red Team |

**Observação:** IPs podem ser DHCP ou estáticos. O guia mostra ambas opções.

---

## Conhecimentos Recomendados

### Essenciais (Obrigatórios)
- ✅ Uso básico de Windows (criar pastas, instalar programas)
- ✅ Uso básico de VirtualBox (criar VM, anexar ISO)
- ✅ Conceitos básicos de rede (IP, Gateway, DNS)

### Desejáveis (Facilitam muito)
- 🟡 Linha de comando Windows (cmd ou PowerShell básico)
- 🟡 Linha de comando Linux (ls, cd, pwd, sudo)
- 🟡 Conceitos de SIEM e logs
- 🟡 Noções de segurança da informação

### Avançados (Aprenderá no projeto)
- ⚪ PowerShell scripting
- ⚪ Bash scripting
- ⚪ Análise de logs
- ⚪ Detecção de ameaças
- ⚪ MITRE ATT&CK Framework

**Não se preocupe:** Este guia ensina tudo passo a passo!

---

## Espaço em Disco

### Breakdown Detalhado

```
C:\SOC-Lab\
├── ISOs\           15-18 GB (temporário, pode deletar depois)
├── VMs\            150-200 GB (permanente)
│   ├── pfSense         10 GB
│   ├── DC01            60 GB
│   ├── Wazuh Server    40 GB
│   ├── Ubuntu Lab      20 GB
│   └── Kali Linux      30 GB
├── Snapshots\      50-100 GB (recomendado para backup)
├── Scripts\        < 1 MB
├── Logs\           1-5 GB (amostras)
└── Documentacao\   < 100 MB
```

**Total recomendado:** 300-500 GB livres em SSD

**Mínimo absoluto:** 200 GB (sem snapshots)

---

## Tempo Estimado

### Tempo Total do Projeto
- **Instalação inicial:** 8-12 horas
- **Configuração e testes:** 6-8 horas
- **Documentação e screenshots:** 4-6 horas
- **Aprendizado (TryHackMe):** 6-8 horas
- **Total:** 24-34 horas

### Distribuição Semanal Sugerida

**Semana 1 (15h):**
- Preparação do ambiente (2h)
- Instalação de VMs (8h)
- Instalação de ferramentas (5h)

**Semana 2 (12h):**
- Configuração avançada (4h)
- Testes e validação (4h)
- Screenshots e evidências (4h)

**Semana 3 (8h):**
- Documentação GitHub (4h)
- TryHackMe (4h)

**Semana 4 (5h):**
- Revisão final (2h)
- Publicação (2h)
- Divulgação LinkedIn (1h)

---

## Licenças de Software

### Gratuito / Open Source
- ✅ VirtualBox - GPL (gratuito)
- ✅ pfSense - Apache 2.0 (gratuito)
- ✅ Ubuntu - GPL (gratuito)
- ✅ Kali Linux - GPL (gratuito)
- ✅ Wazuh - GPL (gratuito)
- ✅ Sysmon - Freeware Microsoft
- ✅ Wireshark - GPL (gratuito)

### Avaliação Gratuita
- 🟡 Windows Server 2022 - **180 dias grátis** (evaluation)
- 🟡 Splunk Enterprise - **60 dias grátis** + 500MB/dia após (free tier)

**Observação:** Você não precisa pagar por NADA! Todas as ferramentas têm versões gratuitas ou de avaliação suficientes para o projeto.

---

## Checklist de Pré-requisitos

### Hardware
- [ ] CPU com 4+ threads
- [ ] 16+ GB RAM
- [ ] 300+ GB SSD livre
- [ ] Conexão de rede estável

### Software
- [ ] Windows 10/11 atualizado
- [ ] VirtualBox instalado
- [ ] VirtualBox Extension Pack instalado
- [ ] Navegador atualizado
- [ ] Ferramenta de diagramas escolhida

### ISOs
- [ ] pfSense CE baixado
- [ ] Windows Server 2022 baixado
- [ ] Ubuntu Server 22.04 baixado
- [ ] Ubuntu Desktop 22.04 baixado
- [ ] Kali Linux baixado

### Conhecimento
- [ ] Sei usar VirtualBox básico
- [ ] Sei criar/deletar pastas no Windows
- [ ] Tenho noção de rede (IP, Gateway)

### Tempo
- [ ] Tenho 25-35 horas disponíveis nas próximas semanas
- [ ] Posso dedicar 5-7h por semana ao projeto

### Motivação
- [ ] Estou comprometido em completar o projeto
- [ ] Entendo que haverá desafios e troubleshooting
- [ ] Tenho objetivo claro (portfólio, aprendizado, emprego)

---

## Próximos Passos

Após confirmar todos os pré-requisitos:

1. Seguir para [02-preparacao-host.md](02-preparacao-host.md)
2. Preparar ambiente do host
3. Criar estrutura de pastas
4. Configurar VirtualBox

---

## Dúvidas Frequentes

**P: Posso usar VMware ao invés de VirtualBox?**  
R: Sim, mas o guia usa VirtualBox. Você precisará adaptar algumas instruções.

**P: Posso usar menos de 16GB RAM?**  
R: Não recomendado. Com 8GB você terá problemas graves de performance. Mínimo é 16GB.

**P: Preciso de licença do Windows Server?**  
R: Não! Use a versão de avaliação gratuita de 180 dias.

**P: Meu PC é AMD, funciona?**  
R: Sim! Funciona perfeitamente com processadores AMD.

**P: Posso fazer no Linux (Ubuntu como host)?**  
R: Sim, mas o guia é focado em Windows host. Você precisará adaptar comandos PowerShell.

**P: Quanto tempo leva para baixar as ISOs?**  
R: Depende da sua internet. Com 100Mbps, ~2-3 horas total.

---

**Pronto?** Vamos para a preparação! 🚀
