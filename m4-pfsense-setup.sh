#!/bin/sh

# Ativa o modo de depuração para exibir todos os comandos executados
set -x

# Baixa o arquivo pfsense_zbx.php para o diretório /root/scripts
echo "Baixando o arquivo pfsense_zbx.php..."
curl --create-dirs -o /root/scripts/pfsense_zbx.php https://raw.githubusercontent.com/rbicelli/pfsense-zabbix-template/master/pfsense_zbx.php

# Remove qualquer configuração duplicada das opções avançadas do Zabbix Agent
echo "Removendo configurações duplicadas do Zabbix Agent..."
sed -i '' '/AllowRoot=1/d' /usr/local/etc/zabbix_agentd.conf
sed -i '' '/UserParameter=pfsense.states.max/d' /usr/local/etc/zabbix_agentd.conf
sed -i '' '/UserParameter=pfsense.states.current/d' /usr/local/etc/zabbix_agentd.conf
sed -i '' '/UserParameter=pfsense.mbuf.current/d' /usr/local/etc/zabbix_agentd.conf
sed -i '' '/UserParameter=pfsense.mbuf.cache/d' /usr/local/etc/zabbix_agentd.conf
sed -i '' '/UserParameter=pfsense.mbuf.max/d' /usr/local/etc/zabbix_agentd.conf
sed -i '' '/UserParameter=pfsense.discovery/d' /usr/local/etc/zabbix_agentd.conf
sed -i '' '/UserParameter=pfsense.value/d' /usr/local/etc/zabbix_agentd.conf

# Adiciona as novas configurações ao Zabbix Agent
echo "Configurando Zabbix Agent..."
cat <<EOF >> /usr/local/etc/zabbix_agentd.conf
AllowRoot=1
UserParameter=pfsense.states.max,grep "limit states" /tmp/rules.limits | cut -f4 -d ' '
UserParameter=pfsense.states.current,grep "current entries" /tmp/pfctl_si_out | tr -s ' ' | cut -f4 -d ' '
UserParameter=pfsense.mbuf.current,netstat -m | grep "mbuf clusters" | cut -f1 -d ' ' | cut -d '/' -f1
UserParameter=pfsense.mbuf.cache,netstat -m | grep "mbuf clusters" | cut -f1 -d ' ' | cut -d '/' -f2
UserParameter=pfsense.mbuf.max,netstat -m | grep "mbuf clusters" | cut -f1 -d ' ' | cut -d '/' -f4
UserParameter=pfsense.discovery[*],/usr/local/bin/php /root/scripts/pfsense_zbx.php discovery \$1
UserParameter=pfsense.value[*],/usr/local/bin/php /root/scripts/pfsense_zbx.php \$1 \$2 \$3
EOF

# Habilita o Zabbix Agent no /etc/rc.conf
echo "Habilitando Zabbix Agent no /etc/rc.conf..."
echo 'zabbix_agentd_enable="YES"' >> /etc/rc.conf

# Aumenta o valor do timeout para 5 no arquivo de configuração do Zabbix
echo "Aumentando o Timeout para 5..."
sed -i '' 's/^# Timeout=3/Timeout=5/' /usr/local/etc/zabbix_agentd.conf

# Reinicia o serviço do Zabbix Agent com 'onerestart'
echo "Reiniciando o Zabbix Agent..."
service zabbix_agentd onerestart

# Instala o Speedtest CLI e configura o cronjob para o sysversion
echo "Instalando Speedtest e configurando cronjob..."
pkg update && pkg install -y py311-speedtest-cli-2.1.3
/usr/local/bin/php /root/scripts/pfsense_zbx.php sysversion_cron

# Corrige a instalação do speedtest caso necessário
echo "Corrigindo a instalação do Speedtest (se necessário)..."
curl -Lo /usr/local/lib/python3.11/site-packages/speedtest.py https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py

# Testa a instalação do Speedtest
echo "Testando o Speedtest..."
/usr/local/bin/speedtest

# Configura o cronjob para rodar o speedtest regularmente
echo "Configurando o cronjob do Speedtest..."
/usr/local/bin/php /root/scripts/pfsense_zbx.php speedtest_cron

echo "Script finalizado com sucesso!"

# Desativa o modo de depuração
set +x
