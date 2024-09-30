#!/bin/sh

# Instala o qemu-guest-agent
echo "Instalando qemu-guest-agent..."
pkg update
pkg install -y qemu-guest-agent

# Instruções para instalação do pacote Shellcmd na GUI
echo "Por favor, instale o pacote 'Shellcmd' através da interface web em 'System > Package Manager'."

# Aguarda a instalação do pacote Shellcmd
echo "Aguardando instalação do pacote 'Shellcmd'..."
sleep 10  # Ajuste o tempo conforme necessário

# Cria o early shell command para iniciar o qemu-guest-agent
echo "Criando o early shell command para iniciar o qemu-guest-agent..."
cat <<EOF >> /usr/local/etc/shellcmd.conf
service qemu-guest-agent start
EOF

# Edita o rc.conf.local para habilitar o qemu-guest-agent
echo "Editando /etc/rc.conf.local para habilitar o qemu-guest-agent..."
cat <<EOF >> /etc/rc.conf.local
qemu_guest_agent_enable="YES"
qemu_guest_agent_flags="-d -v -l /var/log/qemu-ga.log"
EOF

# Adiciona o tunable virtio_console_load
echo "Adicionando tunable virtio_console_load..."
sysctl -w kern.virtio_console_load=1

# Mensagem final
echo "Configuração do qemu-guest-agent concluída. Por favor, reinicie o sistema para aplicar as mudanças."
