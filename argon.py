#!/bin/bash

# Define constants
CONFIG_FILE="/etc/argon_fan_config.json"
CPU_TEMP_CMD="vcgencmd measure_temp"  # Command to get the current CPU temperature
GITHUB_REPO="https://raw.githubusercontent.com/jt1900jt/Argon40-Ubuntu-FanScript/main"
SCRIPT_FILE="/usr/local/bin/argon_fan_control.py"
CONFIG_FILE="/etc/argon_fan_config.json"

# Function to update the fan speed curve
update_fan_curve() {
    if [ -z "$1" ]; then
        echo "Usage: argon -curve temp:speed, temp1:speed1, temp2:speed2"
        exit 1
    fi

    IFS=',' read -ra PAIRS <<< "$1"
    declare -A fan_speeds
    for pair in "${PAIRS[@]}"; do
        IFS=':' read -r temp speed <<< "$pair"
        if [[ -z "$temp" || -z "$speed" ]]; then
            echo "Invalid format for curve. Use temp:speed format."
            exit 1
        fi
        fan_speeds["$temp"]="$speed"
    done

    echo "{ \"fan_speeds\": {" > /tmp/fan_speeds.tmp
    for temp in "${!fan_speeds[@]}"; do
        echo "\"$temp\": ${fan_speeds[$temp]}," >> /tmp/fan_speeds.tmp
    done
    sed -i '$ s/,$//' /tmp/fan_speeds.tmp
    echo "}, \"hysteresis\": 5 }" >> /tmp/fan_speeds.tmp

    sudo mv /tmp/fan_speeds.tmp $CONFIG_FILE
    sudo chmod 644 $CONFIG_FILE

    echo "Reloading the fan control service..."
    sudo systemctl restart argon_fan_control.service
    echo "Fan speed curve updated successfully."
}

# Function to update the hysteresis value
update_hysteresis() {
    if [ -z "$1" ]; then
        echo "Usage: argon -h hysteresis_value"
        exit 1
    fi

    if ! [[ "$1" =~ ^[0-9]+$ ]]; then
        echo "Invalid hysteresis value. Please enter a numeric value."
        exit 1
    fi

    local hysteresis=$1
    fan_speeds=$(jq '.fan_speeds' $CONFIG_FILE)

    echo "{ \"fan_speeds\": $fan_speeds, \"hysteresis\": $hysteresis }" > $CONFIG_FILE
    sudo chmod 644 $CONFIG_FILE

    echo "Reloading the fan control service..."
    sudo systemctl restart argon_fan_control.service
    echo "Hysteresis updated successfully."
}

# Function to update the script from GitHub
update_fan_control() {
    echo "Updating the fan control script and configuration from GitHub..."

    sudo wget -O $SCRIPT_FILE "$GITHUB_REPO/argon_fan_control.py"
    sudo chmod +x $SCRIPT_FILE

    sudo wget -O $CONFIG_FILE "$GITHUB_REPO/fan_config.json"
    sudo chmod 644 $CONFIG_FILE

    echo "Reloading the systemd service..."
    sudo systemctl daemon-reload
    sudo systemctl restart argon_fan_control.service

    echo "Update complete."
}

# Function to get the current CPU temperature
get_cpu_temp() {
    temp=$(eval "$CPU_TEMP_CMD" | sed 's/[^0-9.]//g')
    echo $temp
}

# Function to return the current fan speed based on the temperature
get_fan_speed() {
    current_temp=$(get_cpu_temp)
    echo "Current CPU temperature: $current_temp°C"

    fan_speeds=$(jq -r '.fan_speeds' $CONFIG_FILE)
    current_speed=0
    for temp in $(echo $fan_speeds | jq -r 'keys[]'); do
        if (( $(echo "$current_temp >= $temp" | bc -l) )); then
            current_speed=$(echo $fan_speeds | jq -r --arg temp "$temp" '.[$temp]')
        fi
    done

    echo "Current fan speed: $current_speed%"
}

# Parse command line arguments
if [ "$1" == "-update" ]; then
    update_fan_control
elif [ "$1" == "-curve" ]; then
    update_fan_curve "$2"
elif [ "$1" == "-h" ]; then
    update_hysteresis "$2"
elif [ "$1" == "-speed" ]; then
    get_fan_speed
else
    echo "Usage: argon -update, argon -curve temp:speed, temp1:speed1, temp2:speed2, argon -h hysteresis_value, or argon -speed"
    exit 1
fi
