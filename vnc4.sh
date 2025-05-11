#!/bin/bash

VNC_PASS="pas123"
DISPLAY_NUM=1
active_user="$(logname)"
HOME_DIR="$(eval echo ~$active_user)"

# Buat systemd service untuk vncserver@.service dengan dynamic User
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
