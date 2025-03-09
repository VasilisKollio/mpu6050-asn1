import smbus2
import time
import asn1tools
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Load ASN.1 schema
try:
    asn1 = asn1tools.compile_files('sensor_data.asn')
    logging.info("ASN.1 schema loaded successfully.")
except Exception as e:
    logging.error(f"Failed to load ASN.1 schema: {e}")
    exit(1)

# MPU6050 Registers
PWR_MGMT_1 = 0x6B
ACCEL_XOUT_H = 0x3B
GYRO_XOUT_H = 0x43

# MPU6050 Constants
ACCEL_SCALE = 16384.0  # For ±2g range
GYRO_SCALE = 131.0     # For ±250°/s range

# Initialize I2C
try:
    bus = smbus2.SMBus(1)  # Use I2C bus 1
    device_address = 0x68  # MPU6050 I2C address
    logging.info("I2C bus initialized successfully.")
except Exception as e:
    logging.error(f"Failed to initialize I2C bus: {e}")
    exit(1)

# Wake up MPU6050
try:
    bus.write_byte_data(device_address, PWR_MGMT_1, 0)
    logging.info("MPU6050 powered on.")
except Exception as e:
    logging.error(f"Failed to wake up MPU6050: {e}")
    exit(1)

def read_word_2c(reg):
    """Read a 16-bit signed value from the specified register."""
    try:
        high = bus.read_byte_data(device_address, reg)
        low = bus.read_byte_data(device_address, reg + 1)
        value = (high << 8) + low
        if value >= 0x8000:
            return -((65535 - value) + 1)
        else:
            return value
    except Exception as e:
        logging.error(f"Failed to read from register {reg}: {e}")
        return 0

def get_accel_data():
    """Read accelerometer data and scale it to g."""
    accel_x = read_word_2c(ACCEL_XOUT_H) / ACCEL_SCALE
    accel_y = read_word_2c(ACCEL_XOUT_H + 2) / ACCEL_SCALE
    accel_z = read_word_2c(ACCEL_XOUT_H + 4) / ACCEL_SCALE
    return accel_x, accel_y, accel_z

def get_gyro_data():
    """Read gyroscope data and scale it to °/s."""
    gyro_x = read_word_2c(GYRO_XOUT_H) / GYRO_SCALE
    gyro_y = read_word_2c(GYRO_XOUT_H + 2) / GYRO_SCALE
    gyro_z = read_word_2c(GYRO_XOUT_H + 4) / GYRO_SCALE
    return gyro_x, gyro_y, gyro_z

def main():
    while True
