---
weight: 3030
---

# Character Base Animations

Popochiu allows you to configure custom animation names for the three basic character animations: idle, walk, and talk. These animations are considered basic because the engine will automatically play them when the character is in one of those three states.

By default, Popochiu used standard animation names like `idle`, `walk`, and `talk` for their basic animations. However, you may want to use different animation names to better fit your game's art style, animation conventions, or for specific cases. So now you can set which animation to use for each of these default states, directly in the character's inspector, giving you full control over how your characters animate.

But why would you want to change these animation names? There are some use cases:

- **Ghost character** may have `float` and `glide` animations for idle and walk states.
- **Injured character**: you may want to temporary change the walk animation to `limp` until the character recovers.
- **R2D2-like robot**: your talk animation changes to `broadcast`, and idle becomes `standby` for robot-specific animations.

!!! Tip "Foundamental reasons for this feature"
    Basically, this feature helps in you two areas:

    1. You want to keep your animation names significant (`float` instead of `walk`, `broadcast` instead of `talk`).
    2. You need to change the actual animation along the game, so the engine will play the correct one.

    Weather your reason, Popochiu gets you covered.

## Configuring Animation Names

In Godot editor, open the character scene and look at the **Inspector** panel. You'll find three properties:

- **Idle Animation**: The root name for idle animations (default: `idle`)
- **Walk Animation**: The root name for walk animations (default: `walk`)
- **Talk Animation**: The root name for talk animations (default: `talk`)

![Character animation properties in the inspector](../../assets/images/how-to-develop-a-game/adv_tech-character_base_animations-1-inspector.png "Configure custom animation names in the character inspector")

Simply enter your desired animation names in these fields. The engine will automatically use these names when playing animations for the three base sequences:

```gdscript
# These methods will use your custom animation names
character.idle()
character.walk(target_position)
character.say("Hello!", "happy")
```

The animation names you set in the inspector are automatically used by these methods.

!!! info "Outfit changes"
    These variables are meant to instruct the engine about which animation to use for the three basic managed states. Although they can be used to change the outfit or appearance of a character, additional animations should have managed by hand.

    For the purpose of applying costumes, outfits, or other state-changes that apply to **every** animation, see the dedicated [Animation Prefix](../character-animation-prefix) guide.

## About directions and naming conventions

When Popochiu needs to play an animation, it follows this process:

1. When animations are imported via one of the available [importers](../../the-editor-handbook/importers/) it evens them out by forcing _snake_case_ format. The tags in your source file can be in another format though. If the exact animation name you entered isn't found, Popochiu will automatically try the snake_case version. This means you can enter animation names in any case format (camelCase, PascalCase, etc.) and Popochiu will find the corresponding snake_case animations if they exist.

2. Popochiu automatically appends **directional suffixes** to your animation name based on the character's facing direction - `_r` (right), `_dr` (down-right), `_d` (down), and so on. If no directional variant exists, it falls back to the base animation name.

3. If neither the original name nor the _snake_case_ version is found, Popochiu falls back to the standard animation names.

### Example Scenarios

Let's say you have animations named `float_r`, `float_l`, `glide_l`, `glide_wobble`, `say_boo` and your character is **facing right**:

| User Input | Animation Lookup Order | Result |
|------------|------------------------|---------|
| `float` | `float_r`, `float_l`, `float` | Uses `float_r` |
| `Float` | `Float_r`, `Float_l`, `Float`, `float_r`, `float_l`, `float` | Uses `float_r` |
| `GlideWobble` | `GlideWobble_r`, `GlideWobble_l`,` GlideWobble`, `glide_wobble_r`, `glide_wobble_l`, `glide_wobble` | Uses `glide_wobble` |
| `say_boo` | `say_boo_r`, `say_boo_l`, `say_boo` | Uses `say_boo` |
| `boo` | `boo_r`, `boo_l`, `boo` | Uses `talk` |


## Queue Methods

To change animation names dynamically during cutscenes use the queue methods:

```gdscript
await E.queue([
    C.player.queue_say("Let me relax for a moment"),
    C.player.queue_set_idle_animation("relaxed"),
    E.queue_wait(5.0),
    C.player.queue_set_idle_animation("idle"),  # Reset to default
])
```

## Troubleshooting

**Animation not playing?**

- Check that your animation exists in the character's AnimationPlayer
- Verify the animation name matches (matching is case-sensitive with snake_case fallback)
- Make sure directional suffixes are correct if using them

**Wrong animation playing?**

- Popochiu prioritizes directional variants over base animations, check your flipping settings
- Check your animation naming matches the expected pattern

**Inspector changes not taking effect?**

- Remember the game must run in the editor to see the actual idle animation, the sprite in the editor might not reflect the change immediately
- If the game is playing, mind that currently playing animations may need to complete before new names take effect
