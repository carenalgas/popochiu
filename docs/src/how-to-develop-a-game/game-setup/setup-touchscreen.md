---
weight: 2024
---
### Touchscreen support

!!! warning
    Touchscreen support is **not official yet**. Interactions are built around mouse events, and touch only works when it is normalized to the mouse by the engine or the operating system.

Popochiu reacts to mouse events everywhere: hovering uses `mouse_entered` and `mouse_exited`, cursor and click-to-walk use the mouse position, and GUI components react to mouse input. For a touchscreen to drive the game, taps must be delivered as mouse events.

Godot does this by default through the **Emulate Mouse From Touch** setting, and most desktop systems map touchscreen input to the mouse on their own. Keep this setting enabled:

**Project Settings > Input Devices > Pointing > Emulate Mouse From Touch**

If you disable it on a touchscreen device, Popochiu logs a warning at startup and touch input is ignored, because no pointer events reach the game.

#### Known limitations

* Disabling **Emulate Mouse From Touch** on a touchscreen-only device makes touch interactions unusable.
* There is no persistent cursor on a touchscreen, so hover feedback appears only while a finger is on the screen.
* Multi-finger gestures are not mapped to commands.
