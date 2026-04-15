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

When running multiple Claude Code sessions simultaneously, each gets a unique color assigned automatically. Colors are coordinated across sessions — no two active sessions share a color.

**Status bar:**
- Session A: `🟦 ctx:5% in:2k out:1k sess:29% week:35% [blue]`
- Session B: `🟩 ctx:12% in:8k out:3k sess:44% week:12% [green]`

**Terminal window title** (via OSC 2, works in GNOME Terminal, Kitty, WezTerm, iTerm2, Alacritty):
- `[blue] claude — ~/Projects/my-api`
- `[green] claude — ~/Projects/frontend`

The status bar also renders a colored ANSI background block behind the emoji. If your terminal strips ANSI from status bar output, the emoji + `[name]` label still provide clear visual identity.

Up to 8 simultaneous sessions get unique colors (blue, green, purple, teal, orange, crimson, olive, slate). If you run more than 8, colors wrap around.

### Setup

1. Save [`session-color.sh`](session-color.sh) to `~/.claude/session-color.sh` and make it executable:

   ```bash
   chmod +x ~/.claude/session-color.sh
   ```

2. Update `~/.claude/settings.json` — replace the `statusLine` key and add hooks:

   ```json
   {
     "statusLine": {
       "type": "command",
       "command": "bash ~/.claude/session-color.sh statusline"
     },
     "hooks": {
       "Stop": [
         { "matcher": "", "hooks": [{ "type": "command", "command": "bash ~/.claude/session-color.sh cleanup" }] }
       ],
       "UserPromptSubmit": [
         { "matcher": "", "hooks": [{ "type": "command", "command": "bash ~/.claude/session-color.sh title" }] }
       ]
     }
   }
   ```

3. Restart Claude Code.

### How it works

Each Claude Code session writes `~/.claude/sessions/<pid>.json` containing its UUID. The script reads this via `$PPID` (the Claude process is the parent of the statusLine subprocess and hooks). On first run, it claims the lowest available color index from a registry at `/tmp/claude-sessions/<uuid>`. Stale registry entries (from crashed sessions) are cleaned up automatically by checking whether the session's PID is still alive. The window title is set via OSC 2 escape sequences written directly to `/dev/tty`.

**Requires:** `jq`

---

## Contributing

Open a PR with your own snippets — keep entries self-contained and free of personal paths or credentials.
