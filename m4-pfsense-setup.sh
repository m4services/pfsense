#!/bin/sh

# Baixa o arquivo pfsense_zbx.php para o diretório /root/scripts
echo "Baixando o arquivo pfsense_zbx.php..."
curl --create-dirs -o /root/scripts/pfsense_zbx.php https://raw.githubusercontent.com/rbicelli/pfsense-zabbix-template/master/pfsense_zbx.php

# Remove parâmetros de usuário existentes
echo "Removendo parâmetros de usuário existentes..."
sed -i '' '/^UserParameter=/d' /usr/local/etc/zabbix6/zabbix_agentd.conf

# Edita o Timeout para 30
echo "Configurando o Timeout para 30..."
sed -i '' '/^Timeout=/d' /usr/local/etc/zabbix6/zabbix_agentd.conf
sed -i '' '/^StartAgents=/i\
Timeout=30\
' /usr/local/etc/zabbix6/zabbix_agentd.conf

# Adiciona AllowRoot e UserParameters na posição correta
echo "Configurando Zabbix Agent..."
{
  echo
  echo "AllowRoot=1"
  echo "UserParameter=pfsense.states.max,grep \"limit states\" /tmp/rules.limits | cut -f4 -d ' '"
  echo "UserParameter=pfsense.states.current,grep \"current entries\" /tmp/pfctl_si_out | tr -s ' ' | cut -f4 -d ' '"
  echo "UserParameter=pfsense.mbuf.current,netstat -m | grep \"mbuf clusters\" | cut -f1 -d ' ' | cut -d '/' -f1"
  echo "UserParameter=pfsense.mbuf.cache,netstat -m | grep \"mbuf clusters\" | cut -f1 -d ' ' | cut -d '/' -f2"
  echo "UserParameter=pfsense.mbuf.max,netstat -m | grep \"mbuf clusters\" | cut -f1 -d ' ' | cut -d '/' -f4"
  echo "UserParameter=pfsense.discovery[*],/usr/local/bin/php /root/scripts/pfsense_zbx.php discovery \$1"
  echo "UserParameter=pfsense.value[*],/usr/local/bin/php /root/scripts/pfsense_zbx.php \$1 \$2 \$3"
} >> /usr/local/etc/zabbix6/zabbix_agentd.conf

# Reinicia o serviço do Zabbix Agent para aplicar as mudanças
echo "Reiniciando o Zabbix Agent..."
service zabbix_agentd restart

# Verifica o status do Zabbix Agent
echo "Verificando o status do Zabbix Agent..."
service zabbix_agentd status

echo "Configuração do Zabbix Agent concluída!"
