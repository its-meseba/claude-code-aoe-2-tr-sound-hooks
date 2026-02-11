# Age of Empires II - Turkish Villager

Turn your Claude Code terminal into an AoE2 Turkish villager colony. Every action triggers an iconic sound -- session starts with "Selam!", prompts get "Emrin!", and completed tasks finish with "Yaparim!".

## Sounds

| Sound | Meaning | Hook Events |
|-------|---------|-------------|
| `selam.mp3` | "Hello" | SessionStart |
| `emrin.mp3` | "At your command" | SessionStart, UserPromptSubmit |
| `evet.mp3` | "Yes" | UserPromptSubmit, Notification, SubagentStart |
| `oduncu.mp3` | "Lumberjack" | Notification, SubagentStart |
| `yaparim.mp3` | "I'll do it" | Stop, SubagentStop |
| `daha_iyice.mp3` | "Even better" | Stop, SubagentStop |

Each hook randomly picks between two sounds, so it doesn't get repetitive.

## Hook Mapping

```
SessionStart      -> selam / emrin        (greeting)
UserPromptSubmit  -> emrin / evet         (acknowledging your command)
Notification      -> oduncu / evet        (task assignment)
Stop              -> yaparim / daha_iyice (task complete)
SubagentStart     -> evet / oduncu        (sub-agent dispatched)
SubagentStop      -> daha_iyice / yaparim (sub-agent finished)
```

## Install

From the repository root:

```bash
./install.sh aoe2-turkish-villager
```

## Uninstall

```bash
./uninstall.sh aoe2-turkish-villager
```

## Audio Disclaimer

**The audio files included are not original works of the author.** They are sourced from publicly available channels and are based on sound effects from the *Age of Empires II* video game series.

*Age of Empires* and *Age of Empires II* are registered trademarks of **Xbox Game Studios** and **Microsoft Corporation**. All audio assets, sound effects, and related intellectual property belong to their respective owners.

This is a fan-made, non-commercial hobby tool. It is not affiliated with, endorsed by, or sponsored by Microsoft Corporation, Xbox Game Studios, or any of their subsidiaries. The sounds are used here for personal entertainment and educational purposes only.

If you are a rights holder and would like any content removed, please open an issue.
