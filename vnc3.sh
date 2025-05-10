#!/bin/bash

# Nama script: setup_vnc_lxde.sh
# Deskripsi: Install LXDE & TigerVNC; setup VNC server di display :1

set -e

# --- Variabel ---
VNC_PASS="pas123"
# Gunakan logname untuk mendapatkan user yang menjalankan skrip
active_user="$(logname)"
HOME_DIR="$(eval echo ~$active_user)"
DISPLAY_NUM=1

# Ubah hostname (opsional)
hostnamectl set-hostname ubuntu

# 1) Update & upgrade paket
echo "[1/6] Update & upgrade sistem..."
sudo apt update && sudo apt upgrade -y

# 2) Install LXDE
echo "[2/6] Install LXDE..."
sudo apt install -y lxde-core lxterminal xfonts-base

# 3) Install TigerVNC
echo "[3/6] Install TigerVNC..."
sudo apt install -y tigervnc-standalone-server

# 4) Setup password VNC dan buat sesi awal
echo "[4/6] Setup password VNC dan buat sesi untuk $active_user..."
sudo -u "$active_user" vncserver --pretend-input-tty <<EOF
$VNC_PASS
$VNC_PASS
n
EOF

# 5) Matikan sesi VNC lama & bersihkan cache
echo "[5/6] Kill sesi lama dan bersihkan cache untuk $active_user..."
sudo -u "$active_user" vncserver -kill :$DISPLAY_NUM 2>/dev/null || true
sudo rm -f "$HOME_DIR/.vnc/"*.pid
sudo rm -f "$HOME_DIR/.vnc/"*.log
sudo rm -f "$HOME_DIR/.vnc/"*.sock

# 6) Buat direktori .vnc jika belum ada dan file xstartup
echo "[6/6] Buat direktori $HOME_DIR/.vnc dan file xstartup..."
mkdir -p "$HOME_DIR/.vnc"
cat <<EOF > "$HOME_DIR/.vnc/xstartup"
#!/bin/bash
xrdb \$HOME/.Xresources
startlxde &
EOF
chmod +x "$HOME_DIR/.vnc/xstartup"
sudo chown -R "$active_user":"$active_user" "$HOME_DIR/.vnc"

# 7) Buat systemd service untuk vncserver@.service dengan dynamic User
sudo tee /etc/systemd/system/vncserver@.service > /dev/null <<EOF
[Unit]
Description=Start TigerVNC server at startup for user $active_user (display :%i)
After=syslog.target network.target

[Service]
Type=forking
User=$active_user
PAMName=login
PIDFile=$HOME_DIR/.vnc/%H:%i.pid
ExecStartPre=-/usr/bin/vncserver -kill :%i > /dev/null 2>&1
ExecStart=/usr/bin/vncserver :%i -geometry 1024x768 -depth 16 -dpi 96 -localhost no
ExecStop=/usr/bin/vncserver -kill :%i

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd dan aktifkan service
sudo systemctl daemon-reload
echo "Enabling vncserver@$DISPLAY_NUM.service for $active_user..."
sudo systemctl enable "vncserver@$DISPLAY_NUM.service"
echo "Starting vncserver@$DISPLAY_NUM.service for $active_user..."
sudo systemctl start "vncserver@$DISPLAY_NUM.service"

echo
s="✅ VNC server untuk user $active_user sudah aktif di display :$DISPLAY_NUM"
echo "$s (port $((5900 + DISPLAY_NUM))) dengan password: $VNC_PASS"
