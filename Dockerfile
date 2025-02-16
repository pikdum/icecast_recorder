FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash curl jq wget ca-certificates procps \
    && rm -rf /var/lib/apt/lists/*

COPY record-stream.sh /app/record-stream.sh
RUN chmod +x /app/record-stream.sh

WORKDIR /app
