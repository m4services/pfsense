#!/bin/sh

# Baixa o arquivo pfsense_zbx.php para o diretório /root/scripts
echo "Baixando o arquivo pfsense_zbx.php..."
curl --create-dirs -o /root/scripts/pfsense_zbx.php https://raw.githubusercontent.com/rbicelli/pfsense-zabbix-template/master/pfsense_zbx.php

# Define o arquivo de configuração
CONF_FILE="/usr/local/etc/zabbix6/zabbix_agentd.conf"

# Cria um backup do arquivo de configuração
cp $CONF_FILE ${CONF_FILE}.bak

# Edita o arquivo de configuração
awk -v ORS= -v timeout=30 '
{
    if ($0 ~ /^Timeout=/) {
        print "Timeout=" timeout "\n"
        next
    }
    print $0 "\n"
}
END {
    print "\nAllowRoot=1\n"
    print "UserParameter=pfsense.states.max,grep \"limit states\" /tmp/rules.limits | cut -f4 -d ' '\n"
    print "UserParameter=pfsense.states.current,grep \"current entries\" /tmp/pfctl_si_out | tr -s ' ' | cut -f4 -d ' '\n"
    print "UserParameter=pfsense.mbuf.current,netstat -m | grep \"mbuf clusters\" | cut -f1 -d ' ' | cut -d '/' -f1\n"
    print "UserParameter=pfsense.mbuf.cache,netstat -m | grep \"mbuf clusters\" | cut -f1 -d ' ' | cut -d '/' -f2\n"
    print "UserParameter=pfsense.mbuf.max,netstat -m | grep \"mbuf clusters\" | cut -f1 -d ' ' | cut -d '/' -f4\n"
    print "UserParameter=pfsense.discovery[*],/usr/local/bin/php /root/scripts/pfsense_zbx.php discovery $1\n"
    print "UserParameter=pfsense.value[*],/usr/local/bin/php /root/scripts/pfsense_zbx.php $1 $2 $3\n"
}' $CONF_FILE > /tmp/zabbix_agentd.conf

# Sobrescreve o arquivo de configuração original
mv /tmp/zabbix_agentd.conf $CONF_FILE

# Reinicia o serviço do Zabbix Agent para aplicar as mudanças
echo "Reiniciando o Zabbix Agent..."
service zabbix_agentd restart

# Verifica o status do Zabbix Agent
echo "Verificando o status do Zabbix Agent..."
service zabbix_agentd status

echo "Configuração do Zabbix Agent concluída!"
