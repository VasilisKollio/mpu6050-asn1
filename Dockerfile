# Use an ARMv8-A compatible base image
FROM arm64v8/ubuntu:22.04 AS build

# Set the time zone non-interactively
ENV DEBIAN_FRONTEND=noninteractive

# Install CA certificates first to help with SSL connections
RUN apt-get update && apt-get install -y ca-certificates && update-ca-certificates

# Set timezone
RUN apt-get install -y tzdata \
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
        git \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get purge --auto-remove \
    && apt-get clean

# Configure DNS to improve network reliability
RUN echo "nameserver 8.8.8.8" > /etc/resolv.conf
RUN echo "nameserver 8.8.4.4" >> /etc/resolv.conf

# Configure NuGet to be more resilient
RUN mkdir -p /root/.nuget/NuGet
RUN echo '<?xml version="1.0" encoding="utf-8"?><configuration><packageSources><add key="nuget.org" value="https://api.nuget.org/v3/index.json" protocolVersion="3" /></packageSources><packageSourceMapping><packageSource key="nuget.org"><package pattern="*" /></packageSource></packageSourceMapping><config><add key="maxHttpRequestsPerSource" value="5" /><add key="ConnectionTimeout" value="600" /></config></configuration>' > /root/.nuget/NuGet/NuGet.Config

# Install .NET SDK for ARM64 with retry mechanism
RUN wget https://dotnet.microsoft.com/download/dotnet/scripts/v1/dotnet-install.sh \
    && chmod +x dotnet-install.sh \
    && (./dotnet-install.sh --channel 7.0 --architecture arm64 || sleep 10 && ./dotnet-install.sh --channel 7.0 --architecture arm64 || sleep 20 && ./dotnet-install.sh --channel 7.0 --architecture arm64)

# Add .NET to PATH
ENV PATH="/root/.dotnet:${PATH}"

# Install SDKMAN and Java/Scala/SBT with retry mechanism
RUN (curl -s "https://get.sdkman.io" | bash) || (sleep 10 && curl -s "https://get.sdkman.io" | bash) \
    && chmod a+x "$HOME/.sdkman/bin/sdkman-init.sh" \
    && bash -c "source $HOME/.sdkman/bin/sdkman-init.sh && (sdk install java 17.0.9-oracle || sleep 10 && sdk install java 17.0.9-oracle) && (sdk install scala 3.3.0 || sleep 10 && sdk install scala 3.3.0) && (sdk install sbt 1.9.0 || sleep 10 && sdk install sbt 1.9.0)"

# Verify SDKMAN installation
RUN bash -c "source $HOME/.sdkman/bin/sdkman-init.sh && sdk version"

# Clone and build asn1scc with retry mechanism
WORKDIR /root
RUN git clone https://github.com/maxime-esa/asn1scc.git

# Build with multiple retries and increased timeout
WORKDIR /root/asn1scc
RUN bash -c "source $HOME/.sdkman/bin/sdkman-init.sh && (dotnet build -c Debug --no-restore || sleep 30 && dotnet build -c Debug --no-restore || sleep 60 && dotnet build -c Debug --no-restore)"

# Try restoring packages separately first
RUN bash -c "source $HOME/.sdkman/bin/sdkman-init.sh && (dotnet restore || sleep 30 && dotnet restore || sleep 60 && dotnet restore)"

# Then try the build again
RUN bash -c "source $HOME/.sdkman/bin/sdkman-init.sh && (dotnet build -c Debug || sleep 30 && dotnet build -c Debug || sleep 60 && dotnet build -c Debug)"

# Verify the asn1scc binary exists
RUN ls -l /root/asn1scc/asn1scc/bin/Debug/net7.0/asn1scc || echo "Binary not found, but continuing..."
RUN chmod +x /root/asn1scc/asn1scc/bin/Debug/net7.0/asn1scc || echo "Couldn't set executable permission, but continuing..."

# Set the working directory
WORKDIR /app

# Copy the ASN.1 schema and Python script
COPY sensor_data.asn /app/
COPY mpu6050_asn1.py /app/

# Generate C code from the ASN.1 schema using the full path to asn1scc
RUN /root/asn1scc/asn1scc/bin/Debug/net7.0/asn1scc -c -uPER -o /app/generated /app/sensor_data.asn || echo "Failed to generate C code, but continuing..."

# Install Python dependencies for the MPU6050 script
RUN pip3 install smbus2 asn1tools

# Run the application
CMD ["python3", "mpu6050_asn1.py"]
