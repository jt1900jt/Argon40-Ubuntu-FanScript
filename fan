#!/bin/bash

# Define constants
GITHUB_REPO="https://raw.githubusercontent.com/jt1900jt/Argon40-Ubuntu-FanScript/main"
CONFIG_FILE="/etc/fan_config.json"
FAN_CONTROL_FILE="/sys/class/thermal/cooling_device0/cur_state"
TEMP_COMMAND="/usr/bin/vcgencmd measure_temp"
SERVICE_NAME="fan_control"

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

# Function to get the current CPU temperature
get_cpu_temp() {
    temp=$($TEMP_COMMAND | egrep -o '[0-9]*\.[0-9]*')
    echo "$temp"
}

# Function to set fan speed based on temperature
set_fan_speed() {
    local temp=$1

    if (( $(echo "$temp < $off_temp" | bc -l) )); then
        echo 0 | sudo tee $FAN_CONTROL_FILE  # OFF
    elif (( $(echo "$temp < $low_temp" | bc -l) )); then
        echo 1 | sudo tee $FAN_CONTROL_FILE  # LOW
    elif (( $(echo "$temp < $medium_temp" | bc -l) )); then
        echo 2 | sudo tee $FAN_CONTROL_FILE  # MEDIUM
    elif (( $(echo "$temp < $high_temp" | bc -l) )); then
        echo 3 | sudo tee $FAN_CONTROL_FILE  # HIGH
    else
        echo 4 | sudo tee $FAN_CONTROL_FILE  # FULL
    fi
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
}

# Parse command line arguments
if [ "$1" == "-speed" ]; then
    load_config
    current_temp=$(get_cpu_temp)
    echo "Current CPU temperature: $current_temp°C"
    set_fan_speed $current_temp
elif [ "$1" == "-temp" ]; then
    get_cpu_temp
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
else
    echo "Usage: fan -speed, fan -temp, fan -config off:temp,low:temp,medium:temp,high:temp,full:temp, fan -h hysteresis_value, fan -show, fan -stop, fan -start"
    exit 1
fi
