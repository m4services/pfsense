#!/bin/sh

# Script para configurar o pfSense para Speedtest

# 1. Copiar o arquivo pfsense_zbx.php
echo "Copiando o arquivo pfsense_zbx.php..."
curl --create-dirs -o /root/scripts/pfsense_zbx.php https://raw.githubusercontent.com/rbicelli/pfsense-zabbix-template/master/pfsense_zbx.php

# 2. Configurar cronjob para a versão do sistema
echo "Configurando cronjob para a versão do sistema..."
/usr/local/bin/php /root/scripts/pfsense_zbx.php sysversion_cron

# 3. Verificar e instalar o pacote speedtest
echo "Verificando o pacote speedtest..."
PACKAGE_NAME=$(pkg search speedtest | grep -oE 'py[0-9]+-speedtest-cli')

if [ -z "$PACKAGE_NAME" ]; then
    echo "Pacote speedtest não encontrado."
    exit 1
fi

echo "Instalando o pacote $PACKAGE_NAME..."
pkg install -y $PACKAGE_NAME

# 4. Testar se o speedtest foi instalado corretamente
echo "Testando a instalação do speedtest..."
/usr/local/bin/speedtest

if [ $? -ne 0 ]; then
    echo "Erro ao executar speedtest. Baixando o script mais recente..."
    curl -Lo /usr/local/lib/python3.8/site-packages/speedtest.py https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py
fi

# 5. Configurar cronjob para o Speedtest
echo "Configurando cronjob para o Speedtest..."
/usr/local/bin/php /root/scripts/pfsense_zbx.php speedtest_cron

echo "Configuração do pfSense concluída."

echo "EDITE O TIMEOUT."

echo "EDITE O USERPARAMETERS DO ZABBIX AGENT."
