# Third-party skills (vetted before install)

Cloned with `--depth 1`, read, and scanned for hooks, network calls, obfuscation and install scripts. No hooks, settings or MCP configs were copied. Nothing from these repos was executed during vetting.

| Source (commit) | License | Installed | Not installed (why) |
|---|---|---|---|
| [VGonPa/mobile-dev-agency](https://github.com/VGonPa/mobile-dev-agency) `7f4937b` | MIT (plugin.json) | mobile-design-discovery, mobile-ux-patterns, mobile-visual-design, flutter-ui-craft, mobile-design-review, implementing-riverpod, integrating-flutter-backend, securing-flutter-apps, testing-flutter, optimizing-flutter-performance | agents (broad tool access), `quality-checks.sh` (1,800-line shell script), deploy/architecture/animation/widgets/standards skills (later or overlap) |
| [dhruvanbhalara/skills](https://github.com/dhruvanbhalara/skills) `a74a6fb` | LICENSE file | 11 Flutter skills, renamed with `dh-` prefix (ui, responsive layout, layout fixes, localization, routing, widget/integration/testing, security, json serialization, dio) | BLoC, Isar, GitHub/git skills (not our stack / conflict with commit rules), Node build scripts |
| [nextlevelbuilder/ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) `9a3f14f` | MIT | `ui-ux-pro-max` only (local CSV search, stdlib-only Python, no network; writes files only with `--persist`). `${CLAUDE_PLUGIN_ROOT}` paths edited to project-relative | design, brand, slides, banner-design, ui-styling, design-system (web/marketing, image-generation APIs, shadcn installs, subprocess calls), CLI, gallery, stack/ settings that pre-allow Bash/MCP |
| [cleydson/flutter-claude-code](https://github.com/cleydson/flutter-claude-code) `4319e00` | **none found** | nothing | No license file, so reuse rights are unclear. Its agents also inherit all tools. |

Rules: re-vet before updating any of these; never auto-update; scripts only run after reading them.
