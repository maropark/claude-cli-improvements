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

- Session A: deep blue background
- Session B: dark teal background
- Session C: dark forest green background
- … up to 8 distinct colors

Colors are coordinated across sessions — no two active sessions share a color. On exit, each session's terminal background resets to your default. The window title also gets labeled for extra context:

```
[blue] claude — ~/Projects/my-api
[teal] claude — ~/Projects/frontend
```

The background shifts on your first message in each session (no start hook exists in Claude Code), then stays stable.

### How it works

Each Claude Code session writes `~/.claude/sessions/<pid>.json` with a UUID. The script reads this via `$PPID` (Claude is the parent process of all hooks). On first `UserPromptSubmit`, it claims the lowest available color index from a file registry at `/tmp/claude-sessions/`. Stale entries from crashed sessions are detected via `kill -0` and cleaned up automatically. Background color is applied via `OSC 11` (`\e]11;#hexcolor\a`) and window title via `OSC 2`, both written directly to `/dev/tty` so they reach the terminal rather than being captured by Claude Code.

Supported terminals: GNOME Terminal, Kitty, WezTerm, iTerm2, Alacritty, xterm. The color defaults back to your theme on session end.

### Setup

1. Save [`session-color.sh`](session-color.sh) to `~/.claude/session-color.sh` and make it executable:

   ```bash
   chmod +x ~/.claude/session-color.sh
   ```

2. Add hooks to `~/.claude/settings.json`:

   ```json
   {
     "hooks": {
       "UserPromptSubmit": [
         { "matcher": "", "hooks": [{ "type": "command", "command": "bash ~/.claude/session-color.sh set" }] }
       ],
       "Stop": [
         { "matcher": "", "hooks": [{ "type": "command", "command": "bash ~/.claude/session-color.sh cleanup" }] }
       ]
     }
   }
   ```

3. Restart Claude Code.

**Requires:** `jq`

---

## Contributing

Open a PR with your own snippets — keep entries self-contained and free of personal paths or credentials.
