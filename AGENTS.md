# AGENTS.md

## Lua / WoW addon rules
- After changing any `.lua` file, run `luac -p` on every modified Lua file before returning the final diff.
- Target Lua 5.1 syntax compatibility for WoW 3.3.5 addons.
- If a syntax check fails, report the exact file and line.
- Keep diffs minimal.
- Always return formatted diffs with real line breaks and file paths.