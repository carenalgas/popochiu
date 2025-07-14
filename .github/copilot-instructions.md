# GitHub Copilot Repository Instructions for Popochiu

Popochiu is a Godot addon that helps developers create classic point-and-click adventure games. It is composed of two main components:

## Editor Plugin (`editor/`)

This component extends the Godot Editor with a full suite of tools and interfaces to build, organize, and maintain all elements of a graphic adventure.

- `main_dock/`: The central UI that lists and manages characters, rooms, inventory items, audio cues, and more.
- `canvas_editor_menu/`: Adds buttons to the Scene Preview toolbar for enabling Popochiu’s interactive gizmos.
- `inspector/`: Customizes how Popochiu objects appear in the Godot Inspector to hide or expose relevant properties.
- `popups/`: Provides modal dialogs for creating and managing game objects and settings.
- `migration/`: Implements version migrations to update existing projects when upgrading Popochiu.
- `gizmos/`: Adds in-editor visual handlers (walk-to points, baselines, etc.) for interactive scene editing.
- `importers/`: Allows importing of assets (e.g., Aseprite animations) and auto-generating rooms and characters.
- `factories/`: Builds game object instances (characters, props, rooms) from engine templates.
- `config/`: Exposes and reads project/editor settings related to Popochiu.
- `helpers/`: Shared utility functions and classes used across the plugin.

## Game Engine (`engine/`)

This is the runtime layer that is bundled with the game and handles all core logic and reusable functionality.

- `popochiu.gd`: The main controller that initializes the engine, routes input, and manages the game's lifecycle.
- `audio_manager/`: Manages music and sound effects playback, including positional and non-positional audio.
- `cursor/`: Handles the runtime mouse pointer (not to be confused with the GUI Cursor component).
- `objects/`: Base classes for game entities like characters, rooms, props, hotspots, inventory items, and more.
- `interfaces/`: High-level APIs (via singletons) for accessing and manipulating game objects from scripts.
- `templates/`: Script templates used by the Editor Plugin to generate new game objects and GUI components.

Note: scripts in the `game/` folder are meant for actual game logic and may access engine singletons like `E`, `C`, `D`, etc. Scripts in `editor/` and `engine/` must **not** use those directly, but must use `PopochiuUtils` instead.
 Just map each singleton to a lowercase variable name, under `PopochiuUtils`, like this:

```gdscript
# Inside game scripts
R.get_prop("PropName")

# Inside engine or editor scripts
PopochiuUtils.r.get_prop("PropName")
```

## Coding standards

When generating code, please follow these guidelines:

- **Always** follow the official Godot GDScript style guide.
- Use **tabs**, NOT spaces, for indentation.
- Do **not** leave trailing whitespace at the end of lines or on empty lines.
- File names should use `snake_case` and reflect the class they define.
- All classes in the `engine/` and `editor/` folders must be explicitly named and start with `Popochiu`, due to the lack of namespaces in GDScript.

## Commenting rules

- Only in the `engine/` folder, always use `##` for documentation comments on **public or virtual** methods, classes, constants, enums, signals, and exported variables. These should include a description, details, and usage examples when relevant.
- Use `#` for internal comments in **private methods or classes**, and in every comment in the `editor` folder, never starting comments with `##` to prevent them from appearing in the API documentation.
- Comments should always explain *why* the code is written a certain way, not just what it does (which should already be clear from the code).
- Place comments above the code they reference, not at the end of a line.
- All comments must start with a capital letter and end with a period.
