# claude-cli-improvements

Small quality-of-life improvements for [Claude Code](https://claude.ai/code) — config snippets and scripts that make the TUI more useful day-to-day.

---

## 1. Usage stats in the status bar

Adds a live token counter to the bottom status bar so you can see context usage without opening `/usage`.

**Output:** `sess:29% in:2k out:1k week:35%`

- `sess` — % of your 5-hour rolling rate limit consumed (matches "current session usage" in `/usage`)
- `in` / `out` — cumulative input/output tokens (in thousands)
- `week` — % of your 7-day usage limit consumed

The bar is blank until you send the first message (data isn't available before that).

### Setup

Add the `statusLine` key to your `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "input=$(cat); spct=$(echo \"$input\" | jq -r '.rate_limits.five_hour.used_percentage // empty'); [ -z \"$spct\" ] && exit 0; tin=$(echo \"$input\" | jq -r '.context_window.total_input_tokens // 0'); tout=$(echo \"$input\" | jq -r '.context_window.total_output_tokens // 0'); wpct=$(echo \"$input\" | jq -r '.rate_limits.seven_day.used_percentage // empty'); printf 'sess:%.0f%% in:%dk out:%dk' \"$spct\" \"$((tin/1000))\" \"$((tout/1000))\"; [ -n \"$wpct\" ] && printf ' week:%.0f%%' \"$wpct\""
  }
}
```

**Requires:** `jq` (`brew install jq` / `apt install jq`)

Restart Claude Code after saving.

---

## Contributing

Open a PR with your own snippets — keep entries self-contained and free of personal paths or credentials.
