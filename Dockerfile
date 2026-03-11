# Этап 1: Сборка
FROM --platform=$BUILDPLATFORM ubuntu:22.04 AS builder

RUN apt-get update && apt-get install -y \
    git build-essential cmake libboost-all-dev libssl-dev libunbound-dev \
    libminiupnpc-dev libunwind8-dev liblzma-dev libreadline6-dev \
    libldns-dev libexpat1-dev doxygen graphviz libpcsclite-dev \
    pkg-config ca-certificates

# Клонируем официальную ноду
RUN git clone --recursive --depth 1 https://github.com/scala-network/Scala.git /scala-node
WORKDIR /scala-node

# Собираем (ограничим потоки, чтобы GitHub не упал на ARM эмуляции)
RUN mkdir build && cd build && \
    cmake .. && \
    make -j$(nproc)

# Этап 2: Финальный образ
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y \
    libboost-system-dev libboost-filesystem-dev libboost-thread-dev \
    libboost-program-options-dev libssl3 libunbound8 libminiupnpc17 \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /scala-node/build/bin/scalad /usr/local/bin/scalad

# Порты для P2P и RPC
EXPOSE 11812 11813

ENTRYPOINT ["scalad"]
CMD ["--non-interactive", "--restricted-rpc", "--rpc-bind-ip=0.0.0.0", "--confirm-external-bind"]
