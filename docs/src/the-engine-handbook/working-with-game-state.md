---
weight: 7040
---

# Working with game state

In a point-and-click adventure, the world changes as the player interacts with it: doors get unlocked, items are collected, characters move between rooms, dialog options get exhausted. Popochiu needs to **remember** all of this, even when the player leaves a room and comes back, or saves and loads the game.

This page explains how Popochiu tracks object state, how you can add your own custom properties, and how the save/load system works.

## How state works in Popochiu

Every game object (rooms, characters, props, hotspots, inventory items, dialogs, regions, and walkable areas) has **state that persists** across room changes. When you leave a room, Popochiu stores the current state of everything in it. When you return, it restores that state.

This means:

- If you hide a prop, it stays hidden when the player comes back
- If you change a character's position, they'll be where you left them
- If you turn off a dialog option, it stays off

Popochiu **automatically** persists the following built-in properties for room children (props, hotspots, walkable areas, regions), so you don't need to write any save/load code for them:

- `position`
- `visible`
- `modulate` and `self_modulate`
- `clickable` (whether the object responds to clicks)
- `walk_to_point` and `look_at_point`
- `baseline`
- `interaction_polygon` and `interaction_polygon_position`
- Click counts (`times_clicked`, `times_right_clicked`, etc.)

For characters in a room, these additional data is stored:

- Facing direction
- `light_mask`
- `dialog_pos`
- Face/follow character settings

Rooms also track visit metadata:

- `visited` (whether the room has been visited at all)
- `visited_first_time` (true only on the first visit)
- `visited_times` (how many times the room has been entered)

---

## Data resources: where state lives

Each game object has a corresponding **data resource**, a `.tres` file with a script that extends one of Popochiu's data classes:

| Object type | Data class | Example file |
| :---------- | :--------- | :----------- |
| Room | `PopochiuRoomData` | `room_living_room.tres` + `room_living_room_state.gd` |
| Character | `PopochiuCharacterData` | `character_will.tres` + `character_will_state.gd` |
| Inventory item | `PopochiuInventoryItemData` | `inventory_item_key.tres` + `inventory_item_key_state.gd` |

When Popochiu creates an object through the editor dock, it generates both the `.tres` resource and the `*_state.gd` script. The script extends the corresponding data class and is where you add custom properties.

Here's what a generated state script looks like for a room (same happens for characters and inventory items, just with different base classes):

```gdscript
# room_living_room_state.gd
extends PopochiuRoomData
```

And the room script loads it:

```gdscript
# room_living_room.gd
extends PopochiuRoom

const Data := preload("room_living_room_state.gd")
var state: Data = load("res://game/rooms/living_room/room_living_room.tres")
```

This way, you access the state through the `state` property on the room.

---

## Adding custom properties

This is where things get interesting. To track your own game-specific data (whether a door is unlocked, how many clues the player has found in a room, which color a light is set to), you add properties to the state script.

### Example: tracking a locked door

```gdscript
# room_living_room_state.gd
extends PopochiuRoomData

var door_unlocked := false
var times_knocked := 0
```

Then use those properties in your room or prop scripts:

```gdscript
# In a hotspot script (the door)
func _on_click() -> void:
	if R.LivingRoom.state.door_unlocked:
		R.goto_room("Kitchen")
	else:
		await C.player.say("It's locked.")
		R.LivingRoom.state.times_knocked += 1
		if R.LivingRoom.state.times_knocked >= 3:
			await C.player.say("Maybe I should find a key.")
```

!!! note
	Why not just put these properties on the room node itself? Because the room node gets unloaded when you leave the room, so any state stored there would be lost. By putting it in the data resource, which stays in memory, we ensure it persists across room changes and saves/loads.

### Example: tracking character state

```gdscript
# character_will_state.gd
extends PopochiuCharacterData

var has_met_bartender := false
var mood := "neutral"  # "neutral", "happy", "angry"
```

```gdscript
# In a dialog script
func _on_start() -> void:
	if C.Popsy.state.has_met_bartender:
		await C.Bartender.say("Back again?")
	else:
		await C.Bartender.say("Welcome, stranger!")
		C.Popsy.state.has_met_bartender = true
```

### Example: tracking inventory item state

```gdscript
# inventory_item_key_state.gd
extends PopochiuInventoryItemData

var is_rusty := true
```

```gdscript
# In a prop script (a grindstone)
func _on_item_used(item: PopochiuInventoryItem) -> void:
	if item == I.Key and I.Key.state.is_rusty:
		await C.player.say("Let me clean this key up...")
		I.Key.state.is_rusty = false
		await C.player.say("Much better!")
```

!!! warning "Managing complex types"
    We said Popochiu automatically saves and loads state properties, but there's a catch: **only certain types are supported**. `bool`, `int`, `float`, and `String` are safe. Arrays and Dictionaries require their contents to be of safe types as well. Complex types like `Vector2`, `Color`, `Node`, or `Resource` require custom save and load logic.

    **Read on to learn how to handle those cases.**

---

## Custom save and load logic

Custom state properties are automatically saved and loaded only if their type is safe (for more expert readers, only if they are _JSON-serializable_): `bool`, `int`, `float`, and `String` are all safe types.

**Arrays** and **Dictionaries** also work as long as their contents are safely typed.

Sometimes you will need to use complex types like `Vector2`, `Color`, `Node`, `Resource`, and so on. In these cases, Popochiu won't know how to serialize them by default, so you need to implement custom save and load logic.

The core of the problem lies in a process called **serialization**: converting your in-memory data into a format that can be saved to a simple text file, then converting it back when loading. It's pretty easy for basic types, but more complex data structures like Godot nodes and native classes don't have a built-in way to be represented as plain text.  
That's why Popochiu only automatically handles simple types.

But don't worry! You can still save complex data by implementing two virtual methods on your data resource: `_on_save()` and `_on_load()`. These methods allow you to define exactly how your custom data should be serialized and deserialized.

Every data resource has these two virtual methods:

```gdscript
## Called when the game is saved.
## Return a Dictionary with custom data (JSON-safe types only).
func _on_save() -> Dictionary:
	return {}

## Called when the game is loaded.
## The Dictionary matches what you returned in _on_save().
func _on_load(_data: Dictionary) -> void:
	pass
```

As you can see, by default they return an empty dictionary and do nothing on load. Your task is to override them to include your custom state.

Understanding how to do this requires a bit of knowledge about programming and depends on the specific data you're trying to save. But the general idea is: find what the complex type represents in terms of simple data, convert it to a dictionary in `_on_save()`, and then reconstruct it in `_on_load()`.

We provide three examples below to illustrate this pattern in different contexts.

### Esample 1: saving a custom position property

```gdscript
# room_living_room_state.gd
extends PopochiuRoomData
var secret_door_position: Vector2 = Vector2.ZERO
func _on_save() -> Dictionary:
    return {
        "secret_door_position": {
            "x": secret_door_position.x,
            "y": secret_door_position.y
        }
    }

func _on_load(data: Dictionary) -> void:
    var pos_data = data.get("secret_door_position", {})
    secret_door_position = Vector2(pos_data.get("x", 0), pos_data.get("y", 0))
```

When you look at the code above, it may feel a bit redundant: you write out the `x` and `y` values separately, then immediately put them back together. That's intentional and it's the core concept behind saving complex types.

In simple terms:

- A `Vector2` is a compound value (two numbers). The save system only understands simple serializable data such as numbers, strings, lists, and dictionaries.
- To save a `Vector2` you convert it into simple parts (for example the `x` and `y` numbers) and put them in a dictionary. These are easy to write to disk or include in a save file.
- When loading, you read those simple numbers back from the dictionary and reconstruct the `Vector2` instance.

Yes, it looks like extra steps, but this explicit conversion is exactly how you make complex in-memory objects persist across runs: represent them with plain numbers or strings, and then repopulate the original object when you load.

### Example 2: saving the color of an inventory item

```gdscript
# inventory_item_paintbrush_state.gd
extends PopochiuInventoryItemData

# A Color value we want to persist
var brush_color: Color = Color(1, 1, 1, 1) # white by default

func _on_save() -> Dictionary:
    # Save the color as a single hex string (include alpha)
    return {
        "brush_color": brush_color.to_html(true)  # e.g. "#rrggbbaa"
    }

func _on_load(data: Dictionary) -> void:
    var hex := data.get("brush_color", "")
    brush_color.from_string(hex)
```

Much like the code above, we need to instruct Popochiu about how to save data from a specific class. Godot's `Color` can be exported to a compact hex string using `to_html(true)` (the `true` includes alpha). Storing a single string is often more convenient and smaller than saving four separate numbers. On load, just use the `from_string()` method that can take either an html string or a named color.

### Example 3: saving a custom class instance

The previous two examples dealt with Godot built-in types (`Vector2`, `Color`). There is another situation that requires custom serialization: when you define your own inner class.

Consider a dialog where an NPC tracks its emotional disposition toward the player. You model that as a small inner class:

```gdscript
# dialog_bartender.gd
extends PopochiuDialog

# A custom class to track the NPC's attitude toward the player
class Disposition:
	var trust: float = 0.5
	var suspicion: float = 0.0
	var anger: float = 0.0

var attitude := Disposition.new()

func _on_start() -> void:
	if attitude.trust > 0.7:
		await C.Bartender.say("Good to see you again!")
	elif attitude.suspicion > 0.6:
		await C.Bartender.say("What do you want this time...")
	else:
		await C.Bartender.say("What'll it be?")

func _on_save() -> Dictionary:
	return {
		"attitude": {
			"trust": attitude.trust,
			"suspicion": attitude.suspicion,
			"anger": attitude.anger,
		}
	}

func _on_load(data: Dictionary) -> void:
	var d: Dictionary = data.get("attitude", {})
	attitude.trust = d.get("trust", 0.5)
	attitude.suspicion = d.get("suspicion", 0.0)
	attitude.anger = d.get("anger", 0.0)
```

Popochiu has no way to know what a `Disposition` object is or how to serialize it. By flattening it into a plain `Dictionary` in `_on_save()` and rebuilding it in `_on_load()`, you explicitly define that conversion. The pattern is the same as for `Vector2` and `Color`; the only difference is that you designed the class and therefore decide how it maps to simple values.

This example is a bit more advanced, but it shows how far you can stretch the classic adventure-game gameplay and what Popochiu makes possible. The project's philosophy is the same as Godot: make easy things simple and complex things possible.

!!! note
    Experienced developers often add serialization methods directly to their custom classes (for example `to_dict()` and `from_dict()`), similar to the helpers available on Godot types like `Color`. That is a cleaner, reusable approach and we recommend it when you control the class implementation. The example above keeps the focus on `_on_save()` and `_on_load()` to demonstrate the core pattern.

    If every Godot built-in class provided built-in serialization, custom `_on_save()`/`_on_load()` logic would rarely be necessary.

---

### Globals persistence

Much like any other state variables, `Globals` properties of safe types (`bool`, `int`, `float`, `String`) are automatically saved and loaded.

If you need to persist complex data on `Globals`, add `on_save()` and `on_load()` methods to `res://game/popochiu_globals.gd`. Unlike data resources, these methods are **not stubbed out** for you: you need to add them yourself. They are also **public** (no leading underscore), because `Globals` extends `Node`, not a Popochiu data class.

```gdscript
# popochiu_globals.gd
extends Node

var total_score := 0
var completed_puzzles: Array = []

func on_save() -> Dictionary:
	return {
		"puzzles": completed_puzzles
	}

func on_load(data: Dictionary) -> void:
	completed_puzzles = data.get("puzzles", [])
```

!!! warning
    Note the method names: `on_save()` and `on_load()`, **not** `_on_save()` and `_on_load()`. The underscore-prefixed versions are virtual methods on Popochiu data resources. The Globals versions are plain public methods with no underscore.

---

## State persistence

It's important to understand that Popochiu has **two separate persistence mechanisms**, and they serve different purposes:

- **Cross-room persistence** keeps state alive while the player moves between rooms during a single play session. No file is written to disk.
- **Save/load persistence** writes state to a save file so it survives quitting and restarting the game.

Both mechanisms work together seamlessly: changes you make to state are preserved across room transitions automatically, and when the player saves, everything (including those in-session changes) is written to disk.

### Cross-room persistence

When the player leaves a room, Popochiu stores the current state of all room children (props, hotspots, regions, walkable areas, characters) in the data resource. When the player returns, the room loads and restores that state.

This means you can rely on state changes surviving room transitions without explicitly saving the game:

```gdscript
# In Room A: hide a prop
R.get_prop("Vase").hide()

# Player goes to Room B, then comes back to Room A
# → The vase is still hidden, because the state was stored
```

Custom properties on state scripts also survive room changes, since they live on the data resource (which stays in memory), not on the room node (which gets unloaded).

### Saving

When you call `E.save_game(slot, description)`, the engine runs these steps in order:

1. Collect player data: current room, position, and inventory.
2. Collect room states: props, hotspots, regions, walkable areas, and characters present in each room.
3. Collect character states.
4. Collect inventory item states.
5. Collect dialog states: option usage and on/off flags.
6. Collect `Globals` properties.
7. Call `_on_save()` on every data resource and on `Globals`.
8. Write everything as JSON to `user://save_N.json`.
9. Emit the `game_saved` signal.

### Loading

When you call `E.load_game(slot)`, the steps mirror saving in reverse:

1. Read JSON from `user://save_N.json`.
2. Restore inventory items.
3. Restore room, character, inventory item, and dialog states.
4. Restore `Globals` properties.
5. Call `_on_load()` on every data resource and on `Globals`.
6. Navigate to the room the player was in when they saved.
7. The room applies its stored state: positions, visibility, and so on.
8. Emit the `game_loaded` signal.

### Save slots

Popochiu supports up to **4 save slots** by default. Save files are stored as JSON at `user://save_1.json` through `user://save_4.json`.

The API is straightforward:

```gdscript
# Save in slot 1 with a description
E.save_game(1, "Before the final puzzle")

# Load from slot 1
E.load_game(1)

# Check if a save exists
if E.has_save():
	# At least one save file exists

# Get the number of saves
var count := E.saves_count()

# Get descriptions for all saves {slot_number: description}
var saves := E.get_saves_descriptions()
```

!!! info "Under the hood"
    The save file is a flat JSON dictionary. Room states include nested dictionaries for props, hotspots, walkable areas, regions, and characters within that room. Dialog states include the state of each dialog option (whether it's been used, how many times, whether it's turned off). Custom data from `_on_save()` is stored under a `custom_data` key.

---

## Summary

| Concept | How it works |
| :------ | :----------- |
| **Built-in state** | Properties like position, visibility, and click counts are tracked automatically for all game objects. |
| **Custom state** | Add properties to `*_state.gd` scripts. Use JSON-safe types (`bool`, `int`, `float`, `String`). |
| **Custom save/load** | Override `_on_save()` and `_on_load()` on data resources for complex persistence needs. For `Globals`, use `on_save()` and `on_load()` (no underscore). |
| **Cross-room persistence** | State survives room changes automatically, since data resources stay in memory. |
| **Save/load** | `E.save_game()` / `E.load_game()` serialize everything to JSON files (up to 4 slots). |
