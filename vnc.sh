#!/bin/bash
# Auto-setup TigerVNC + LXDE dengan user 'master' dan password 'qwerty'

USERNAME="master"
DISPLAY="1"

echo "[1/6] Install LXDE + TigerVNC..."
sudo apt-get update && apt-get upgrade -y
sudo apt-get install -y tigervnc-standalone-server lxde-core lxterminal xfonts-base

echo "[2/6] Membuat user '$USERNAME' (jika belum ada)..."
if ! id "$USERNAME" &>/dev/null; then
    sudo adduser --disabled-password --gecos "" "$USERNAME"
    echo "$USERNAME:qwerty" | sudo chpasswd
    sudo usermod -aG sudo "$USERNAME"
fi

echo "[3/6] Setup password VNC untuk user $USERNAME..."
sudo -u $USERNAME mkdir -p /home/$USERNAME/.vnc
sudo -u $USERNAME bash -c "echo 'qwerty' | vncpasswd -f > /home/$USERNAME/.vnc/passwd"
sudo chmod 600 /home/$USERNAME/.vnc/passwd

echo "[4/6] Membuat file xstartup LXDE..."
cat <<EOF | sudo tee /home/$USERNAME/.vnc/xstartup
#!/bin/sh
export XKL_XMODMAP_DISABLE=1
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
startlxde &
EOF

sudo chmod +x /home/$USERNAME/.vnc/xstartup
sudo chown -R $USERNAME:$USERNAME /home/$USERNAME/.vnc

echo "[5/6] Membuat systemd service vncserver@.service..."
sudo tee /etc/systemd/system/vncserver@.service > /dev/null <<EOF
[Unit]
Description=TigerVNC server for %i
After=syslog.target network.target

[Service]
Type=forking
User=$USERNAME
PAMName=login
PIDFile=/home/$USERNAME/.vnc/%H:%i.pid
ExecStart=/usr/bin/vncserver :%i -geometry 1280x720 -depth 24 -localhost no
ExecStop=/usr/bin/vncserver -kill :%i

[Install]
WantedBy=multi-user.target
EOF

echo "[6/6] Enable dan start VNC service..."
sudo systemctl daemon-reload
sudo systemctl enable vncserver@$DISPLAY
sudo systemctl restart vncserver@$DISPLAY

echo "✅ Selesai! Akses VNC di: IP_ADDRESS:$DISPLAY (port $((5900 + DISPLAY)))"
echo "🔐 Login user: master / qwerty | VNC password: qwerty"
