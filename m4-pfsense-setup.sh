#!/bin/sh

# Script para configurar pfSense para Zabbix e Speedtest

# 1. Copiar o arquivo pfsense_zbx.php
echo "Copiando o arquivo pfsense_zbx.php..."
curl --create-dirs -o /root/scripts/pfsense_zbx.php https://raw.githubusercontent.com/rbicelli/pfsense-zabbix-template/master/pfsense_zbx.php

# 2. Instalar o pacote Zabbix Agent
echo "Instalando o Zabbix Agent..."
pkg update
pkg install -y zabbix-agent6  # ou zabbix-agent5, dependendo do que você preferir

# 3. Configurar cronjob para a versão do sistema
echo "Configurando cronjob para a versão do sistema..."
/usr/local/bin/php /root/scripts/pfsense_zbx.php sysversion_cron

# 4. Verificar e instalar o pacote speedtest
echo "Verificando o pacote speedtest..."
PACKAGE_NAME=$(pkg search speedtest | grep -oE 'py[0-9]+-speedtest-cli')

if [ -z "$PACKAGE_NAME" ]; then
    echo "Pacote speedtest não encontrado."
    exit 1
fi

echo "Instalando o pacote $PACKAGE_NAME..."
pkg install -y $PACKAGE_NAME

# 5. Testar se o speedtest foi instalado corretamente
echo "Testando a instalação do speedtest..."
/usr/local/bin/speedtest

if [ $? -ne 0 ]; then
    echo "Erro ao executar speedtest. Baixando o script mais recente..."
    curl -Lo /usr/local/lib/python3.11/site-packages/speedtest.py https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py
fi

# 6. Configurar cronjob para o Speedtest
echo "Configurando cronjob para o Speedtest..."
/usr/local/bin/php /root/scripts/pfsense_zbx.php speedtest_cron

echo "Configuração do pfSense concluída."

echo "EDITE O TIMEOUT."

echo "EDITE O USERPARAMETERS DO ZABBIX AGENT."
