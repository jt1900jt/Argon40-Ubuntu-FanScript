#!/usr/bin/env python3
import lgpio
import time

FAN_PIN = 4  # Replace with the actual GPIO pin you're using

def turn_off_fan():
    h = lgpio.gpiochip_open(0)  # Open GPIO chip 0
    lgpio.gpio_claim_output(h, FAN_PIN)  # Claim the pin as output
    lgpio.gpio_write(h, FAN_PIN, 0)  # Set pin to 0 (turn off fan)
    time.sleep(1)  # Optional: keep it off for 1 second
    lgpio.gpiochip_close(h)  # Close the GPIO chip

if __name__ == "__main__":
    turn_off_fan()
