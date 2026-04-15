#!/usr/bin/env bash
# session-color.sh — per-session terminal background color for Claude Code
#
# Each session claims a unique background color from a shared registry so
# concurrent sessions are visually distinct when alt-tabbing between windows.
# Colors are assigned on first UserPromptSubmit and released on Stop.
#
# Modes:
#   set     (UserPromptSubmit hook) — assign color, apply OSC 11, set window title
#   cleanup (Stop hook)             — release color, reset terminal background

REGISTRY_DIR="/tmp/claude-sessions"
SESSION_DIR="$HOME/.claude/sessions"

# 8 distinct dark backgrounds — all clearly different from each other and
# from the default Claude Code purple/magenta theme
BG_COLORS=("#00001e" "#002020" "#001400" "#1e0000" "#141000" "#001428" "#1e1400" "#0e000e")
NAMES=(     blue      teal      forest    maroon    amber     navy      copper    plum)

_get_session_id() {
    jq -r '.sessionId // empty' "$SESSION_DIR/$PPID.json" 2>/dev/null || true
}

_cleanup_stale() {
    [ -d "$REGISTRY_DIR" ] || return 0
    for f in "$REGISTRY_DIR"/*; do
        [ -f "$f" ] || continue
        fsid=$(basename "$f")
        fpid=$(grep -rl "\"$fsid\"" "$SESSION_DIR/" 2>/dev/null \
               | head -1 | xargs -r basename | sed 's/\.json//')
        if [ -z "$fpid" ] || ! kill -0 "$fpid" 2>/dev/null; then
            rm -f "$f"
        fi
    done
}

_assign_color() {
    local sid="$1"
    local reg="$REGISTRY_DIR/$sid"

    # Already assigned — idempotent
    [ -f "$reg" ] && { cat "$reg"; return; }

    mkdir -p "$REGISTRY_DIR"
    _cleanup_stale

    local taken=""
    for f in "$REGISTRY_DIR"/*; do
        [ -f "$f" ] && taken="$taken $(cat "$f")"
    done

    local chosen=0
    for i in 0 1 2 3 4 5 6 7; do
        if ! echo "$taken" | grep -qw "$i"; then
            chosen=$i
            break
        fi
    done

    printf '%d' "$chosen" > "$reg"
    echo "$chosen"
}

case "${1:-}" in

  set)
    [ -w /dev/tty ] || exit 0
    sid=$(_get_session_id)
    [ -z "$sid" ] && exit 0
    idx=$(_assign_color "$sid")
    color="${BG_COLORS[$idx]}"
    name="${NAMES[$idx]}"
    # Apply terminal background color
    printf '\e]11;%s\a' "$color" > /dev/tty
    # Set window title for extra context
    cwd=$(pwd | sed "s|$HOME|~|")
    printf '\e]2;[%s] claude — %s\a' "$name" "$cwd" > /dev/tty
    ;;

  cleanup)
    sid=$(_get_session_id)
    [ -n "$sid" ] && rm -f "$REGISTRY_DIR/$sid"
    # Reset terminal background and window title to defaults
    if [ -w /dev/tty ]; then
        printf '\e]111\a' > /dev/tty
        printf '\e]2;\a'  > /dev/tty
    fi
    ;;

esac
