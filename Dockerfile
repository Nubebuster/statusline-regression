FROM ubuntu:25.04

ENV DEBIAN_FRONTEND=noninteractive

USER root

# KDE Plasma desktop
RUN apt-get update && apt-get install -y \
    kde-plasma-desktop \
    konsole \
    systemd \
    dbus \
    xorg \
    xinit \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Tools needed for the test
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    gpg \
    xclip \
    wmctrl \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# VS Code
RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /usr/share/keyrings/packages.microsoft.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list \
    && apt-get update \
    && apt-get install -y code \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && mv /usr/bin/code /usr/bin/code-real \
    && printf '#!/bin/sh\nexec /usr/bin/code-real --no-sandbox "$@"\n' > /usr/bin/code \
    && chmod +x /usr/bin/code

# Node.js 22 (for Claude Code)
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Test scripts and Konsole config
COPY scripts/ /opt/test-scripts/
COPY konsole/konsolerc /opt/test-scripts/konsolerc
COPY konsole/Test.profile /opt/test-scripts/Test.profile
RUN chmod +x /opt/test-scripts/*.sh

# KDE autostart
RUN mkdir -p /etc/xdg/autostart && \
    cp /opt/test-scripts/autostart.desktop /etc/xdg/autostart/

USER 1000
CMD ["startplasma-x11"]
