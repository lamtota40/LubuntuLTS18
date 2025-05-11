#!/bin/bash

# Nama script: setup_vnc_lxde.sh
# Deskripsi: Install LXDE & TigerVNC; setup VNC server di display :1

# Gunakan logname untuk mendapatkan user yang menjalankan skrip
VNC_PASS="pas123"
DISPLAY_NUM=1
active_user="$(logname)"
HOME_DIR="$(eval echo ~$active_user)"

# Ubah hostname (opsional)
hostnamectl set-hostname ubuntu

# Update & upgrade paket
sudo apt update && sudo apt upgrade -y

# Install LXDE
sudo apt install -y lxde-core lxterminal xfonts-base lxsession

# Install TigerVNC
sudo apt install -y tigervnc-standalone-server

# Buat direktori .vnc jika belum ada dan file xstartup
mkdir -p "$HOME_DIR/.vnc"

cat <<EOF > ~/.vnc/xstartup
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
xrdb \$HOME/.Xresources
lxsession -s Lubuntu -e LXDE &
EOF

chmod +x ~/.vnc/xstartup 
# Setup password VNC dan buat sesi awal
sudo vncserver ---pretend-input-tty <<EOF
$VNC_PASS
$VNC_PASS
n
EOF

# Matikan semua sesi VNC lama & Hapus semua log dan cache
sudo vncserver -kill :*
sudo rm -f "$HOME_DIR/.vnc/"*.pid
sudo rm -f "$HOME_DIR/.vnc/"*.log
sudo rm -f "$HOME_DIR/.vnc/"*.sock

# Buat systemd service untuk vncserver@.service dengan dynamic User
cat <<EOF > /etc/systemd/system/vncserver@.service
[Unit]
Description=Start TigerVNC server at startup for user $active_user (display :%i)
After=syslog.target network.target

[Service]
Type=forking
User=$active_user
PAMName=login
PIDFile=$HOME_DIR/.vnc/%H:%i.pid
ExecStartPre=-/usr/bin/vncserver -kill :* > /dev/null 2>&1
ExecStart=/usr/bin/vncserver :%i -geometry 1024x768 -depth 16 -dpi 96 -localhost no -IdleTimeout=300

ExecStop=/usr/bin/vncserver -kill :*

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd dan aktifkan service
sudo systemctl daemon-reload
sudo systemctl enable "vncserver@$DISPLAY_NUM.service"
sudo systemctl start "vncserver@$DISPLAY_NUM.service"

echo "VNC server untuk user $active_user sudah aktif di display :$DISPLAY_NUM"
echo "$s (port $((5900 + DISPLAY_NUM))) dengan password: $VNC_PASS"


sudo chown lubuntu:lubuntu /home/lubuntu/.vnc/passwd
sudo chmod 600 /home/lubuntu/.vnc/passwd
sudo rm -f /home/lubuntu/.Xauthority
sudo touch /home/lubuntu/.Xauthority
sudo chown lubuntu:lubuntu /home/lubuntu/.Xauthority
sudo chmod 600 /home/lubuntu/.Xauthority

