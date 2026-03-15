# GitHub Copilot Repository Instructions for Popochiu

Popochiu is a Godot addon for building classic point-and-click adventure games. It is organized into two main components:

## Architecture Overview

- **Editor Plugin (`addons/popochiu/editor/`)**: Extends the Godot Editor with tools for managing game assets, custom inspector views, asset importers, migration logic, and UI popups. All editor-side scripts/classes must be named with the `Popochiu` prefix and use tabs for indentation.
- **Game Engine (`addons/popochiu/engine/`)**: Contains runtime logic, base classes for game entities, audio/cursor managers, and high-level APIs. All engine scripts/classes must also use the `Popochiu` prefix and tabs for indentation.

Scripts in `game/` are for actual game logic and may access engine singletons directly (e.g., `E`, `C`, `D`). Scripts in `editor/` and `engine/` must use `PopochiuUtils` for singleton access, mapping each singleton to a lowercase variable (e.g., `PopochiuUtils.r.get_prop("PropName")`).

## Developer Workflows

- **Building/Exporting**: Use the Godot Editor's export functionality. The file `addons/popochiu/popochiu_export_plugin.gd` customizes export behavior.
- **Testing**: Manual testing via the Godot Editor is typical. Debug using Godot's built-in debugger. No standard test framework is present.
- **Migration**: Version migrations are handled in `addons/popochiu/editor/migration/`. Update logic here when introducing changes to Popochiu objects that require an update in the `game` folder.
- **Asset Importing**: Use importers in `addons/popochiu/editor/importers/` for assets like Aseprite animations.

## Key Conventions for AI Agents

- **Class Naming**: All classes in `editor/` and `engine/` must start with `Popochiu`.
- **Indentation**: Use tabs, not spaces.
- **File Naming**: Use `snake_case` matching the class name.
- **Commenting**:
  - In `engine/`: Use `##` for documentation comments on public/virtual methods, classes, constants, enums, signals, and exported variables. Use `#` for internal/private comments.
  - In `editor/`: Use `#` for all comments, never `##`.
  - Comments should explain *why* code is written a certain way, not just what it does. Place comments above the referenced code.
  - Reference issues in comments using `#<issue_number>~` when relevant.
- **Singleton Access**: Only game scripts access engine singletons directly. Editor/engine scripts must use `PopochiuUtils`.
- **Functions/Variables**: Use explicit, relevant names. Avoid cryptic or generic names.

## Directory Structure

- Place code in the correct directory: `addons/popochiu/editor/` for editor tools, `addons/popochiu/engine/` for engine logic, and `game/` for game scripts.
- Documentation lives in `docs/src/` and assets in `docs/src/assets/`.

## Versioning & PRs

- Branch naming: `feature/<issue_number>-name`, `fix/<issue_number>-name`, `docs/<issue_number>-name`.
- Commit messages: `refs #<issue_number>: Clear message explaining why.`
- PR titles should follow commit message format. Large PRs should include a summary.

## Documentation Contributions

- Use [MkDocs](https://www.mkdocs.org/) and Markdown. Preview changes locally using the provided Docker environment.
- Documentation must be in clear English, with an informal but accessible tone.
- Use the Diátaxis framework: Tutorials, How-to Guides, Explanations, Reference.
- Update documentation for new features, public interface changes, or GUI updates.
- Update screenshots/visuals as needed, using Godot dark theme and red annotations for clarity.

## Integration Points

- Asset importers may depend on external formats (e.g., Aseprite). No other major external dependencies are present.
- Use interfaces in `addons/popochiu/engine/interfaces/` for high-level API access.
- Avoid introducing third-party Godot addons. All features should be implemented internally.

## Example Patterns

- **Accessing a prop in game scripts**:
  ```gdscript
  R.get_prop("PropName")
  ```
- **Accessing a prop in engine/editor scripts**:
  ```gdscript
  PopochiuUtils.r.get_prop("PropName")
  ```

## Definition of Done

- Address all edge cases, follow naming and project standards, test locally, update documentation, include migrations, remove temporary code, and add meaningful comments.

## Useful Links
- [Popochiu Documentation](https://github.com/carenalgas/popochiu/tree/main/docs)
- [Godot GDScript Style Guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)
- [Diátaxis Documentation Framework](https://diataxis.fr/)
