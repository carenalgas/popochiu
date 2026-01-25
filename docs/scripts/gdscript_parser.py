#!/usr/bin/env python3
"""
GDScript Parser for Popochiu Documentation Generation

Parses GDScript files to extract documentation from ## comments,
including classes, properties, methods, signals, enums, and constants.
"""

import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional
from enum import Enum, auto


class MemberType(Enum):
    """Types of class members that can be documented."""
    SIGNAL = auto()
    CONSTANT = auto()
    ENUM = auto()
    ENUM_VALUE = auto()
    PROPERTY = auto()
    METHOD = auto()


@dataclass
class DocComment:
    """Represents a documentation comment block."""
    text: str
    is_virtual: bool = False

    @classmethod
    def from_lines(cls, lines: list[str]) -> "DocComment":
        """Create a DocComment from a list of comment lines."""
        text = "\n".join(lines).strip()
        is_virtual = "[i]Virtual[/i]" in text or "_Virtual_" in text
        return cls(text=text, is_virtual=is_virtual)


@dataclass
class SignalInfo:
    """Represents a signal definition."""
    name: str
    parameters: list[tuple[str, str]]  # (name, type)
    description: str = ""
    annotations: set[str] = field(default_factory=set)

    @property
    def signature(self) -> str:
        """Get the signal signature string."""
        params = ", ".join(
            f"{name}: {type_}" if type_ else name 
            for name, type_ in self.parameters
        )
        return f"{self.name}({params})"


@dataclass
class ConstantInfo:
    """Represents a constant definition."""
    name: str
    value: str
    type_hint: str = ""
    description: str = ""
    annotations: set[str] = field(default_factory=set)

@dataclass
class EnumValue:
    """Represents a single enum value."""
    name: str
    value: Optional[int]
    description: str = ""


@dataclass
class EnumInfo:
    """Represents an enum definition."""
    name: str
    values: list[EnumValue] = field(default_factory=list)
    description: str = ""
    annotations: set[str] = field(default_factory=set)


@dataclass
class PropertyInfo:
    """Represents a property/variable definition."""
    name: str
    type_hint: str = ""
    default_value: str = ""
    description: str = ""
    is_exported: bool = False
    export_hint: str = ""
    getter: str = ""
    setter: str = ""
    annotations: set[str] = field(default_factory=set)


@dataclass 
class ParameterInfo:
    """Represents a function parameter."""
    name: str
    type_hint: str = ""
    default_value: str = ""


@dataclass
class MethodInfo:
    """Represents a method/function definition."""
    name: str
    parameters: list[ParameterInfo] = field(default_factory=list)
    return_type: str = ""
    description: str = ""
    is_virtual: bool = False
    is_static: bool = False
    annotations: set[str] = field(default_factory=set)

    @property
    def signature(self) -> str:
        """Get the method signature string."""
        params = ", ".join(
            f"{p.name}: {p.type_hint}" + (f" = {p.default_value}" if p.default_value else "")
            if p.type_hint else p.name + (f" = {p.default_value}" if p.default_value else "")
            for p in self.parameters
        )
        ret = f" -> {self.return_type}" if self.return_type else ""
        return f"{self.name}({params}){ret}"


@dataclass
class ClassInfo:
    """Represents a complete GDScript class."""
    name: str
    file_path: str
    extends: str = ""
    icon: str = ""
    description: str = ""
    signals: list[SignalInfo] = field(default_factory=list)
    constants: list[ConstantInfo] = field(default_factory=list)
    enums: list[EnumInfo] = field(default_factory=list)
    properties: list[PropertyInfo] = field(default_factory=list)
    methods: list[MethodInfo] = field(default_factory=list)
    is_tool: bool = False
    is_class_ignored: bool = False


class GDScriptParser:
    """Parser for GDScript files that extracts documentation."""

    # Regex patterns for parsing
    PATTERNS = {
        "class_name": re.compile(r"^class_name\s+(\w+)"),
        "extends": re.compile(r"^extends\s+(\w+)"),
        "icon": re.compile(r'^@icon\s*\(\s*["\'](.+?)["\']\s*\)'),
        "tool": re.compile(r"^@tool\b"),
        "doc_comment": re.compile(r"^##\s?(.*)$"),
        "single_comment": re.compile(r"^#\s?(.*)$"),
        "annotation": re.compile(r"@popochiu-docs-(ignore-class|ignore|include)"),
        "signal": re.compile(
            r"^signal\s+(\w+)(?:\s*\(([^)]*)\))?"
        ),
        "const": re.compile(
            r"^const\s+(\w+)(?:\s*:\s*(\w+))?\s*=\s*(.+)$"
        ),
        "enum_start": re.compile(r"^enum\s+(\w+)\s*\{"),
        "enum_inline": re.compile(r"^enum\s+(\w+)\s*\{([^}]+)\}"),
        "var": re.compile(
            r"^(?:@export(?:_\w+)?(?:\s*\([^)]*\))?\s+)?var\s+(\w+)"
        ),
        "export": re.compile(r"^@export(?:_(\w+))?(?:\s*\(([^)]*)\))?"),
        "func": re.compile(r"^(?:static\s+)?func\s+(\w+)\s*\("),
        "static_func": re.compile(r"^static\s+func\s+"),
        "type_hint": re.compile(r":\s*(\w+(?:\[[\w,\s]+\])?)"),
        "default_value": re.compile(r"=\s*(.+?)(?:\s*:\s*set|\s*$)"),
        "setter_getter": re.compile(r":\s*(?:set\s*=\s*(\w+)|get\s*=\s*(\w+))"),
        "return_type": re.compile(r"\)\s*->\s*(\w+(?:\[[\w,\s]+\])?)"),
        "region": re.compile(r"^#region\s+(.*)$"),
        "endregion": re.compile(r"^#endregion"),
    }

    def __init__(self):
        self.current_doc_lines: list[str] = []
        self.current_class: Optional[ClassInfo] = None
        self.in_enum: bool = False
        self.current_enum: Optional[EnumInfo] = None
        self.enum_value_docs: dict[str, str] = {}
        self.brace_depth: int = 0
        self.indent_level: int = 0  # Track indentation to distinguish class vs local variables
        # Annotation tracking
        self.current_annotations: set[str] = set()
        self.pending_annotation_line: Optional[int] = None  # Line number of unresolved annotation
        self.pending_annotation_type: Optional[str] = None  # Type of unresolved annotation
        self.warnings: list[str] = []  # Accumulated warnings
        self.in_function: bool = False  # Track if we're inside a function body

    def parse_file(self, file_path: Path) -> Optional[ClassInfo]:
        """Parse a GDScript file and extract class documentation."""
        try:
            content = file_path.read_text(encoding="utf-8")
        except Exception as e:
            print(f"Error reading {file_path}: {e}")
            return None

        return self.parse_content(content, str(file_path))

    def parse_content(self, content: str, file_path: str = "") -> Optional[ClassInfo]:
        """Parse GDScript content and extract class documentation."""
        self.current_doc_lines = []
        self.current_class = None
        self.in_enum = False
        self.current_enum = None
        self.enum_value_docs = {}
        self.brace_depth = 0
        self.indent_level = 0
        self.in_function = False
        self.current_annotations = set()
        self.pending_annotation_line = None
        self.pending_annotation_type = None
        self.warnings = []

        lines = content.split("\n")

        # Check for @popochiu-docs-ignore-class anywhere in file
        is_class_ignored = any(
            "@popochiu-docs-ignore-class" in line for line in lines
        )

        # First pass: find class_name and basic info
        class_name = Path(file_path).stem if file_path else "Unknown"
        extends = ""
        icon = ""
        is_tool = False
        class_description_lines = []

        i = 0
        collecting_class_docs = False  # Track if we've started collecting class docs
        while i < len(lines):
            line = lines[i].strip()

            # Check for @tool
            if self.PATTERNS["tool"].match(line):
                is_tool = True
                i += 1
                continue

            # Check for @icon
            icon_match = self.PATTERNS["icon"].match(line)
            if icon_match:
                icon = icon_match.group(1)
                i += 1
                continue

            # Check for class_name
            class_match = self.PATTERNS["class_name"].match(line)
            if class_match:
                class_name = class_match.group(1)
                i += 1
                continue

            # Check for extends
            extends_match = self.PATTERNS["extends"].match(line)
            if extends_match:
                extends = extends_match.group(1)
                i += 1
                continue

            # Collect class-level doc comments (before any member)
            doc_match = self.PATTERNS["doc_comment"].match(line)
            if doc_match:
                class_description_lines.append(doc_match.group(1))
                collecting_class_docs = True
                i += 1
                continue

            # Blank line after class docs ends class description collection
            if not line and collecting_class_docs:
                i += 1
                break

            # Handle single-hash comments
            if line.startswith("#") and not line.startswith("##"):
                # Check for annotation
                annotation_match = self.PATTERNS["annotation"].search(line)
                if annotation_match:
                    annotation_type = annotation_match.group(1)
                    # ignore-class is fine, continue first pass
                    if annotation_type != "ignore-class":
                        # Member-level annotation, stop first pass
                        break
                # Non-annotation single-hash comment, continue
                i += 1
                continue

            # Stop collecting class docs when we hit a member definition
            if line:
                break

            i += 1

        self.current_class = ClassInfo(
            name=class_name,
            file_path=file_path,
            extends=extends,
            icon=icon,
            description="\n".join(class_description_lines).strip(),
            is_tool=is_tool,
            is_class_ignored=is_class_ignored,
        )

        # Second pass: parse members
        self.current_doc_lines = []

        while i < len(lines):
            line = lines[i]
            stripped = line.strip()

            # Calculate indentation level (tabs or spaces)
            indent = len(line) - len(line.lstrip())
            is_class_level = indent == 0 and stripped != ""

            # Track if we're entering/exiting a function
            func_match = self.PATTERNS["func"].match(stripped)
            if func_match and is_class_level:
                self.in_function = True
            elif is_class_level and not stripped.startswith("#") and not stripped.startswith("@"):
                # Any class-level non-comment line that's not a function means we exited
                if not func_match:
                    self.in_function = False

            # Track brace depth for multi-line constructs
            self.brace_depth += stripped.count("{") - stripped.count("}")

            # Check for member annotation in single-hash comment (only at class level)
            # Must be on immediate line before a docblock
            if stripped.startswith("#") and not stripped.startswith("##"):
                annotation_match = self.PATTERNS["annotation"].search(stripped)
                if annotation_match and (is_class_level or indent == 0):
                    annotation_type = annotation_match.group(1)
                    # ignore-class is handled at file level, skip member handling
                    if annotation_type != "ignore-class":
                        # If there's already a pending annotation, warn about it
                        if self.pending_annotation_line is not None:
                            self.warnings.append(
                                f"Warning: @popochiu-docs-{self.pending_annotation_type} at "
                                f"{file_path}:{self.pending_annotation_line} has no docblock below it"
                            )
                        self.pending_annotation_line = i + 1  # 1-based line number
                        self.pending_annotation_type = annotation_type
                i += 1
                continue

            # Handle doc comments (only at class level)
            doc_match = self.PATTERNS["doc_comment"].match(stripped)
            if doc_match:
                # Only collect doc comments at class level
                if is_class_level or indent == 0:
                    # If this is the first doc line and we have a pending annotation,
                    # transfer it to current_annotations
                    if not self.current_doc_lines and self.pending_annotation_line is not None:
                        self.current_annotations.add(self.pending_annotation_type)
                        self.pending_annotation_line = None
                        self.pending_annotation_type = None
                    self.current_doc_lines.append(doc_match.group(1))
                i += 1
                continue

            # Any non-comment, non-empty line invalidates pending annotations
            if stripped and self.pending_annotation_line is not None:
                self.warnings.append(
                    f"Warning: @popochiu-docs-{self.pending_annotation_type} at "
                    f"{file_path}:{self.pending_annotation_line} has no docblock below it"
                )
                self.pending_annotation_line = None
                self.pending_annotation_type = None

            # Handle enum parsing
            if self.in_enum:
                i = self._parse_enum_content(lines, i)
                continue

            # Skip everything that's not at class level (indented code = inside function)
            if not is_class_level:
                i += 1
                continue

            # Check for enum start
            enum_inline = self.PATTERNS["enum_inline"].match(stripped)
            if enum_inline:
                self._handle_inline_enum(enum_inline)
                self.current_doc_lines = []
                self.current_annotations = set()
                i += 1
                continue

            enum_start = self.PATTERNS["enum_start"].match(stripped)
            if enum_start:
                self._start_enum(enum_start.group(1))
                # Check if enum continues on next lines
                if "{" in stripped and "}" not in stripped:
                    self.in_enum = True
                i += 1
                continue

            # Check for signal
            signal_match = self.PATTERNS["signal"].match(stripped)
            if signal_match:
                self._handle_signal(signal_match, stripped)
                self.current_doc_lines = []
                self.current_annotations = set()
                i += 1
                continue

            # Check for constant
            const_match = self.PATTERNS["const"].match(stripped)
            if const_match:
                self._handle_constant(const_match)
                self.current_doc_lines = []
                self.current_annotations = set()
                i += 1
                continue

            # Check for variable/property
            var_match = self.PATTERNS["var"].match(stripped)
            if var_match:
                self._handle_variable(stripped, var_match)
                self.current_doc_lines = []
                self.current_annotations = set()
                i += 1
                continue

            # Check for function
            func_match = self.PATTERNS["func"].match(stripped)
            if func_match:
                # Collect full function signature (may span multiple lines)
                func_lines = [stripped]
                while ")" not in func_lines[-1] or (
                    func_lines[-1].count("(") > func_lines[-1].count(")")
                ):
                    i += 1
                    if i >= len(lines):
                        break
                    func_lines.append(lines[i].strip())

                full_sig = " ".join(func_lines)
                self._handle_function(full_sig)
                self.current_doc_lines = []
                self.current_annotations = set()
                i += 1
                continue

            # Clear doc lines and annotations if we hit a non-doc line that's not empty
            if stripped and not stripped.startswith("#"):
                self.current_doc_lines = []
                self.current_annotations = set()

            i += 1

        return self.current_class

    def _parse_enum_content(self, lines: list[str], start_idx: int) -> int:
        """Parse enum values from content."""
        i = start_idx
        line = lines[i].strip()

        # Check for enum value doc comment
        doc_match = self.PATTERNS["doc_comment"].match(line)
        if doc_match:
            self.current_doc_lines.append(doc_match.group(1))
            return i + 1

        # Check for end of enum
        if "}" in line:
            # Parse any values on this line before the closing brace
            content = line.split("}")[0]
            self._parse_enum_values(content)

            if self.current_enum and self.current_class:
                self.current_class.enums.append(self.current_enum)

            self.in_enum = False
            self.current_enum = None
            self.current_doc_lines = []
            return i + 1

        # Parse enum values on this line
        self._parse_enum_values(line)
        self.current_doc_lines = []
        return i + 1

    def _parse_enum_values(self, content: str) -> None:
        """Parse enum values from a line of content."""
        if not self.current_enum:
            return

        # Split by comma, handling potential inline comments
        parts = content.split(",")
        for part in parts:
            part = part.strip()
            if not part or part.startswith("#"):
                continue

            # Remove inline comments
            if "#" in part:
                part = part.split("#")[0].strip()

            # Parse value assignment
            if "=" in part:
                name, value = part.split("=", 1)
                name = name.strip()
                try:
                    value = int(value.strip())
                except ValueError:
                    value = None
            else:
                name = part.strip()
                value = None

            if name:
                description = "\n".join(self.current_doc_lines).strip()
                self.current_enum.values.append(
                    EnumValue(name=name, value=value, description=description)
                )
                self.current_doc_lines = []

    def _handle_inline_enum(self, match: re.Match) -> None:
        """Handle a single-line enum definition."""
        name = match.group(1)
        content = match.group(2)

        enum_info = EnumInfo(
            name=name,
            description="\n".join(self.current_doc_lines).strip(),
            annotations=self.current_annotations.copy(),
        )

        # Parse values
        for part in content.split(","):
            part = part.strip()
            if not part:
                continue

            if "=" in part:
                val_name, val = part.split("=", 1)
                val_name = val_name.strip()
                try:
                    val = int(val.strip())
                except ValueError:
                    val = None
            else:
                val_name = part.strip()
                val = None

            if val_name:
                enum_info.values.append(EnumValue(name=val_name, value=val))

        if self.current_class:
            self.current_class.enums.append(enum_info)

    def _start_enum(self, name: str) -> None:
        """Start parsing a multi-line enum."""
        self.current_enum = EnumInfo(
            name=name,
            description="\n".join(self.current_doc_lines).strip(),
            annotations=self.current_annotations.copy(),
        )
        self.current_doc_lines = []
        self.current_annotations = set()

    def _handle_signal(self, match: re.Match, full_line: str) -> None:
        """Handle a signal definition."""
        name = match.group(1)
        params_str = match.group(2) or ""

        parameters = []
        if params_str.strip():
            for param in params_str.split(","):
                param = param.strip()
                if not param:
                    continue

                # Parse parameter type hint
                if ":" in param:
                    pname, ptype = param.split(":", 1)
                    parameters.append((pname.strip(), ptype.strip()))
                else:
                    parameters.append((param, ""))

        signal_info = SignalInfo(
            name=name,
            parameters=parameters,
            description="\n".join(self.current_doc_lines).strip(),
            annotations=self.current_annotations.copy(),
        )

        if self.current_class:
            self.current_class.signals.append(signal_info)

    def _handle_constant(self, match: re.Match) -> None:
        """Handle a constant definition."""
        name = match.group(1)
        type_hint = match.group(2) or ""
        value = match.group(3).strip()

        const_info = ConstantInfo(
            name=name,
            value=value,
            type_hint=type_hint,
            description="\n".join(self.current_doc_lines).strip(),
            annotations=self.current_annotations.copy(),
        )

        if self.current_class:
            self.current_class.constants.append(const_info)

    def _handle_variable(self, line: str, match: re.Match) -> None:
        """Handle a variable/property definition."""
        name = match.group(1)

        # Check if exported
        is_exported = "@export" in line
        export_hint = ""
        export_match = self.PATTERNS["export"].match(line)
        if export_match:
            export_type = export_match.group(1) or ""
            export_args = export_match.group(2) or ""
            if export_type:
                export_hint = f"@export_{export_type}"
                if export_args:
                    export_hint += f"({export_args})"
            elif export_args:
                export_hint = f"@export({export_args})"
            else:
                export_hint = "@export"

        # Extract type hint
        type_hint = ""
        # Look for type after variable name
        after_name = line.split(name, 1)[1] if name in line else ""
        type_match = self.PATTERNS["type_hint"].match(after_name)
        if type_match:
            type_hint = type_match.group(1)

        # Extract default value
        default_value = ""
        if "=" in line:
            # Get everything after = but before : set or : get
            after_eq = line.split("=", 1)[1]
            # Remove setter/getter syntax
            after_eq = re.sub(r":\s*set\s*=.*", "", after_eq)
            after_eq = re.sub(r":\s*get\s*=.*", "", after_eq)
            after_eq = re.sub(r":\s*set\s*$", "", after_eq)
            after_eq = re.sub(r":\s*get\s*$", "", after_eq)
            default_value = after_eq.strip()

        # Extract setter/getter
        getter = ""
        setter = ""
        setter_match = re.search(r"set\s*=\s*(\w+)", line)
        getter_match = re.search(r"get\s*=\s*(\w+)", line)
        if setter_match:
            setter = setter_match.group(1)
        if getter_match:
            getter = getter_match.group(1)

        prop_info = PropertyInfo(
            name=name,
            type_hint=type_hint,
            default_value=default_value,
            description="\n".join(self.current_doc_lines).strip(),
            is_exported=is_exported,
            export_hint=export_hint,
            getter=getter,
            setter=setter,
            annotations=self.current_annotations.copy(),
        )

        if self.current_class:
            self.current_class.properties.append(prop_info)

    def _handle_function(self, full_sig: str) -> None:
        """Handle a function/method definition."""
        # Check if static
        is_static = self.PATTERNS["static_func"].match(full_sig) is not None

        # Extract function name
        func_match = self.PATTERNS["func"].search(full_sig)
        if not func_match:
            return

        name = func_match.group(1)

        # Extract parameters
        params_start = full_sig.index("(") + 1
        # Find matching closing paren
        depth = 1
        params_end = params_start
        for i, c in enumerate(full_sig[params_start:], params_start):
            if c == "(":
                depth += 1
            elif c == ")":
                depth -= 1
                if depth == 0:
                    params_end = i
                    break

        params_str = full_sig[params_start:params_end]
        parameters = self._parse_parameters(params_str)

        # Extract return type
        return_type = ""
        return_match = self.PATTERNS["return_type"].search(full_sig[params_end:])
        if return_match:
            return_type = return_match.group(1)

        # Check if virtual from doc
        description = "\n".join(self.current_doc_lines).strip()
        is_virtual = "[i]Virtual[/i]" in description or "_Virtual_" in description

        method_info = MethodInfo(
            name=name,
            parameters=parameters,
            return_type=return_type,
            description=description,
            is_virtual=is_virtual,
            is_static=is_static,
            annotations=self.current_annotations.copy(),
        )

        if self.current_class:
            self.current_class.methods.append(method_info)

    def _parse_parameters(self, params_str: str) -> list[ParameterInfo]:
        """Parse function parameters from a string."""
        parameters = []
        if not params_str.strip():
            return parameters

        # Split by comma, but respect nested structures
        depth = 0
        current = []
        for char in params_str:
            if char in "([{":
                depth += 1
                current.append(char)
            elif char in ")]}":
                depth -= 1
                current.append(char)
            elif char == "," and depth == 0:
                param_str = "".join(current).strip()
                if param_str:
                    parameters.append(self._parse_single_param(param_str))
                current = []
            else:
                current.append(char)

        # Don't forget the last parameter
        param_str = "".join(current).strip()
        if param_str:
            parameters.append(self._parse_single_param(param_str))

        return parameters

    def _parse_single_param(self, param_str: str) -> ParameterInfo:
        """Parse a single parameter string."""
        param_str = param_str.strip()

        name = ""
        type_hint = ""
        default_value = ""

        # Check for default value
        if "=" in param_str:
            param_part, default_value = param_str.rsplit("=", 1)
            param_str = param_part.strip()
            default_value = default_value.strip()

        # Check for type hint
        if ":" in param_str:
            name, type_hint = param_str.split(":", 1)
            name = name.strip()
            type_hint = type_hint.strip()
        else:
            name = param_str

        return ParameterInfo(
            name=name,
            type_hint=type_hint,
            default_value=default_value,
        )

    def get_warnings(self) -> list[str]:
        """Return any warnings generated during parsing."""
        return self.warnings.copy()


def parse_directory(directory: Path, recursive: bool = True) -> tuple[list[ClassInfo], list[str]]:
    """
    Parse all GDScript files in a directory.

    Returns:
        Tuple of (classes, warnings) where warnings is a list of warning messages.
    """
    parser = GDScriptParser()
    classes = []
    all_warnings = []

    pattern = "**/*.gd" if recursive else "*.gd"
    for file_path in directory.glob(pattern):
        # Skip private files (starting with _)
        if file_path.name.startswith("_"):
            continue

        class_info = parser.parse_file(file_path)
        if class_info and class_info.name:
            classes.append(class_info)

        # Collect warnings from this file
        all_warnings.extend(parser.get_warnings())

    return classes, all_warnings


if __name__ == "__main__":
    import sys

    if len(sys.argv) < 2:
        print("Usage: gdscript_parser.py <file_or_directory>")
        sys.exit(1)

    path = Path(sys.argv[1])

    if path.is_file():
        parser = GDScriptParser()
        class_info = parser.parse_file(path)
        if class_info:
            print(f"Class: {class_info.name}")
            print(f"Extends: {class_info.extends}")
            print(f"Is ignored: {class_info.is_class_ignored}")
            print(f"Description: {class_info.description[:100]}...")
            print(f"Signals: {len(class_info.signals)}")
            print(f"Constants: {len(class_info.constants)}")
            print(f"Enums: {len(class_info.enums)}")
            print(f"Properties: {len(class_info.properties)}")
            print(f"Methods: {len(class_info.methods)}")

        # Print any warnings
        for warning in parser.get_warnings():
            print(warning, file=sys.stderr)
    elif path.is_dir():
        classes, warnings = parse_directory(path)
        print(f"Found {len(classes)} classes")
        for cls in classes:
            ignored_marker = " [IGNORED]" if cls.is_class_ignored else ""
            print(f"  - {cls.name} (extends {cls.extends}){ignored_marker}")

        # Print any warnings
        for warning in warnings:
            print(warning, file=sys.stderr)
    else:
        print(f"Path not found: {path}")
        sys.exit(1)
        sys.exit(1)
