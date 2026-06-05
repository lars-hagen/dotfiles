---
name: toolkit
description: "Index: bun (runtime, bundler, dev server, HMR, plugins, Bun.serve, HTML entrypoints, Tauri+Bun, WebSocket quirks, replacing Vite), zig (Zig 0.16 build.zig, std.process.Init main, ArrayList unmanaged, std.Io clocks/sleep/entropy, cross-compile to Windows/Linux/macOS, install-local), playwright-cli (browser automation, page snapshots/refs, click/type/fill, network mocking, storage state, tracing, video, spec-driven test generation), facebook-messenger (manage your own Facebook Messenger via playwright-cli attached to logged-in Chrome: list/read threads, send/reply, search, mark read, archive, mute), tavily (web search, URL content extraction, site crawl, and URL mapping via the Tavily REST API using raw curl + jq; LLM-optimized results, AI answers, clean markdown). On-demand skill loader: Read only the skill file you need."
---

# Toolkit

On-demand skill loader. Read only the skill you need.

| Skill          | File                                                        |
| -------------- | ----------------------------------------------------------- |
| bun            | /Users/lars/.config/opencode/skills/bun/SKILL.md            |
| zig            | /Users/lars/.config/opencode/skills/zig/SKILL.md            |
| playwright-cli | /Users/lars/.config/opencode/skills/playwright-cli/SKILL.md |
| facebook-messenger | /Users/lars/.config/opencode/skills/facebook-messenger/SKILL.md |
| tavily         | /Users/lars/.config/opencode/skills/tavily/SKILL.md         |

When told to use a skill, Read the file above and follow its instructions.
Supporting files (references/, scripts/) are in the same directory as the skill file.
`<SKILL_DIR>` in each skill resolves to the directory containing that skill's SKILL.md file.
If a loaded skill references another skill listed here, Read it from this table.
