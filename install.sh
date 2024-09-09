#!/bin/bash

# Define constants
SERVICE_NAME="fan_control"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"
CONFIG_FILE="/etc/fan_config.json"
FAN_CMD="/usr/local/bin/fan"
GITHUB_REPO="https://raw.githubusercontent.com/jt1900jt/Argon40-Ubuntu-FanScript/main"

# Function to install the fan control app
install_fan_control() {
    # Install necessary packages
    echo "Installing required packages..."
    sudo apt update
    sudo apt install -y python3 python3-pip jq

    # Download the fan command script
    echo "Downloading fan command script..."
    sudo wget -O $FAN_CMD "$GITHUB_REPO/fan"
    
    # Ensure that the fan command script is executable
    sudo chmod +x $FAN_CMD

    # Create a default configuration file
    echo "Creating default configuration file..."
    sudo wget -O $CONFIG_FILE "$GITHUB_REPO/fan_config.json"
    sudo chmod 644 $CONFIG_FILE

    # Create the systemd service file
    echo "Creating systemd service..."
    sudo bash -c "cat <<EOT > $SERVICE_FILE
[Unit]
Description=Fan Control Service
After=multi-user.target

[Service]
Type=simple
ExecStart=$FAN_CMD -poll
Restart=on-failure
User=root

[Install]
WantedBy=multi-user.target
EOT"

    # Set appropriate permissions for the service file
    sudo chmod 644 $SERVICE_FILE

    # Reload systemd daemon to recognize the new service
    echo "Reloading systemd daemon..."
    sudo systemctl daemon-reload

    # Enable and start the service
    echo "Enabling and starting the fan control service..."
    sudo systemctl enable $SERVICE_NAME
    sudo systemctl start $SERVICE_NAME

    echo "Installation complete. The fan control service should now be running."
}

# Function to uninstall the fan control app
uninstall_fan_control() {
    # Stop the service if running
    echo "Stopping the fan control service..."
    sudo systemctl stop $SERVICE_NAME

    # Disable the service
    echo "Disabling the fan control service..."
    sudo systemctl disable $SERVICE_NAME

    # Remove the systemd service file
    echo "Removing the systemd service file..."
    sudo rm -f $SERVICE_FILE

    # Reload the systemd daemon to apply changes
    echo "Reloading systemd daemon..."
    sudo systemctl daemon-reload

    # Remove the fan command script
    echo "Removing the fan command script..."
    sudo rm -f $FAN_CMD

    # Remove the configuration file
    echo "Removing the configuration file..."
    sudo rm -f $CONFIG_FILE

    echo "Uninstallation complete. The fan control app has been removed from your system."
}

# Command-line interface for install or uninstall
if [ "$1" == "uninstall" ]; then
    uninstall_fan_control
else
    install_fan_control
fi
