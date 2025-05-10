#!/bin/bash

# Nama script: setup_vnc_lxde.sh
# Deskripsi: Install LXDE & TigerVNC; setup VNC server di display :1

# --- Deklarasi Password VNC ---
VNC_PASS="pas123"

# Ubah hostname (opsional)
hostnamectl set-hostname ubuntu

# Update & upgrade paket
echo "[1/6] Update & upgrade sistem..."
sudo apt update && sudo apt upgrade -y

# Install LXDE
echo "[2/6] Install LXDE..."
sudo apt install -y lxde-core lxterminal xfonts-base

# Install TigerVNC
echo "[3/6] Install TigerVNC..."
sudo apt install -y tigervnc-standalone-server

# Set password VNC dan buat sesi awal
echo "[4/6] Setup password VNC dan buat sesi..."
vncserver --pretend-input-tty <<EOF
$VNC_PASS
$VNC_PASS
n
EOF

# Matikan sesi VNC lama dan bersihkan cache
echo "[5/6] Kill sesi lama dan bersihkan cache..."
vncserver -kill :* 2>/dev/null || true
rm -f "$HOME/.vnc/"*.pid "$HOME/.vnc/"*.log "$HOME/.vnc/"*.sock

# Buat direktori .vnc jika belum ada dan file xstartup
echo "[6/6] Buat direktori $HOME/.vnc dan file xstartup..."
mkdir -p "$HOME/.vnc"

cat <<EOF > "$HOME/.vnc/xstartup"
#!/bin/bash
xrdb \$HOME/.Xresources
startlxde &
EOF

chmod +x "$HOME/.vnc/xstartup"

# Buat systemd service
sudo tee /etc/systemd/system/vncserver@.service > /dev/null <<EOF
[Unit]
Description=Start TigerVNC server at startup
After=syslog.target network.target

[Service]
Type=forking
User=root
PAMName=login
PIDFile=%h/.vnc/%H:%i.pid
ExecStartPre=-/usr/bin/vncserver -kill :* > /dev/null 2>&1
ExecStart=/usr/bin/vncserver -geometry 1024x768 -depth 16 -dpi 96 -localhost no :%i
ExecStop=/usr/bin/vncserver -kill :*

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd dan aktifkan service
echo "[7/6] Reload daemon dan start vncserver@1.service"
sudo systemctl daemon-reload
sudo systemctl enable vncserver@1.service
sudo systemctl start vncserver@1.service

echo "✅ VNC server is up on display :1 (port 5901) with password: $VNC_PASS"
