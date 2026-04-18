---
weight: 7010
---

# Scripting principles

Popochiu bundles everything you need to build a classic point-and-click adventure: characters, dialogs, inventory items, rooms, props, and the small systems that make them work together. The Popochiu Engine is the runtime that makes the game run: it handles input, rendering, transitions, queued actions, and the high-level features you use through singletons.

Unlike some engines that try to hide code behind visual tools, Popochiu expects you to write the game logic in GDScript: you decide how the story unfolds and how objects react when the player does things. That said, Popochiu provides a facilitated coding approach so you only need the basics of GDScript (and almost nothing about Godot) to make a complete game quickly.

If you know Godot well, great: that knowledge is still valuable for deep customizations, mixing other gameplay styles, or tweaking scene-based behaviours. But it is not required to get a working 2D point-and-click game up and running.

This page covers the three fundamental concepts you need to understand before writing any game logic in Popochiu: **singletons** (how you access game objects), **virtual functions** (where you put your code), and **signals** (how you react to engine events).

## Accessing game objects through singletons

Every Popochiu game has a set of **singletons**: globally available objects that act as entry points to your game's data. You don't need to look up nodes in the scene tree or wire references manually. Instead, you use short, memorable names to reach anything in your game.

### Primary objects vs. room objects

Before looking at the full list of singletons, it's helpful to understand how Popochiu organizes game objects:

- **Primary objects** (rooms, characters, inventory items, dialogs) exist at the **project level**. They are always accessible through their dedicated singletons (`R`, `C`, `I`, `D`), regardless of which room is currently active. When you create them through the Popochiu dock, they appear as typed properties with full autocomplete.
- **Room objects** (props, hotspots, markers, regions, walkable areas) belong to a **specific room** and only exist while that room is loaded. They can't be reached through a typed singleton property; instead, you look them up through `R` at runtime using functions like `R.get_prop()`.

This distinction explains why characters and inventory items give you `C.Popsy` or `I.Key`, while props and hotspots require a lookup.

### Singleton reference

Here's the complete list, organized by purpose:

**Accessors** (for game objects):

| Singleton | Interface to | What it gives you access to |
| :-------: | :----------- | :-------------------------- |
| **R** | Rooms | All rooms in your project, plus the current room's props, hotspots, markers, regions, and walkable areas. |
| **C** | Characters | All characters, including the player-controlled character (`C.player`). |
| **I** | Inventory | Inventory items and inventory state (what's collected, what's active). |
| **D** | Dialogs | Dialog trees and dialog flow control. |

**Systems** (for engine features):

| Singleton | Interface to | What it gives you access to |
| :-------: | :----------- | :-------------------------- |
| **E** | Engine | Core engine features: camera, settings, queues, save/load, command registration. |
| **A** | Audio | Audio cues (music and sound effects). |
| **G** | Graphic Interface | GUI control: showing text, blocking/unblocking input, hiding/showing the interface. |
| **T** | Transition Layer | Screen transitions (fade in/out, curtains, custom animations). |
| **Cursor** | Cursor | Cursor appearance and behavior. |

**Globals** (for custom game state):

| Singleton | Interface to | What it gives you access to |
| :-------: | :----------- | :-------------------------- |
| **Globals** | Game globals | Your own project-wide variables and methods, defined in `res://game/popochiu_globals.gd`. |

### Accessing primary objects

Because characters, rooms, inventory items, and dialogs are primary objects, Popochiu generates typed properties for them on the corresponding singleton.

For example, if your project has a character called "Popsy" and a room called "LivingRoom":

```gdscript
# Access a character by its typed property
C.Popsy.say("Hello there!")

# Access a room
R.LivingRoom

# Access the player-controlled character (always available)
C.player.walk_to(Vector2(100, 80))

# Access an inventory item
I.HairDryer.add()
```

These typed properties are generated in the autoload files under `res://game/autoloads/`. You don't need to edit those files, as Popochiu keeps them in sync when you create or remove game objects through the dock.

!!! info "Under the hood"
    Each autoload (e.g. `res://game/autoloads/c.gd`) extends the corresponding engine interface class (e.g. `PopochiuICharacter`). The generated typed properties use getter functions that fetch the runtime instance by script name. This is why `C.Popsy` gives you a fully typed `PCPopsy` reference with all its methods and properties.

    This also means you get **full autocomplete** in the script editor! Yay!

### Accessing room objects

Room objects only exist when their room is loaded, so you look them up dynamically through `R`:

```gdscript
# Get a prop in the current room
R.get_prop("ToyCar")

# Get a hotspot
R.get_hotspot("Door")

# Get a marker position (useful for character placement)
R.get_marker_position("SpawnPoint")

# Get a region
R.get_region("DarkCorner")

# Get a walkable area
R.get_walkable_area("Floor")
```

### Usage examples

Here's how singletons look in real game code:

```gdscript
# Navigate to another room
R.goto_room("Kitchen")

# Play background music
A.mx_kitchen_theme.play()

# Make a character say something
await C.Popsy.say("I should check the kitchen.")

# Play a screen transition
await T.play_transition("fade", 3, T.PLAY_MODE.IN_OUT)

# Show a system message through the GUI
G.show_system_text("After a while...")

# Make a character say something
await C.Popsy.say("I found nothing!")

# Save the game in slot 1
E.save_game(1, "Mysterious Kitchen")
```

!!! tip
    You'll notice that some calls use `await` and some don't. This is an important distinction: [Await and queue functions](await-and-queue-functions.md) explains when and why you need `await`.

---

## Reacting to events with virtual functions

Here's the most important thing to understand about scripting in Popochiu: **you don't write game loops**. You don't need `_process()` or `_physics_process()` to drive your game logic. Instead, you implement **virtual functions**: methods that Popochiu calls for you at the right moment.

When a player clicks on a prop, Popochiu calls `_on_click()` on that prop's script. When a room loads, Popochiu calls `_on_room_entered()` on the room script. Your job is to fill in those functions with what should happen.

Think of it like directing a play: you don't control the stage machinery. You just write what happens when the curtain rises, when an actor is spoken to, or when a prop is picked up.

### Clickable interactions

Props, hotspots, and characters all inherit from `PopochiuClickable`, which provides a consistent set of virtual functions for player interactions:

| Function | Trigger |
| :------- | :------ |
| `_on_click()` | Left click |
| `_on_double_click()` | Double click |
| `_on_right_click()` | Right click |
| `_on_middle_click()` | Middle click |
| `_on_item_used(item)` | Click while an inventory item is selected |

Here's an example prop script:

```gdscript
extends PopochiuProp

func _on_click() -> void:
    await C.player.walk_to_clicked()
    await C.player.say("It's an old trophy. Dusty but proud.")

func _on_right_click() -> void:
    await C.player.face_clicked()
    await C.player.say("I don't want to touch it.")

func _on_item_used(item: PopochiuInventoryItem) -> void:
    if item == I.Feather:
        await C.player.say("I dust it off with the feather.")
        # ...do something with the trophy
    else:
        await C.player.say("That won't work.")
```

And a hotspot script that acts as a door:

```gdscript
extends PopochiuHotspot

func _on_click() -> void:
    R.goto_room("Kitchen")

func _on_right_click() -> void:
    await C.player.face_clicked()
    await C.player.say("It leads to the kitchen.")
```

!!! info
    When you create a prop or hotspot through the Popochiu dock, the editor generates a script with all virtual functions stubbed out and the default `E.command_fallback()` call. You just replace those calls with your own logic.

### Room lifecycle events

Every room has three key moments, each with its own virtual function:

| Function | When it's called | What to do here |
| :------- | :--------------- | :-------------- |
| `_on_room_entered()` | The room is loaded and in the tree, but **not visible** yet (the transition hasn't finished). | Set the stage: position characters, set facing directions, toggle prop visibility, choose the active walkable area, start background music. |
| `_on_room_transition_finished()` | The transition animation has finished and the room is **now visible**. | Start gameplay: trigger intro cutscenes, play sounds, begin timers. |
| `_on_room_exited()` | The room is about to be unloaded. It's **no longer visible** and characters have been removed. | Clean up: stop music, reset temporary state. |

Here's a concrete example:

```gdscript
extends PopochiuRoom

func _on_room_entered() -> void:
    # Set the stage before the player sees anything
    A.mx_background_theme.play()
    if state.visited_first_time:
        C.player.teleport_to_marker("EnterPos")
    else:
        C.player.teleport_to_marker("StartingPos")
        C.player.face_left()

func _on_room_transition_finished() -> void:
    # The room is now visible: start gameplay
    if state.visited_first_time:
        await E.cutscene([
            "Popsy: Where am I?",
            "Popsy: This place looks familiar...",
        ])

func _on_room_exited() -> void:
    # Clean up before leaving
    A.mx_background_theme.stop()
```

!!! note
    `state.visited_first_time` is a built-in property that Popochiu sets to `true` only on the very first visit to a room. It's part of the [Working with Game State](working-with-game-state.md) system.

### Region events

Regions trigger events when characters walk into or out of them:

| Function | Trigger |
| :------- | :------ |
| `_on_character_entered(chr)` | A character enters the region |
| `_on_character_exited(chr)` | A character exits the region |

By default, regions apply a color tint when a character enters and reset it when they exit. You can override this to do something different entirely. For example, a region can trigger a prop to play an open or close animation when the player walks into or out of the region.

```gdscript
extends PopochiuRegion

# Example: open a sliding door when a character approaches it enters the
# region, and close it when they leave. The region simply tells the prop
# to play its animations; the prop is responsible for its own visuals.
func _on_character_entered(chr: PopochiuCharacter) -> void:
    R.get_prop("SlidingDoor").play_animation("open")

func _on_character_exited(chr: PopochiuCharacter) -> void:
    R.get_prop("SlidingDoor").play_animation("close")
```

If you want to *add* behavior while keeping the region's default tinting, call `super()` from your override. That runs Popochiu's built-in tint logic first, then your custom actions:

```gdscript
extends PopochiuRegion

# Example: keep the default tinting and also open the door.
func _on_character_entered(chr: PopochiuCharacter) -> void:
    super() # Run the default tinting behavior
    R.get_prop("SlidingDoor").play_animation("open")

func _on_character_exited(chr: PopochiuCharacter) -> void:
    super() # Run the default tint reset behavior
    R.get_prop("SlidingDoor").play_animation("close")
```

### Inventory item events

Inventory items have their own set of virtual functions, since they live in the inventory bar rather than in a room:

| Function | Trigger |
| :------- | :------ |
| `_on_click()` | Item clicked in the inventory |
| `_on_right_click()` | Item right-clicked in the inventory |
| `_on_middle_click()` | Item middle-clicked in the inventory |
| `_on_item_used(item)` | Another inventory item used on this one |
| `_on_added_to_inventory()` | After this item is added to the inventory |
| `_on_discard()` | When this item is discarded |

```gdscript
extends PopochiuInventoryItem

func _on_click() -> void:
    await C.player.say("It's a shiny key.")

func _on_item_used(item: PopochiuInventoryItem) -> void:
    if item == I.Ring:
        await C.player.say("I thread the ring onto the keychain.")
        # Combine items, replace, etc.
```

### Dialog events

Dialog trees have two main virtual functions:

| Function | Trigger |
| :------- | :------ |
| `_on_start()` | When the dialog begins |
| `_option_selected(opt)` | When the player picks a dialog option |

```gdscript
extends PopochiuDialog

func _on_start() -> void:
    await C.Popsy.say("Hey there!")
    await C.Bartender.say("What can I get you?")

func _option_selected(opt: PopochiuDialogOption) -> void:
    match opt.id:
        "AskForBeer":
            await D.say_selected()  # Speak the same text that's on the dialog option's label
            await C.Bartender.say("Coming right up!")
            turn_off_options(["AskForBeer"])
        "AskAboutTreasure":
            await C.player.say("Do you know anything about the cursed hidden treasure?")
            await C.Bartender.say("I don't know what you're talking about...")
        "Bye":
            await C.Popsy.say("See you later!")
            D.finish_dialog() # End the dialog when the player says goodbye
```

### Movement events

Props, hotspots, and characters also have movement-related virtual functions:

| Function | Trigger |
| :------- | :------ |
| `_on_movement_started()` | The object starts moving (via `move_to()`) |
| `_on_movement_ended()` | The object finishes moving |

These are useful for triggering side effects when objects move programmatically.

### How dispatch works

When a player clicks on a game object, here's what happens behind the scenes:

```mermaid
flowchart TD
    A["Player clicks on a Prop"] --> B{"Is an inventory<br/>item active?"}
    B -- Yes --> C["Call _on_item_used(item)"]
    B -- No --> D{"Which mouse<br/>button?"}
    D -- Left --> E["Call _on_click()"]
    D -- Right --> F["Call _on_right_click()"]
    D -- Middle --> G["Call _on_middle_click()"]
    D -- Double --> H["Call _on_double_click()"]
```

!!! info
    This is a simplified view. When a GUI template with commands is active (like the 9-Verb GUI), the dispatch logic is more complex. It maps commands to method names. That's covered in [GUI commands and fallbacks](gui-commands-and-fallbacks.md).

---

## Writing non-reactive code

Not everything in your game is a reaction to a player click. Sometimes you need helper functions, utility methods, or logic that runs across multiple objects. There are two good places for this:

### Helper methods on game objects

You can add any method to any game object script. These aren't virtual functions, they're your own helpers:

```gdscript
extends PopochiuRoom

func _on_room_transition_finished() -> void:
    if _should_trigger_storm():
        await _play_storm_sequence()

func _should_trigger_storm() -> bool:
    return state.visited_times > 2 and not Globals.storm_happened

func _play_storm_sequence() -> void:
    await E.cutscene([
        C.player.queue_say("What's that rumbling?"),
        E.queue_wait(0.5),
        C.player.queue_say("Thunder!"),
    ])
    Globals.storm_happened = true
```

You can write you helper functions any way you want, but we strongly suggest following these guidelines:

- Use private helper functions (named with a leading underscore) unless you have a specific reason to make them public.
- Keep helper functions grouped in a clearly marked region (for example `# region Private helpers` / `# endregion`) so they are easy to find, less likely to be confused with virtuals and leverage code folding in Godot editor.
- Use clear, descriptive names for private helpers and avoid reusing names that collide with virtual functions.
- When you *do* override a virtual but want to preserve the base behavior, call `super()` inside your implementation.

These are best practices that make scripts easier to read and more reliable.

!!! tip
    Those of you coming from a background in object-oriented programming might wonder how to mark a function as private in a language that doesn't have built-in support for access modifiers.

    As mentioned, that's achieved by convention: prefix private functions with an underscore (e.g. `_calculate_score()`, `_is_puzzle_solved()`). While those methods can still be called from outside the class, this signals to other developers that these functions are intended for internal use.
    
    Popochiu virtuals also start with an underscore (for example `_on_click()`), so yes... both private helpers and engine virtuals use the same underscore.  
    That's a Godot convention: the leading underscore means "not part of the public API".  
    `¯\_(ツ)_/¯`

### The Globals singleton

Not all game logic belongs to a specific room, character, or item. You often need variables and functions that are accessible from anywhere: story flags, counters, score tracker, or utility checks that multiple scripts rely on.

That's what `Globals` is for. Popochiu creates an empty script at `res://game/popochiu_globals.gd` when you set up a project. It is registered as an autoload, so you can reference it as `Globals` from any game script.

Because the file starts empty, it can feel unclear what you're supposed to put there. The answer is simple: any **project-wide state** (variables and flags) or **shared helper functions** that don't naturally belong to a single object.

Here's an example of how you might set it up:

```gdscript
# res://game/popochiu_globals.gd
extends Node

# Project-wide flags and counters
var storm_happened := false
var total_clues_found := 0
var difficulty := "normal"

# A shared helper function any script can call
func is_puzzle_complete() -> bool:
    return total_clues_found >= 5
```

Then in any game script:

```gdscript
# In a prop script
func _on_click() -> void:
    Globals.total_clues_found += 1
    if Globals.is_puzzle_complete():
        await C.player.say("I've found all the clues!")
```

`Globals` properties of safe types (`bool`, `int`, `float`, `String`) are **automatically saved and loaded** with the game. You don't need to write any persistence code for them. For complex types, you can add custom `on_save()` and `on_load()` methods. See [Working with Game State](working-with-game-state.md) for details on how persistence works.

---

## Signals: reacting to engine events

Virtual functions let you respond to **player actions** (clicks, item use, room changes). But sometimes you need to react to things that happen inside the engine itself: a character finished talking, an item was added to the inventory, a transition completed.

That's what **signals** are for.

### When to use signals

Use signals when you need to:

- React to something that happens **elsewhere** in the engine (not directly on the current object)
- Coordinate behavior between objects that don't have a parent-child relationship
- Track engine state changes (like the GUI being blocked or unblocked)

### Common signal patterns

Here are some signals you'll use most often:

**Character signals** (on the `C` singleton):

```gdscript
# React when any character finishes speaking
C.character_spoke.connect(_on_any_character_spoke)

func _on_any_character_spoke(character: PopochiuCharacter, message: String) -> void:
    print("%s said: %s" % [character.script_name, message])
```

**Inventory signals** (on the `I` singleton):

```gdscript
# React when an item is added to the inventory
I.item_added.connect(_on_item_collected)

func _on_item_collected(item: PopochiuInventoryItem) -> void:
    if item == I.GoldenKey:
        await C.player.say("This could open something important...")
```

**GUI signals** (on the `G` singleton):

```gdscript
# React when the interface is blocked (e.g. during a cutscene)
G.blocked.connect(func(): print("GUI blocked"))
G.unblocked.connect(func(): print("GUI unblocked"))
```

**Transition signals** (on the `T` singleton):

```gdscript
# React when a screen transition finishes
T.transition_finished.connect(func(name): print("Transition done: " + name))
```

**Individual object signals** (on characters, props, etc.):

```gdscript
# React when a specific character stops walking
C.Popsy.stopped_walk.connect(_on_popsy_stopped)

func _on_popsy_stopped() -> void:
    # Popsy reached his destination
    await C.Popsy.say("I'm here!")
```

### Signals vs. virtual functions

A good rule of thumb:

| Use... | When... |
| :----- | :------ |
| **Virtual functions** | You're writing behavior for *this specific object* in response to a player action. |
| **Signals** | You need to react to something that happens on *another object* or inside the *engine*. |

For example, if you want a prop to react when the player clicks on it, use `_on_click()`. But if you want a prop to react when a character reaches a certain position, connect to that character's `stopped_walk` signal.

!!! info
    For the complete list of signals available on each class, check the [Scripting Reference](scripting-reference/index.md). The signals listed here are just the most commonly used ones.

---

## Summary

These three concepts (singletons, virtual functions, and signals) form the foundation of all Popochiu scripting:

1. **Singletons** (`E`, `R`, `C`, `I`, `D`, `A`, `G`, `T`, `Globals`, `Cursor`) give you access to everything in your game.
2. **Virtual functions** (`_on_click()`, `_on_room_entered()`, etc.) are where you write your game logic in response to player actions.
3. **Signals** let you react to engine events that happen outside your current object.

With these tools, you can build the vast majority of your game's interactive behavior. The next pages cover more specialized topics: how [GUI commands](gui-commands-and-fallbacks.md) route player intent to your objects, how [await and queues](await-and-queue-functions.md) let you choreograph sequences, and how [working with game state](working-with-game-state.md) keeps track of everything across room changes and save files.
