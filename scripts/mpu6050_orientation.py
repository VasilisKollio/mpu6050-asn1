import smbus2
import time
import math

# MPU6050 Registers
PWR_MGMT_1 = 0x6B
GYRO_XOUT_H = 0x43

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

def get_gyro_data():
    """Read gyroscope data."""
    gyro_x = read_word_2c(GYRO_XOUT_H)
    gyro_y = read_word_2c(GYRO_XOUT_H + 2)
    gyro_z = read_word_2c(GYRO_XOUT_H + 4)
    return gyro_x, gyro_y, gyro_z

def estimate_orientation(gyro_x, gyro_y, gyro_z, dt=0.01):
    """Estimate orientation using gyroscope data."""
    roll = gyro_x * dt
    pitch = gyro_y * dt
    yaw = gyro_z * dt
    return roll, pitch, yaw

def main():
    print("Estimating orientation...")
    while True:
        gyro_x, gyro_y, gyro_z = get_gyro_data()
        roll, pitch, yaw = estimate_orientation(gyro_x, gyro_y, gyro_z)
        print(f"Roll: {roll:.2f}, Pitch: {pitch:.2f}, Yaw: {yaw:.2f}")
        time.sleep(0.01)

if __name__ == "__main__":
    main()
