#!/bin/bash
# KDE autostart wrapper — sets up Konsole config, then opens Konsole with setup script.

# Install Konsole profile BEFORE launching Konsole (enables OSC 8 links + toclipboard://)
mkdir -p ~/.config ~/.local/share/konsole
cp -n /opt/test-scripts/konsolerc ~/.config/konsolerc 2>/dev/null || true
cp -n /opt/test-scripts/Test.profile ~/.local/share/konsole/Test.profile 2>/dev/null || true

konsole -e /opt/test-scripts/auto-setup.sh
