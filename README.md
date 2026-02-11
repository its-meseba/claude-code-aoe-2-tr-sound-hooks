# Awesome Claude Code Sounds

A community-driven collection of sound packs for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) hooks. Turn your coding sessions into an immersive audio experience.

## What is this?

Claude Code supports [lifecycle hooks](https://docs.anthropic.com/en/docs/claude-code/hooks) that run shell commands at key moments: session start, prompt submit, task completion, and more. This repo provides **themed sound packs** that play audio clips on these events, plus a **universal installer** that handles cross-platform playback and safe `settings.json` merging.

## Available Packs

| Pack | Description | Sounds | Hooks | Author |
|------|-------------|--------|-------|--------|
| [aoe2-turkish-villager](packs/aoe2-turkish-villager/) | Turkish villager voice lines from Age of Empires II | 6 | 6 | [@mehmetsemihbabacan](https://github.com/mehmetsemihbabacan) |

> Want to add yours? See [CONTRIBUTING.md](CONTRIBUTING.md).

## Quick Install

```bash
git clone https://github.com/user/awesome-claude-code-sounds.git
cd awesome-claude-code-sounds
./install.sh aoe2-turkish-villager
```

Restart Claude Code to activate.

## Quick Uninstall

```bash
./uninstall.sh aoe2-turkish-villager
```

## List Packs

```bash
./list.sh
```

## How It Works

1. **Sound files** are copied to `~/.claude/hooks/sounds/<pack-id>/` (namespaced per pack, no collisions)
2. **Hook entries** are merged into `~/.claude/settings.json` without touching your existing config
3. Each hook randomly picks between assigned sounds so it doesn't get repetitive
4. Sounds play in the background (`&`) so they never block Claude Code

## Platform Support

| Platform | Audio Player | Status |
|----------|-------------|--------|
| macOS | `afplay` | Fully supported |
| Linux | `paplay` / `aplay` / `mpg123` | Fully supported |
| WSL | `paplay` via PulseAudio | Experimental |

The installer auto-detects your platform and available audio player.

## Create Your Own Pack

```bash
# 1. Copy the template
cp -r template/ packs/my-pack-name/

# 2. Add your sounds to packs/my-pack-name/sounds/

# 3. Edit packs/my-pack-name/pack.json

# 4. Test it
./install.sh --dry-run my-pack-name
./install.sh my-pack-name

# 5. Open a PR!
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full guide including the pack.json schema, all 14 hook events, sound requirements, and the PR checklist.

## Supported Hook Events

| Event | When it fires |
|-------|---------------|
| `SessionStart` | Session begins |
| `SessionEnd` | Session terminates |
| `UserPromptSubmit` | User sends a prompt |
| `Stop` | Claude finishes responding |
| `Notification` | Claude needs attention |
| `SubagentStart` | Subagent spawns |
| `SubagentStop` | Subagent finishes |
| `TaskCompleted` | Task marked complete |
| `PreToolUse` | Before a tool runs |
| `PostToolUse` | After a tool succeeds |
| `PostToolUseFailure` | After a tool fails |
| `PermissionRequest` | Permission dialog shown |
| `TeammateIdle` | Teammate going idle |
| `PreCompact` | Before context compaction |

## Requirements

- macOS or Linux (or WSL)
- Python 3 (for JSON merge during install)
- Claude Code CLI

## License

MIT for the tooling. Individual sound packs may have their own licensing terms -- check each pack's README.
