# claude-cli-improvements

Small quality-of-life improvements for [Claude Code](https://claude.ai/code) — config snippets and scripts that make the TUI more useful day-to-day.

---

## 1. Usage stats in the status bar

Adds a live token counter to the bottom status bar so you can see context usage without opening `/usage`.

**Output:** `ctx:5% in:2k out:1k sess:29% week:35%`

- `ctx` — % of context window consumed (this conversation's token buffer)
- `in` / `out` — cumulative input/output tokens (in thousands)
- `sess` — % of your 5-hour rolling rate limit consumed (matches "current session usage" in `/usage`)
- `week` — % of your 7-day usage limit consumed

The bar is blank until you send the first message (data isn't available before that).

### Setup

Add the `statusLine` key to your `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "input=$(cat); pct=$(echo \"$input\" | jq -r '.context_window.used_percentage // empty'); [ -z \"$pct\" ] && exit 0; tin=$(echo \"$input\" | jq -r '.context_window.total_input_tokens // 0'); tout=$(echo \"$input\" | jq -r '.context_window.total_output_tokens // 0'); spct=$(echo \"$input\" | jq -r '.rate_limits.five_hour.used_percentage // empty'); wpct=$(echo \"$input\" | jq -r '.rate_limits.seven_day.used_percentage // empty'); printf 'ctx:%.0f%% in:%dk out:%dk' \"$pct\" \"$((tin/1000))\" \"$((tout/1000))\"; [ -n \"$spct\" ] && printf ' sess:%.0f%%' \"$spct\"; [ -n \"$wpct\" ] && printf ' week:%.0f%%' \"$wpct\""
  }
}
```

**Requires:** `jq` (`brew install jq` / `apt install jq`)

Restart Claude Code after saving.

---

## 2. Multi-session color identity

When running multiple Claude Code sessions simultaneously, each session automatically gets a unique terminal background color. This makes sessions instantly distinguishable when alt-tabbing between windows.

- Session A: deep blue background (`#00001e`)
- Session B: dark teal background (`#002020`)
- Session C: dark forest green (`#001400`)
- … up to 8 distinct colors

Colors are coordinated across active sessions so no two share a color. The assignment is **persistent** — if you `/resume` a session, it picks up the same color it had before. The window title is also labeled:

```
[blue] claude — ~/Projects/my-api
[teal] claude — ~/Projects/frontend
```

The background applies on your first message (Claude Code has no session-start hook), then stays visible for the entire session — including while Claude is responding.

### GNOME Terminal prerequisite

OSC 11 color sequences are silently ignored if the profile forces system theme colors. In GNOME Terminal, go to **Preferences → your profile → Colors** and uncheck **"Use colors from system theme"** before using this.

### How it works

The `UserPromptSubmit` hook receives a JSON payload containing `session_id`. The script uses this UUID to look up or create a persistent color assignment in `~/.claude/session-colors/`. An ephemeral active-session registry at `/tmp/claude-active-sessions/` tracks which colors are in use; dead sessions are detected via `kill -0` and cleaned up before new assignments. Background color is applied via OSC 11 (`\e]11;#hexcolor\a`) written directly to `/dev/tty`. No `Stop` hook is needed — re-applying OSC 11 on every `UserPromptSubmit` keeps the color stable, and the background simply remains set when the session ends.

Supported terminals: GNOME Terminal (with custom colors enabled), Kitty, WezTerm, iTerm2, Alacritty, xterm.

### Setup

1. Save [`session-color.sh`](session-color.sh) to `~/.claude/session-color.sh` and make it executable:

   ```bash
   chmod +x ~/.claude/session-color.sh
   ```

2. Add a `UserPromptSubmit` hook to `~/.claude/settings.json`:

   ```json
   {
     "hooks": {
       "UserPromptSubmit": [
         { "matcher": "", "hooks": [{ "type": "command", "command": "bash ~/.claude/session-color.sh set" }] }
       ]
     }
   }
   ```

3. Restart Claude Code.

**Requires:** `jq`

---

## Contributing

Open a PR with your own snippets — keep entries self-contained and free of personal paths or credentials.
