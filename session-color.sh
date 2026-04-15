#!/usr/bin/env bash
# session-color.sh — per-session terminal background color for Claude Code
#
# Each session gets a unique background color, persisted across resumes.
# The background is applied on every UserPromptSubmit so it stays visible
# throughout the conversation. No Stop hook is needed — dead sessions are
# detected via kill -0 before new color assignments.
#
# Mode:
#   set  (UserPromptSubmit hook) — assign/recall color, apply OSC 11

COLORS_DIR="$HOME/.claude/session-colors"   # persistent: UUID → color index
ACTIVE_DIR="/tmp/claude-active-sessions"    # ephemeral: currently-running sessions
LOCK_DIR="/tmp/claude-color-lock"           # atomic mkdir lock
SESSION_DIR="$HOME/.claude/sessions"

# 8 distinct dark backgrounds, all clearly different from the default
# Claude Code purple/magenta theme
BG_COLORS=("#00001e" "#002020" "#001400" "#1e0000" "#141000" "#001428" "#1e1400" "#0e000e")
NAMES=(     blue      teal      forest    maroon    amber     navy      copper    plum)

_acquire_lock() {
    local tries=0
    while ! mkdir "$LOCK_DIR" 2>/dev/null; do
        sleep 0.05
        tries=$((tries + 1))
        [ $tries -gt 100 ] && return 1  # 5s timeout
    done
}

_release_lock() {
    rmdir "$LOCK_DIR" 2>/dev/null
}

_cleanup_stale_active() {
    [ -d "$ACTIVE_DIR" ] || return 0
    for f in "$ACTIVE_DIR"/*; do
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
    local persistent="$COLORS_DIR/$sid"
    local active="$ACTIVE_DIR/$sid"

    mkdir -p "$COLORS_DIR" "$ACTIVE_DIR"

    # Persistent assignment exists — reuse same color (handles resume)
    if [ -f "$persistent" ]; then
        cp "$persistent" "$active"
        cat "$persistent"
        return
    fi

    # New session — lock to prevent race between concurrent first messages
    _acquire_lock || { echo 0; return; }

    _cleanup_stale_active

    local taken=""
    for f in "$ACTIVE_DIR"/*; do
        [ -f "$f" ] && taken="$taken $(cat "$f")"
    done

    local chosen=0
    for i in 0 1 2 3 4 5 6 7; do
        if ! echo "$taken" | grep -qw "$i"; then
            chosen=$i
            break
        fi
    done

    printf '%d' "$chosen" > "$persistent"
    cp "$persistent" "$active"

    _release_lock

    echo "$chosen"
}

case "${1:-}" in

  set)
    [ -w /dev/tty ] || exit 0

    sid=$(cat | jq -r '.session_id // empty' 2>/dev/null)
    [ -z "$sid" ] && exit 0

    idx=$(_assign_color "$sid")
    color="${BG_COLORS[$idx]}"
    name="${NAMES[$idx]}"

    printf '\e]11;%s\a' "$color" > /dev/tty
    cwd=$(pwd | sed "s|$HOME|~|")
    printf '\e]2;[%s] claude — %s\a' "$name" "$cwd" > /dev/tty
    ;;

esac
