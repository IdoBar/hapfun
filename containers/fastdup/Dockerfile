# ============================================================
# FastDup v1.0.0 Docker image
# A Scalable Duplicate Marking Tool using Speculation-and-Test Mechanism
# https://github.com/zzhofict/FastDup
# ============================================================

# -----------------------------------------------------------
# Stage 1: Build
# -----------------------------------------------------------
FROM ubuntu:22.04 AS builder

ARG FASTDUP_VERSION=1.0.0

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        autoconf \
        automake \
    ca-certificates \
        cmake \
        g++ \
        libcurl4-openssl-dev \
        libdeflate-dev \
        libbz2-dev \
        liblzma-dev \
        libncurses-dev \
        libssl-dev \
        make \
        pkg-config \
        python3-pip \
        curl \
        zlib1g-dev \
    && python3 -m pip install --no-cache-dir --upgrade cmake \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Download and extract source
RUN update-ca-certificates \
    && curl -fsSL "https://github.com/zzhofict/FastDup/archive/refs/tags/v${FASTDUP_VERSION}.tar.gz" \
        -o fastdup.tar.gz \
    && tar -xzf fastdup.tar.gz \
    && mv "FastDup-${FASTDUP_VERSION}" fastdup \
    && rm -f fastdup.tar.gz

WORKDIR /build/fastdup

# Build the bundled htslib first
RUN cd ext/htslib \
    && autoreconf -i \
    && ./configure --disable-plugins \
    && make -j"$(nproc)"

# Build FastDup
RUN mkdir -p build \
    && cmake -S . -B build \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_CXX_FLAGS="-O3" \
    && cmake --build build --clean-first --target fastdup -j"$(nproc)"

# -----------------------------------------------------------
# Stage 2: Runtime
# -----------------------------------------------------------
FROM ubuntu:22.04 AS runtime

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        libcurl4 \
        libdeflate0 \
        libbz2-1.0 \
        liblzma5 \
        libncurses6 \
        samtools \
        zlib1g \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /build/fastdup/build/bin/fastdup /usr/local/bin/fastdup

# Sanity check
RUN fastdup --version
RUN samtools --version

LABEL org.opencontainers.image.source="https://github.com/zzhofict/FastDup" \
      org.opencontainers.image.version="1.0.0" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.description="FastDup: A Scalable Duplicate Marking Tool"

ENTRYPOINT ["fastdup"]
