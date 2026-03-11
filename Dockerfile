# Этап 1: Сборка (Builder)
FROM ubuntu:22.04 AS builder

# Устанавливаем все твои зависимости + git
RUN apt-get update && apt-get install -y \
    build-essential cmake pkg-config libboost-all-dev \
    libssl-dev libzmq3-dev libunbound-dev libsodium-dev \
    libunwind8-dev liblzma-dev libreadline-dev \
    libldns-dev libexpat1-dev doxygen graphviz git \
    && rm -rf /var/lib/apt/lists/*

# Клонируем исходники прямо в образ (так надежнее для GitHub Actions)
RUN git clone --recursive --depth 1 https://github.com/scala-network/Scala.git /src
WORKDIR /src

# Сборка (используем -j4, чтобы не перегружать раннер при эмуляции ARM)
RUN mkdir build && cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release .. && \
    make -j4

# Этап 2: Финальный образ (Runtime)
FROM ubuntu:22.04

# Твой список библиотек для запуска
RUN apt-get update && apt-get install -y \
    libboost-chrono1.74.0 \
    libboost-date-time1.74.0 \
    libboost-filesystem1.74.0 \
    libboost-thread1.74.0 \
    libboost-program-options1.74.0 \
    libboost-regex1.74.0 \
    libboost-serialization1.74.0 \
    libboost-system1.74.0 \
    libzmq5 libunbound8 libsodium23 libunwind8 \
    libreadline8 libexpat1 libldns3 ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
# Копируем бинарник из билдера
COPY --from=builder /src/build/bin/scalad /app/scalad

# Настройки портов и томов
EXPOSE 11812 11813
VOLUME ["/root/.scala"]

# Запуск
ENTRYPOINT ["/app/scalad"]
CMD ["--non-interactive", "--restricted-rpc", "--rpc-bind-ip=0.0.0.0", "--confirm-external-bind"]
