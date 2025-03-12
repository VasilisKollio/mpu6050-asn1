import paho.mqtt.client as mqtt
import sqlite3
import json

# MQTT Configuration
MQTT_BROKER = "localhost"  # Replace with Raspberry Pi's IP if running the broker on the Pi
MQTT_PORT = 1883
MQTT_TOPIC = "sensor/data"

# Database Configuration
DATABASE = "data/sensor_data.db"


def on_message(client, userdata, message):
    data = json.loads(message.payload.decode())
    print(f"Received data: {data}")


    # Store data in the database
    conn = sqlite3.connect(DATABASE)
    cursor = conn.cursor()
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS sensor_data (
            timestamp INTEGER,
            accel_x INTEGER,
            accel_y INTEGER,
            accel_z INTEGER,
            gyro_x INTEGER,
            gyro_y INTEGER,
            gyro_z INTEGER
        )
    ''')
    cursor.execute('''
        INSERT INTO sensor_data (timestamp, accel_x, accel_y, accel_z, gyro_x, gyro_y, gyro_z)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ''', (data['timestamp'], data['accel_x'], data['accel_y'], data['accel_z'], data['gyro_x'], data['gyro_y'], data['gyro_z']))
    conn.commit()
    conn.close()

# Initialize MQTT Client
client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2)
client.connect(MQTT_BROKER, MQTT_PORT, 60)

# Subscribe to the topic
client.subscribe(MQTT_TOPIC)
client.on_message = on_message

# Start the loop
client.loop_forever()
