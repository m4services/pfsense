#!/bin/sh

# Definindo o caminho do arquivo de configuração do Zabbix Agent
ZABBIX_CONF="/usr/local/etc/zabbix6/zabbix_agentd.conf"

# Baixa o arquivo pfsense_zbx.php para o diretório /root/scripts
echo "Baixando o arquivo pfsense_zbx.php..."
curl --create-dirs -o /root/scripts/pfsense_zbx.php https://raw.githubusercontent.com/rbicelli/pfsense-zabbix-template/master/pfsense_zbx.php

# Remove parâmetros UserParameter existentes
echo "Removendo parâmetros UserParameter existentes..."
grep -v '^UserParameter' "$ZABBIX_CONF" > /tmp/zabbix_agentd.conf && mv /tmp/zabbix_agentd.conf "$ZABBIX_CONF"

# Adiciona as configurações dos User Parameters no final do arquivo de configuração do Zabbix
echo "Configurando Zabbix Agent..."
{
    echo ""
    echo "# User Parameters"
    echo "AllowRoot=1"
    echo "UserParameter=pfsense.states.max,grep \"limit states\" /tmp/rules.limits | cut -f4 -d ' '"
    echo "UserParameter=pfsense.states.current,grep \"current entries\" /tmp/pfctl_si_out | tr -s ' ' | cut -f4 -d ' '"
    echo "UserParameter=pfsense.mbuf.current,netstat -m | grep \"mbuf clusters\" | cut -f1 -d ' ' | cut -d '/' -f1"
    echo "UserParameter=pfsense.mbuf.cache,netstat -m | grep \"mbuf clusters\" | cut -f1 -d ' ' | cut -d '/' -f2"
    echo "UserParameter=pfsense.mbuf.max,netstat -m | grep \"mbuf clusters\" | cut -f1 -d ' ' | cut -d '/' -f4"
    echo "UserParameter=pfsense.discovery[*],/usr/local/bin/php /root/scripts/pfsense_zbx.php discovery \$1"
    echo "UserParameter=pfsense.value[*],/usr/local/bin/php /root/scripts/pfsense_zbx.php \$1 \$2 \$3"
} >> "$ZABBIX_CONF"

# Habilita o Zabbix Agent no /etc/rc.conf
echo "Habilitando Zabbix Agent no /etc/rc.conf..."
if ! grep -q 'zabbix_agentd_enable="YES"' /etc/rc.conf; then
    echo 'zabbix_agentd_enable="YES"' >> /etc/rc.conf
fi

# Aumenta o valor do timeout para 5 no arquivo de configuração do Zabbix
echo "Aumentando o Timeout para 5..."
sed -i '' 's/^# Timeout=3/Timeout=5/' "$ZABBIX_CONF"

# Reinicia o serviço do Zabbix Agent com 'onerestart'
echo "Reiniciando o Zabbix Agent..."
service zabbix_agentd onerestart

echo "Script finalizado com sucesso!"
