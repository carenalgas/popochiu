# AGENTS.md

Instructions for AI coding agents working in the Popochiu repository. This file is the single source of truth across harnesses (GitHub Copilot, Cursor, Claude Code, OpenAI Codex, OpenCode).

## Communication style

- When writing anything for human consumption (comments, commit messages, replies, reviews), use as few words as possible. Pick every word meticulously. Less is more.
- Be direct but respectful. No superlatives, no praise, no flattery. Give the cold hard truth.
- Explain *what* the code does and *why*, never just *how*. The code itself reveals the how.

## Planning

- During planning phases, use the agent's question tool (`ask_questions` / `question`) to clarify requirements and confirm decisions before implementing. Ask one question at a time.

## Architecture overview

Popochiu is a Godot addon for building classic point-and-click adventure games. It has two components plus game scripts:

- **Editor Plugin** (`addons/popochiu/editor/`): extends the Godot Editor with tools for managing game assets, custom inspector views, asset importers, migration logic, and UI popups.
- **Game Engine** (`addons/popochiu/engine/`): runtime logic, base classes for game entities, audio/cursor managers, and high-level APIs.
- **Game scripts** (`game/`): auto-created functional game project, not versioned (gitignored).

Engine and editor classes must use the `Popochiu` prefix and tabs for indentation.

**Singleton access**: Only scripts in `game/` may access engine singletons directly (`E`, `C`, `D`, etc.). Scripts in `editor/` and `engine/` must use `PopochiuUtils`, mapping each singleton to a lowercase variable (e.g. `PopochiuUtils.r.get_prop("PropName")`).

## GDScript standards

Popochiu adheres to the [official GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html), with these repository-specific additions:

- Use **tabs**, not spaces.
- Keep lines within **100 columns**.
- Classes must start with `Popochiu` (compensates for GDScript's lack of namespacing).
- Name scripts with `snake_case` matching the class they contain (e.g. `cursor.gd` holds `PopochiuCursor`).
- Function and variable names must be explicit and relevant. Avoid cryptic abbreviations (`mh`, `htm`) and vague names (`doStuff`).
- Type every variable, either explicitly (`var room: PopochiuRoom`) or via inference (`var room := get_tree()`).
- Declare an explicit return type on every function (`-> void`, `-> Dictionary`, etc.).
- Group functions using `#region` taxonomy when the file uses regions: `Godot`, `Public`, `Virtual`, `Protected`, `Signals`/`Signals handlers`, `Private`.

## Comments and documentation

- Comments explain *why*, not *what*. Place them above the referenced code, starting with a capital letter and ending with a period.
- Reference issues in comments using `#<issue_number>~` when relevant, e.g. `# Fixes #322 (Hidden characters are still visible...).`
- In `engine/`: use `##` (GDScript doc-comment, BBCode) for **public/virtual** members — classes, methods, signals, constants, enums, exported variables. Use `#` for private/internal comments.
- In `editor/`: use `#` for all comments, never `##`.
- Documentation-export annotations (`# @popochiu-docs-*`) use single-hash comments placed immediately before the docblock they control. See `docs/README.md`.
- Admonitions: `TODO:` (out-of-scope work), `FIXME:` (known issues; only in draft PRs), `IMPROVE:` (possible wins out of scope), `NOTE:` (important context for future readers).

## Code design principles

- Avoid magic numbers and strings. Extract recurring or meaningful values into descriptive `const` or `enum`. Keep self-explanatory one-off values inline to avoid clutter. If a value comes from a spec (e.g. an HTTP status), use a constant regardless.
- Reduce indentation. Leverage early `return` and `continue`. Avoid deeply nested branches.
- Add empty lines between logical blocks so the reader can breathe.
- Encapsulate low-level mechanics behind clean, high-level APIs. Calling code should work with domain concepts, not raw implementation details.
- Program to levels of abstraction; each layer communicates only with its immediate neighbor. Do not punch holes through layers.
- Treat visibility changes as a breaking design shift. Keep members private unless external access is strictly required by the design. **Prompt the user for explicit approval before changing any access modifier from private to internal or public.**
- Don't touch blocks of code unrelated to the feature you implement. Minimize the number of changed lines.
- Never introduce third-party Godot addons. All features must be implemented internally.

## Migration awareness

When modifying Popochiu objects or their properties, check whether version migration logic in `addons/popochiu/editor/migration/` needs updating. Introductions of changes to Popochiu objects that require updates in the `game` folder must be accompanied by the corresponding migration.

## Git workflow

- Branch naming (maintainers): `feature/<issue_number>-name`, `fix/<issue_number>-name`, `docs/<issue_number>-name`. The integration branch is `develop`; releases on `main` tagged `vX.Y.Z`.
- Commit message format: `refs #<issue_number>: Clear message explaining why - not what.` Start with a capital letter, end with a full stop.
- PR titles follow the same format as commit messages.
- Prefer rebase over merging `develop` back. Never force-push.

## Definition of done

Address all edge cases, follow the naming and project standards, test locally, update documentation, include migrations, remove temporary/debug code, and add meaningful comments.
