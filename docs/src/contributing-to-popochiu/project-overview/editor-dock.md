---
weight: 9525
---

# The Editor Dock

The Popochiu dock is the panel that appears in the Godot Editor's right sidebar when the plugin is
enabled. It groups the objects that build the game (rooms, characters, inventory items, dialogs,
audio, and the objects of the currently open room) into tabs so you can manage them without leaving
the editor.

This page explains how the dock is structured internally. It is aimed at **contributors** who want
to understand or extend it.

## Folder layout

The dock lives in `addons/popochiu/editor/main_dock/`:

```
main_dock/
├── popochiu_dock.gd / .tscn      # Top-level Panel hosting the TabContainer
├── popochiu_tree_dock.gd         # Base class for the tabs that use a Tree
├── rows/                         # Row classes (one per resource type)
│   ├── popochiu_dock_row.gd      # Base row class (strategy pattern)
│   ├── popochiu_room_obj_row.gd  # Base for room object rows (hybrid)
│   ├── popochiu_room_row.gd      # Rooms (Main tab)
│   ├── popochiu_character_row.gd # Characters (Main tab)
│   ├── popochiu_inventory_item_row.gd
│   ├── popochiu_dialog_row.gd
│   ├── popochiu_prop_row.gd      # Room object (config-only)
│   ├── popochiu_hotspot_row.gd   # Room object (config-only)
│   ├── popochiu_region_row.gd    # Room object (config-only)
│   ├── popochiu_marker_row.gd    # Room object (config-only)
│   ├── popochiu_walkable_area_row.gd
│   └── popochiu_character_in_room_row.gd  # Special room row
├── tab_main/                     # Main tab (rooms, characters, items, dialogs)
├── tab_room/                     # Room tab (objects of the open room)
├── tab_audio/                    # Audio tab (music, sfx, voices, UI)
└── tab_tools/                    # Tools tab
```

`popochiu_dock.gd` is the top-level `Panel`. It hosts the `TabContainer`, forwards the editor's
`scene_changed` / `scene_closed` signals to the tabs, and triggers `fill_data()` on the Main and
Audio tabs.

## PopochiuTreeDock

`popochiu_tree_dock.gd` is the base class for the tabs that display grouped items in a native
[`Tree`](https://docs.godotengine.org/en/stable/classes/class_tree.html) control. It centralizes
everything the tabs share:

- The **filter** `LineEdit` and the **Tree** setup (three columns: text, tag, buttons).
- The **right-click / three-dots context menu**, built from a per-item list of options.
- **Group and item helpers**: `create_group()`, `add_item()`, `add_button()`, `set_tag()`,
  `set_dimmed()`, `remove_item()`, `get_item()`, `update_group_count()`, and more.
- **Shared file operations**: `open()`, `open_script()`, `remove_object()`,
  `delete_from_file_system()`, and the `delete_dialog` used by the delete confirmation.

Subclasses must provide a scene with a `%Filter` `LineEdit` and a `%Tree` `Tree` node, and implement
the virtual methods to build their own content.

### Virtual contract

The base class defines a small set of virtual methods that subclasses override:

- `_get_menu_cfg(item)` — returns the context-menu options for an item.
- `_get_location(path)` — the location name shown in the delete confirmation.
- `_remove_from_core(item, ...)` — handles the confirmed deletion.

!!! note
    These virtuals are kept with an underscore prefix for now because the Audio tab still overrides
    them. They will be renamed to public (`get_menu_cfg`, `get_location`, `remove_from_core`) when
    and if the Audio tab is refactored.

## The row strategy pattern

Each tab keeps only its orchestration (scanning folders, wiring signals, dispatching events). The
per-type logic lives in **row classes** — plain `RefCounted` objects that hold a reference to their
owning tab (a `PopochiuTreeDock`) and call its public helpers to interact with the Tree.

The base class is `PopochiuDockRow`. It provides:

- The `dock`, `type` and `group` references.
- Config getters (`get_title()`, `get_icon()`, `get_popup()`, `get_folder_path()`, ...).
- `create_group()` — creates the group item for the type.
- Virtual behavior methods: `create_row()`, `get_menu_cfg()`, `add_to_core()`,
  `remove_from_core()`, `on_item_clicked()`, `on_button_clicked()`, `on_menu_item_selected()`.

The Main tab registers one row per object type:

| Type | Row class |
|------|-----------|
| Room | `PopochiuRoomRow` |
| Character | `PopochiuCharacterRow` |
| Inventory item | `PopochiuInventoryItemRow` |
| Dialog | `PopochiuDialogRow` |

### Room objects: a hybrid hierarchy

The five room object types (Props, Hotspots, Regions, Markers, Walkable areas) are nearly
identical, as they differ only in configuration. To avoid duplication they share a base class,
`PopochiuRoomObjRow`, which holds all the common behavior (creating rows from room nodes, the
"Remove" menu, removing the node from the room, handling child add/remove). Each concrete type is a
**config-only subclass** that sets its `method`, `type_class`, `parent_name`, `getter`, `popup`,
icon and title in `_init()`:

```
PopochiuDockRow
├── PopochiuRoomObjRow
│   ├── PopochiuPropRow
│   ├── PopochiuHotspotRow
│   ├── PopochiuRegionRow
│   ├── PopochiuMarkerRow
│   └── PopochiuWalkableAreaRow
└── PopochiuCharacterInRoomRow   # special, does NOT extend RoomObjRow
```

`PopochiuCharacterInRoomRow` is special on purpose: characters are **external objects linked into
the room**, not room objects created there. It has no create button, no context menu, and a
"Remove character from room" button instead of the usual open/script buttons.

## How to add a new type

1. Create a row class in `rows/` that extends `PopochiuDockRow` (or `PopochiuRoomObjRow` if it is a
   room object). Set the config in `_init()` and override the behavior methods you need.
2. Register it in the tab's `_rows` dictionary, keyed by its `PopochiuResources.Types` value.
3. The tab's `_ready()` instantiates the row and calls `create_group()`; the signal handlers
   dispatch to the row automatically.

## The handbook

For a user-facing description of each tab, see
[Popochiu dock](../../the-editor-handbook/popochiu-dock.md) section of **The Editor Handbook**.
