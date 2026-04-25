FROM mcr.microsoft.com/devcontainers/base:trixie

ENV DEBIAN_FRONTEND=noninteractive
ENV GODOT_VERSION=4.6.2-stable

# Base packages + Python support for Codex skill validation
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        iputils-ping \
        poppler-utils \
        python3 \
        python3-pip \
        python3-venv \
        python3-yaml \
        vim \
        imagemagick \
        librsvg2-bin \
        zip \
        unzip \
        xvfb \
    && rm -rf /var/lib/apt/lists/*

# Install Godot 4.x from official release binaries.
RUN curl -fsSL -o /tmp/godot.zip "https://github.com/godotengine/godot-builds/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_linux.x86_64.zip" \
    && mkdir -p /opt/godot \
    && unzip -q /tmp/godot.zip -d /opt/godot \
    && rm -f /tmp/godot.zip \
    && chmod +x /opt/godot/Godot_v${GODOT_VERSION}_linux.x86_64 \
    && ln -sf /opt/godot/Godot_v${GODOT_VERSION}_linux.x86_64 /usr/local/bin/godot
# VS Code / X / cache dirs
RUN chmod 1777 /tmp \
    && mkdir -p /tmp/.X11-unix \
    && chmod 1777 /tmp/.X11-unix \
    && mkdir -p /home/vscode/.cache \
    && mkdir -p /home/vscode/.vscode-server/extensions \
    && mkdir -p /home/vscode/.vscode-server/data/User/globalStorage \
    && mkdir -p /home/vscode/.vscode-server-insiders/extensions \
    && mkdir -p /home/vscode/.vscode-server-insiders/data/User/globalStorage \
    && chown -R vscode:vscode /home/vscode/.cache \
    && chown -R vscode:vscode /home/vscode/.vscode-server \
    && chown -R vscode:vscode /home/vscode/.vscode-server-insiders \
    && echo 'vscode ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
