# Use an ARMv8-A compatible base image
FROM arm64v8/ubuntu:22.04 AS build

# Set the time zone non-interactively
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y tzdata \
    && ln -fs /usr/share/zoneinfo/Europe/Athens /etc/localtime \
    && dpkg-reconfigure --frontend noninteractive tzdata

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
        bash \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get purge --auto-remove \
    && apt-get clean

# Install .NET SDK for ARM64
RUN wget https://dotnet.microsoft.com/download/dotnet/scripts/v1/dotnet-install.sh \
    && chmod +x dotnet-install.sh \
    && ./dotnet-install.sh --channel 7.0 --architecture arm64

# Add .NET to PATH
ENV PATH="/root/.dotnet:${PATH}"

# Install SDKMAN and Java/Scala/SBT
RUN curl -s "https://get.sdkman.io" | bash \
    && chmod a+x "$HOME/.sdkman/bin/sdkman-init.sh" \
    && bash -c "source $HOME/.sdkman/bin/sdkman-init.sh && sdk install java 17.0.9-oracle && sdk install scala 3.3.0 && sdk install sbt 1.9.0"

# Verify SDKMAN installation
RUN bash -c "source $HOME/.sdkman/bin/sdkman-init.sh && sdk version"

# Copy the asn1scc binary into the image
COPY asn1scc /root/asn1scc/asn1scc/bin/Debug/net7.0/asn1scc

# Make the asn1scc binary executable
RUN chmod +x /root/asn1scc/asn1scc/bin/Debug/net7.0/asn1scc

# Verify the asn1scc binary
RUN ls -l /root/asn1scc/asn1scc/bin/Debug/net7.0/asn1scc

# Add asn1scc to PATH
ENV PATH="/root/asn1scc/asn1scc/bin/Debug/net7.0:${PATH}"

# Set the working directory
WORKDIR /app

# Copy the ASN.1 schema and Python script
COPY sensor_data.asn /app/
COPY mpu6050_asn1.py /app/

# Generate C code from the ASN.1 schema
RUN asn1scc -c -uPER -o /app/generated /app/sensor_data.asn

# Install Python dependencies for the MPU6050 script
RUN pip3 install smbus2 asn1tools

# Run the application
CMD ["python3", "mpu6050_asn1.py"]
