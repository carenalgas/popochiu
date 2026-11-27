---
weight: 3042
---

# Simple Click

The **Simple Click** GUI is the most minimal of the three templates: no visible verb buttons, no action
cycling. The player interacts with the world directly, and the meaning of a click depends on which
mouse button is pressed.

**Inspired by:** _Beneath a Steel Sky_, _Broken Sword_, _Samorost_, _Machinarium_.

!!! info "2-click Context-sensitive"
    This template is also known as the **2-click Context-sensitive** GUI — the name used by its
    classes and files.

## How it works

- **Left click** interacts with an object (walk, use, open, ...).
- **Right click** examines an object.
- Clicking an empty spot makes the character walk there.

Because there are no verb buttons, the template has **no explicit commands**. Everything flows through
the `fallback()` method of `SimpleClickCommands`, which looks at the last mouse button used and calls
one of these:

| Method | Trigger |
| :----- | :------ |
| `click_clickable()` | Left click on a `PopochiuClickable` |
| `right_click_clickable()` | Right click on a `PopochiuClickable` |
| `click_inventory_item()` | Left click on a `PopochiuInventoryItem` |
| `right_click_inventory_item()` | Right click on a `PopochiuInventoryItem` |

By default these show a generic message (for example `Can't INTERACT with it` or `Can't EXAMINE it`).
To change them, override the methods in `res://game/gui/gui_commands.gd`. See
[GUI commands and fallbacks](gui-commands-and-fallbacks.md) for details.

## Layout

The GUI is mostly transparent, with a single bar that slides in when the cursor reaches the top of the
screen:

- **SimpleClickBar** — a bar on the **top** with the inventory on the left and the settings button on
  the right. It has two useful exported properties: `always_visible` (keep it on screen) and
  `input_zone_height` (the size of the zone that triggers the slide).
- **HoverText** — the description of whatever is under the cursor.
- **DialogOverhead** — dialogue lines shown above the speaking character.

The available popups are **SimpleClickSettingsPopup**, **SaveAndLoadPopup**, **HistoryPopup** and
**QuitPopup**.

## Inventory

- It lives in the top-left corner, inside the **SimpleClickBar**, and slides in when the cursor moves
  to the top of the screen.
- It is a horizontal bar that grows as you collect items.
- Clicking an item selects it: the item becomes **active** and the cursor turns into the item's
  texture. Then click another object (in the scene or in the inventory) to use it — Popochiu calls the
  `_on_item_used(item)` method on that target.
- To deselect an item, right-click anywhere on the screen.

## Settings

The settings button on the right of the **SimpleClickBar** opens the **SimpleClickSettingsPopup**,
which gives access to save/load, volume settings, the dialogue advancement mode and typing speed, the
history popup, and the quit popup.

## Cursor

The Simple Click cursor is the classic pointing arrow. It switches to:

- `wait` while the game is busy or a dialogue line is showing,
- `gui` over interface elements,
- the texture of the active inventory item, when one is selected.

To customize it, edit the frames of the **Cursor** `AnimatedSprite2D` in `gui.tscn`. Objects can also
declare their own cursor with the `cursor` property (a `PopochiuCursor.Type` value), which is shown
while the cursor hovers over them.

## Customizing

Everything you can edit for this template lives in `res://game/gui/`:

- `gui.gd` — override the virtual methods (cursor, hover, save/load feedback, ...).
- `gui_commands.gd` — override the four click handlers to change the default behavior.
- `templates/simple_click/` — the **SimpleClickBar** and **SimpleClickSettingsPopup** scenes and their
  `*_custom.gd` scripts.
