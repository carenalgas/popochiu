---
weight: 3043
---

# 9-Verbs

The **9-Verbs** GUI is the classic LucasArts-style interface: a panel at the bottom of the screen with
a row of verb buttons. The player picks a verb, then clicks on an object to apply it.

**Inspired by:** _The Secret of Monkey Island_, _Day of the Tentacle_, _Thimbleweed Park_.

## Commands

The template registers ten commands, exposed as the `Commands` enum of `NineVerbCommands`:

| Enum | Command | Enum | Command |
| :--- | :------ | :--- | :------ |
| `WALK_TO` | Walk to | `LOOK_AT` | Look at |
| `OPEN` | Open | `PULL` | Pull |
| `PICK_UP` | Pick up | `GIVE` | Give |
| `PUSH` | Push | `TALK_TO` | Talk to |
| `CLOSE` | Close | `USE` | Use |

!!! note "Why ten commands in a 9-Verbs GUI?"
    The nine verb buttons correspond to `OPEN` through `USE`. `WALK_TO` is the implicit default: it is
    selected whenever no verb button is pressed, and it makes the character walk to the clicked spot.

The player selects a command with the buttons in the bottom panel, then clicks an object. Popochiu
calls `on_<command>()` on that object (for example `on_pick_up()`), falling back to the command's
fallback method when the object doesn't handle it. See [GUI commands and fallbacks](gui-commands-and-fallbacks.md).

The default fallbacks make the character say a generic line (for example `Not picking that up` or
`Can't open that`). Override them in `res://game/gui/gui_commands.gd`.

## Suggested commands

Objects can advertise a suggested action with a `suggested_command` variable. When the cursor hovers
over such an object, the matching verb button is highlighted:

```gdscript
extends PopochiuProp

var suggested_command := NineVerbCommands.Commands.PICK_UP
```

Right-clicking the object then triggers its suggested command; otherwise right-clicking makes the
character walk to the clicked point.

!!! info
    `suggested_command` is a convention, not a built-in property — the template reads it dynamically
    with `get("suggested_command")`. Set it to a `NineVerbCommands.Commands` value.

## Layout

The GUI is dominated by the **9VerbPanel** at the bottom, which contains the verb buttons, the
inventory, and the button that opens the settings popup. Above the panel sit the **HoverText**, the
**DialogOverhead**, the **DialogMenu** and the **SystemText** components.

The available popups are **9VerbSettingsPopup**, **SaveAndLoadPopup**, **HistoryPopup** and
**9VerbQuitPopup**.

## Inventory

- Always visible, in the bottom-right corner of the **9VerbPanel**.
- A grid of 16 slots (`number_of_slots`), in 4 columns (`columns`), with 2 rows always visible
  (`visible_rows`). These values are exported in the **9VerbInventoryGrid** inspector.
- `LOOK_AT` is always the suggested command for inventory items, so right-clicking one examines it.
- Clicking an item while no verb is selected selects it (as if using `USE`), so you can combine it
  with another item or a scene object. The hover text then reads like `Use <item> on <target>`.

## Settings

The gear button in the top-right corner opens the **9VerbSettingsPopup**, which offers save, load,
history and quit buttons, plus a toggle for the hover text style:

- **Classic style** — the text appears centered, at the top of the bottom panel.
- **Non-classic style** (default) — the text follows the cursor.

## Cursor

The cursor is the classic pointing arrow, switching to `wait` or `gui` when appropriate, and to the
`cursor` property of a hovered object when set. As in the other templates, edit the frames of the
**Cursor** `AnimatedSprite2D` in `gui.tscn` to change its look.

## Customizing

Everything you can edit for this template lives in `res://game/gui/`:

- `gui.gd` — override the virtual methods (hover, settings, save/load feedback, ...).
- `gui_commands.gd` — override the verb fallbacks (for example `push()` or `look_at()`).
- `templates/9_verb/` — the **9VerbPanel**, **9VerbInventoryGrid**, **9VerbSettingsPopup** and
  **9VerbQuitPopup** scenes and their `*_custom.gd` scripts.
