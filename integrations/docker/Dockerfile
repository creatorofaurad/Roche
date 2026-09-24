FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV ZIG_VERSION=0.16.0

RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Zig 0.16.0
RUN wget -q https://ziglang.org/builds/zig-linux-x86_64-0.16.0-dev.685+93d56fcf2.tar.xz -O zig.tar.xz \
    || wget -q https://ziglang.org/download/0.13.0/zig-linux-x86_64-0.13.0.tar.xz -O zig.tar.xz \
    && tar -xf zig.tar.xz \
    && mv zig-linux-x86_64-* /usr/local/zig \
    && ln -s /usr/local/zig/zig /usr/local/bin/zig \
    && rm zig.tar.xz

WORKDIR /app
COPY . .

RUN zig build -Doptimize=ReleaseFast

EXPOSE 8080

CMD ["./zig-out/bin/roche", "server", "--port", "8080"]
