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
    wget \
    unzip \
    mono-runtime \
    libmono-system-core4.0-cil \
    libmono-system-numerics4.0-cil \
    libmono-system-xml-linq4.0-cil \
    libicu-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Download pre-built ASN1SCC compiler from the ESA GitLab repository
RUN wget https://gitlab.com/taste-official/asn1scc/-/releases/5.0.0/downloads/asn1scc-5.0.0-Linux-x86_64.zip && \
    unzip asn1scc-5.0.0-Linux-x86_64.zip -d /opt/asn1scc && \
    chmod +x /opt/asn1scc/asn1.exe && \
    rm asn1scc-5.0.0-Linux-x86_64.zip

# Create a wrapper script for asn1scc
RUN echo '#!/bin/bash\nmono /opt/asn1scc/asn1.exe "$@"' > /usr/local/bin/asn1scc && \
    chmod +x /usr/local/bin/asn1scc

# Copy your application files
COPY sensor_data.asn /app/
COPY mpu6050_asn1.py /app/

# Generate C code from the ASN.1 schema
RUN asn1scc -c -uPER -o /app/generated /app/sensor_data.asn

# Install Python dependencies
RUN pip3 install smbus2 asn1tools

# Run the application
CMD ["python3", "mpu6050_asn1.py"]
