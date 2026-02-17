#!/bin/bash
# Launch VS Code with Claude auto-running in integrated terminal

TEST_DIR="/tmp/claude-test"
CLAUDE_CMD="claude"

# VS Code user settings — trust workspaces, allow auto tasks
mkdir -p ~/.config/Code/User
cat > ~/.config/Code/User/settings.json << 'EOF'
{
  "task.allowAutomaticTasks": "on",
  "security.workspace.trust.enabled": false,
  "security.workspace.trust.startupPrompt": "never"
}
EOF

# Create test workspace with auto-run task
mkdir -p "$TEST_DIR/.vscode"

cat > "$TEST_DIR/.vscode/tasks.json" << EOF
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Run Claude",
      "type": "shell",
      "command": "$CLAUDE_CMD",
      "presentation": {
        "reveal": "always",
        "panel": "new",
        "focus": true
      },
      "runOptions": {
        "runOn": "folderOpen"
      }
    }
  ]
}
EOF

cat > "$TEST_DIR/.vscode/settings.json" << 'EOF'
{
  "task.allowAutomaticTasks": "on",
  "security.workspace.trust.enabled": false
}
EOF

echo "Opening VS Code with Claude test workspace..."
code "$TEST_DIR" &

sleep 3
wmctrl -r "Visual Studio Code" -b add,maximized_vert,maximized_horz 2>/dev/null
