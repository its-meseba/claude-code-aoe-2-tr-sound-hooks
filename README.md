# Claude Code × Age of Empires II Sound Hooks

Turn your Claude Code terminal into an AoE2 Turkish villager colony. Every action triggers an iconic sound — session starts with "Selam!", prompts get "Emrin!", and completed tasks finish with "Yaparım!".

## Sound Files

| File | Meaning | Used In |
|------|---------|---------|
| `aoe_selam.mp3` | "Hello" | SessionStart |
| `aoe_emrin.mp3` | "At your command" | SessionStart, UserPromptSubmit |
| `aoe_evet.mp3` | "Yes" | UserPromptSubmit, Notification, SubagentStart |
| `aoe_oduncu.mp3` | "Lumberjack" | Notification, SubagentStart |
| `aoe_yaparim.mp3` | "I'll do it" | Stop, SubagentStop |
| `aoe_daha_iyice.mp3` | "Even better" | Stop, SubagentStop |

Each hook randomly picks between two sounds, so it doesn't get repetitive.

## Hook Mapping

```
SessionStart      → selam / emrin       (greeting)
UserPromptSubmit  → emrin / evet        (acknowledging your command)
Notification      → oduncu / evet       (task assignment)
Stop              → yaparım / daha iyice (task complete)
SubagentStart     → evet / oduncu       (sub-agent dispatched)
SubagentStop      → daha iyice / yaparım (sub-agent finished)
```

## Install

```bash
cd claude-hooks-setup
bash install.sh
```

The installer:
- Copies all 6 `.mp3` files to `~/.claude/hooks/`
- Merges hooks into your existing `~/.claude/settings.json` (won't overwrite other settings)
- Cleans up any invalid keys from previous installs

## Troubleshooting

If Claude Code shows a "Settings Error" about invalid keys, run:

```bash
python3 fix-settings.py
```

This removes `SubAgentStart`/`SubAgentStop` (wrong casing) — the valid names are `SubagentStart`/`SubagentStop`.

## Requirements

- macOS (uses `afplay` for audio playback)
- Claude Code CLI
- Python 3 (for JSON merge during install)

## Trademark & Audio Disclaimer

**The audio files included in this repository are not original works of the author.** They are sourced from publicly available channels and are based on sound effects from the *Age of Empires II* video game series.

*Age of Empires* and *Age of Empires II* are registered trademarks of **Xbox Game Studios** and **Microsoft Corporation**. All audio assets, sound effects, and related intellectual property belong to their respective owners.

This project is a fan-made, non-commercial hobby tool. It is not affiliated with, endorsed by, or sponsored by Microsoft Corporation, Xbox Game Studios, or any of their subsidiaries. The sounds are used here for personal entertainment and educational purposes only.

If you are a rights holder and would like any content removed, please open an issue.

## License

MIT — do whatever you want with the code. Audio files are subject to their original owners' terms.
