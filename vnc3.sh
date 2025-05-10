#!/bin/bash

# Nama script: setup_vnc_lxde.sh
# Deskripsi: Install LXDE & TigerVNC; setup VNC server di display :1

set -e

# Gunakan logname untuk mendapatkan user yang menjalankan skrip
active_user="$(logname)"
HOME_DIR="$(eval echo ~$active_user)"
DISPLAY_NUM=1
VNC_PASS="pas123"

# Ubah hostname (opsional)
hostnamectl set-hostname ubuntu

# 1) Update & upgrade paket
sudo apt update && sudo apt upgrade -y

# 2) Install LXDE
sudo apt install -y lxde-core lxterminal xfonts-base

# 3) Install TigerVNC
sudo apt install -y tigervnc-standalone-server

# 4) Setup password VNC dan buat sesi awal
sudo -u "$active_user" vncserver --pretend-input-tty <<EOF
$VNC_PASS
$VNC_PASS
n
EOF

# 5) Matikan semua sesi VNC lama
sudo vncserver -kill :*

# 6) Buat direktori .vnc jika belum ada dan file xstartup
mkdir -p "$HOME_DIR/.vnc"

cat <<EOF > ~/.vnc/xstartup
#!/bin/bash
xrdb \$HOME/.Xresources
startlxde &
EOF

chmod +x ~/.vnc/xstartup

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
ExecStartPre=-/usr/bin/vncserver -kill :* > /dev/null 2>&1
ExecStart=/usr/bin/vncserver :%i -geometry 1024x768 -depth 16 -dpi 96 -localhost no
ExecStop=/usr/bin/vncserver -kill :*

[Install]
WantedBy=multi-user.target
EOF

# Hapus semua log dan cache
sudo rm -f "$HOME_DIR/.vnc/"*.pid
sudo rm -f "$HOME_DIR/.vnc/"*.log
sudo rm -f "$HOME_DIR/.vnc/"*.sock

# Reload systemd dan aktifkan service
sudo systemctl daemon-reload
sudo systemctl enable "vncserver@$DISPLAY_NUM.service"
sudo systemctl start "vncserver@$DISPLAY_NUM.service"

echo
s="✅ VNC server untuk user $active_user sudah aktif di display :$DISPLAY_NUM"
echo "$s (port $((5900 + DISPLAY_NUM))) dengan password: $VNC_PASS"
