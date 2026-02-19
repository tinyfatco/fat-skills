# fat-skills

Platform skills for TinyFat agents. Cloned into container images at build time and loaded via crawdad's `--skills` flag.

## Skills

| Skill | Description |
|-------|-------------|
| `browser-tools` | Headless Chrome automation — navigate, screenshot, evaluate JS, extract content |

## Usage

Skills are loaded by crawdad at startup:

```bash
crawdad --skills /opt/fat-skills --port 3002 /data
```

Crawdad's skill loader discovers `SKILL.md` files and injects their descriptions into the agent's system prompt. The agent decides when to use them based on natural language context.

## Priority

Skills from `--skills` load at the lowest priority. User-defined skills in the workspace or channel override platform skills on name collision.
