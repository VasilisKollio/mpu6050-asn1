FROM arm64v8/ubuntu:22.04

# Set the time zone non-interactively
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y tzdata \
    && ln -fs /usr/share/zoneinfo/Europe/Athens /etc/localtime \
    && dpkg-reconfigure --frontend noninteractive tzdata

# Install necessary dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    git \
    mono-complete \
    fsharp \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt

# Clone the asn1scc repository from GitHub
RUN git clone https://github.com/esa/asn1scc.git
WORKDIR /opt/asn1scc

# Build asn1scc with Mono
RUN fsharpc -o:asn1.exe Frontend/Main.fs

# Create a wrapper script for asn1scc
RUN echo '#!/bin/bash\nmono /opt/asn1scc/asn1.exe "$@"' > /usr/local/bin/asn1scc && \
    chmod +x /usr/local/bin/asn1scc

WORKDIR /app

# Copy your application files
COPY sensor_data.asn /app/
COPY mpu6050_asn1.py /app/

# Generate C code from the ASN.1 schema
RUN asn1scc -c -uPER -o /app/generated /app/sensor_data.asn

# Install Python dependencies
RUN pip3 install smbus2 asn1tools

# Run the application
CMD ["python3", "mpu6050_asn1.py"]
