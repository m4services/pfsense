#!/bin/sh

# Instala o qemu-guest-agent
echo "Instalando qemu-guest-agent..."
pkg update
pkg install -y qemu-guest-agent

# Edita o rc.conf para habilitar o qemu-guest-agent
echo "Editando /etc/rc.conf para habilitar o qemu-guest-agent..."
cat <<EOF >> /etc/rc.conf
qemu_guest_agent_enable="YES"
qemu_guest_agent_flags="-d -v -l /var/log/qemu-ga.log"
EOF

# Adiciona o tunable virtio_console_load
echo "Adicionando tunable virtio_console_load..."
echo 'virtio_console_load="YES"' >> /boot/loader.conf

# Mensagem final
echo "Configuração do qemu-guest-agent concluída."
echo "O tunable 'virtio_console_load' foi adicionado ao /boot/loader.conf."
echo "Por favor, reinicie o sistema para aplicar as mudanças."
