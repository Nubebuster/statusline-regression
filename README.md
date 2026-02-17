# Claude Code Statusline OSC 8 Regression

Minimal reproduction environment for the `toclipboard://` copy-link bug in Claude Code's statusline.

## The Bug

Claude Code's statusline supports a `command` type that runs a shell script and renders its output. The statusline script emits an [OSC 8 hyperlink](https://gist.github.com/egmontkob/eb114294efbcd5adb1944c9f3cb5feda) — the standard terminal escape for clickable links:

```
ESC ] 8 ; ; toclipboard://test-uuid ESC \ uuid ESC ] 8 ; ; ESC \
```

This worked in **v2.0.76** but is broken in later versions. The link is no longer rendered or clickable in Konsole (a terminal that fully supports OSC 8). It still works in VS Code's integrated terminal across all versions, suggesting a regression in how Claude Code emits the escape sequence to real terminal emulators.

## Requirements

- Docker
- [x11docker](https://github.com/mviereck/x11docker)

## Usage

```bash
git clone <this-repo>
cd statusline-regression
chmod +x run.sh
./run.sh
```

You will be prompted to pick a Claude Code version. The container builds once; Claude Code is installed on first run.

## Reproduction Steps

### 1. Initial setup

`run.sh` opens a KDE Plasma desktop in a window. A Konsole terminal launches and installs Claude Code automatically. VS Code also opens with a test workspace.

### 2. Skip the VS Code credential store popup

When VS Code opens, it may prompt about a credential/keyring store. **Dismiss or skip this dialog** — it is not needed for the test.

### 3. Authenticate Claude Code

In the Konsole terminal, run:

```bash
claude
```

Complete the authentication flow (browser OAuth). Auth credentials persist in `persist/` between container runs, so you only need to do this once.

### 4. Verify OSC 8 works in VS Code (all versions)

Open VS Code's integrated terminal (`Ctrl+`\``) and run `claude`. Look at the statusline at the bottom — the "uuid" text should be an underlined, clickable link. **This works in all Claude Code versions** because VS Code handles the escape rendering itself.

### 5. Test in Konsole (the actual regression)

Open a **new Konsole tab** (`Ctrl+Shift+T` or via the menu) and run:

```bash
claude
```

Check the statusline at the bottom:

| Version | Expected behavior |
|---------|-------------------|
| **2.0.76** | "uuid" is underlined and clickable — Ctrl+click copies `test-uuid` to clipboard |
| **latest** | "uuid" is **not** clickable — the OSC 8 hyperlink is broken |

### 6. Verify clipboard (when working)

```bash
xclip -selection clipboard -o
# Should output: test-uuid
```

## Files

| File | Purpose |
|------|---------|
| `Dockerfile` | Ubuntu 25.04 + KDE Plasma + Node.js |
| `run.sh` | Launches x11docker with the test container |
| `scripts/statusline.sh` | Minimal statusline: single OSC 8 hyperlink |
| `scripts/auto-setup.sh` | Installs Claude Code, configures statusline, launches VS Code |
| `scripts/vscode-claude.sh` | Opens VS Code with auto-run Claude task |
| `scripts/desktop-setup.sh` | KDE autostart: installs Konsole profile, opens Konsole |
| `scripts/run-test.sh` | Test instructions shown in Konsole |
