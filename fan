#!/bin/bash

# Define constants
GITHUB_REPO="https://raw.githubusercontent.com/jt1900jt/Argon40-Ubuntu-FanScript/main"
CONFIG_FILE="/etc/fan_config.json"
FAN_CONTROL_FILE="/sys/class/thermal/cooling_device0/cur_state"
TEMP_COMMAND="/usr/bin/vcgencmd measure_temp"
SERVICE_NAME="fan_control"
FAN_CMD="/usr/local/bin/fan"
POLL_INTERVAL=60  # Time in seconds between temperature checks
last_fan_speed=-1  # Cache the last fan speed to avoid unnecessary I/O

# Function to load configuration from config.json
load_config() {
    if [ ! -f $CONFIG_FILE ]; then
        echo "Configuration file not found! Please create $CONFIG_FILE"
        exit 1
    fi
    off_temp=$(jq '.fan_speeds.off' $CONFIG_FILE)
    low_temp=$(jq '.fan_speeds.low' $CONFIG_FILE)
    medium_temp=$(jq '.fan_speeds.medium' $CONFIG_FILE)
    high_temp=$(jq '.fan_speeds.high' $CONFIG_FILE)
    full_temp=$(jq '.fan_speeds.full' $CONFIG_FILE)
    hysteresis=$(jq '.hysteresis' $CONFIG_FILE)
}

# Function to get the current CPU temperature using vcgencmd
get_cpu_temp() {
    temp=$($TEMP_COMMAND | egrep -o '[0-9]*\.[0-9]*')  # Use vcgencmd measure_temp
    echo "$temp"
}

# Function to set fan speed based on temperature
set_fan_speed() {
    local temp=$1
    local new_fan_speed=0  # Initialize with a default value of 0 (OFF)

    # Initialize last_fan_speed with the current state of the fan
    if [[ $last_fan_speed -eq -1 ]]; then
        last_fan_speed=$(cat $FAN_CONTROL_FILE 2>/dev/null)
        if [[ $? -ne 0 ]]; then
            echo "ERROR: Failed to read current fan state from $FAN_CONTROL_FILE" | sudo tee -a /var/log/fan_control.log
            last_fan_speed=0  # Default to fan off if reading fails
        fi
        echo "DEBUG: Initializing last_fan_speed to $last_fan_speed" | sudo tee -a /var/log/fan_control.log
    fi

    echo "DEBUG: Current Temp: $temp°C" | sudo tee -a /var/log/fan_control.log
    echo "DEBUG: Thresholds - Off: $off_temp, Low: $low_temp, Medium: $medium_temp, High: $high_temp, Full: $full_temp" | sudo tee -a /var/log/fan_control.log
    echo "DEBUG: Hysteresis: $hysteresis°C" | sudo tee -a /var/log/fan_control.log
    echo "DEBUG: Current Fan Speed: $last_fan_speed" | sudo tee -a /var/log/fan_control.log

    # Fan speed ramping up (when temp rises above the threshold)
    if [[ "$temp" -ge "$full_temp" ]]; then
        new_fan_speed=4  # Full
        echo "DEBUG: Temp >= Full threshold, setting fan speed to FULL" | sudo tee -a /var/log/fan_control.log
    elif [[ "$temp" -ge "$high_temp" ]]; then
        new_fan_speed=3  # High
        echo "DEBUG: Temp >= High threshold, setting fan speed to HIGH" | sudo tee -a /var/log/fan_control.log
    elif [[ "$temp" -ge "$medium_temp" ]]; then
        new_fan_speed=2  # Medium
        echo "DEBUG: Temp >= Medium threshold, setting fan speed to MEDIUM" | sudo tee -a /var/log/fan_control.log
    elif [[ "$temp" -ge "$low_temp" ]]; then
        new_fan_speed=1  # Low
        echo "DEBUG: Temp >= Low threshold, setting fan speed to LOW" | sudo tee -a /var/log/fan_control.log
    fi

    # Fan speed ramping down (temperature below threshold minus hysteresis)
    if [[ "$temp" -lt "$low_temp" && "$last_fan_speed" -gt 0 ]]; then
        if [[ "$temp" -le "$((low_temp - hysteresis))" ]]; then
            new_fan_speed=0  # Off
            echo "DEBUG: Temp <= Off threshold (after hysteresis), setting fan speed to OFF" | sudo tee -a /var/log/fan_control.log
        elif [[ "$temp" -le "$((medium_temp - hysteresis))" && "$last_fan_speed" -ge 2 ]]; then
            new_fan_speed=1  # Low
            echo "DEBUG: Temp <= Low threshold (after hysteresis), setting fan speed to LOW" | sudo tee -a /var/log/fan_control.log
        elif [[ "$temp" -le "$((high_temp - hysteresis))" && "$last_fan_speed" -ge 3 ]]; then
            new_fan_speed=2  # Medium
            echo "DEBUG: Temp <= Medium threshold (after hysteresis), setting fan speed to MEDIUM" | sudo tee -a /var/log/fan_control.log
        elif [[ "$temp" -le "$((full_temp - hysteresis))" && "$last_fan_speed" -ge 4 ]]; then
            new_fan_speed=3  # High
            echo "DEBUG: Temp <= High threshold (after hysteresis), setting fan speed to HIGH" | sudo tee -a /var/log/fan_control.log
        fi
    fi

    # Ensure new_fan_speed is valid and within the valid range
    if [[ "$new_fan_speed" -lt 0 || "$new_fan_speed" -gt 4 ]]; then
        echo "ERROR: Invalid new_fan_speed detected: $new_fan_speed" | sudo tee -a /var/log/fan_control.log
        new_fan_speed=0  # Default to off in case of error
    fi

    # Only update fan speed if it has changed
    if [[ "$new_fan_speed" != "$last_fan_speed" ]]; then
        echo "Changing fan speed to $new_fan_speed" | sudo tee -a /var/log/fan_control.log
        echo $new_fan_speed | sudo tee $FAN_CONTROL_FILE > /dev/null
        last_fan_speed=$new_fan_speed
    else
        echo "DEBUG: Fan speed remains unchanged at $new_fan_speed" | sudo tee -a /var/log/fan_control.log
    fi
}

# Function to restart the fan control service
restart_fan_service() {
    echo "Restarting the fan control service..."
    sudo systemctl restart $SERVICE_NAME
}

# Function to update fan configuration from the command line
update_fan_config() {
    if [ -z "$1" ]; then
        echo "Usage: fan -config off:temp,low:temp,medium:temp,high:temp,full:temp"
        exit 1
    fi

    IFS=',' read -ra PAIRS <<< "$1"
    declare -A fan_speeds
    for pair in "${PAIRS[@]}"; do
        IFS=':' read -r level temp <<< "$pair"
        if [[ -z "$level" || -z "$temp" ]]; then
            echo "Invalid format. Use level:temp format."
            exit 1
        fi
        fan_speeds["$level"]="$temp"
    done

    echo "Updating fan speed configuration..."
    jq --argjson off "${fan_speeds[off]}" --argjson low "${fan_speeds[low]}" --argjson medium "${fan_speeds[medium]}" --argjson high "${fan_speeds[high]}" --argjson full "${fan_speeds[full]}" \
       '.fan_speeds.off = $off | .fan_speeds.low = $low | .fan_speeds.medium = $medium | .fan_speeds.high = $high | .fan_speeds.full = $full' $CONFIG_FILE > /tmp/config.json

    sudo mv /tmp/config.json $CONFIG_FILE
    sudo chmod 644 $CONFIG_FILE

    echo "Fan speed configuration updated."
    restart_fan_service  # Restart the service to apply the new configuration
}

# Function to update hysteresis value
update_hysteresis() {
    if [ -z "$1" ]; then
        echo "Usage: fan -h hysteresis_value"
        exit 1
    fi

    if ! [[ "$1" =~ ^[0-9]+$ ]]; then
        echo "Invalid hysteresis value. Please enter a numeric value."
        exit 1
    fi

    local hysteresis=$1
    jq --argjson hysteresis "$hysteresis" '.hysteresis = $hysteresis' $CONFIG_FILE > /tmp/config.json
    sudo mv /tmp/config.json $CONFIG_FILE
    sudo chmod 644 $CONFIG_FILE

    echo "Hysteresis updated to $hysteresis°C."
    restart_fan_service  # Restart the service to apply the new hysteresis
}

# Function to stop the fan control service
stop_fan_service() {
    echo "Stopping the fan control service..."
    sudo systemctl stop $SERVICE_NAME

    echo "Turning off the fan (setting fan speed to 0)..."
    echo 0 | sudo tee $FAN_CONTROL_FILE

    echo "Fan control service stopped and fan turned off."
}

# Function to start the fan control service
start_fan_service() {
    echo "Starting the fan control service..."
    sudo systemctl start $SERVICE_NAME

    if sudo systemctl is-active --quiet $SERVICE_NAME; then
        echo "Fan control service started."
    else
        echo "Failed to start the fan control service."
    fi
}

# Function to show the current fan configuration
show_fan_config() {
    echo "Current Fan Configuration:"
    jq '.' $CONFIG_FILE

    # Check the current fan speed and display it as "off," "low," "medium," "high," or "full"
    current_fan_speed=$(cat $FAN_CONTROL_FILE)

    case "$current_fan_speed" in
        0)
            fan_speed="off"
            ;;
        1)
            fan_speed="low"
            ;;
        2)
            fan_speed="medium"
            ;;
        3)
            fan_speed="high"
            ;;
        4)
            fan_speed="full"
            ;;
        *)
            fan_speed="unknown"
            ;;
    esac

    echo "Current Fan Speed: $fan_speed"
}

# Function to check the current fan status
show_fan_status() {
    current_temp=$(get_cpu_temp)
    echo "Current CPU temperature: $current_temp°C"

    current_fan_speed=$(cat $FAN_CONTROL_FILE)
    case "$current_fan_speed" in
        0)
            fan_speed="off"
            ;;
        1)
            fan_speed="low"
            ;;
        2)
            fan_speed="medium"
            ;;
        3)
            fan_speed="high"
            ;;
        4)
            fan_speed="full"
            ;;
        *)
            fan_speed="unknown"
            ;;
    esac

    echo "Current Fan Speed: $fan_speed"
}

# Polling loop for checking the temperature every 60 seconds
poll_temperature() {
    while true; do
        load_config  # Load configuration once per cycle
        current_temp=$(get_cpu_temp)  # Get current temperature
        set_fan_speed $current_temp   # Adjust fan speed
        sleep $POLL_INTERVAL  # Wait for the polling interval
    done
}

# Function to update the script from GitHub
update_fan_control() {
    echo "Updating the fan control script and configuration from GitHub..."

    # Stop the service before updating
    stop_fan_service

    # Download the latest fan command script
    sudo wget -q -O $FAN_CMD "$GITHUB_REPO/fan"
    sudo chmod +x $FAN_CMD

    # Download the latest configuration file
    sudo wget -q -O $CONFIG_FILE "$GITHUB_REPO/fan_config.json"
    sudo chmod 644 $CONFIG_FILE

    # Reload the systemd service to apply the updates
    echo "Reloading the systemd service..."
    sudo systemctl daemon-reload && sudo systemctl restart $SERVICE_NAME

    echo "Update complete. The fan command and fan control script have been updated."
}

# Function to uninstall the fan control app
uninstall_fan_control() {
    echo "Uninstalling the fan control service..."

    # Stop and disable the service
    sudo systemctl stop $SERVICE_NAME
    sudo systemctl disable $SERVICE_NAME

    # Remove service, script, and config files
    sudo rm -f /etc/systemd/system/$SERVICE_NAME.service
    sudo rm -f $FAN_CMD
    sudo rm -f $CONFIG_FILE

    # Reload systemd to apply changes
    sudo systemctl daemon-reload

    echo "Fan control service uninstalled successfully."
}

# Parse command line arguments
if [ "$1" == "-status" ]; then
    show_fan_status  # Show current status of CPU temp and fan speed
elif [ "$1" == "-config" ]; then
    update_fan_config "$2"
elif [ "$1" == "-h" ]; then
    update_hysteresis "$2"
elif [ "$1" == "-show" ]; then
    show_fan_config
elif [ "$1" == "-stop" ]; then
    stop_fan_service
elif [ "$1" == "-start" ]; then
    start_fan_service
elif [ "$1" == "-poll" ]; then
    poll_temperature  # Start polling for temperature in a loop
elif [ "$1" == "-update" ]; then
    update_fan_control  # Update the script from GitHub
elif [ "$1" == "-uninstall" ]; then
    uninstall_fan_control  # Uninstall the service and remove files
else
    echo "Usage: fan -status, fan -config off:temp,low:temp,medium:temp,high:temp,full:temp, fan -h hysteresis_value, fan -show, fan -stop, fan -start, fan -poll, fan -update, fan -uninstall"
    exit 1
fi
