---
weight: 3031
---

# Character Animation Prefix

The **Animation Prefix** feature allows characters to change their appearance for entire game sections without creating a separate character. Instead of duplicating characters for different outfits, states, or temporary effects, you can prefix existing animations to create visual variety.

## How Animation Prefix Works

When you set an animation prefix and you then play an animation, Popochiu searches for prefixed animations before falling back to standard ones.

Imagine your character has the following animations:

- `idle`
- `walk`
- `talk`
- `grab`
- `sneeze`
- `jump`
- `angry_scream`
- `pajama_idle`
- `pajama_walk`
- `pajama_talk`
- `pajama_grab`

```gdscript
C.player.play_animation("grab") # plays the `grab` animation

C.player.animation_prefix = "pajama"
C.player.play_animation("grab") # plays the `pajama_grab` animation
C.player.walk_to_marker("EnterPos") # plays the `pajama_walk` animation

C.player.play_animation("jump") # searches for `pajama_jump` but falls back to `jump` and plays it

C.player.animation_prefix = "" # go back to normal animations
```

Of course, Popochiu maintains the same directional animation logic if directional prefixed animations are available.

## Configuring animation prefix in the editor

In the Godot editor, select any character and look at the **Inspector** panel. You'll find the **Animation Prefix** property in the animation section.

![Character animation prefix property](../../assets/images/how-to-develop-a-game/adv_tech-character_animation_prefix-1-inspector.png "Animation Prefix property in the character inspector")

Leave it empty for standard animations, or enter a prefix string for outfit changes.

## Prefix format options

For your convienence, Popochiu automatically handles different naming conventions:

- **Capitalized input** (`"Pajama"`): Tries `Pajamawalk`, then `PajamaWalk`, then `pajama_walk`
- **Lowercase input** (`"pajama"`): Tries `pajamawalk`, then `PajamaWalk`, then `pajama_walk`
- **Snake_case input** (`"pajama_"`): Tries `pajama_walk`, then `Pajama_walk`

In short, the system first tries to apply your settings as you wrote it, trusting your knowledge of your own naming conventions, then tries to address the `PascalCase` and `snake_case` options (the latter being used internally by the [importers](../../the-editor-handbook/importers/)).

This flexibility should make your life a bit easier. Of course, it's not magic and you don't have to try that hard to break it (ex. `pajama___` will not work).

See [below](#animation-priority-order) for more details.

## Setting animation prefix

### In Code

Set the prefix directly on the character:

```gdscript
    # Set prefix in code
    character.animation_prefix = "armor"
    
    # Clear the prefix
    character.animation_prefix = ""
```

### In cutscenes

Use queue methods for dynamic changes during gameplay:

```gdscript
    E.queue([
        C.player.queue_say("Time to change into pajamas!"),
        C.player.queue_set_animation_prefix("pajama"),
        C.player.queue_idle(),  # Uses pajama_idle_* animations
        C.player.queue_walk_to(Vector2(100, 200)),  # Uses pajama_walk_* animations
        C.player.queue_set_animation_prefix(""),  # Clear prefix
    ])
```

## Animation priority order

The engine searches for animations in this priority order:

1. **Prefixed animations** (if prefix is set): `pajama_walk_r`, `armor_idle_l`
2. **Standard animations**: `walk_r`, `idle_l`
3. **Snake_case fallback**: Converts animation names to snake_case if needed

## Troubleshooting

**Animation prefix not working?**

- Check that prefixed animations exist (e.g., `pajama_walk_r`, `pajama_idle_l`)
- Verify prefix format: `"pajama"` tries `pajamawalk`, `PajamaWalk` and `pajama_walk`
- Use empty string `""` to clear the animation prefix
- Prefixed animations take priority over base animations
