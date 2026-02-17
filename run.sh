#!/bin/bash
# Launch the OSC 8 statusline regression test in an x11docker KDE desktop.
# Requires: docker, x11docker (https://github.com/mviereck/x11docker)
#
# Usage: ./run.sh [latest|stable|next|<version>]
set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="statusline-osc8-test"
CLAUDE_VERSION="${1:-}"

if [[ -z $CLAUDE_VERSION ]]; then
    echo "Claude Code version to test:"
    echo "  1) 2.1.2"
    echo "  2) 2.1.3"
    echo "  3) latest"
    echo "  4) stable"
    echo "  5) next"
    echo "  6) custom version"
    echo ""
    read -rp "Choice [1]: " choice
    case "${choice:-1}" in
    1) CLAUDE_VERSION="2.1.2" ;;
    2) CLAUDE_VERSION="2.1.3" ;;
    3) CLAUDE_VERSION="latest" ;;
    4) CLAUDE_VERSION="stable" ;;
    5) CLAUDE_VERSION="next" ;;
    6) read -rp "Version (e.g. 2.1.2): " CLAUDE_VERSION ;;
    *) CLAUDE_VERSION="latest" ;;
    esac
fi

# Build if image missing or files changed
needs_rebuild() {
    if ! docker image inspect "$IMAGE_NAME" &> /dev/null; then
        return 0
    fi
    local image_time
    image_time=$(date -d "$(docker image inspect -f '{{.Created}}' "$IMAGE_NAME")" +%s)
    if [[ $(stat -c %Y "$SCRIPT_DIR/Dockerfile") -gt $image_time ]]; then
        return 0
    fi
    for f in "$SCRIPT_DIR"/scripts/*; do
        if [[ -f $f && $(stat -c %Y "$f") -gt $image_time ]]; then
            return 0
        fi
    done
    return 1
}

if needs_rebuild; then
    echo "Building image..."
    docker build -t "$IMAGE_NAME" -f "$SCRIPT_DIR/Dockerfile" "$SCRIPT_DIR"
fi

# Persistent dir for Claude Code auth (survives between runs)
mkdir -p "$SCRIPT_DIR/persist"

# Display server auto-detection
# Xwayland doesn't support RANDR CreateMode, so skip --size on Wayland
x11docker_display=()
if [[ ${XDG_SESSION_TYPE:-} == "wayland" ]]; then
    x11docker_display=(--xwayland)
else
    x11docker_display=(--size 1920x1080)
fi

echo "Starting KDE desktop with Claude Code ($CLAUDE_VERSION)..."
echo "Auth persists in: $SCRIPT_DIR/persist"
echo ""

x11docker --desktop \
    "${x11docker_display[@]}" \
    --clipboard \
    --network \
    --init=systemd \
    --sudouser \
    --env "CLAUDE_VERSION=$CLAUDE_VERSION" \
    --env "PERSIST_DIR=$SCRIPT_DIR/persist" \
    --env "DISABLE_AUTOUPDATER=1" \
    --share "$SCRIPT_DIR/persist" \
    -- \
    "$IMAGE_NAME"
