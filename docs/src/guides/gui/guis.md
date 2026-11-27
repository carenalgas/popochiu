---
weight: 3041
---

# Game UI

The **GUI** (Graphic User Interface) is how the player interacts with your game: the cursor, the
inventory, the dialogue panels, the settings windows, and — in some templates — the buttons that let
the player pick an action (a _verb_) before clicking on an object.

Popochiu ships with three ready-to-use GUI templates:

| Template | Interaction style | Inspired by |
| :------- | :---------------- | :---------- |
| [Simple Click](simple-click.md) | Left click to interact, right click to examine | _Beneath a Steel Sky_, _Broken Sword_, _Deponia_ |
| [9-Verbs](nine-verb.md) | Pick a verb, then click | _The Secret of Monkey Island_, _Day of the Tentacle_, _Thimbleweed Park_ |
| [Action Bar](action-bar.md) | Cycle through actions, then click | _King's Quest V_, _Space Quest IV_, _Quest for Glory_ |

You choose one when you [set up your game](../../your-first-adventure/game-setup/select-game-gui.md),
and you can switch to another later from the Setup popup. Keep in mind that applying a different
template **replaces** your current GUI, including any custom logic or art you added to it.

Each template is described in detail on its own page:

- [Simple Click](simple-click.md)
- [9-Verbs](nine-verb.md)
- [Action Bar](action-bar.md)

---

## How a GUI is created

When you apply a template, Popochiu **copies** that template — its scene and its scripts — from the
plugin's folder into `res://game/gui/`, inside your own project. What you get is:

- `gui.tscn` — the scene that holds all the interface elements.
- `gui.gd` — the script attached to that scene, full of virtual methods you can override.
- `gui_commands.gd` — the script that declares the template's commands and their fallbacks.
- a `<component>_custom.gd` script next to each copied component, ready for you to edit.

The copies are **decoupled from the plugin**. `gui.gd` extends the template's script inside `addons/`
(for example `extends "res://addons/popochiu/engine/objects/gui/templates/simple_click/simple_click_gui.gd"`),
and `gui_commands.gd` extends the template's commands class (for example `extends SimpleClickCommands`).

!!! info "Why copies instead of just inheritance?"
    The point of copying is **ownership**. Everything you are meant to edit lives in
    `res://game/gui/`, so you can change it freely and Popochiu updates won't overwrite your work.
    The files under `addons/` belong to the plugin and must be left untouched.

    Inheritance still happens — your copies extend the plugin's classes — but only as a way to reuse
    the built-in logic. It is **not** the place where you write your own code.

!!! tip
    A GUI is only generated the first time you apply a template. If you want a fresh, clean copy of
    the template you are already using, remove the `res://game/gui/` folder and apply the template
    again from the Setup popup.

---

## Anatomy of a GUI

A GUI is a single scene (`gui.tscn`) made of **components** and **popups**. The exact set varies per
template, but most of them share the following pieces:

### Components

- **HoverText** — shows the description of an object when the cursor hovers over it.
- **SystemText** — shows a message in the middle of the screen (for game messages or a narrator).
- **DialogText** — renders the characters' dialogue lines. It can display them **above the character**,
  in a **portrait** panel, or as a **caption** at the bottom of the screen.
- **DialogMenu** — the list of options shown when a `PopochiuDialog` starts.
- **InventoryBar** / **InventoryGrid** — display the player's inventory as an expandable bar or as a
  grid of slots.
- **SoundVolumes** — the sliders for each audio bus.
- **SettingsBar** — the row of buttons that opens the settings popups.

### Popups

Pop-ups that can be closed with a button or by clicking outside them:

- **QuitPopup** — confirmation dialog to close the game.
- **HistoryPopup** — the log of interactions and dialogue lines.
- **SaveAndLoadPopup** — save and load the game.
- **SoundSettingsPopup** / **TextSettingsPopup** — audio and dialogue presentation settings.

Template-specific pieces (like the **9VerbPanel**, the **SierraMenu**, or the **SimpleClickBar**) are
covered on each template's page.

---

## Commands

Some templates let the player choose an action before clicking — _Open_, _Pick up_, _Talk to_, and so
on. In Popochiu, each of these actions is a **command** (a _verb_). The GUI declares its commands and
their fallbacks, and your game objects respond to them with `on_<command>()` methods.

Simple Click has no explicit commands (it relies on the mouse button), 9-Verbs has ten of them, and
the Action Bar has four. See [GUI commands and fallbacks](gui-commands-and-fallbacks.md) for the full
picture of how commands are dispatched and how you can customize them.

---

## The cursor

The mouse pointer is driven by the [`PopochiuCursor`](../../reference/scripting-api/game-user-interface/PopochiuCursor.md)
singleton. Each template ships its own cursor art as an `AnimatedSprite2D` named **Cursor** at the
root of `gui.tscn`; at startup the GUI hands those frames to the engine with `replace_frames()`.

The cursor can show different animations — for example `normal`, `wait` while the game is busy, or
`gui` over interface elements. Which animation is shown is decided by the `_get_cursor_name()` virtual
method in `gui.gd`:

- Simple Click and 9-Verbs use the default (`normal`).
- The Action Bar overrides it to return the name of the active command, so the cursor changes as the
  player cycles through _Walk_, _Look_, _Interact_ and _Talk_.

When an inventory item is active, the cursor is usually replaced by the item's texture. You can also
set a per-object cursor with the `cursor` property (`PopochiuCursor.Type`) of a clickable or inventory
item.

To customize the cursor, edit the frames of the **Cursor** sprite in `gui.tscn`, or override
`_get_cursor_name()` to point to different animations. See each template's page for its specifics.

---

## Customizing a GUI

The general workflow for theming any GUI — the `gui_theme.tres` file, theme overrides, layout, and
textures — is covered in [Customize the Game UI](../../your-first-adventure/customize-the-game-ui.md).
For template-specific knobs (where the inventory sits, how many slots it has, how the settings open,
how the cursor behaves), see each template's page:

- [Simple Click](simple-click.md)
- [9-Verbs](nine-verb.md)
- [Action Bar](action-bar.md)
