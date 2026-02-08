#!/usr/bin/env python3
"""
BBCode to Markdown Converter for Popochiu Documentation

Converts GDScript documentation BBCode tags to Markdown format,
with support for internal cross-references to Popochiu classes.
"""

import re
from typing import Optional


def get_relative_class_path(
    source_category: str, target_class: str,
    class_to_category: dict[str, str],
    anchor: str = "",
) -> str:
    """
    Compute the relative Markdown path from a source category to a target class.

    Args:
        source_category: Category slug of the class generating the link (or "" for root).
        target_class: Name of the target class.
        class_to_category: Mapping of class name → category slug (or "").
        anchor: Optional anchor fragment (without leading #).

    Returns:
        A relative path like "ClassName.md", "game-objects/ClassName.md",
        or "../game-objects/ClassName.md".
    """
    target_category = class_to_category.get(target_class, "")
    suffix = f"#{anchor}" if anchor else ""

    if source_category == target_category:
        return f"{target_class}.md{suffix}"

    # Build relative path: go up from source, then down to target
    parts = []
    if source_category:
        parts.append("..")
    if target_category:
        parts.append(target_category)
    parts.append(f"{target_class}.md{suffix}")
    return "/".join(parts)


class BBCodeConverter:
    """Converts GDScript BBCode documentation to Markdown."""

    # Known Popochiu classes for cross-referencing
    POPOCHIU_CLASSES = {
        "PopochiuCharacter", "PopochiuClickable", "PopochiuProp", "PopochiuHotspot",
        "PopochiuRegion", "PopochiuRoom", "PopochiuWalkableArea", "PopochiuInventoryItem",
        "PopochiuDialog", "PopochiuDialogOption", "PopochiuAudioCue", "PopochiuMarker",
        "Popochiu", "PopochiuSettings", "PopochiuUtils", "PopochiuGraphicInterface",
        "PopochiuICharacter", "PopochiuIDialog", "PopochiuIInventory", "PopochiuIRoom",
        "PopochiuIGraphicInterface", "PopochiuIAudio",
    }

    # Godot built-in classes for external linking
    GODOT_CLASSES = {
        # Variant types (core built-in types)
        "Variant", "AABB", "Array", "Basis", "bool", "Callable", "Color", "Dictionary",
        "float", "int", "NodePath", "Object", "PackedByteArray", "PackedColorArray",
        "PackedFloat32Array", "PackedFloat64Array", "PackedInt32Array", "PackedInt64Array",
        "PackedStringArray", "PackedVector2Array", "PackedVector3Array", "PackedVector4Array",
        "Plane", "Projection", "Quaternion", "Rect2", "Rect2i", "RID", "Signal", "String",
        "StringName", "Transform2D", "Transform3D", "Vector2", "Vector2i", "Vector3",
        "Vector3i", "Vector4", "Vector4i",
        # Common Node types
        "Node", "Node2D", "Node3D", "Control", "Resource", "RefCounted",
        "CanvasItem", "Viewport", "SceneTree", "Window",
        # Commonly referenced classes in docs
        "AnimationPlayer", "AnimatedSprite2D", "Sprite2D", "Sprite3D", "Label", "Button",
        "CollisionPolygon2D", "CollisionShape2D", "CollisionShape3D",
        "NavigationObstacle2D", "NavigationRegion2D", "NavigationAgent2D",
        "Marker2D", "Marker3D", "Area2D", "Area3D", "Camera2D", "Camera3D",
        "CharacterBody2D", "CharacterBody3D", "RigidBody2D", "RigidBody3D",
        "StaticBody2D", "StaticBody3D", "PhysicsBody2D", "PhysicsBody3D",
        "Tween", "Timer", "AudioStreamPlayer", "AudioStreamPlayer2D", "AudioStreamPlayer3D",
        "Texture2D", "Texture", "AudioStream", "PackedScene", "TileMap", "TileMapLayer",
        "Engine", "Input", "InputEvent", "InputEventMouse", "InputEventMouseButton",
        "InputEventMouseMotion", "InputEventKey", "InputEventAction",
    }

    def __init__(self, current_class: str = "", known_classes: Optional[set[str]] = None,
                 source_category: str = "", class_to_category: Optional[dict[str, str]] = None):
        """
        Initialize the converter.

        Args:
            current_class: The name of the class being documented (for self-references)
            known_classes: Additional known classes for cross-referencing
            source_category: Category slug of the class being documented (for relative paths)
            class_to_category: Mapping of class name → category slug for all known classes
        """
        self.current_class = current_class
        self.known_classes = known_classes or set()
        self.all_known_classes = self.POPOCHIU_CLASSES | self.known_classes
        self.source_category = source_category
        self.class_to_category = class_to_category or {}

    def _get_class_path(self, target_class: str, anchor: str = "") -> str:
        """Get the relative path to a Popochiu class, respecting categories."""
        return get_relative_class_path(
            self.source_category, target_class,
            self.class_to_category, anchor,
        )

    def convert(self, text: str) -> str:
        """Convert BBCode text to Markdown."""
        if not text:
            return ""

        result = text

        # Process code blocks first (to avoid processing BBCode inside them)
        result = self._convert_codeblocks(result)

        # Convert inline BBCode tags
        result = self._convert_code(result)
        result = self._convert_param(result)
        result = self._convert_member(result)
        result = self._convert_method(result)
        result = self._convert_signal(result)
        result = self._convert_constant(result)
        result = self._convert_enum(result)
        result = self._convert_formatting(result)
        result = self._convert_links(result)
        result = self._convert_references(result)
        result = self._convert_line_breaks(result)

        return result

    def _convert_codeblocks(self, text: str) -> str:
        """Convert [codeblock] tags to fenced code blocks."""
        # [codeblock]...[/codeblock] -> ```gdscript...```
        pattern = r'\[codeblock\](.*?)\[/codeblock\]'

        def replace_codeblock(match: re.Match) -> str:
            code = match.group(1).strip()
            return f"\n```gdscript\n{code}\n```\n"

        return re.sub(pattern, replace_codeblock, text, flags=re.DOTALL)

    def _convert_code(self, text: str) -> str:
        """Convert [code] tags to inline code."""
        # [code]...[/code] -> `...`
        return re.sub(r'\[code\](.*?)\[/code\]', r'`\1`', text)

    def _convert_param(self, text: str) -> str:
        """Convert [param] tags to emphasized parameter references."""
        # [param name] -> `name`
        return re.sub(r'\[param\s+(\w+)\]', r'`\1`', text)

    def _convert_member(self, text: str) -> str:
        """Convert [member] tags to property references."""
        # [member property] -> `property`
        # [member Class.property] -> `Class.property`
        def replace_member(match: re.Match) -> str:
            ref = match.group(1)
            if "." in ref:
                class_name, prop = ref.split(".", 1)
                if class_name in self.all_known_classes:
                    anchor = prop.lower().replace('_', '-')
                    path = self._get_class_path(class_name, anchor)
                    return f"[`{prop}`]({path})"
                elif class_name in self.GODOT_CLASSES:
                    return f"[`{ref}`](https://docs.godotengine.org/en/stable/classes/class_{class_name.lower()}.html#class-{class_name.lower()}-property-{prop.lower().replace('_', '-')})"
            return f"`{ref}`"

        return re.sub(r'\[member\s+([\w.]+)\]', replace_member, text)

    def _convert_method(self, text: str) -> str:
        """Convert [method] tags to method references."""
        # [method name] -> `name()`
        # [method Class.name] -> link to Class.name
        def replace_method(match: re.Match) -> str:
            ref = match.group(1)
            if "." in ref:
                class_name, method = ref.split(".", 1)
                if class_name in self.all_known_classes:
                    anchor = method.lower().replace('_', '-')
                    path = self._get_class_path(class_name, anchor)
                    return f"[`{method}()`]({path})"
                elif class_name in self.GODOT_CLASSES:
                    return f"[`{method}()`](https://docs.godotengine.org/en/stable/classes/class_{class_name.lower()}.html#class-{class_name.lower()}-method-{method.lower().replace('_', '-')})"
            # Same class reference
            anchor = ref.lower().replace("_", "-")
            return f"[`{ref}()`](#{anchor})"

        return re.sub(r'\[method\s+([\w.]+)\]', replace_method, text)

    def _convert_signal(self, text: str) -> str:
        """Convert [signal] tags to signal references."""
        # [signal name] -> link to signal
        def replace_signal(match: re.Match) -> str:
            ref = match.group(1)
            if "." in ref:
                class_name, signal = ref.split(".", 1)
                if class_name in self.all_known_classes:
                    path = self._get_class_path(class_name, "signals")
                    return f"[`{signal}`]({path})"
            anchor = ref.lower().replace("_", "-")
            return f"[`{ref}`](#signal-{anchor})"

        return re.sub(r'\[signal\s+([\w.]+)\]', replace_signal, text)

    def _convert_constant(self, text: str) -> str:
        """Convert [constant] tags to constant references."""
        # [constant NAME] -> `NAME`
        # [constant Class.NAME] -> link
        def replace_constant(match: re.Match) -> str:
            ref = match.group(1)
            if "." in ref:
                class_name, const = ref.split(".", 1)
                if class_name in self.all_known_classes:
                    path = self._get_class_path(class_name, "constants")
                    return f"[`{const}`]({path})"
            return f"`{ref}`"

        return re.sub(r'\[constant\s+([\w.]+)\]', replace_constant, text)

    def _convert_enum(self, text: str) -> str:
        """Convert [enum] tags to enum references."""
        # [enum EnumName] -> link to enum
        def replace_enum(match: re.Match) -> str:
            ref = match.group(1)
            if "." in ref:
                class_name, enum = ref.split(".", 1)
                if class_name in self.all_known_classes:
                    anchor = f"enum-{enum.lower().replace('_', '-')}"
                    path = self._get_class_path(class_name, anchor)
                    return f"[`{enum}`]({path})"
            anchor = ref.lower().replace("_", "-")
            return f"[`{ref}`](#enum-{anchor})"

        return re.sub(r'\[enum\s+([\w.]+)\]', replace_enum, text)

    def _convert_formatting(self, text: str) -> str:
        """Convert formatting BBCode tags."""
        # [b]...[/b] -> **...**
        text = re.sub(r'\[b\](.*?)\[/b\]', r'**\1**', text)

        # [i]...[/i] -> *...*
        text = re.sub(r'\[i\](.*?)\[/i\]', r'*\1*', text)

        # [u]...[/u] -> <u>...</u> (HTML underline, limited MD support)
        text = re.sub(r'\[u\](.*?)\[/u\]', r'<u>\1</u>', text)

        # [s]...[/s] -> ~~...~~ (strikethrough)
        text = re.sub(r'\[s\](.*?)\[/s\]', r'~~\1~~', text)

        return text

    def _convert_links(self, text: str) -> str:
        """Convert URL BBCode tags."""
        # [url]link[/url] -> <link>
        text = re.sub(r'\[url\](.*?)\[/url\]', r'<\1>', text)

        # [url=link]text[/url] -> [text](link)
        text = re.sub(r'\[url=([^\]]+)\](.*?)\[/url\]', r'[\2](\1)', text)

        return text

    def _convert_references(self, text: str) -> str:
        """Convert class references [ClassName] to links."""
        def replace_class_ref(match: re.Match) -> str:
            class_name = match.group(1)

            # Skip if it looks like a BBCode tag we already processed
            if class_name.lower() in ("code", "param", "member", "method", "signal", 
                                       "constant", "enum", "b", "i", "u", "s", "url",
                                       "codeblock", "br"):
                return match.group(0)

            # Popochiu class reference
            if class_name in self.all_known_classes:
                path = self._get_class_path(class_name)
                return f"[{class_name}]({path})"

            # Godot class reference
            if class_name in self.GODOT_CLASSES:
                return f"[{class_name}](https://docs.godotengine.org/en/stable/classes/class_{class_name.lower()}.html)"

            # Unknown, keep as-is but make it code
            return f"`{class_name}`"

        # Match [ClassName] but not [tag ...] or [tag=...]
        return re.sub(r'\[([A-Z]\w+)\](?!\()', replace_class_ref, text)

    def _convert_line_breaks(self, text: str) -> str:
        """Convert [br] tags to line breaks."""
        # [br] -> <br> or double newline
        text = re.sub(r'\[br\]', '  \n', text)

        return text


def convert_description(text: str, current_class: str = "", 
                       known_classes: Optional[set[str]] = None,
                       source_category: str = "",
                       class_to_category: Optional[dict[str, str]] = None) -> str:
    """
    Convenience function to convert a description string.

    Args:
        text: The BBCode text to convert
        current_class: The current class name for self-references
        known_classes: Set of known class names for cross-referencing
        source_category: Category slug of the source class
        class_to_category: Mapping of class name → category slug

    Returns:
        Markdown-formatted text
    """
    converter = BBCodeConverter(current_class, known_classes,
                                source_category, class_to_category)
    return converter.convert(text)


if __name__ == "__main__":
    # Test the converter
    test_cases = [
        # Basic formatting
        "[b]bold[/b] and [i]italic[/i]",
        # Code
        "[code]var x = 5[/code]",
        # Parameters
        "The [param target_pos] parameter",
        # Method references
        "See [method walk] and [method PopochiuCharacter.say]",
        # Member references
        "Uses [member walk_speed]",
        # Class references
        "Returns a [PopochiuCharacter]",
        # Godot class
        "Takes a [Vector2] position",
        # Code blocks
        "[codeblock]\nfunc test():\n    pass\n[/codeblock]",
        # Line breaks
        "Line one[br]Line two",
        # Complex example
        """Calls [method _play_talk] and emits [signal character_spoke] sending itself as parameter.
You can specify the emotion to use with [param emo]. If an [AudioCue] is defined for the emotion,
it is played. Once the talk animation finishes, the characters return to its idle state.[br][br]
[i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]""",
    ]

    converter = BBCodeConverter("PopochiuCharacter")

    for test in test_cases:
        print("Input:", test[:50] + "..." if len(test) > 50 else test)
        print("Output:", converter.convert(test)[:80] + "..." if len(converter.convert(test)) > 80 else converter.convert(test))
        print("-" * 40)
