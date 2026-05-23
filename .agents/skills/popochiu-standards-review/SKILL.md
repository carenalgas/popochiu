---
name: popochiu-standards-review
description: Review whether a branch respects Popochiu coding standards. Use this skill whenever the user asks to review standards in a branch, audit a PR for coding conventions, check changed GDScript files for compliance, or prepare a standards-only review report.
---

# Popochiu Standards Review

Review the GDScript files changed by the current branch against Popochiu and Godot coding standards.
This workflow is review-only: inspect, explain, and suggest fixes, but do not edit any file.

## Context

- Scope the review to files changed by the current branch compared with the PR base.
- Only inspect `.gd` files.
- Default PR base is `develop`, because Popochiu PRs target `develop`.
- Prefer repository-specific rules when they are stricter than the upstream Godot style guide.

Primary references:

- `docs/src/contributing-to-popochiu/conventions/coding-standards.md`
- `docs/src/contributing-to-popochiu/conventions/naming-conventions.md`
- `docs/src/contributing-to-popochiu/conventions/comments.md`
- `docs/README.md` (`Controlling API documentation export`)
- Godot GDScript style guide:
  `https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html`

---

## Workflow

### Step 1 - Determine the review base with git

Interpret "the last PR" as the current branch diff against its PR target branch.

Use git only.

1. Get the current branch name.
2. Try to diff against `origin/develop`.
3. If `origin/develop` does not exist locally, try `develop`.
4. If neither branch exists, ask the user which base branch to compare against.

Recommended commands:

```bash
git branch --show-current
git rev-parse --verify origin/develop
git merge-base HEAD origin/develop
git diff --name-only --diff-filter=ACMR "$(git merge-base HEAD origin/develop)"...HEAD -- '*.gd'
```

Fallback when `origin/develop` is unavailable:

```bash
git rev-parse --verify develop
git diff --name-only --diff-filter=ACMR "$(git merge-base HEAD develop)"...HEAD -- '*.gd'
```

Notes:

- `--diff-filter=ACMR` keeps added, copied, modified, and renamed files.
- If no `.gd` files changed, report that explicitly and stop.
- Do not review deleted files.

---

### Step 2 - Read the changed scripts

Open every changed `.gd` file and review the actual file contents, not just the diff.
Use the diff only to confirm which files are in scope.

While reading, pay attention to the file's role:

- `addons/popochiu/editor/`: editor-side plugin code.
- `addons/popochiu/engine/`: runtime engine code.
- `addons/popochiu/migration/`: migration logic.
- `game/`: game-side scripts.

This matters because some standards apply only to engine files, especially exported API documentation rules.

---

### Step 3 - Check every file against the required standards

For each changed script, check all of the following.

#### 1. Godot and Popochiu style guide compliance

Check for violations of the official GDScript style guide and Popochiu repository rules, including but not limited to:

- Tabs, indentation, spacing, and blank-line consistency.
- Constant, enum, signal, class, variable, and function layout.
- File naming and class naming consistency.
- Comment formatting where present.
- In `addons/popochiu/editor/`, comments should use `#`, not `##`.
- Region usage that matches the file's existing structure.

Do not nitpick purely stylistic alternatives unless they clearly contradict the style guide or the repository's established conventions.

#### 2. Variable typing

Every variable declaration must be either:

- explicitly typed, for example `var room: PopochiuRoom`, or
- dynamically typed through inference with `:=`, for example `var room := get_tree()`.

Flag declarations such as `var room = get_tree()` unless the codebase forces a special case that cannot reasonably use either an explicit type or `:=`.

Apply this check to:

- local variables
- member variables
- `const` declarations when type clarity is relevant

If a declaration is intentionally `Variant`, that is acceptable when it is explicit and makes sense for the API or data being stored.

#### 3. Function return typing

Every function should declare an explicit return type.

Examples of acceptable signatures:

- `func _ready() -> void:`
- `func get_data() -> Dictionary:`
- `func find_node_by_name(name: String) -> Variant:`

Flag functions without a return annotation, including private helpers, unless there is a very strong language-driven reason not to annotate them.

If the function may return heterogeneous values or an API-friendly generic value, suggest `Variant` where appropriate instead of leaving the return type implicit.

#### 4. Function region placement

Verify that functions are grouped in the correct region for the file's structure.

Use the repository's existing region taxonomy when present, commonly:

- `#region Godot`
- `#region Public`
- `#region Virtual`
- `#region Protected`
- `#region Signals` or `#region Signals handlers`
- `#region Private`

Use these heuristics:

- Built-in Godot lifecycle hooks belong in `Godot`.
  Examples: `_init`, `_ready`, `_enter_tree`, `_exit_tree`, `_process`, `_physics_process`, `_input`, `_unhandled_input`, `_notification`.
- Public API methods without a leading underscore belong in `Public`.
- Popochiu extension points and intended overrides belong in `Virtual`.
  Examples include methods such as `_on_click`, `_on_use`, `_on_item_used`, room and object hooks, template hooks, and other framework-defined overridables.
- Protected methods belong in `Protected` when that region exists in the file.
- Signal callbacks belong in `Signals` or `Signals handlers` when the file uses that dedicated region; otherwise they usually belong in `Private`.
- Internal helpers with a leading underscore belong in `Private` unless the file already uses a more specific region.

When the file does not use explicit regions, do not demand a full refactor just to add them.
Report only clear ordering or grouping issues that conflict with existing repository patterns or with the user's requested standard.

#### 5. Engine public API documentation and export annotations

This check applies only to files under `addons/popochiu/engine/`.

Review public class members, including public methods, signals, constants, enums, and exported or public variables.

Expectations:

- Public and virtual engine API members should have `##` documentation comments.
- Private implementation comments should use `#`, not `##`.
- Documentation-export annotations must use single-hash comments placed immediately before the docblock they control.

Supported annotations:
- `# @popochiu-docs-ignore-class`
- `# @popochiu-docs-ignore`
- `# @popochiu-docs-include`
- `# @popochiu-docs-category <slug>`

Flag cases such as:

- missing `##` docblocks on public engine API members
- `##` docblocks used on clearly private members without a valid reason
- annotations placed in the wrong position
- annotations with no docblock below them
- public members that look like internal implementation details but are not excluded from export when they should be

Be careful here: not every public member requires an annotation.
The default is exportable unless there is a reason to include or exclude it explicitly.

#### 6. Line length

Flag lines longer than 100 characters.

Prefer actionable suggestions such as:

- split chained calls across lines
- extract intermediate variables
- reflow long conditions or array literals
- wrap doc comments cleanly

#### 7. Naming conventions

Check naming against both Godot conventions and Popochiu-specific conventions.

At minimum verify:

- engine and editor classes start with `Popochiu`
- script names follow Godot `snake_case` and reasonably match the class they contain
- function and variable names are explicit and relevant
- public API names read naturally from call sites
- avoid cryptic abbreviations and vague names like `doStuff`, `tmp`, `handler2`, `mh`

Do not invent naming rules that are not documented.
Focus on explicitness, relevance, and the Popochiu prefix requirement where applicable.

---

### Step 4 - Build a review report, not a patch

Produce a findings-first report. Do not modify files. Do not propose automatic edits. Do not present a diff.

For each issue include:

- file path
- line number or the narrowest location you can identify
- violated rule
- why it is a problem
- a concrete suggestion for how to fix it

Group findings by severity:

- `Must fix`: clear standards violations
- `Should fix`: strong convention violations or maintainability problems
- `Needs confirmation`: cases where the correct fix depends on intent

If a file is clean, say so briefly.

If the whole review is clean, state that explicitly and mention any residual uncertainty, such as heuristic region classification.

---

## Output Format

Use this structure:

```markdown
# Standards Review Report

Base branch: develop
Changed GDScript files reviewed: N

## Must fix

- `path/to/file.gd:123` - Missing return type on `func ...`.
  Suggestion: declare `-> void` or a concrete type such as `Dictionary` or `Variant`.

## Should fix

- `path/to/file.gd:45` - Variable uses `=` without a type annotation or `:=`.
  Suggestion: change it to `var example := ...` or add an explicit type.

## Needs confirmation

- `path/to/file.gd:88` - `_on_something()` is in `Private`, but it may be intended as a Popochiu virtual and belong in `Virtual`.
  Suggestion: confirm whether this overrides a framework hook; if it does, move it to the `Virtual` region.

## Notes

- No code was changed.
- Suggestions are intentionally review-only until the user asks to apply them.
```

Do not list clean files, but do report if no issues were found across the whole review.

Keep the report concise but specific. Prefer fewer, higher-signal findings over a flood of trivial comments.

---

## Guardrails

- Never edit code as part of this skill.
- Never stage, commit, or rewrite history.
- Never treat uncertain style preferences as hard failures.
- Prefer repository conventions over personal taste.
- If the base branch cannot be determined with git alone, ask the user instead of guessing.
- If the user later asks to apply the suggestions, switch out of this skill and make the code changes in a separate implementation step.
