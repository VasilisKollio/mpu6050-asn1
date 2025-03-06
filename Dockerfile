# Use an ARMv6-compatible base image
FROM arm32v6/alpine:latest

# Install dependencies
RUN apk add --no-cache \
    build-base \
    git \
    cmake \
    python3 \
    py3-pip

# Clone and build asn1scc
RUN git clone https://github.com/ttsiodras/asn1scc.git /asn1scc
WORKDIR /asn1scc
RUN mkdir build && cd build && cmake .. && make

# Add asn1scc to PATH
ENV PATH="/asn1scc/build:${PATH}"

# Set the working directory
WORKDIR /app

# Copy the ASN.1 schema
COPY sensor_data.asn /app/

# Generate C code from the ASN.1 schema
RUN asn1scc -c -uPER sensor_data.asn

# Install Python dependencies for the MPU6050 script
RUN pip3 install smbus2 asn1tools

# Copy the MPU6050 script
COPY mpu6050_asn1.py /app/

# Run the application
CMD ["python3", "mpu6050_asn1.py"]
