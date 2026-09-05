# 1. Use an official Node.js base image with a specific version
FROM debian:trixie-slim
RUN apt update
RUN apt install -y curl git
RUN git clone -b dev https://github.com/TreeFrogTinkerer/my-quake-shakes.git
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:$PATH"
WORKDIR ./my-quake-shakes
RUN chmod +x docker-install.sh
RUN ./docker-install.sh
WORKDIR /home/root/my-quake-shakes/SAIPy
CMD ["./wrapper-my-quake-shakes.sh"]
