# GitHub Copilot Repository Instructions for Popochiu

Popochiu is a Godot addon for building classic point-and-click adventure games. It is organized into two main components:

## Architecture Overview

- **Editor Plugin (`addons/popochiu/editor/`)**: Extends the Godot Editor with tools for managing game assets (characters, rooms, inventory, audio, etc.), custom inspector views, asset importers, migration logic, and UI popups. All editor-side scripts/classes must be named with the `Popochiu` prefix and use tabs for indentation.
- **Game Engine (`addons/popochiu/engine/`)**: Contains runtime logic, base classes for game entities, audio/cursor managers, and high-level APIs. All engine scripts/classes must also use the `Popochiu` prefix and tabs for indentation.

Scripts in `game/` are for actual game logic and may access engine singletons directly (e.g., `E`, `C`, `D`). Scripts in `editor/` and `engine/` must use `PopochiuUtils` for singleton access, mapping each singleton to a lowercase variable (e.g., `PopochiuUtils.r.get_prop("PropName")`).

## Developer Workflows

- **Building/Exporting**: Use the Godot Editor's export functionality. The file `addons/popochiu/popochiu_export_plugin.gd` customizes export behavior.
- **Testing**: No standard test framework is present; manual testing via the Godot Editor is typical. Debug using Godot's built-in debugger whenever possible (not available during Editor Plugin development).
- **Migration**: Version migrations are handled in `addons/popochiu/editor/migration/`. Update logic here when introducing changes to Popochiu objects that require an update in the `game` folder to work properly.
- **Graphical Assets Importing**: Use importers in `addons/popochiu/editor/importers/` for assets like Aseprite animations.

## Project-Specific Conventions

- **Class Naming**: All classes in `editor/` and `engine/` must start with `Popochiu`.
- **Indentation**: Always use tabs, never use spaces.
- **File Naming**: Use `snake_case` matching the class name.
- **Commenting**:
  - In `engine/`: Use `##` for documentation comments on public/virtual methods, classes, constants, enums, signals, and exported variables. Use `#` for internal/private comments.
  - In `editor/`: Use `#` for all comments, never `##`.
  - Comments should explain *why* code is written a certain way, not just what it does.
  - Place comments above the referenced code.
  - **Singleton Access**: Only game scripts access engine singletons directly. Editor/engine scripts must use `PopochiuUtils`.

## Integration Points

- **External Dependencies**: Asset importers may depend on external formats (e.g., Aseprite). No other major external dependencies are present.
- **Cross-Component Communication**: Use interfaces in `addons/popochiu/engine/interfaces/` for high-level API access.

## Key Files & Directories

- `addons/popochiu/editor/main_dock/`: Main UI for managing game elements.
- `addons/popochiu/editor/importers/`: Asset importers.
- `addons/popochiu/editor/migration/`: Migration logic.
- `addons/popochiu/engine/popochiu.gd`: Main engine controller.
- `addons/popochiu/engine/objects/`: Base classes for game entities.
- `addons/popochiu/engine/interfaces/`: APIs for game object access.
- `addons/popochiu/engine/templates/`: Script templates for new objects.

## Example Patterns

- **Accessing a prop in game scripts**:
  ```gdscript
  R.get_prop("PropName")
  ```
- **Accessing a prop in engine/editor scripts**:
  ```gdscript
  PopochiuUtils.r.get_prop("PropName")
  ```
