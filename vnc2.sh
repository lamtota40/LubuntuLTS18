#!/bin/bash

sudo apt update && sudo apt upgrade -y
sudo apt install tigervnc-standalone-server -y
sudo apt install -y net-tools
sudo apt install lxde-core lxterminal xfonts-base -y

vncserver ---pretend-input-tty <<EOF
pas123
pas123
n
EOF
vncserver -kill :*

mkdir -p /root/.vnc

cat <<EOF > ~/.vnc/xstartup
#!/bin/bash
xrdb $HOME/.Xresources
startlxde &
EOF

chmod +x ~/.vnc/xstartup

cat <<EOF > /etc/systemd/system/vncserver@.service
[Unit]
Description=Start TightVNC server at startup
After=syslog.target network.target

[Service]
Type=forking
User=root
PAMName=login
PIDFile=/root/.vnc/%H:%i.pid
ExecStartPre=-/usr/bin/vncserver -kill :%i > /dev/null 2>&1
ExecStart=/usr/bin/vncserver -geometry 1024x768 -depth 16 -dpi 96 -localhost no :%i
ExecStop=/usr/bin/vncserver -kill :%i

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable vncserver@1.service
sudo systemctl start vncserver@1.service
