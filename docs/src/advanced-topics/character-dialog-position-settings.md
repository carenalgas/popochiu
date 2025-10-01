---
weight: 3032
---

# Character dialog position settings

Want your character’s speech to appear *exactly* where you want it?
These runtime helpers let you nudge, replace, or even "pin down" dialog positions.

## What you can do

First and foremost, these work for dialog GUI components that are shown overhead, or that respect the placement of the `dialog position` gizmo.

Since the position is defined in the editor, relative to the character sprite, it is usually always the same. Changing it from a script can be inconvenient, since you need to keep track of the default position.

These helpers allow to:

* **Offset** the dialog, giving the default anchor a little push.
* **Override** the position entirely, tossing the default anchor out the window and dropping a new one.
* **Lock** the position at a certain point of execution, freezing the dialog in world space so it stays put on screen while your character goes wandering off.

## Use cases

* A character "costume" defined by an animation prefix is taller than the regular sprite.
* When the character walks near the top edge of the scene, normal dialog would appear above the sprite and risk overlapping the background, so we want to temporarily display the dialog below the character’s feet.
* If the character speaks while walking, zooming, zipping out of the scene, or while the camera is moving in a way that could make the text hard to read, we want to lock the dialog in place.

## House rules

* `dialog_pos_offset` is added to the character’s default `dialog_pos`.
* `dialog_pos_override` takes over when it’s not `Vector2.ZERO`. By convention, `Vector2.ZERO` = “unset.”
* `lock_dialog_pos()` stores a world coordinate. When locked, the character converts that world position back into local space so the GUI only needs one final local→screen transform (and doesn’t get confused).

## Quick examples

Nudge the dialog under a 55-pixels-tall character's feet:

```gdscript
C.player.dialog_pos_offset = Vector2(0, 75)
C.player.reset_dialog_pos_offset()
```

Swap the anchor for a special pose:

```gdscript
C.player.dialog_pos_override = Vector2(6, -30)
C.player.reset_dialog_pos_override()
```

Lock it in place while moving:

```gdscript
C.player.walk_to_marker("Parterre")
C.player.lock_dialog_pos()
C.player.walk_to_marker("Stage")
C.player.say("Tze-tze fly!") # displays over the parterre
C.player.unlock_dialog_pos()
C.face_down()
C.player.say("It works.") # displays over the character
```

Cutscene-friendly queue helpers:

```gdscript
E.queue([
    C.player.queue_say("I'll stand here and my dialog won’t move."),
    C.player.queue_lock_dialog_pos(),
    C.player.queue_walk_to(Vector2(400, 200)),
    C.player.queue_say("See? Still there."),
    C.player.queue_unlock_dialog_pos(),
])
```

Callable inside a queue:

```gdscript
E.queue([
    Callable(C.player, "set_dialog_pos_offset").bind(Vector2(0, -20)),
    C.player.queue_say("Offset applied inside queue."),
])
```

## Troubleshooting

* If a locked bubble shows up in the wrong spot, remember the lock grabs the world position *at the exact moment* you call `lock_dialog_pos()`. If your camera/HUD is offset at that moment, the bubble will inherit that offset too.
