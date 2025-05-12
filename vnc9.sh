#!/bin/bash

# Nama script: setup_vnc_lxde.sh
# Deskripsi: Install LXDE & TigerVNC; setup VNC server di display :1

VNC_PASS="pas123"
DISPLAY_NUM=1
active_user="$(logname)"
HOME_DIR="$(eval echo ~$active_user)"

# Tentukan Type systemd berdasarkan user
if [ "$EUID" -eq 0 ]; then
    SYSTEMD_TYPE="forking"
    PIDFILE="PIDFile=$HOME_DIR/.vnc/%H:%i.pid"
else
    SYSTEMD_TYPE="simple"
    PIDFILE=""
fi

# Update & upgrade paket
sudo apt update && sudo apt upgrade -y

# Install LXDE dan TigerVNC
sudo apt install -y lxde-core lxterminal xfonts-base lxsession tigervnc-standalone-server

# Buat direktori .vnc dan file xstartup
sudo -u "$active_user" mkdir -p "$HOME_DIR/.vnc"

sudo tee "$HOME_DIR/.vnc/xstartup" > /dev/null <<EOF
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
xrdb \$HOME/.Xresources
lxsession -s Lubuntu -e LXDE &
EOF

sudo chown "$active_user:$active_user" "$HOME_DIR/.vnc/xstartup"
sudo chmod +x "$HOME_DIR/.vnc/xstartup"

# Siapkan file .Xauthority
sudo -u "$active_user" touch "$HOME_DIR/.Xauthority"
sudo chown "$active_user:$active_user" "$HOME_DIR/.Xauthority"
sudo chmod 600 "$HOME_DIR/.Xauthority"

# Setup password VNC dan buat sesi awal
sudo vncserver ---pretend-input-tty <<EOF
$VNC_PASS
$VNC_PASS
n
EOF

# Matikan semua sesi VNC lama & bersihkan
sudo -u "$active_user" vncserver -kill :*
sudo -u "$active_user" rm -f "$HOME_DIR/.vnc/"*.pid "$HOME_DIR/.vnc/"*.log "$HOME_DIR/.vnc/"*.sock

# Buat systemd service
sudo tee /etc/systemd/system/vncserver@.service > /dev/null <<EOF
[Unit]
Description=Start TigerVNC server at startup for user $active_user (display :%i)
After=network.target

[Service]
Type=$SYSTEMD_TYPE
User=%u
PAMName=login
$PIDFILE
ExecStartPre=-/usr/bin/vncserver -kill :%i > /dev/null 2>&1
ExecStart=/usr/bin/vncserver :%i -geometry 1024x768 -depth 16 -dpi 96 -localhost no
ExecStop=/usr/bin/vncserver -kill :%i

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd & aktifkan VNC
sudo systemctl daemon-reload
sudo systemctl enable "vncserver@$DISPLAY_NUM"
sudo systemctl restart "vncserver@$DISPLAY_NUM"

echo "✅ VNC server aktif untuk user $active_user di display :$DISPLAY_NUM"
echo "🔑 Password: $VNC_PASS (akses via port $((5900 + DISPLAY_NUM)))"
