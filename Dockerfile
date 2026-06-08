FROM rust:1-slim-bookworm

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		build-essential \
		ca-certificates \
		libssl-dev \
		pkg-config \
	&& rm -rf /var/lib/apt/lists/*

RUN cargo install lune --locked

WORKDIR /app
COPY . .

CMD ["lune", "run", "bot.luau"]
