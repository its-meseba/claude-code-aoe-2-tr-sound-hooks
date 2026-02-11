# Contributing a Sound Pack

Thank you for wanting to share your sound pack with the community!

## Quick Start

1. Fork this repository
2. Copy `template/` to `packs/<your-pack-id>/`
3. Add your sound files to `packs/<your-pack-id>/sounds/`
4. Fill out `packs/<your-pack-id>/pack.json`
5. Write a `packs/<your-pack-id>/README.md`
6. Test with `./install.sh <your-pack-id>`
7. Open a pull request

## Pack ID Rules

- Lowercase letters, numbers, and hyphens only
- Must start and end with a letter or number
- Minimum 2 characters
- Must match your directory name under `packs/`
- Should be descriptive: `star-wars-droid-beeps`, not `my-sounds`

## Sound File Requirements

- **Formats:** MP3 (preferred), WAV, OGG
- **Max size:** 500KB per file (keeps the repo fast to clone)
- **Max files:** 20 per pack
- **Duration:** 0.5 to 3 seconds ideal
- **Quality:** No silence padding at start/end, reasonable volume levels

## The pack.json Manifest

Every pack needs a `pack.json` at its root. Here's the full schema:

```json
{
  "id": "your-pack-id",
  "name": "Human-Readable Name",
  "version": "1.0.0",
  "description": "One-line description for the gallery",
  "author": "github-username",
  "license": "MIT",
  "tags": ["optional", "searchable", "tags"],

  "sounds": {
    "sound_key": {
      "file": "sounds/filename.mp3",
      "label": "Human-readable description"
    }
  },

  "hooks": {
    "EventName": {
      "sounds": ["sound_key", "another_key"],
      "matcher": ""
    }
  }
}
```

### Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Unique pack identifier. Must match directory name. |
| `name` | string | Display name for the gallery. |
| `version` | string | Semver version (e.g. `1.0.0`). |
| `description` | string | One-line description. |
| `author` | string | Your GitHub username or name. |
| `license` | string | SPDX license identifier (e.g. `MIT`, `CC-BY-4.0`). |
| `sounds` | object | Map of sound keys to `{ file, label }`. |
| `hooks` | object | Map of hook events to `{ sounds, matcher? }`. |

### Optional Fields

| Field | Type | Description |
|-------|------|-------------|
| `tags` | string[] | Searchable tags for discovery. |
| `hooks.<event>.matcher` | string | Regex matcher for tool-specific hooks. |

### Validation Rules

- Every sound key referenced in `hooks` must exist in `sounds`
- Every `file` in `sounds` must point to an actual file on disk
- Hook event names must be valid (see table below)

## Hook Event Reference

All 14 Claude Code hook events. You don't need to cover all of them -- map sounds to events that make thematic sense for your pack.

| Event | When it fires | Good sounds for |
|-------|---------------|-----------------|
| `SessionStart` | Session begins | Greeting, startup chime |
| `SessionEnd` | Session terminates | Goodbye, shutdown |
| `UserPromptSubmit` | User sends a prompt | Acknowledgment, "ready" |
| `Stop` | Claude finishes responding | Completion, done chime |
| `Notification` | Claude needs attention | Bell, alert |
| `SubagentStart` | Subagent spawns | Deployment, launch |
| `SubagentStop` | Subagent finishes | Return, arrival |
| `TaskCompleted` | Task marked complete | Victory, celebration |
| `PreToolUse` | Before a tool runs | Click, activation |
| `PostToolUse` | After a tool succeeds | Subtle confirmation |
| `PostToolUseFailure` | After a tool fails | Error buzz, sad trombone |
| `PermissionRequest` | Permission dialog shown | Alert, question |
| `TeammateIdle` | Teammate going idle | Yawn, waiting |
| `PreCompact` | Before context compaction | Rarely useful for sounds |

### Matcher Field

For `PreToolUse`, `PostToolUse`, `PostToolUseFailure`, and `PermissionRequest`, you can use the `matcher` field to target specific tools:

```json
{
  "hooks": {
    "PreToolUse": {
      "sounds": ["typing"],
      "matcher": "Edit|Write"
    }
  }
}
```

This plays the sound only when the Edit or Write tools are used.

## Testing Your Pack

```bash
# Validate without installing
./install.sh --dry-run your-pack-id

# Install and test
./install.sh your-pack-id

# Verify it shows up
./list.sh

# Open Claude Code, trigger events, hear sounds

# Clean removal
./uninstall.sh your-pack-id
```

## Legal Requirements

- **Your own recordings:** Any license works.
- **Game/movie sounds:** Include a clear disclaimer in your pack's README naming the original rights holders. Mark it as non-commercial/fan-made.
- **Creative Commons audio:** Include proper attribution as required by the license.
- **Do NOT include:** Copyrighted music tracks, sounds ripped from proprietary software without fair-use justification.

When in doubt, use [freesound.org](https://freesound.org), [BBC Sound Effects](https://sound-effects.bbcrewind.co.uk/), or record your own.

## Pull Request Checklist

- [ ] Pack directory name matches `id` in pack.json
- [ ] All sound files referenced in pack.json exist in `sounds/`
- [ ] All hook event names use correct casing (e.g. `SessionStart`, not `sessionStart`)
- [ ] Each sound file is under 500KB
- [ ] pack.json is valid JSON (no trailing commas)
- [ ] README.md exists with sound descriptions
- [ ] README.md includes attribution/disclaimer for non-original audio
- [ ] `./install.sh --dry-run <pack-id>` passes validation
- [ ] `./install.sh <pack-id>` installs correctly
- [ ] `./uninstall.sh <pack-id>` removes cleanly (no leftover hooks or files)
