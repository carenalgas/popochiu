---
weight: 7330
---

# Comments

## Commenting code

Commenting the code, whether it’s part of the plugin or the engine, is strongly encouraged. Detailed, multi-line comments that explain the reasoning behind a function’s implementation are highly appreciated, as they enhance maintainability and readability for future contributors. Comments not only help maintainers understand your code but also make it easier for other contributors to navigate the codebase.

**Good**:

```{.gdscript .code-example-good}
    # If the path is not empty it has at least two points: the start and the end
    # so we can safely say index 1 is available.
    # The character should face the direction of the next point in the path, then...
    character.face_direction(moving_character_data.path[1])
    # ... we remove the first point of the path since it is the character's current position.
    moving_character_data.path.remove_at(0)
```

**Bad**:

```{.gdscript .code-example-bad}
    # Face the character to the next point in path
    character.face_direction(moving_character_data.path[1])
    moving_character_data.path.remove_at(0)
```

Comments should focus on explaining why the code is written a certain way, rather than what it does (which should already be clear from the code itself). Including references to specific issues in the format `#<issue_number>~` is valid and encouraged, as it provides helpful context to readers.

**Good**:

```{.gdscript .code-example-good}
    # Fixes #322 (Hidden Character are still visible in a room after hiding it).
    # This was expected to be done in function ... but we're doing it here because ...
    Character.visible = false
```

**Bad**:

```{.gdscript .code-example-bad}
    # Fixes a bug that makes a hidden character still visible in a room.
    Character.visible = false
```

All comments, even single-line ones, should start with a capital letter and end with a period. Whenever possible, use single-line comments placed above the relevant code rather than at the end of a line, as this improves clarity and readability.

**Good**:

```{.gdscript .code-example-good}
    # The character is now visible.
    Character.visible = false
```

**Bad**:

```{.gdscript .code-example-bad}
    # the character is now visible
    Character.visible = false
```

---

## Code documentation comments

When adding a **public** or **virtual** method to any of the Engine classes, it is **mandatory** to include documentation comments following the [GDScript documentation comments format](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_documentation_comments.html#gdscript-documentation-comments). These comments ensure that the method is properly documented for both inline consumption within Godot and the code reference exported to the documentation website.

Remember, [you can use _BBCode_ formatting and reference other code elements](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_documentation_comments.html#bbcode-and-class-reference).

The preferred format for public methods is as follows:

### Classes and inner classes

```gdcript
## A brief description of the class's role and functionality.
##
## The description of the script / class, its purpose, what
## it can do, and any further detail.
##
## @tutorial:             https://example.com/tutorial_1
## @experimental
## @deprecated
```

The `@tutorial`, `@experimental`, and `@deprecated` tags are optional. They can all contain descriptions, such as:

```gdscript
## @deprecated: Use [Class OtherClass] instead.
```

### Fuctions and methods

```gdcript
## A brief description of the function, its purpose, what it
## does, and how it relates with other functions (if relevant).
##
## Explain function arguments and return value.
##
## Usage:
## [codeblock]
## ...
##     # Do this in that context
##     my_var = my_function(param, other_param)
##     my_var.some_method()
## ...
## [/codeblock]
```

The `Usage` section is optional but **strongly encouraged** for all non-trivial functions. Including it significantly improves the quality and clarity of Popochiu's public API.

### Enums, Enum values, Signals, Constants and Variables

The preferred format for all these elements is:

```gdscript
## Purpose of the constant
## ... uses that constant to ...
const MY_CONSTANT = "Value"

## Purpose, context and scope of the enum
enum MyEnum {
    ## Meaning of this value
    VALUE_1,
    ## Meaning of this value
    VALUE_2,
    ## Meaning of this value
    VALUE_3,
}

## Emitted when ...
## Arguments contain ...
## ... connects to this signal in order to ....
signal my_signal(arg1: Type, arg2: Type)

## Holds ...
## Defaults to ... (value and meaning)
## Set this to ... for ... and to ... for ...
@export var my_public_var: Type = Class.VALUE
```

Although Godot allows end-of-line comments for these elements, Popochiu adheres to the "above the line" format:

**Good**:

```{.gdscript .code-example-good}
## Documentation comment
var my_public_var: Type
```

**Bad**:

```{.gdscript .code-example-bad}
var my_public_var: Type ## Documentation comment
```

For private methods or classes within the Plugin, writing proper comments in the aforementioned format is encouraged but not required. In these cases, however, **comments should not start with the double hash** (`##`). This distinction is crucial, as only public methods relevant to game developers using Popochiu should appear in the exported code reference. This ensures that the documentation focuses exclusively on scripting functions that assist developers in creating their projects.

```{.gdscript .code-example-good}
# A brief description of this private function, its purpose, what
# it does, and how it relates with other functions (if relevant).
#
# Explain function arguments and return value.
func _my_private_function(arg1: Type) -> Type:
    # ...
```

**Bad**:

```{.gdscript .code-example-bad}
## A brief description of this private function, its purpose, what
## it does, and how it relates with other functions (if relevant).
##
## Explain function arguments and return value.
func _my_private_function(arg1: Type) -> Type:
    # ...
```

Writing private code documentation using the same structure as public documentation but with single-hash comments (`#`) helps explain to other contributors how to use functions within the plugin space effectively.

---

## Admonitions

You can use `TODO:`, `FIXME:`, `IMPROVE:`, or `NOTE:` annotations in your comments when needed. Here's a quick guide to when each should be used:

| **Admonition** | **When to use it** |
| --- | --- |
| `TODO` | Use this when you know some out-of-scope work needs to be done. It's especially helpful if you also include a brief explanation or reasoning to guide future development. |
| `FIXME` | Use this when committing code with known issues or temporary fixes. **Only allowed in draft PRs.** |
| `IMPROVE` | Use this when you recognize that your code could be improved but don't yet know how, or when you know how to improve it but it’s out of scope for the current implementation. |
| `NOTE` | Use this to leave important information for yourself or other contributors. It's ideal for clarifying false code smells, explaining impacts or reasoning behind the code, or highlighting any other critical details that **should** be understood before touching the code. |
