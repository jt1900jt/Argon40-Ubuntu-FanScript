#!/usr/bin/env python3
import RPi.GPIO as GPIO
import time

FAN_PIN = 4  # Update this to the correct GPIO pin

def setup_gpio():
    GPIO.setmode(GPIO.BCM)  # Use BCM pin numbering
    GPIO.setup(FAN_PIN, GPIO.OUT)

def turn_off_fan():
    setup_gpio()
    GPIO.output(FAN_PIN, GPIO.LOW)  # Set pin to LOW (turn off fan)
    time.sleep(1)  # Optional: sleep to ensure the pin state takes effect
    GPIO.cleanup()  # Clean up the GPIO pins

if __name__ == "__main__":
    turn_off_fan()
