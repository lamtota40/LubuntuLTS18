#!/bin/bash
#
# setup_vnc_lxde.sh
# Usage (as yourself, tidak perlu sudo di panggilnya):
#   sudo ./setup_vnc_lxde.sh [username] [vnc_password]
#
# contoh:
#   sudo ./setup_vnc_lxde.sh root pas123
#   sudo ./setup_vnc_lxde.sh lubuntu secret

set -e

# --- Parameter dan default ---
VNC_USER="${1:-$(logname)}"
VNC_PASS="${2:-pas123}"
DISPLAY_NUM=1

# --- Cari home directory user (bisa root atau user biasa) ---
HOME_DIR=$(getent passwd "$VNC_USER" | cut -d: -f6)
if [ -z "$HOME_DIR" ]; then
  echo "Error: user '$VNC_USER' tidak ditemukan!" >&2
  exit 1
fi

# --- 1) Install LXDE & TigerVNC ---
sudo apt update
sudo apt install -y lxde-core lxterminal xfonts-base tigervnc-standalone-server

# --- 2) Setup VNC password menggunakan pretend-input-tty ---
sudo -u "$VNC_USER" mkdir -p "$HOME_DIR/.vnc"
sudo -u "$VNC_USER" bash -c "vncserver --pretend-input-tty <<EOF
$VNC_PASS
$VNC_PASS
n
EOF"

# --- 3) Bersihkan sisa sesi lama & cache ---
sudo -u "$VNC_USER" vncserver -kill :"$DISPLAY_NUM" 2>/dev/null || true
sudo rm -f "$HOME_DIR/.vnc/"*.pid
sudo rm -f "$HOME_DIR/.vnc/"*.log
sudo rm -f "$HOME_DIR/.vnc/"*.sock
sudo rm -f /tmp/.X${DISPLAY_NUM}-lock
sudo rm -f /tmp/.X11-unix/X${DISPLAY_NUM}

# --- 4) Buat ulang file xstartup ---
cat <<'EOF' | sudo tee "$HOME_DIR/.vnc/xstartup" > /dev/null
#!/bin/sh
xrdb $HOME/.Xresources
startlxde &
EOF
sudo chmod +x "$HOME_DIR/.vnc/xstartup"
sudo chown -R "$VNC_USER":"$VNC_USER" "$HOME_DIR/.vnc"

# --- 5) Buat systemd service vncserver@.service ---
sudo tee /etc/systemd/system/vncserver@.service > /dev/null <<EOF
[Unit]
Description=TigerVNC server for user %i (display :${DISPLAY_NUM})
After=network.target

[Service]
Type=forking
User=%i
PAMName=login
PIDFile=${HOME_DIR}/.vnc/%H:${DISPLAY_NUM}.pid
ExecStartPre=-/usr/bin/vncserver -kill :${DISPLAY_NUM} > /dev/null 2>&1
ExecStart=/usr/bin/vncserver :${DISPLAY_NUM} -geometry 1024x768 -depth 16 -localhost no
ExecStop=/usr/bin/vncserver -kill :${DISPLAY_NUM}

[Install]
WantedBy=multi-user.target
EOF

# --- 6) Enable & start service ---
sudo systemctl daemon-reload
sudo systemctl enable vncserver@"$VNC_USER"
sudo systemctl restart vncserver@"$VNC_USER"

echo
echo "✅ VNC server untuk user '$VNC_USER' sudah running di display :${DISPLAY_NUM}"
echo "   • Port: $((5900 + DISPLAY_NUM))"
echo "   • Password VNC: $VNC_PASS"
echo "   • Home Dir: $HOME_DIR"
