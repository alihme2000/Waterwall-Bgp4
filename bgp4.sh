#!/bin/bash

setup_waterwall_service() {
    cat > /etc/systemd/system/waterwall-bgp4.service << EOF
[Unit]
Description=Waterwall-bgp4 Service
After=network.target

[Service]
ExecStart=/root/bgp4/Waterwall-bgp4
WorkingDirectory=/root/bgp4
Restart=always
RestartSec=5
User=root
StandardOutput=null
StandardError=null

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable waterwall-bgp4
    systemctl start waterwall-bgp4
}

while true; do
    echo "Please choose Number:"
    echo "1) Iran "
    echo "2) Kharej "
    echo "3) Uninstall"
    echo "9) Back"

    read -p "Enter your choice: " choice
    if [[ "$choice" -eq 1 || "$choice" -eq 2 ]]; then
        apt update
        sleep 0.5
        SSHD_CONFIG_FILE="/etc/ssh/sshd_config"
        CURRENT_PORT=$(grep -E '^(#Port |Port )' "$SSHD_CONFIG_FILE")

        if [[ "$CURRENT_PORT" != "Port 22" && "$CURRENT_PORT" != "#Port 22" ]]; then
            sudo sed -i -E 's/^(#Port |Port )[0-9]+/Port 22/' "$SSHD_CONFIG_FILE"
            echo "SSH Port has been updated to Port 22."
            sudo systemctl restart sshd
            sudo service ssh restart
        fi
        sleep 0.5
        mkdir /root/bgp4
        cd /root/bgp4
        wget https://github.com/radkesvat/WaterWall/releases/download/v1.21/Waterwall-linux-64.zip
        apt install unzip -y
        unzip Waterwall-linux-64.zip
        sleep 0.5
        chmod +x Waterwall
        sleep 0.5
        rm Waterwall-linux-64.zip
        cat > core.json << EOF
{
    "log": {
        "path": "log/",
        "core": {
            "loglevel": "DEBUG",
            "file": "core.log",
            "console": true
        },
        "network": {
            "loglevel": "DEBUG",
            "file": "network.log",
            "console": true
        },
        "dns": {
            "loglevel": "SILENT",
            "file": "dns.log",
            "console": false
        }
    },
    "dns": {},
    "misc": {
        "workers": 0,
        "ram-profile": "server",
        "libs-path": "libs/"
    },
    "configs": [
        "config.json"
    ]
}
EOF
        public_ip=$(wget -qO- https://api.ipify.org)
        echo "Your Server IPv4 is: $public_ip"
    fi

    if [ "$choice" -eq 1 ]; then
        echo "You chose Iran."
        read -p "enter iran Port: " port_local
        read -p "enter kharej IP: " ip_remote
        cat > config.json << EOF
{
    "name": "bgp_client",
    "nodes": [
        {
            "name": "input",
            "type": "TcpListener",
            "settings": {
                "address": "0.0.0.0",
                "port": $port_local,
                "nodelay": true
            },
            "next": "bgp_client"
        },
        {
            "name": "bgp_client",
            "type": "Bgp4Client",
            "settings": {},
            "next": "output"
        },
        {
            "name": "output",
            "type": "TcpConnector",
            "settings": {
                "nodelay": true,
                "address":"$ip_remote",
                "port":179
            }
        }
    ]
}
EOF
        sleep 0.5
        setup_waterwall_service
        sleep 0.5
        echo "Iran IPv4 is: $public_ip"
        echo "Kharej IPv4 is: $ip_remote"
        echo "Iran Setup Successfully Created "
    elif [ "$choice" -eq 2 ]; then
        echo "You chose Kharej."
        read -p "enter kharej Port: " port_local
        cat > config.json << EOF
{
    "name": "bgp_server",
    "nodes": [
        {
            "name": "input",
            "type": "TcpListener",
            "settings": {
                "address": "::",
                "port": 179,
                "nodelay": true
            },
            "next": "bgp_server"
        },
        {
            "name":"bgp_server",
            "type":"Bgp4Server",
            "settings":{},
            "next":"output"
        },
        
        {
            "name": "output",
            "type": "TcpConnector",
            "settings": {
                "nodelay": true,
                "address": "127.0.0.1",
                "port": $port_local
            }
        }

    ]
}
EOF
        sleep 0.5
        setup_waterwall_service
        sleep 0.5
        echo "Kharej IPv4 is: $public_ip"
        echo "Kharej Setup Successfully Created "
    elif [ "$choice" -eq 3 ]; then
        sudo systemctl stop waterwall-bgp4
        sudo systemctl disable waterwall-bgp4
        rm -rf /etc/systemd/system/waterwall-bgp4.service
        pkill -f Waterwall-bgp4
        rm -rf /root/bgp4

        echo "Removed"
    elif [ "$choice" -eq 9 ]; then
        echo "Going back..."
        break
    else
        echo "Invalid choice. Please try again."
    fi
done
