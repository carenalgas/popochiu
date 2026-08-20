---
weight: 5020
---

![Popochiu dock](../../assets/images/_other/_popochiu_dock.png)

The Popochiu dock consists of different tabs, used to group the objects that build the game. It
appears in the Godot Editor's right sidebar when the plugin is enabled.

<!-- TODO: add screenshots of each tab (pending) -->

## Main tab

The Main tab is a HUD for the main objects of the game: **Rooms**, **Characters**, **Inventory
items**, and **Dialog trees**. Each group lists the objects of that type found in the `game/`
folder.

- **Rooms** can be set as the **Main scene** (heart icon) that is the game starting location.
- **Characters** can be set as the **Player-controlled Character (PC)** (player icon).
- **Inventory items** can be set to **start in the player's inventory** (start icon).
- Objects that are not part of Popochiu yet (not in `popochiu_data.cfg`) are shown dimmed and can
  be added via the context menu.

Each row has buttons to open the object in the editor, open its script, open its state resource,
and (for rooms) play the scene. The **+** button on each group allows you to create a new object of
that type. The filter box at the top lets you search the objects by name.

## Room tab

The Room tab shows the objects of the currently open room, grouped by type: **Props**, **Hotspots**,
**Regions**, **Markers**, **Walkable areas**, and **Characters in room**.

- Clicking a row selects the corresponding node in the room.
- The **+** button on each group creates a new object of that type in the room.
- **Characters in room** are external characters linked into the room. Use the **Add character to
  room** button on that group to link one, and the unlink button on a row to remove it.

The header shows the room name and buttons to open the room's script, state resource, and state
script.

!!! Note
    The Room tab is only available when a room scene is open in the editor. If no room is open, the
    tab shows a message prompting you to open one. Taht's why there is not button to open the room
    scene in the tab header: you are already in it!

## Audio tab

The Audio tab lists the audio cues and files of the game, grouped by type by mean of a naming
convention: files which names starts with `mx_` go under **Music**, `sfx_` under **Sound
effects**, `voice_` under **Voices**, and `gui_` under **Graphic interface**. Audio files that are not assigned to a group appear under **Unassigned**. From there you can assign them manually to the group you prefer.

## Tools tab

The Tools tab groups utility tools for working with the project. At the moment it contains buttons
to trigger the export of translation files.

<!-- TODO: fill the Tools tab section -->
