import RPi.GPIO as GPIO
import time
import os
import json
import argparse

# Define GPIO pin (check your Argon case manual for the correct pin)
FAN_PIN = 4

# Setup GPIO
GPIO.setmode(GPIO.BCM)
GPIO.setup(FAN_PIN, GPIO.OUT)

CONFIG_FILE = '/etc/argon_fan_config.json'


def get_cpu_temp():
    """Read the CPU temperature."""
    temp = os.popen("vcgencmd measure_temp").readline()
    temp = temp.replace("temp=", "").replace("'C\n", "")
    return float(temp)


def load_fan_config():
    """Load fan speed configuration and hysteresis from a JSON file."""
    try:
        with open(CONFIG_FILE, 'r') as f:
            config = json.load(f)
            fan_speeds = config['fan_speeds']
            hysteresis = config.get('hysteresis', 5)  # Default to 5 if not set
            return fan_speeds, hysteresis
    except (FileNotFoundError, json.JSONDecodeError):
        return {}, 5


def save_fan_config(fan_speeds, hysteresis):
    """Save fan speed configuration and hysteresis to a JSON file."""
    config = {'fan_speeds': fan_speeds, 'hysteresis': hysteresis}
    with open(CONFIG_FILE, 'w') as f:
        json.dump(config, f, indent=4)


def set_fan_speed(fan_speeds, hysteresis, current_temp, fan_state):
    """Adjust fan speed based on current temperature and hysteresis."""
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
    """Control fan speed based on temperature thresholds and hysteresis."""
    fan_speeds, hysteresis = load_fan_config()
    fan_state = "off"

    while True:
        current_temp = get_cpu_temp()
        fan_state = set_fan_speed(fan_speeds, hysteresis, current_temp, fan_state)
        time.sleep(5)  # Check every 5 seconds


def configure_fan_speeds():
    """CLI interface for configuring fan speed thresholds and hysteresis."""
    parser = argparse.ArgumentParser(description="Configure fan speeds and hysteresis.")
    parser.add_argument('--set', nargs=2, action='append', metavar=('TEMP', 'SPEED'),
                        help="Set fan speed for a given temperature (e.g., --set 50 70 for 70% speed at 50°C)")
    parser.add_argument('--hysteresis', type=int, help="Set the hysteresis value (default is 5°C)")

    args = parser.parse_args()

    if args.set or args.hysteresis is not None:
        fan_speeds, current_hysteresis = load_fan_config()

        if args.set:
            for temp, speed in args.set:
                fan_speeds[temp] = int(speed)
                print(f"Set fan speed to {speed}% at {temp}°C")

        if args.hysteresis is not None:
            current_hysteresis = args.hysteresis
            print(f"Set hysteresis to {current_hysteresis}°C")

        save_fan_config(fan_speeds, current_hysteresis)


if __name__ == "__main__":
    # CLI interface for setting fan speeds and hysteresis
    configure_fan_speeds()

    try:
        control_fan()
    except KeyboardInterrupt:
        pass
    finally:
        GPIO.cleanup()
