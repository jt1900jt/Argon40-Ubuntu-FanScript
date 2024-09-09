Raspberry Pi Fan Control Script

This project provides a simple yet effective way to control a fan on a Raspberry Pi, adjusting the fan speed based on the CPU temperature. The script polls the temperature at regular intervals and adjusts the fan speed accordingly. It also includes functionality for configuring fan speed thresholds, updating hysteresis values, and more.
Features

    Automatic Fan Control: Adjusts fan speed based on CPU temperature thresholds.
    Configurable Fan Speeds: Set temperature thresholds for different fan speeds (off, low, medium, high, full).
    Hysteresis: Prevents unnecessary fan speed changes by defining a buffer range.
    Status Check: Displays the current CPU temperature and fan speed.
    Service Management: Start, stop, and restart the fan control service.
    Update: Easily update the script from GitHub.
    Uninstall: Completely remove the fan control service from your system.

Installation
Step 1: Download and Install the Script

To install the fan control script, use the following command to download and run the installer:

bash

wget https://raw.githubusercontent.com/jt1900jt/Argon40-Ubuntu-FanScript/main/install.sh
sudo chmod +x install.sh
sudo ./install.sh

The installation will:

    Install required packages (python3, jq).
    Download the fan control script and configuration file.
    Set up the fan control service to run automatically.

Step 2: Configuration

The script uses a configuration file located at /etc/fan_config.json. The file contains temperature thresholds for the different fan speeds:

json

{
  "fan_speeds": {
    "off": 55,
    "low": 60,
    "medium": 68,
    "high": 75,
    "full": 80
  },
  "hysteresis": 5
}

You can manually edit this file or use the built-in commands to modify it.
Usage
Fan Command

The main command to interact with the fan control script is:

bash

fan [option]

Available Options

    fan -status: Displays the current CPU temperature and fan speed.
    fan -config off:temp,low:temp,medium:temp,high:temp,full:temp: Updates the temperature thresholds for fan speeds.
    fan -h hysteresis_value: Updates the hysteresis value.
    fan -show: Displays the current fan configuration.
    fan -start: Starts the fan control service.
    fan -stop: Stops the fan control service and turns off the fan.
    fan -poll: Continuously monitors the temperature and adjusts the fan speed.
    fan -update: Updates the script and configuration from GitHub.
    fan -uninstall: Completely removes the fan control service and configuration files.

Examples
Check Current Fan Status

bash

fan -status

Update Fan Speed Configuration

bash

fan -config off:55,low:60,medium:68,high:75,full:80

Update Hysteresis Value

bash

fan -h 5

Start or Stop the Fan Control Service

bash

fan -start
fan -stop

Update the Script

bash

fan -update

Uninstall the Script

bash

fan -uninstall

Uninstalling

To completely remove the fan control script and service, use the following command:

bash

fan -uninstall

This will stop the service, remove the script, and delete the configuration files.
