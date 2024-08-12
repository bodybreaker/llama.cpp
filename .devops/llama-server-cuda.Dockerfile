ARG UBUNTU_VERSION=22.04
# This needs to generally match the container host's environment.
ARG CUDA_VERSION=12.2.2
# Target the CUDA build image
ARG BASE_CUDA_DEV_CONTAINER=nvidia/cuda:${CUDA_VERSION}-devel-ubuntu${UBUNTU_VERSION}
# Target the CUDA runtime image
ARG BASE_CUDA_RUN_CONTAINER=nvidia/cuda:${CUDA_VERSION}-runtime-ubuntu${UBUNTU_VERSION}

FROM ${BASE_CUDA_DEV_CONTAINER} AS build

# Unless otherwise specified, we make a fat build.
ARG CUDA_DOCKER_ARCH=all

RUN apt-get update && \
    apt-get install -y build-essential git libcurl4-openssl-dev cmake curl && \
    rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g npm@latest

RUN curl -LO https://golang.org/dl/go1.20.6.linux-amd64.tar.gz \
    && tar -C /usr/local -xzf go1.20.6.linux-amd64.tar.gz \
    && rm go1.20.6.linux-amd64.tar.gz

# PADDLER
ENV PATH=$PATH:/usr/local/go/bin

WORKDIR /app

RUN git clone https://github.com/distantmagic/paddler.git

WORKDIR /app/paddler

RUN make

RUN mv ./paddler-bin-linux-x64 /usr/local/bin/paddler

# END PADDLER

WORKDIR /app

COPY . .

# Set nvcc architecture
ENV CUDA_DOCKER_ARCH=${CUDA_DOCKER_ARCH}
# Enable CUDA
ENV GGML_CUDA=1
# Enable cURL
ENV LLAMA_CURL=1

RUN make -j$(nproc) llama-server

FROM ${BASE_CUDA_RUN_CONTAINER} AS runtime

RUN apt-get update && \
    apt-get install -y libcurl4-openssl-dev libgomp1 curl

COPY --from=build /app/llama-server /llama-server

HEALTHCHECK CMD [ "curl", "-f", "http://localhost:8080/health" ]

ENTRYPOINT [ "/llama-server" ]
