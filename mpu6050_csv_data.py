import smbus2
import time
import asn1tools
import csv

# Load ASN.1 schema
asn1 = asn1tools.compile_files('sensor_data.asn')

# MPU6050 Registers
PWR_MGMT_1 = 0x6B
ACCEL_XOUT_H = 0x3B
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

def get_accel_data():
    """Read accelerometer data."""
    accel_x = read_word_2c(ACCEL_XOUT_H)
    accel_y = read_word_2c(ACCEL_XOUT_H + 2)
    accel_z = read_word_2c(ACCEL_XOUT_H + 4)
    return accel_x, accel_y, accel_z

def get_gyro_data():
    """Read gyroscope data."""
    gyro_x = read_word_2c(GYRO_XOUT_H)
    gyro_y = read_word_2c(GYRO_XOUT_H + 2)
    gyro_z = read_word_2c(GYRO_XOUT_H + 4)
    return gyro_x, gyro_y, gyro_z

def main():
    # List to store sensor data
    sensor_data_list = []

    # Set the duration for data collection (30 seconds)
    duration = 30  # seconds
    start_time = time.time()

    print(f"Collecting data for {duration} seconds...")

    while time.time() - start_time < duration:
        # Read sensor data
        accel_x, accel_y, accel_z = get_accel_data()
        gyro_x, gyro_y, gyro_z = get_gyro_data()

        # Create a dictionary for the current reading
        sensor_data = {
            'timestamp': int(time.time()),
            'accel_x': accel_x,
            'accel_y': accel_y,
            'accel_z': accel_z,
            'gyro_x': gyro_x,
            'gyro_y': gyro_y,
            'gyro_z': gyro_z
        }

        # Append the data to the list
        sensor_data_list.append(sensor_data)

        # Print the current reading
        print(f"Data collected: {sensor_data}")

        # Wait for 1 second before the next reading
        time.sleep(1)

    # Save the data to a CSV file
    csv_filename = "sensor_data.csv"
    with open(csv_filename, mode='w', newline='') as file:
        writer = csv.DictWriter(file, fieldnames=sensor_data.keys())
        writer.writeheader()
        writer.writerows(sensor_data_list)

    print(f"Data collection complete. Saved to {csv_filename}.")

if __name__ == "__main__":
    main()
