PASSWORD="root1234"
echo "root:$PASSWORD" | chpasswd

cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
sed -i '/^#\?PermitRootLogin/c\PermitRootLogin yes' /etc/ssh/sshd_config
systemctl restart ssh
