# claude-cli-improvements

Small quality-of-life improvements for [Claude Code](https://claude.ai/code) — config snippets and scripts that make the TUI more useful day-to-day.

---

## 1. Usage stats in the status bar

Adds a live token counter to the bottom status bar so you can see context usage without opening `/usage`.

**Output:** `ctx:42% in:2k out:1k week:35%`

- `ctx` — % of context window consumed this session
- `in` / `out` — cumulative input/output tokens (in thousands)
- `week` — % of your 7-day usage limit consumed (Claude.ai subscribers only; omitted otherwise)

The bar is blank until you send the first message (data isn't available before that).

### Setup

Add the `statusLine` key to your `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "input=$(cat); pct=$(echo \"$input\" | jq -r '.context_window.used_percentage // empty'); [ -z \"$pct\" ] && exit 0; tin=$(echo \"$input\" | jq -r '.context_window.total_input_tokens // 0'); tout=$(echo \"$input\" | jq -r '.context_window.total_output_tokens // 0'); wpct=$(echo \"$input\" | jq -r '.rate_limits.seven_day.used_percentage // empty'); printf 'ctx:%.0f%% in:%dk out:%dk' \"$pct\" \"$((tin/1000))\" \"$((tout/1000))\"; [ -n \"$wpct\" ] && printf ' week:%.0f%%' \"$wpct\""
  }
}
```

**Requires:** `jq` (`brew install jq` / `apt install jq`)

Restart Claude Code after saving.

---

## Contributing

Open a PR with your own snippets — keep entries self-contained and free of personal paths or credentials.
