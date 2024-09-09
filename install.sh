#!/bin/bash

# Define constants
SERVICE_NAME="fan_control"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"
CONFIG_FILE="/etc/fan_config.json"
SCRIPT_FILE="/usr/local/bin/fan"
MANPAGE_FILE="/usr/local/man/man1/fan.1.gz"
GITHUB_REPO="https://raw.githubusercontent.com/jt1900jt/Argon40-Ubuntu-FanScript/main"

# Function to install the fan control app
install_fan_control() {
    # Install necessary packages
    echo "Installing required packages..."
    sudo apt update
    sudo apt install -y python3 python3-pip jq gzip

    # Download the fan control script
    echo "Downloading fan control script..."
    sudo wget -O $SCRIPT_FILE "$GITHUB_REPO/fan"
    sudo chmod +x $SCRIPT_FILE

    # Download the man page
    echo "Downloading and installing man page..."
    sudo wget -O /usr/local/man/man1/fan.1 "$GITHUB_REPO/fan.1"
    sudo gzip /usr/local/man/man1/fan.1

    # Ensure the man page directory is in the MANPATH
    if ! manpath | grep -q "/usr/local/man"; then
        echo "Adding /usr/local/man to MANPATH..."
        export MANPATH=$MANPATH:/usr/local/man
        echo 'export MANPATH=$MANPATH:/usr/local/man' >> ~/.bashrc
    fi

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
ExecStart=/usr/local/bin/fan -poll
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

    # Remove the fan control script
    echo "Removing the fan control script..."
    sudo rm -f $SCRIPT_FILE

    # Remove the configuration file
    echo "Removing the configuration file..."
    sudo rm -f $CONFIG_FILE

    # Remove the man page
    echo "Removing the man page..."
    sudo rm -f /usr/local/man/man1/fan.1.gz

    echo "Uninstallation complete. The fan control app has been removed from your system."
}

# Command-line interface for install or uninstall
if [ "$1" == "uninstall" ]; then
    uninstall_fan_control
else
    install_fan_control
fi
