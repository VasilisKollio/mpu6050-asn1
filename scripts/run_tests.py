import ctypes
import os

# Load the compiled C library
lib = ctypes.CDLL("./sample.so")

# Define the Message structure
class Message(ctypes.Structure):
    _fields_ = [
        ("msgId", ctypes.c_int),
        ("myflag", ctypes.c_int),
        ("value", ctypes.c_double),
        ("szDescription", ctypes.c_char * 10),
        ("isReady", ctypes.c_bool)
    ]

# Test encoding and decoding
def test_message():
    # Create a message instance
    msg = Message()
    msg.msgId = 5
    msg.myflag = 15
    msg.value = 2.718
    msg.szDescription = b"Hello!"
    msg.isReady = True

    # Encode the message
    encoded = bytearray(100)  # Buffer for encoded data
    encoded_ptr = (ctypes.c_ubyte * len(encoded)).from_buffer(encoded)
    lib.Message_Encode(ctypes.byref(msg), ctypes.byref(encoded_ptr), None, True)

    # Decode the message
    decoded_msg = Message()
    lib.Message_Decode(ctypes.byref(decoded_msg), ctypes.byref(encoded_ptr), None)

    # Print the results
    print("Original Message:", msg.msgId, msg.myflag, msg.value, msg.szDescription, msg.isReady)
    print("Decoded Message:", decoded_msg.msgId, decoded_msg.myflag, decoded_msg.value, decoded_msg.szDescription, decoded_msg.isReady)

if __name__ == "__main__":
    test_message()
