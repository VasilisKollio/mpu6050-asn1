import smbus2
import time

# MPU6050 Registers
PWR_MGMT_1 = 0x6B
TEMP_OUT_H = 0x41

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

def get_temperature():
    """Read temperature data."""
    temp_raw = read_word_2c(TEMP_OUT_H)
    temperature = (temp_raw / 340.0) + 36.53  # Convert to Celsius
    return temperature

def main():
    print("Reading temperature data...")
    while True:
        temperature = get_temperature()
        print(f"Temperature: {temperature:.2f} °C")
        time.sleep(1)

if __name__ == "__main__":
    main()
