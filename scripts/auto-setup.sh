#!/bin/bash
# Runs inside Konsole — installs Claude Code, configures statusline, drops to shell.

export PATH="$HOME/.local/bin:$PATH"

# Install toclipboard:// URI handler (for statusline copy link)
mkdir -p ~/.local/bin ~/.local/share/applications
cat > ~/.local/bin/toclipboard-handler << 'HANDLER'
#!/bin/bash
uri="$1"
payload="${uri#toclipboard://}"
payload="${payload#toclipboard:}"
[[ "$payload" == /* ]] && payload="${payload:1}"
decoded=$(python3 -c "import sys, urllib.parse; print(urllib.parse.unquote_plus(sys.argv[1]), end='')" "$payload")
echo -n "$decoded" | xclip -selection clipboard
HANDLER
chmod +x ~/.local/bin/toclipboard-handler

cat > ~/.local/share/applications/toclipboard-handler.desktop << DESKTOP
[Desktop Entry]
Type=Application
Name=ToClipboard Handler
Exec="$HOME/.local/bin/toclipboard-handler" %u
StartupNotify=false
NoDisplay=true
MimeType=x-scheme-handler/toclipboard;
DESKTOP
update-desktop-database ~/.local/share/applications/ 2>/dev/null
xdg-mime default toclipboard-handler.desktop x-scheme-handler/toclipboard 2>/dev/null

if ! grep -q '.local/bin' ~/.bashrc 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
fi

# Link auth from persistent dir (PERSIST_DIR mounted at its host path by x11docker --share)
if [[ -n "${PERSIST_DIR:-}" ]]; then
    mkdir -p "$PERSIST_DIR/.claude"
    touch "$PERSIST_DIR/.claude.json"
    if [[ ! -e ~/.claude ]]; then
        ln -sf "$PERSIST_DIR/.claude" ~/.claude
        echo "Linked .claude from persist dir."
    fi
    if [[ ! -e ~/.claude.json ]]; then
        ln -sf "$PERSIST_DIR/.claude.json" ~/.claude.json
        echo "Linked .claude.json from persist dir."
    fi
fi

VERSION="${CLAUDE_VERSION:-latest}"

# Install if not already done
if [[ ! -f ~/.setup_done ]]; then
    echo "=== Installing Claude Code ($VERSION) ==="
    if [[ "$VERSION" == "latest" ]]; then
        curl -fsSL https://claude.ai/install.sh | bash
    else
        curl -fsSL https://claude.ai/install.sh | bash -s "$VERSION"
    fi
    touch ~/.setup_done
    echo ""
    echo "=== Setup complete ==="
fi

# Configure the minimal statusline
mkdir -p ~/.claude
cat > ~/.claude/settings.json << 'EOF'
{
  "statusLine": {
    "type": "command",
    "command": "/opt/test-scripts/statusline.sh",
    "padding": 0
  }
}
EOF

claude --version
echo ""

# Launch VS Code with Claude in integrated terminal
echo "Starting VS Code with Claude..."
/opt/test-scripts/vscode-claude.sh &

echo ""
echo "========================================================"
echo "  SETUP COMPLETE — TEST INSTRUCTIONS"
echo "========================================================"
echo ""
echo "  1. VS Code opened — dismiss any credential store popup"
echo ""
echo "  2. Run 'claude' HERE to authenticate (OAuth via browser)"
echo "     Auth persists in persist/ between runs."
echo ""
echo "  3. In VS Code, open terminal (Ctrl+\`) and run: claude"
echo "     The statusline 'uuid' link should work in ALL versions."
echo ""
echo "  4. Open a NEW Konsole tab (Ctrl+Shift+T) and run: claude"
echo "     - v2.0.76: 'uuid' is underlined + clickable (WORKING)"
echo "     - latest:  'uuid' is NOT clickable (BROKEN)"
echo ""
echo "  5. Verify clipboard: xclip -selection clipboard -o"
echo "========================================================"
echo ""
exec bash
