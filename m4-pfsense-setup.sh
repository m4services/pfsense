#!/bin/sh

# Baixa o arquivo pfsense_zbx.php para o diretório /root/scripts
echo "Baixando o arquivo pfsense_zbx.php..."
curl --create-dirs -o /root/scripts/pfsense_zbx.php https://raw.githubusercontent.com/rbicelli/pfsense-zabbix-template/master/pfsense_zbx.php

# Verifica se o arquivo de configuração do Zabbix existe
CONFIG_FILE="/usr/local/etc/zabbix6/zabbix_agentd.conf"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Arquivo de configuração do Zabbix não encontrado: $CONFIG_FILE"
    exit 1
fi

# Remove parâmetros de usuário existentes do Zabbix Agent
echo "Removendo parâmetros de usuário existentes..."
sed -i '' '/^UserParameter=/d' "$CONFIG_FILE"

# Configura os novos parâmetros de usuário para o Zabbix Agent
echo "Configurando Zabbix Agent..."
{
    echo "AllowRoot=1"
    echo "UserParameter=pfsense.states.max,grep \"limit states\" /tmp/rules.limits | cut -f4 -d ' '"
    echo "UserParameter=pfsense.states.current,grep \"current entries\" /tmp/pfctl_si_out | tr -s ' ' | cut -f4 -d ' '"
    echo "UserParameter=pfsense.mbuf.current,netstat -m | grep \"mbuf clusters\" | cut -f1 -d ' ' | cut -d '/' -f1"
    echo "UserParameter=pfsense.mbuf.cache,netstat -m | grep \"mbuf clusters\" | cut -f1 -d ' ' | cut -d '/' -f2"
    echo "UserParameter=pfsense.mbuf.max,netstat -m | grep \"mbuf clusters\" | cut -f1 -d ' ' | cut -d '/' -f4"
    echo "UserParameter=pfsense.discovery[*],/usr/local/bin/php /root/scripts/pfsense_zbx.php discovery \$1"
    echo "UserParameter=pfsense.value[*],/usr/local/bin/php /root/scripts/pfsense_zbx.php \$1 \$2 \$3"
} >> "$CONFIG_FILE"

# Aumenta o valor do timeout para 5
echo "Aumentando o Timeout para 5..."
sed -i '' 's/^# Timeout=3/Timeout=5/' "$CONFIG_FILE"

# Reinicia o serviço do Zabbix Agent para aplicar as mudanças
echo "Reiniciando o Zabbix Agent..."
service zabbix6_agentd restart

# Verifica o status do serviço
echo "Verificando o status do Zabbix Agent..."
service zabbix6_agentd status

echo "Configuração do Zabbix Agent concluída!"
