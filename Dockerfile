# Use an ARMv8-A compatible base image
FROM arm64v8/ubuntu:22.04 AS build

# Install dependencies
RUN set -xe \
    && DEBIAN_FRONTEND=noninteractive apt-get update -y \
    && apt-get install -y \
        libfontconfig1 \
        libdbus-1-3 \
        libx11-6 \
        libx11-xcb-dev \
        cppcheck \
        htop \
        python3 \
        python3-distutils \
        gcc \
        g++ \
        make \
        nuget \
        libgit2-dev \
        libssl-dev \
        curl \
        wget \
        unzip \
        zip \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get purge --auto-remove \
    && apt-get clean

# Install .NET SDK for ARM64
RUN wget https://dotnet.microsoft.com/download/dotnet/scripts/v1/dotnet-install.sh \
    && chmod +x dotnet-install.sh \
    && ./dotnet-install.sh --channel 7.0 --architecture arm64

# Add .NET to PATH
ENV PATH="/root/.dotnet:${PATH}"

# Install Scala and Java for ARM64
RUN curl -s "https://get.sdkman.io" | bash \
    && chmod a+x "$HOME/.sdkman/bin/sdkman-init.sh" \
    && source "$HOME/.sdkman/bin/sdkman-init.sh" \
    && sdk install java 17.0.9-oracle \
    && sdk install scala 3.3.0 \
    && sdk install sbt 1.9.0

# Install GNAT for ARM64
WORKDIR /gnat_tmp/
RUN wget -O gnat-2021-arm64-linux-bin.tar.gz https://community.download.adacore.com/v1/<gnat-arm64-download-link> \
    && tar -xzf gnat-2021-arm64-linux-bin.tar.gz \
    && ./gnat-2021-arm64-linux-bin/doinstall.sh /opt/GNAT/gnat-arm64-2021 \
    && cd \
    && rm -rf /gnat_tmp/

# Set up environment variables
ENV PATH="/opt/GNAT/gnat-arm64-2021/bin:${PATH}"

# Set the working directory
WORKDIR /app

# Copy the ASN.1 schema and Python script
COPY sensor_data.asn /app/
COPY mpu6050_asn1.py /app/

# Generate C code from the ASN.1 schema
RUN asn1scc -c -uPER sensor_data.asn

# Install Python dependencies for the MPU6050 script
RUN pip3 install smbus2 asn1tools

# Run the application
CMD ["python3", "mpu6050_asn1.py"]
