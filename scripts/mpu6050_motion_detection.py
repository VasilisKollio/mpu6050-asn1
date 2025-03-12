import smbus2
import time

# MPU6050 Registers
PWR_MGMT_1 = 0x6B
ACCEL_XOUT_H = 0x3B

# Initialize I2C
bus = smbus2.SMBus(1)  # Use I2C bus 1
device_address = 0x68  # MPU6050 I2C address

# Wake up MPU6050
bus.write_byte_data(device_address, PWR_MGMT_1, 0)

def read_word_2c(reg):
    """Read a 16-bit signed value from the specified register."""
    high = bus.read_byte_data(device_address, reg)
    low = bus.read_byte_data(device_address, reg + 1)
    value = (high << 8) + low
    if value >= 0x8000:
        return -((65535 - value) + 1)
    else:
        return value

def get_accel_data():
    """Read accelerometer data."""
    accel_x = read_word_2c(ACCEL_XOUT_H)
    accel_y = read_word_2c(ACCEL_XOUT_H + 2)
    accel_z = read_word_2c(ACCEL_XOUT_H + 4)
    return accel_x, accel_y, accel_z

def detect_motion(accel_x, accel_y, accel_z, threshold=1000):
    """Detect motion based on accelerometer data."""
    return abs(accel_x) > threshold or abs(accel_y) > threshold or abs(accel_z) > threshold

def main():
    print("Starting motion detection...")
    while True:
        accel_x, accel_y, accel_z = get_accel_data()
        if detect_motion(accel_x, accel_y, accel_z):
            print("Motion detected!")
        else:
            print("No motion.")
        time.sleep(1)

if __name__ == "__main__":
    main()
