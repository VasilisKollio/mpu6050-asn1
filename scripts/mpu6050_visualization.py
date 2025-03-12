import smbus2
import time
import matplotlib.pyplot as plt

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

def main():
    print("Starting data visualization...")
    plt.ion()
    fig, ax = plt.subplots()
    x_data, y_data = [], []
    line, = ax.plot(x_data, y_data)
    ax.set_ylim(-20000, 20000)
    ax.set_xlabel("Time")
    ax.set_ylabel("Acceleration")

    start_time = time.time()
    while True:
        accel_x, accel_y, accel_z = get_accel_data()
        x_data.append(time.time() - start_time)
        y_data.append(accel_x)
        line.set_xdata(x_data)
        line.set_ydata(y_data)
        ax.relim()
        ax.autoscale_view()
        plt.draw()
        plt.pause(0.01)

if __name__ == "__main__":
    main()
