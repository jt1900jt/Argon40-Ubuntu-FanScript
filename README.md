#Argon Fan Control Script

This script is designed to control the fan speed of the Argon case on Ubuntu and Raspberry Pi systems. It supports configuring fan speed based on temperature thresholds, setting hysteresis values, and managing the fan control service.

#Installation

    Clone or download the repository.
    Run the install.sh script to install the necessary files and start the fan control service.

bash

sudo ./install.sh

To uninstall:

bash

sudo ./install.sh uninstall

Commands
1. argon -update

This command updates the fan control script, configuration, and the argon command itself by pulling the latest versions from GitHub.

bash

sudo argon -update

2. argon -speed

Displays the current fan speed based on the CPU temperature and the configured fan speed curve.

bash

sudo argon -speed

3. argon -temp

Displays the current CPU temperature.

bash

sudo argon -temp

4. argon -h <hysteresis_value>

Updates the hysteresis value. The hysteresis value prevents frequent toggling of the fan by providing a buffer temperature.

bash

sudo argon -h 5

In the above example, the hysteresis is set to 5°C.
5. argon -config temp:fanspeed,temp1:fanspeed1,...

Configures the fan speed based on temperature thresholds. You can specify multiple temperature and fan speed pairs.

bash

sudo argon -config 40:30,50:50,60:70,70:100

In this example:

    At 40°C, the fan runs at 30% speed.
    At 50°C, the fan runs at 50% speed.
    At 60°C, the fan runs at 70% speed.
    At 70°C and above, the fan runs at 100% speed.

6. argon -show

Displays the current fan configuration (temperature thresholds and corresponding fan speeds) and the hysteresis value in a human-readable format.

bash

sudo argon -show

Example output:

yaml

Current Fan Configuration:
Fan Speeds:
  Temperature: 40°C => Fan Speed: 30%
  Temperature: 50°C => Fan Speed: 50%
  Temperature: 60°C => Fan Speed: 70%
  Temperature: 70°C => Fan Speed: 100%
Hysteresis: 5°C

7. argon -stop

Stops the fan control service and sets the fan speed to 0 (turns off the fan).

bash

sudo argon -stop

8. argon -start

Starts the fan control service if it is not running.

bash

sudo argon -start

9. Service Management

You can also manually control the fan control service using systemd:

    Check the status:

    bash

sudo systemctl status argon_fan_control.service

Restart the service:

bash

    sudo systemctl restart argon_fan_control.service

Troubleshooting
1. Fan not responding

    Ensure that the fan is properly connected to the correct GPIO pin.
    Verify the service status:

    bash

    sudo systemctl status argon_fan_control.service

2. Fan speed not updating

Ensure that the configuration is properly set using the -config command. You can check the configuration using the -show command.
3. Error during update

If argon -update does not seem to be updating the script, you can manually download the latest files from the GitHub repository:

bash

sudo wget -O /usr/local/bin/argon https://raw.githubusercontent.com/jt1900jt/Argon40-Ubuntu-FanScript/main/argon
sudo chmod +x /usr/local/bin/argon

License

This script is open-source and available for use and modification. Feel free to contribute!
