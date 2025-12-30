#!/bin/bash
################################################################################
# Script: install-wazuh-agent.sh
# Descrição: Instalação automatizada do Wazuh Agent no Ubuntu/Debian
# Autor: Natália Grossi
# Projeto: Enterprise SOC Lab
# Requisitos: Ubuntu 20.04+ ou Debian 10+, sudo, internet
################################################################################

set -e  # Parar em caso de erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configurações
WAZUH_MANAGER="192.168.1.102"
AGENT_NAME=$(hostname)

echo -e "${CYAN}======================================${NC}"
echo -e "${CYAN}  Instalação do Wazuh Agent         ${NC}"
echo -e "${CYAN}  Enterprise SOC Lab                ${NC}"
echo -e "${CYAN}======================================${NC}"
echo ""

# Verificar se está rodando como root/sudo
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Este script precisa ser executado com sudo!${NC}"
   echo "Uso: sudo ./install-wazuh-agent.sh"
   exit 1
fi

# Verificar conexão de internet
echo -e "${GREEN}[1/6] Verificando conexão de internet...${NC}"
if ping -c 1 google.com &> /dev/null; then
    echo -e "      ${GREEN}✓${NC} Conexão OK"
else
    echo -e "${RED}      ✗ Sem conexão de internet${NC}"
    exit 1
fi

# Verificar conectividade com Wazuh Manager
echo ""
echo -e "${GREEN}[2/6] Verificando conectividade com Wazuh Manager...${NC}"
if ping -c 1 $WAZUH_MANAGER &> /dev/null; then
    echo -e "      ${GREEN}✓${NC} Manager acessível em $WAZUH_MANAGER"
else
    echo -e "${YELLOW}      ! Manager não acessível no momento${NC}"
    echo -e "${YELLOW}      Continuando instalação...${NC}"
fi

# Adicionar repositório Wazuh
echo ""
echo -e "${GREEN}[3/6] Adicionando repositório Wazuh...${NC}"

# Instalar dependências
apt-get update -qq
apt-get install -y -qq curl gnupg apt-transport-https > /dev/null 2>&1

# Adicionar chave GPG
echo -e "      Adicionando chave GPG..."
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | \
    gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && \
    chmod 644 /usr/share/keyrings/wazuh.gpg

# Adicionar repositório
echo -e "      Adicionando repositório..."
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | \
    tee -a /etc/apt/sources.list.d/wazuh.list > /dev/null

# Atualizar lista de pacotes
apt-get update -qq

echo -e "      ${GREEN}✓${NC} Repositório adicionado"

# Instalar Wazuh Agent
echo ""
echo -e "${GREEN}[4/6] Instalando Wazuh Agent...${NC}"

export WAZUH_MANAGER="$WAZUH_MANAGER"

if apt-get install -y -qq wazuh-agent > /dev/null 2>&1; then
    echo -e "      ${GREEN}✓${NC} Wazuh Agent instalado"
else
    echo -e "${RED}      ✗ Falha na instalação${NC}"
    exit 1
fi

# Configurar agente
echo ""
echo -e "${GREEN}[5/6] Configurando Wazuh Agent...${NC}"

# Backup da configuração original
cp /var/ossec/etc/ossec.conf /var/ossec/etc/ossec.conf.bak

# Atualizar endereço do manager
sed -i "s/<address>MANAGER_IP<\/address>/<address>$WAZUH_MANAGER<\/address>/g" /var/ossec/etc/ossec.conf

# Verificar se substituição foi bem-sucedida
if grep -q "$WAZUH_MANAGER" /var/ossec/etc/ossec.conf; then
    echo -e "      ${GREEN}✓${NC} Manager configurado: $WAZUH_MANAGER"
else
    echo -e "${YELLOW}      ! Configuração manual pode ser necessária${NC}"
fi

# Configurar nome do agente
sed -i "s/<agent_name>AGENT_NAME<\/agent_name>/<agent_name>$AGENT_NAME<\/agent_name>/g" /var/ossec/etc/ossec.conf

echo -e "      ${GREEN}✓${NC} Nome do agente: $AGENT_NAME"

# Habilitar e iniciar serviço
echo ""
echo -e "${GREEN}[6/6] Iniciando Wazuh Agent...${NC}"

systemctl daemon-reload
systemctl enable wazuh-agent > /dev/null 2>&1
systemctl start wazuh-agent

# Aguardar inicialização
sleep 3

# Verificar status
if systemctl is-active --quiet wazuh-agent; then
    echo -e "      ${GREEN}✓${NC} Serviço iniciado com sucesso"
else
    echo -e "${RED}      ✗ Serviço não está rodando${NC}"
    echo -e "${YELLOW}      Verifique logs: sudo journalctl -u wazuh-agent${NC}"
fi

# Exibir informações finais
echo ""
echo -e "${CYAN}======================================${NC}"
echo -e "${CYAN}  Instalação Concluída!              ${NC}"
echo -e "${CYAN}======================================${NC}"
echo ""
echo -e "${YELLOW}Informações do Agente:${NC}"
echo -e "  Manager:    $WAZUH_MANAGER"
echo -e "  Agent Name: $AGENT_NAME"
echo -e "  Config:     /var/ossec/etc/ossec.conf"
echo -e "  Logs:       /var/ossec/logs/ossec.log"
echo ""
echo -e "${YELLOW}Comandos úteis:${NC}"
echo -e "  Ver status:       ${GREEN}sudo systemctl status wazuh-agent${NC}"
echo -e "  Ver logs:         ${GREEN}sudo tail -f /var/ossec/logs/ossec.log${NC}"
echo -e "  Reiniciar:        ${GREEN}sudo systemctl restart wazuh-agent${NC}"
echo -e "  Desinstalar:      ${GREEN}sudo apt remove wazuh-agent${NC}"
echo ""

# Verificar conexão com manager
echo -e "${YELLOW}Verificando conexão com Manager...${NC}"
sleep 5

if grep -q "Connected to the server" /var/ossec/logs/ossec.log; then
    echo -e "${GREEN}✓ Agente conectado ao Manager!${NC}"
    echo ""
    echo -e "${GREEN}Acesse o Wazuh Dashboard em https://$WAZUH_MANAGER${NC}"
    echo -e "${GREEN}para verificar o agente na lista.${NC}"
else
    echo -e "${YELLOW}! Agente ainda conectando...${NC}"
    echo -e "${YELLOW}Aguarde 1-2 minutos e verifique:${NC}"
    echo -e "  ${CYAN}sudo grep 'Connected' /var/ossec/logs/ossec.log${NC}"
fi

echo ""
echo -e "${GREEN}Instalação finalizada!${NC}"
echo ""
