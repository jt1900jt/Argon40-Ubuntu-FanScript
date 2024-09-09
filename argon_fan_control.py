import RPi.GPIO as GPIO
import time
import os
import json

# Define the GPIO pin that the fan is connected to
FAN_PIN = 4  # Replace with your GPIO pin number if different

# Setup GPIO
GPIO.setmode(GPIO.BCM)
GPIO.setup(FAN_PIN, GPIO.OUT)

# Define the path to the configuration file
CONFIG_FILE = '/etc/argon_fan_config.json'


def get_cpu_temp():
    """Reads the current CPU temperature using the vcgencmd command."""
    temp = os.popen("vcgencmd measure_temp").readline()
    temp = temp.replace("temp=", "").replace("'C\n", "")
    return float(temp)


def load_fan_config():
    """Loads fan configuration (fan speeds and hysteresis) from a JSON file."""
    try:
        with open(CONFIG_FILE, 'r') as f:
            config = json.load(f)
            fan_speeds = config.get('fan_speeds', {})
            hysteresis = config.get('hysteresis', 5)
            return fan_speeds, hysteresis
    except (FileNotFoundError, json.JSONDecodeError):
        return {}, 5


def set_fan_speed(fan_speeds, hysteresis, current_temp, fan_state):
    """
    Adjusts the fan speed based on the current temperature and the fan curve.

    Args:
        fan_speeds (dict): A dictionary mapping temperature thresholds to fan speeds.
        hysteresis (int): The hysteresis value to avoid rapid fan toggling.
        current_temp (float): The current CPU temperature.
        fan_state (str): The current state of the fan ("on" or "off").

    Returns:
        str: The new state of the fan ("on" or "off").
    """
    sorted_thresholds = sorted(fan_speeds.keys(), key=int)
    speed = 0
    target_threshold = None

    for threshold in sorted_thresholds:
        threshold = int(threshold)
        if current_temp >= threshold:
            speed = fan_speeds[str(threshold)]
            target_threshold = threshold
        else:
            break

    if fan_state == "on" and current_temp <= target_threshold - hysteresis:
        GPIO.output(FAN_PIN, GPIO.LOW)  # Turn fan off
        fan_state = "off"
        print(f"Fan turned off. Current temp: {current_temp}°C (hysteresis: {hysteresis}°C)")

    elif fan_state == "off" and current_temp >= target_threshold:
        GPIO.output(FAN_PIN, GPIO.HIGH)  # Turn fan on
        fan_state = "on"
        print(f"Fan turned on at {speed}% speed for {current_temp}°C")

    return fan_state


def control_fan():
    """Main loop to control the fan based on temperature and fan curve settings."""
    fan_speeds, hysteresis = load_fan_config()
    fan_state = "off"

    while True:
        current_temp = get_cpu_temp()
        fan_state = set_fan_speed(fan_speeds, hysteresis, current_temp, fan_state)
        time.sleep(5)  # Check temperature every 5 seconds


if __name__ == "__main__":
    try:
        control_fan()
    except KeyboardInterrupt:
        pass
    finally:
        GPIO.cleanup()
