#!/bin/bash

# Define constants
SERVICE_NAME="fan_control"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"
CONFIG_FILE="/etc/fan_config.json"
SCRIPT_FILE="/usr/local/bin/fan"
GITHUB_REPO="https://raw.githubusercontent.com/jt1900jt/Argon40-Ubuntu-FanScript/main"

# Function to install the fan control app
install_fan_control() {
    # Install necessary packages
    echo "Installing required packages..."
    sudo apt update
    sudo apt install -y python3 jq bc

    # Download the fan control script
    echo "Downloading fan control script..."
    sudo wget -O $SCRIPT_FILE "$GITHUB_REPO/fan"
    sudo chmod +x $SCRIPT_FILE

    # Create a default configuration file
    echo "Creating default configuration file..."
    sudo wget -O $CONFIG_FILE "$GITHUB_REPO/fan_config.json"
    sudo chmod 644 $CONFIG_FILE

    # Create the systemd service file for fan control
    echo "Creating systemd service..."
    sudo bash -c "cat <<EOT > /etc/systemd/system/$SERVICE_NAME.service
[Unit]
Description=Fan Control Service
After=multi-user.target

[Service]
Type=simple
ExecStart=$SCRIPT_FILE -poll
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOT"

    # Set appropriate permissions for the service file
    sudo chmod 644 /etc/systemd/system/$SERVICE_NAME.service

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
    sudo rm -f /etc/systemd/system/$SERVICE_NAME.service

    # Reload the systemd daemon to apply changes
    echo "Reloading systemd daemon..."
    sudo systemctl daemon-reload

    # Remove the fan control script
    echo "Removing the fan control script..."
    sudo rm -f $SCRIPT_FILE

    # Remove the configuration file
    echo "Removing the configuration file..."
    sudo rm -f $CONFIG_FILE

    echo "Uninstallation complete. The fan control app has been removed from your system."
}

# Function to update the fan control app
update_fan_control() {
    echo "Updating the fan control app from GitHub..."

    # Download the latest fan control script
    sudo wget -O $SCRIPT_FILE "$GITHUB_REPO/fan"
    sudo chmod +x $SCRIPT_FILE

    # Download the latest configuration file
    sudo wget -O $CONFIG_FILE "$GITHUB_REPO/fan_config.json"
    sudo chmod 644 $CONFIG_FILE

    # Reload the systemd service to apply the updates
    echo "Reloading systemd service..."
    sudo systemctl daemon-reload && sudo systemctl restart $SERVICE_NAME

    echo "Update complete. The fan control app has been updated."
}

# Command-line interface for install, uninstall, or update
if [ "$1" == "uninstall" ]; then
    uninstall_fan_control
elif [ "$1" == "update" ]; then
    update_fan_control
else
    install_fan_control
fi
