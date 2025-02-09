---
weight: 9340
---

# Naming conventions

In addition to the formatting rules outlined in the [GDScript Style Guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html), Popochiu defines a small set of specific naming conventions.

## Classes

All engine and plugin class names **must** begin with `Popochiu`. This compensates for the lack of namespacing in the GDScript language. This rule may (and likely will) change in the future if GDScript introduces proper namespace support.

**Good**:

```{.gdscript .code-example-good}
class PopochiuSuperMagicStuff
```

**Bad**:

```{.gdscript .code-example-bad}
class SuperMagicStuff
```

All classes must be explicitly named. The only exception is for scripts used solely for inheritance and never instantiated by the end user (see `factory_based_popochiu_obj.gd` as an example). However, naming these scripts is still encouraged to enforce strong typing.

## Functions and Variables

The primary rule for functions and variables is to use names that are both explicit **and** relevant. Don't be stingy; keystrokes are free!

**Good**:

```{.gdscript .code-example-good}
func move_handler():
    # ...
var handler_to_move
```

**Bad** (implicit, cryptic):

```{.gdscript .code-example-bad}
func mh():
    # ...
var htm
```

**Also bad** (irrelevant, non-descriptive):

```{.gdscript .code-example-bad}
func doStuff():
    # ...
var myHandler
```

When naming public members that refer to an instance of their class, try to make them read natural when invoked by the client code:

**Good**:

```{.gdscript .code-example-good}
class PopochiuCharacter:
    # ...
    func move_to(target_pos: Vector2) -> void:
        # ...

# In client code
Hero.move_to(_last_clicked.position)
```

**Bad**:

```{.gdscript .code-example-bad}
class PopochiuCharacter:
    # ...
    func move_character(target_pos: Vector2) -> void:
        # ...

# In client code (note how this reads poorly)
Hero.move_character(_last_clicked.position)
```

## Script names

There is no strict rule for script naming. The only best practice we enforce is to name scripts after the class they contain, following Godot's `snake_case` convention. Historically, Popochiu code has mixed file names that start with `popochiu` and those that do not, even if the contained class starts with `Popochiu`.

This redundancy can be safely omitted, and maybe in the future we'll settle on a specific format for that. In the meantime, you are free to name your scripts in the way that feels most clear to you.

**Good**:

```{.text .code-example-good}
cursor.gd -> contains PopochiuCursor class
```

**Also good**:

```{.text .code-example-good}
popochiu_cursor.gd -> contains PopochiuCursor class
```

**Bad**:

```{.gdscript .code-example-bad}
crsr.gd -> not named after the PopochiuCursor class it contains
PopochiuCursor.gd -> does not follow Godot's file naming conventions
```

!!! note
    File naming guidelines for documentation and assets can be found in the [Contributing documentation](TBD) section.
