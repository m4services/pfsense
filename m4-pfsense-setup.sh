#!/bin/sh

# Baixa o arquivo pfsense_zbx.php para o diretório /root/scripts
echo "Baixando o arquivo pfsense_zbx.php..."
curl --create-dirs -o /root/scripts/pfsense_zbx.php https://raw.githubusercontent.com/rbicelli/pfsense-zabbix-template/master/pfsense_zbx.php

# Remove parâmetros de usuário existentes
echo "Removendo parâmetros de usuário existentes..."
sed -i '' '/^UserParameter=/d' /usr/local/etc/zabbix6/zabbix_agentd.conf

# Configura os parâmetros de usuário para o Zabbix Agent
echo "Configurando Zabbix Agent..."
cat <<EOF >> /usr/local/etc/zabbix6/zabbix_agentd.conf
UserParameter=pfsense.states.max,grep "limit states" /tmp/rules.limits | cut -f4 -d ' '
UserParameter=pfsense.states.current,grep "current entries" /tmp/pfctl_si_out | tr -s ' ' | cut -f4 -d ' '
UserParameter=pfsense.mbuf.current,netstat -m | grep "mbuf clusters" | cut -f1 -d ' ' | cut -d '/' -f1
UserParameter=pfsense.mbuf.cache,netstat -m | grep "mbuf clusters" | cut -f1 -d ' ' | cut -d '/' -f2
UserParameter=pfsense.mbuf.max,netstat -m | grep "mbuf clusters" | cut -f1 -d ' ' | cut -d '/' -f4
UserParameter=pfsense.discovery[*],/usr/local/bin/php /root/scripts/pfsense_zbx.php discovery \$1
UserParameter=pfsense.value[*],/usr/local/bin/php /root/scripts/pfsense_zbx.php \$1 \$2 \$3
EOF

# Aumenta o valor do timeout para 3
echo "Aumentando o Timeout para 30..."
sed -i '' 's/^# Timeout=3/Timeout=30/' /usr/local/etc/zabbix6/zabbix_agentd.conf

# Reinicia o serviço do Zabbix Agent para aplicar as mudanças
echo "Reiniciando o Zabbix Agent..."
service zabbix_agentd restart

echo "Configuração do Zabbix Agent concluída!"
