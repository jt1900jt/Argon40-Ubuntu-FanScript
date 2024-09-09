#!/bin/bash

# Define constants
SERVICE_NAME="argon_fan_control"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"
CONFIG_FILE="/etc/argon_fan_config.json"
SCRIPT_FILE="/usr/local/bin/argon_fan_control.py"
GITHUB_REPO="https://raw.githubusercontent.com/your-username/your-repo/main"

# Install necessary packages
echo "Installing required packages..."
sudo apt update
sudo apt install -y python3 python3-pip
pip3 install RPi.GPIO

# Download the Python fan control script
echo "Downloading fan control script..."
sudo wget -O $SCRIPT_FILE "$GITHUB_REPO/argon_fan_control.py"
sudo chmod +x $SCRIPT_FILE

# Create a default configuration file
echo "Creating default configuration file..."
sudo wget -O $CONFIG_FILE "$GITHUB_REPO/fan_config.json"
sudo chmod 644 $CONFIG_FILE

# Create the systemd service file
echo "Creating systemd service..."
cat <<EOT | sudo tee $SERVICE_FILE > /dev/null
[Unit]
Description=Argon Fan Control Service
After=multi-user.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 $SCRIPT_FILE
Restart=on-failure
User=root

[Install]
WantedBy=multi-user.target
EOT

# Set appropriate permissions
sudo chmod 644 $SERVICE_FILE

# Reload systemd and enable the service
echo "Enabling and starting the fan control service..."
sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME
sudo systemctl start $SERVICE_NAME

echo "Installation complete. The fan control service is now running."
