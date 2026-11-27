---
weight: 3044
---

# Action Bar

The **Action Bar** GUI is inspired by the Sierra SCI interface: a thin bar at the top of the screen,
with a set of action icons the player cycles through before clicking on an object.

**Inspired by:** _King's Quest V_, _Space Quest IV_, _Quest for Glory_.

!!! info "Internally known as Sierra"
    Behind the scenes this template is called **Sierra**: its classes are `SierraGUI` and
    `SierraCommands`, and its files live under `templates/sierra/` (for example `sierra_gui.gd` and
    `sierra_commands.gd`).

    This only matters if you work on Popochiu itself — on the plugin side. As a game developer you
    will only see the **Action Bar** name in the Setup popup and in this documentation.

## Commands

The template registers four commands, exposed as the `Commands` enum of `SierraCommands`:

| Enum | Command |
| :--- | :------ |
| `WALK` | Walk |
| `LOOK` | Look |
| `INTERACT` | Interact |
| `TALK` | Talk |

The player cycles through them by **right-clicking**, and applies the active one by left-clicking an
object. Popochiu calls `on_<command>()` on that object (for example `on_talk()`), falling back to the
command's fallback method when the object doesn't handle it. See
[GUI commands and fallbacks](gui-commands-and-fallbacks.md).

The default fallbacks use the **SystemText** component (for example `<Player> has nothing to say about
that object`). Override them in `res://game/gui/gui_commands.gd`.

## How it works

- The character only moves while `WALK` is the active command. Left-clicking with any other command
  selected is ignored unless it hits an interactive object.
- Right-click cycles to the next command; when an inventory item is active, right-click deselects it
  and returns to `WALK`.

## Layout

The GUI is centered on a top bar that appears when the cursor reaches the top of the screen:

- **SierraBar** — the always-visible top bar; it shows the game name on the left, the score on the
  right, and the description of whatever the cursor hovers over in the middle.
- **SierraMenu** — the menu that slides in from the top with the four action buttons, the inventory
  button and the settings button.
- **DialogPortrait** — dialogue shown in a panel with the speaking character's portrait.
- **SystemText** and **DialogMenu** — the shared system messages and dialogue options.

The available popups are **SierraInventoryPopup**, **SierraSettingsPopup**, **SierraSoundPopup**,
**TextSettingsPopup**, **SaveAndLoadPopup** and **QuitPopup**.

## Inventory

- Opened with the briefcase button in the **SierraMenu**.
- A grid of 20 slots (`number_of_slots`), in 5 columns (`columns`), with 3 rows always visible
  (`visible_rows`). These values are exported in the **SierraInventoryPopup** inspector.
- The inventory window has two buttons — **Look** and **Interact** — to examine an item or select it.
  A selected item appears next to the active command and can be used on other items or scene objects
  with the `INTERACT` command.

## Score

The **SierraBar** keeps a score, displayed as `score/max_score` in the top-right corner. Control it
from your game scripts through the `add_score()`, `subtract_score()` and `reset_score()` methods of
the **SierraBar** component.

## Cursor

Unlike the other templates, the Action Bar changes the cursor to match the active command: its
`gui.gd` overrides `_get_cursor_name()` to return the current command name, so the cursor shows a
different icon for `walk`, `look`, `interact` and `talk`.

To customize it, edit the frames of the **Cursor** `AnimatedSprite2D` in `gui.tscn` (or override
`_get_cursor_name()` to point to different animations).

## Customizing

Everything you can edit for this template lives in `res://game/gui/`:

- `gui.gd` — override the virtual methods (including `_get_cursor_name()`).
- `gui_commands.gd` — override the four command fallbacks (`walk()`, `look()`, `interact()`,
  `talk()`).
- `templates/sierra/` — the **SierraBar**, **SierraMenu**, **SierraInventoryPopup** and
  **SierraSettingsPopup** scenes and their `*_custom.gd` scripts.
