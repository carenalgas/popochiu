---
weight: 7040
---

# Project overview

## Popochiu Subsystems

Popochiu is divided into two main subsystems:

- An **Editor Plugin**, which initializes and manages a series of other plugins (for the Inspector, Toolbar, various pop-up windows, viewport Gizmos, etc.), and provides integrated interfaces within the Godot Editor to streamline the primary tasks involved in creating a graphic adventure game. The Editor Plugin is also responsible for setting up a project, configuring its parameters, and creating, updating, and deleting resources that will make up the final game.

- A **Game Engine**, which offers a set of functions, classes, templates, and objects used to build an adventure game. The engine handles all the logic for interactions between these elements and with the player, as well as recurring features of the genre such as dialogues, inventory management, scene transitions, and more. Additionally, the Game Engine takes care of lower-level functions, such as managing audio (music and sound effects), moving characters within and between rooms, saving/loading game states, and rendering the interface through which players interact with the game. Finally, the Game Engine provides an **API** with functions and scripts that make orchestrating all these features intuitive and straightforward.

Together, these features aim to **enable anyone to create graphic adventures without needing to learn Godot** (beyond a few basic concepts).

At the same time, its architecture is developer-friendly, suitable for code-driven workflows, and perfectly viable for larger and more structured teams.

The following sections provide an overview of the specific subsystems, their responsibilities, and their relationships. This is a high-level overview to help contributors make themselves at home, without delving into too much detail.

For specific questions, feel free to [get in touch](../get-in-touch).

### Editor Plugin

Here is a visual representation of the plugin architecture. Read on to learn about each individual block.

!["Plugin Architecture"](../../assets/images/contributing-to-popochiu/project_overview-5-plugin_architecture.svg "Popochiu Plugin subsystems")

#### Popochiu Plugin

This is the plugin activated when the Popochiu addon is enabled in the _Project Settings_.

It can be found in the `editor/popochiu_plugin.gd` file.

#### Main Dock

The Main Dock is Popochiu's primary interface. It allows developers to create, edit, and manage the main elements of the game without manual intervention and (ideally) without accessing the _Scene Tree Editor_.

![Popochiu Main Dock](../../assets/images/contributing-to-popochiu/project_overview-1-main_dock.png "The many elements of the Main Dock")

Located in the `editor/main_dock` folder, it contains:

- `popochiu_dock.tscn`: The scene defining the dock's UI using Control nodes (_1_).
- `popochiu_dock.gd`: The script handling the dock's logic.
- `popochiu_filter.gd`: A script for filtering dock items, essential for large games with many items. (_3_)

The folder also contains the Main Dock's building blocks: tabs (_2_) dedicated to specific elements and their components: groups (_4_) and rows (_5_) and (6)_. Specifically:

- `main_tab`: Interface and logic for listing game elements such as characters, rooms, dialogues, inventory items, etc.
- `room_tab`: Interface and logic for listing room-specific elements like props, hotspots, markers, walkable areas, etc.
- `audio_tab`: Interface and logic for listing audio resources like music and sound effects.

These tabs display a set of `popochiu_group` instances, which group zero or more `popochiu_row` instances (specialized into `object_row` (_5_) for general or room-specific objects and `audio_row` (_6_)for music and sound effects). Groups include buttons for creating new child elements, while rows offer quick access to the scene, script, or specific properties of the represented elements.

#### Scene Toolbar

In the `editor/canvas_editor_menu` folder, you'll find the `canvas_editor_menu.gd` script, which adds buttons defined in the `canvas_editor_menu.tscn` scene to the Scene Preview toolbar.

![Canvas Editor Menu](../../assets/images/contributing-to-popochiu/project_overview-2-canvas_menu.png "The Popochiu Scene Toolbar")

The script also handles the button logic, which primarily activates [Viewport Gizmos](#gizmos), discussed later.

#### Objects Inspector

The `editor/inspector` folder contains scripts that modify specific game objects' inspector panels. For example, the `character_inspector_plugin.gd` script hides certain properties of _Character_ scenes when selected inside a _Room_, to prevent local modifications of properties that should always be edited in the main scene.

![Inspector](../../assets/images/contributing-to-popochiu/project_overview-4-character_inspector.png "A Character Inspector")

#### Popups

The `editor/popups` folder contains subfolders, each with a `.tscn` scene and a `.gd` script implementing a pop-up window required by the plugin. Examples include the setup window for a new game, the window for creating new game objects, and the window for migrating to a new Popochiu version. Speaking of which...

#### Migrations

The `editor/migration` folder includes a basic framework (`migration/popochiu_migration.gd`) for implementing automated updates from older to newer Popochiu versions.

!!! danger "Know what you're doing"
    Writing migrations is a complex and delicate process requiring extensive testing, but it’s essential for ensuring that ongoing projects can be updated to newer versions of Popochiu.

To create a new migration, copy the `popochiu_migration_template.gd` script into the `editor/migration/migrations/` folder (note the `s` at the end!) or duplicate an existing migration script from the same folder, updating its content as needed.

!!! tip
    Writing migrations often involves updating resources, scripts, and files in the `game` folder. This is a delicate process that requires precision.
    Thankfully, the [Editor Helpers](#helpers-editor) and the utilities in `editor/migration/helpers` will be incredibly helpful!

<!-- TODO: Write a guide on how to implement a migration -->

#### Gizmos

Godot doesn't provide built-in functions for drawing interactive elements in the _Scene Preview_, so we had to create our own. These can be found in the `editor/gizmos` folder, along with a base class and the plugin (`gizmo_clickable_plugin.gd`) that registers and initializes them.

![Gizmos](../../assets/images/contributing-to-popochiu/project_overview-3-gizmos.png "A prop's gizmos")

Gizmos allow us to display handlers that game developers can easily manipulate with the mouse to populate properties like _Walk-To Point_, _Look-At Point_, and _Baseline_. In the future, these could be extended to expose more complex features, but generally, all interactive elements for the _Scene Preview_ are located in this folder.

#### Importers

The `editor/importers` folder contains docks and their corresponding logic for importing game assets.

Currently, [the only available importers](../the-editor-handbook/importers.md) configure character animations and create rooms (with graphics and animations) from properly prepared Aseprite files.

We hope to add more importers in the future to support other elements and source formats.

#### Helpers (Editor)

The `editor/helpers` folder contains classes and functions commonly used by many other Editor Plugin components.

!!! note
    Understanding this folder’s content is crucial to avoid writing complex and redundant code. Take the time to review it before contributing advanced plugin features!

Key scripts include:

- `popochiu_editor_helper.gd`: A collection of static functions for handling complex and frequent tasks like opening pop-ups, managing the lifecycle of game objects (creation, deletion, updating), or interacting with the Godot editor (e.g., selecting a scene, modifying dock state).
- `popochiu_gui_templates_helper.gd`: Contains public methods for creating GUIs within the `game` folder from templates provided by the Engine. These methods are used by other Popochiu components like the Setup pop-up and the GUI Tab.
- `popochiu_signal_bus.gd`: Implements the [Publisher-Subscriber pattern](https://en.wikipedia.org/wiki/Publish%E2%80%93subscribe_pattern) to decouple UI components in the Editor Plugin and streamline event-driven interactions.

    !!! tip "Detailed Example"
        Imagine two components (a button in the Main Dock and one in the toolbar) and a third element (e.g., a label in an inspector) that must update when either button is pressed.
        Using signals, the label would need to listen to two separate signals—one from each button.
        With the Signal Bus, the label listens to a single signal emitted by this class, triggered explicitly by both buttons.
        While this example is simple, some interactions in Popochiu notify many recipients. The Signal Bus keeps things organized and makes the code more explicit and readable.

#### Factories and Config

Last two structural elements are less glamorous but equally important:

- The `editor/factories` folder contains classes used to build game and room objects (like Characters, Rooms, Props, etc.) from the Engine’s templates. Factories are used by creation pop-ups triggered from the Main Dock and by importers that create rooms from Aseprite files. All classes inherit from `factory_base_popochiu_obj.gd`, which provides shared functions.
- The `editor/config` folder contains the logic for exposing Popochiu’s _Project Settings_ and _Editor Settings_, as well as functions for retrieving parameters within Plugin scripts.

    !!! warning
        Always use the getter methods in `config.gd` and `editor_config.gd` to access configuration values, ensuring that at least the default value is returned.

### Game Engine

This is the portion of the code referenced by—and bundled with—your game. It handles all the heavy lifting, taking care of the common tasks involved in running a point-and-click adventure game.

Here is a visual representation of the plugin architecture. Read on to learn about each individual block.

!["Engine Architecture"](../../assets/images/contributing-to-popochiu/project_overview-6-engine_architecture.svg "Popochiu Engine subsystems")

The engine is also divided into several subsystems, many of which provide an API (a set of classes and functions) to be used within the game’s scripts. Most of these subsystems are made available to the developer through [singleton](https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html) autoloads.

!!! warning "Important!"
    Accessing engine functions via singletons is only allowed in game scripts (those located in the `game` folder). When developing the engine or plugin, you **MUST** use the access instances provided by the `PopochiuUtils` class, as listed in the paragraph below.  
    If you use a singleton in the engine or editor code, the users will face errors when they enable Popochiu in their project for the first time, and will have to restart the engine to make it work.

#### Popochiu Engine

> **Position**: `engine/popochiu.gd`
> **Singleton**: `E`
> **Engine instance**: `PopochiuUtils.e`

This is the main hub that provides control over the game’s flow and manages its initialization and runtime.  
It initializes game elements, routes input, and offers functions for cross-cutting concerns such as:

- Camera control
- Savegame management
- Handling cutscenes or event queues
- Registering and managing GUI commands

It can be accessed via the `E` singleton in game scripts or through `PopochiuUtils.e` in addon scripts.

#### Audio Manager

> **Position**: `engine/audio_manager` provides the bulk of the logic, while `engine/interfaces/i_audio.gd` exposes an API to control it.
> **Singleton**: `A` (instance of `PopochiuIAudio`)
> **Engine instance**: `PopochiuUtils.a`

It handles playing audio using `PopochiuAudioCue` objects.

It plays sound effects and music through [AudioStreamPlayer](https://docs.godotengine.org/en/stable/classes/class_audiostreamplayer.html) or [AudioStreamPlayer2D](https://docs.godotengine.org/en/stable/classes/class_audiostreamplayer2d.html), creating these nodes at runtime if necessary. By default, it manages 6 nodes for positional streams and 5 nodes for non-positional streams.

The PopochiuAudioManager is initialized as a child of [`Popochiu`](#popochiu-engine) when the game starts.

#### Cursor

> **Position**: `engine/cursor`  
> **Singleton**: `Cursor`  
> **Engine instance**: `PopochiuUtils.cursor`

This tiny subsystem manages the on-screen representation of the mouse pointer. It allows switching between a primary and secondary representation, which is particularly useful for interfaces where the cursor shape changes - for example, to reflect a selected inventory item or a temporary action that deactivates after its next use.

!!! warning
    You might wonder about the relationship between the **Cursor** component in the [GUI scene](../../getting-started/creating-a-game-stub/customize-the-game-ui) and the cursor displayed on the screen. This can be a bit confusing (and is likely to change in the future). The **Cursor** GUI component simply holds a catalog of animations available for the pointer. The actual on-screen cursor is created at runtime by the engine and is not an instance of the GUI component.

#### Popochiu Objects

> **Position**: The `engine/objects` folder contains base classes that define all game objects (see below), while `engine/interfaces` includes classes that expose control APIs for some of these objects.  
> **Singletons**:
>
> - `C` (instance of `PopochiuICharacter`)
> - `D` (instance of `PopochiuIDialog`)
> - `G` (instance of `PopochiuIGraphicInterface`)
> - `I` (instance of `PopochiuIInventory`)
> - `R` (instance of `PopochiuIRoom`)
>
> **Engine instances**: See table below.
>
> **Other Popochiu Objects**: The following subsystems are not exposed as singletons but are still considered Popochiu Objects:
>
> - Clickable objects
> - Room objects
> - Inventory items
> - Transition layer

These subsystems are grouped in the `objects` folder because, despite their differences, they share a common purpose: representing game elements typical of the point-and-click adventure genre, such as characters, rooms (that in Popochiu refers to any location in the game), inventory items, and more.

Game objects are instances of classes that inherit from these subsystems. For example, the character `Popsy` would have its script located at `game/characters/character_popsy.gd`, which extends `PopochiuCharacter`.

!!! note
    You may have noticed that the scripts for _Popochiu Objects_ are marked as `@tool`. This is necessary to expose certain _Popochiu Object_ functions to the editor, allowing them to be loaded, managed, and executed even when the game is not running.

Interfaces like `PopochiuICharacter` or `PopochiuIRoom` are not tied to specific instances of their corresponding game objects. Instead, they expose a scripting API that provides quick access to **all** objects of a specific type, using the syntax:

```text
<Singleton Letter>.<Object Script Name>.<Function or Property>
```

For example:

```gdscript
C.popsy.say("What a great day to contribute to Popochiu!")
```

##### Clickable Objects and Room Objects

Some Popochiu Objects belong to one or both of two main categories.

1. **Clickable objects** extend the `PopochiuClickable` class (found in `engine/objects/clickable.gd`), which provides basic functionality for mouse interactions (hover, click, double-click, left click, etc.) along with "plumbing methods" to execute commands defined in the GUI (such as verbs in the 9-Verbs interface or actions in the Icon-Bar). These commands can trigger various scripts when an object is clicked.

2. **Room objects** are game objects confined to a specific location. In other words, they are always child nodes of a `PopochiuRoom`. These objects may or may not be clickable, but they cannot exist outside of a Room.

##### Summary of Popochiu Objects Subsystems

For easy reference, find here a summary of all Popochiu Objects:

|  | Clickable | Room Object | Singleton / Engine Instance | Description |
|---|:---:|:---:|---|---|
| **Character** | X |  | C / PopochiuUtils.c | A character in the game, either player or non-player. |
| **Dialog** |  |  | D / PopochiuUtils.d | Manages dialog trees and individual options. |
| **GUI** |  |  | G / PopochiuUtils.g | Game user interfaces with all their components. Popochiu provides various templates with common logic, instanced in the game folder during setup. |
| **Hotspot** | X | X |  | A clickable area in a room. Has no sprite, only geometry defining interactive background elements. |
| **Inventory Item** |  |  |  | A single item in the inventory. |
| **Prop** | X | X |  | A clickable object in a room with its own sprite and animations, allowing it to be removed from the scene. |
| **Region** |  | X |  | An area in the scene that triggers logic when the character enters or exits it. |
| **Room** |  |  | R / PopochiuUtils.r | A location in the game. |
| **Transition Layer** |  |  |  | The "curtain" that appears and disappears during location changes. |
| **Walkable Area** |  | X |  | Defines the area limiting character movement within a room. |
| **Marker** |  | X |  | Defines a named position (coordinates) in a room. |

#### Templates

Not exactly a subsystem of the engine, but still worth mentioning, the `engine/templates` directory contains templates for many scripts used to create objects (and their corresponding state scripts, if applicable) in the `game` folder. These templates are read and populated by the [Popochiu plugin factories](#factories-and-config) and other creation scripts, then saved in the appropriate location to instantiate new game elements.

Game UI templates and all their components also belong here and can be found at (`engine/templates/gui`).
