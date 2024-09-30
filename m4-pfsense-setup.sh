#!/bin/sh

# Script para configurar pfSense para Zabbix e Speedtest

# 1. Copiar o arquivo pfsense_zbx.php
echo "Copiando o arquivo pfsense_zbx.php..."
curl --create-dirs -o /root/scripts/pfsense_zbx.php https://raw.githubusercontent.com/rbicelli/pfsense-zabbix-template/master/pfsense_zbx.php

# 2. Instalar o pacote Zabbix Agent
echo "Instalando o Zabbix Agent..."
pkg update
pkg install -y zabbix-agent6  # ou zabbix-agent5, dependendo do que você preferir

# 3. Adicionar User Parameters ao Zabbix Agent
echo "Adicionando User Parameters ao Zabbix Agent..."
cat << EOF >> /usr/local/etc/zabbix6/zabbix_agentd.conf
AllowRoot=1
UserParameter=pfsense.states.max,grep "limit states" /tmp/rules.limits | cut -f4 -d ' '
UserParameter=pfsense.states.current,grep "current entries" /tmp/pfctl_si_out | tr -s ' ' | cut -f4 -d ' '
UserParameter=pfsense.mbuf.current,netstat -m | grep "mbuf clusters" | cut -f1 -d ' ' | cut -d '/' -f1
UserParameter=pfsense.mbuf.cache,netstat -m | grep "mbuf clusters" | cut -f1 -d ' ' | cut -d '/' -f2
UserParameter=pfsense.mbuf.max,netstat -m | grep "mbuf clusters" | cut -f1 -d ' ' | cut -d '/' -f4
UserParameter=pfsense.discovery[*],/usr/local/bin/php /root/scripts/pfsense_zbx.php discovery \$1
UserParameter=pfsense.value[*],/usr/local/bin/php /root/scripts/pfsense_zbx.php \$1 \$2 \$3
EOF

# 4. Aumentar o Timeout
echo "Aumentando o Timeout do Zabbix Agent..."
sed -i '' 's/^Timeout=.*/Timeout=5/' /usr/local/etc/zabbix6/zabbix_agentd.conf

# 5. Configurar cronjob para a versão do sistema
echo "Configurando cronjob para a versão do sistema..."
/usr/local/bin/php /root/scripts/pfsense_zbx.php sysversion_cron

# 6. Verificar e instalar o pacote speedtest
echo "Verificando o pacote speedtest..."
PACKAGE_NAME=$(pkg search speedtest | grep -oE 'py[0-9]+-speedtest-cli')

if [ -z "$PACKAGE_NAME" ]; then
    echo "Pacote speedtest não encontrado."
    exit 1
fi

echo "Instalando o pacote $PACKAGE_NAME..."
pkg install -y $PACKAGE_NAME

# 7. Testar se o speedtest foi instalado corretamente
echo "Testando a instalação do speedtest..."
/usr/local/bin/speedtest

if [ $? -ne 0 ]; then
    echo "Erro ao executar speedtest. Baixando o script mais recente..."
    curl -Lo /usr/local/lib/python3.8/site-packages/speedtest.py https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py
fi

# 8. Configurar cronjob para o Speedtest
echo "Configurando cronjob para o Speedtest..."
/usr/local/bin/php /root/scripts/pfsense_zbx.php speedtest_cron

echo "Configuração do pfSense concluída."
