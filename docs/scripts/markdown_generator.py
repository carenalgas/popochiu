#!/usr/bin/env python3
"""
Markdown Generator for Popochiu Documentation

Generates Godot-style Markdown documentation from parsed GDScript classes,
with summary tables, detailed sections, and proper formatting.
"""

import re
from pathlib import Path
from typing import Optional
from dataclasses import dataclass

from gdscript_parser import (
    ClassInfo, SignalInfo, ConstantInfo, EnumInfo, EnumValue,
    PropertyInfo, MethodInfo, ParameterInfo, parse_directory, GDScriptParser
)
from bbcode_converter import BBCodeConverter


@dataclass
class GeneratorConfig:
    """Configuration for the Markdown generator."""
    # Whether to include private members (starting with _)
    include_private: bool = False
    # Whether to include methods starting with _ (except virtual ones like _ready)
    include_private_methods: bool = False
    # Whether to generate separate files for each class
    separate_files: bool = True
    # Whether to generate an index.md file listing all classes
    generate_index: bool = False
    # Base URL for cross-references
    base_url: str = ""
    # Known classes for cross-referencing
    known_classes: set[str] = None
    
    def __post_init__(self):
        if self.known_classes is None:
            self.known_classes = set()


class MarkdownGenerator:
    """Generates Godot-style Markdown documentation from ClassInfo."""
    
    # Virtual methods from Godot that should always be documented
    GODOT_VIRTUAL_METHODS = {
        "_ready", "_process", "_physics_process", "_enter_tree", "_exit_tree",
        "_input", "_unhandled_input", "_draw", "_notification"
    }
    
    def __init__(self, config: Optional[GeneratorConfig] = None):
        self.config = config or GeneratorConfig()
        self.converter: Optional[BBCodeConverter] = None
    
    def generate(self, class_info: ClassInfo) -> str:
        """Generate Markdown documentation for a class."""
        self.converter = BBCodeConverter(
            class_info.name, 
            self.config.known_classes
        )
        
        sections = []
        
        # Header
        sections.append(self._generate_header(class_info))
        
        # Description
        if class_info.description:
            sections.append(self._generate_description(class_info))
        
        # Table of contents / Summary tables
        sections.append(self._generate_toc(class_info))
        
        # Signals summary and details
        if class_info.signals:
            sections.append(self._generate_signals_section(class_info))
        
        # Enumerations
        if class_info.enums:
            sections.append(self._generate_enums_section(class_info))
        
        # Constants
        if class_info.constants:
            sections.append(self._generate_constants_section(class_info))
        
        # Property descriptions
        visible_props = self._filter_properties(class_info.properties)
        if visible_props:
            sections.append(self._generate_properties_section(class_info, visible_props))
        
        # Method descriptions
        visible_methods = self._filter_methods(class_info.methods)
        if visible_methods:
            sections.append(self._generate_methods_section(class_info, visible_methods))
        
        return "\n\n".join(sections)
    
    def _generate_header(self, class_info: ClassInfo) -> str:
        """Generate the class header section."""
        lines = [f"# {class_info.name}"]
        
        # Inheritance chain
        if class_info.extends:
            lines.append("")
            lines.append(f"**Inherits:** [{class_info.extends}]({class_info.extends}.md)")
        
        return "\n".join(lines)
    
    def _generate_description(self, class_info: ClassInfo) -> str:
        """Generate the description section."""
        lines = ["## Description"]
        lines.append("")
        lines.append(self.converter.convert(class_info.description))
        return "\n".join(lines)
    
    def _generate_toc(self, class_info: ClassInfo) -> str:
        """Generate the table of contents with summary tables."""
        sections = []
        
        # Properties table
        visible_props = self._filter_properties(class_info.properties)
        if visible_props:
            sections.append(self._generate_properties_table(visible_props))
        
        # Methods table
        visible_methods = self._filter_methods(class_info.methods)
        if visible_methods:
            sections.append(self._generate_methods_table(visible_methods))
        
        # Signals table (if any)
        if class_info.signals:
            sections.append(self._generate_signals_table(class_info.signals))
        
        # Enums table (if any)
        if class_info.enums:
            sections.append(self._generate_enums_table(class_info.enums))
        
        # Constants table (if any)
        if class_info.constants:
            sections.append(self._generate_constants_table(class_info.constants))
        
        return "\n\n".join(sections)
    
    def _generate_properties_table(self, properties: list[PropertyInfo]) -> str:
        """Generate the properties summary table."""
        lines = ['<hr class="classref-section-separator">', "", "## Properties"]
        lines.append("")
        lines.append("| Type | Name | Default |")
        lines.append("|------|------|---------|")
        
        for prop in sorted(properties, key=lambda p: p.name.lower()):
            type_str = self._format_type(prop.type_hint) if prop.type_hint else "Variant"
            name_link = f"[{prop.name}](#{prop.name.lower().replace('_', '-')})"
            default = f"`{prop.default_value}`" if prop.default_value else ""
            lines.append(f"| {type_str} | {name_link} | {default} |")
        
        return "\n".join(lines)
    
    def _generate_methods_table(self, methods: list[MethodInfo]) -> str:
        """Generate the methods summary table."""
        lines = ['<hr class="classref-section-separator">', "", "## Methods"]
        lines.append("")
        lines.append("| Return Type | Method |")
        lines.append("|-------------|--------|")
        
        for method in sorted(methods, key=lambda m: m.name.lower()):
            ret_type = self._format_type(method.return_type) if method.return_type else "void"
            
            # Build signature
            params = []
            for p in method.parameters:
                param_str = p.name
                if p.type_hint:
                    param_str += f": {self._format_type_inline(p.type_hint)}"
                if p.default_value:
                    param_str += f" = {p.default_value}"
                params.append(param_str)
            
            sig = f"[{method.name}](#{method.name.lower().replace('_', '-')})({', '.join(params)})"
            
            # Add qualifiers
            qualifiers = []
            if method.is_virtual:
                qualifiers.append("*virtual*")
            if method.is_static:
                qualifiers.append("*static*")
            
            if qualifiers:
                sig += " " + " ".join(qualifiers)
            
            lines.append(f"| {ret_type} | {sig} |")
        
        return "\n".join(lines)
    
    def _generate_signals_table(self, signals: list[SignalInfo]) -> str:
        """Generate the signals summary table."""
        lines = ['<hr class="classref-section-separator">', "", "## Signals"]
        lines.append("")
        
        for signal in sorted(signals, key=lambda s: s.name.lower()):
            params = ", ".join(
                f"{name}: {self._format_type_inline(type_)}" if type_ else name
                for name, type_ in signal.parameters
            )
            lines.append(f"- **[{signal.name}](#signal-{signal.name.lower().replace('_', '-')})**({params})")
        
        return "\n".join(lines)
    
    def _generate_enums_table(self, enums: list[EnumInfo]) -> str:
        """Generate the enumerations summary table."""
        lines = ['<hr class="classref-section-separator">', "", "## Enumerations"]
        lines.append("")
        
        for enum in sorted(enums, key=lambda e: e.name.lower()):
            lines.append(f"- **[{enum.name}](#enum-{enum.name.lower().replace('_', '-')})**")
        
        return "\n".join(lines)
    
    def _generate_constants_table(self, constants: list[ConstantInfo]) -> str:
        """Generate the constants summary table."""
        lines = ['<hr class="classref-section-separator">', "", "## Constants"]
        lines.append("")
        lines.append("| Name | Value |")
        lines.append("|------|-------|")
        
        for const in sorted(constants, key=lambda c: c.name.lower()):
            lines.append(f"| `{const.name}` | `{const.value}` |")
        
        return "\n".join(lines)
    
    def _generate_signals_section(self, class_info: ClassInfo) -> str:
        """Generate the signals detail section."""
        lines = ['<hr class="classref-section-separator">', "", "## Signal Descriptions"]
        
        for i, signal in enumerate(sorted(class_info.signals, key=lambda s: s.name.lower())):
            if i > 0:
                lines.append('')
                lines.append('<hr class="classref-item-separator">')
            lines.append("")
            anchor = f"signal-{signal.name.lower().replace('_', '-')}"
            lines.append(f"### {signal.name} {{#{anchor}}}")
            lines.append("")
            lines.append(f"```gdscript")
            lines.append(f"signal {signal.signature}")
            lines.append(f"```")
            
            if signal.description:
                lines.append("")
                lines.append(self.converter.convert(signal.description))
        
        return "\n".join(lines)
    
    def _generate_enums_section(self, class_info: ClassInfo) -> str:
        """Generate the enumerations detail section."""
        lines = ['<hr class="classref-section-separator">', "", "## Enumeration Descriptions"]
        
        for i, enum in enumerate(sorted(class_info.enums, key=lambda e: e.name.lower())):
            if i > 0:
                lines.append('')
                lines.append('<hr class="classref-item-separator">')
            lines.append("")
            anchor = f"enum-{enum.name.lower().replace('_', '-')}"
            lines.append(f"### enum {enum.name} {{#{anchor}}}")
            lines.append("")
            
            if enum.description:
                lines.append(self.converter.convert(enum.description))
                lines.append("")
            
            lines.append("```gdscript")
            lines.append(f"enum {enum.name} {{")
            for val in enum.values:
                val_str = f"    {val.name}"
                if val.value is not None:
                    val_str += f" = {val.value}"
                val_str += ","
                lines.append(val_str)
            lines.append("}")
            lines.append("```")
            
            # Value descriptions
            has_descriptions = any(v.description for v in enum.values)
            if has_descriptions:
                lines.append("")
                for val in enum.values:
                    if val.description:
                        lines.append(f"- **{val.name}** — {self.converter.convert(val.description)}")
                    else:
                        lines.append(f"- **{val.name}**")
        
        return "\n".join(lines)
    
    def _generate_constants_section(self, class_info: ClassInfo) -> str:
        """Generate the constants detail section."""
        lines = ['<hr class="classref-section-separator">', "", "## Constant Descriptions"]
        
        for i, const in enumerate(sorted(class_info.constants, key=lambda c: c.name.lower())):
            if i > 0:
                lines.append('')
                lines.append('<hr class="classref-item-separator">')
            lines.append("")
            lines.append(f"### {const.name}")
            lines.append("")
            lines.append("```gdscript")
            type_hint = f": {const.type_hint}" if const.type_hint else ""
            lines.append(f"const {const.name}{type_hint} = {const.value}")
            lines.append("```")
            
            if const.description:
                lines.append("")
                lines.append(self.converter.convert(const.description))
        
        return "\n".join(lines)
    
    def _generate_properties_section(self, class_info: ClassInfo, 
                                     properties: list[PropertyInfo]) -> str:
        """Generate the property descriptions section."""
        lines = ['<hr class="classref-section-separator">', "", "## Property Descriptions"]
        
        for i, prop in enumerate(sorted(properties, key=lambda p: p.name.lower())):
            if i > 0:
                lines.append('')
                lines.append('<hr class="classref-item-separator">')
            lines.append("")
            anchor = prop.name.lower().replace("_", "-")
            lines.append(f"### {prop.name} {{#{anchor}}}")
            lines.append("")
            
            # Property signature
            lines.append("```gdscript")
            sig_parts = []
            if prop.export_hint:
                sig_parts.append(prop.export_hint)
            sig_parts.append("var")
            sig_parts.append(prop.name)
            if prop.type_hint:
                sig_parts.append(f": {prop.type_hint}")
            if prop.default_value:
                sig_parts.append(f"= {prop.default_value}")
            lines.append(" ".join(sig_parts))
            lines.append("```")
            
            # Getter/Setter info
            if prop.getter or prop.setter:
                lines.append("")
                if prop.getter:
                    lines.append(f"- **Getter:** `{prop.getter}`")
                if prop.setter:
                    lines.append(f"- **Setter:** `{prop.setter}`")
            
            if prop.description:
                lines.append("")
                lines.append(self.converter.convert(prop.description))
        
        return "\n".join(lines)
    
    def _generate_methods_section(self, class_info: ClassInfo,
                                  methods: list[MethodInfo]) -> str:
        """Generate the method descriptions section."""
        lines = ['<hr class="classref-section-separator">', "", "## Method Descriptions"]
        
        for i, method in enumerate(sorted(methods, key=lambda m: m.name.lower())):
            if i > 0:
                lines.append('')
                lines.append('<hr class="classref-item-separator">')
            lines.append("")
            anchor = method.name.lower().replace("_", "-")
            lines.append(f"### {method.name} {{#{anchor}}}")
            lines.append("")
            
            # Method signature
            lines.append("```gdscript")
            sig_prefix = ""
            if method.is_static:
                sig_prefix = "static "
            
            # Parameters
            params = []
            for p in method.parameters:
                param_str = p.name
                if p.type_hint:
                    param_str += f": {p.type_hint}"
                if p.default_value:
                    param_str += f" = {p.default_value}"
                params.append(param_str)
            
            params_str = ", ".join(params)
            return_str = f" -> {method.return_type}" if method.return_type else ""
            
            lines.append(f"{sig_prefix}func {method.name}({params_str}){return_str}")
            lines.append("```")
            
            # Qualifiers
            if method.is_virtual:
                lines.append("")
                lines.append("*This is a virtual method. Override it in your subclass.*")
            
            if method.description:
                lines.append("")
                lines.append(self.converter.convert(method.description))
        
        return "\n".join(lines)
    
    def _filter_properties(self, properties: list[PropertyInfo]) -> list[PropertyInfo]:
        """Filter properties based on configuration."""
        result = []
        for prop in properties:
            # Skip private properties unless configured to include them
            if prop.name.startswith("_") and not self.config.include_private:
                continue
            result.append(prop)
        return result
    
    def _filter_methods(self, methods: list[MethodInfo]) -> list[MethodInfo]:
        """Filter methods based on configuration."""
        result = []
        for method in methods:
            # Always skip truly private methods (double underscore)
            if method.name.startswith("__"):
                continue
            
            # Skip private methods unless they're virtual/overrides
            if method.name.startswith("_"):
                if not self.config.include_private_methods:
                    # Include Godot virtual methods and Popochiu virtual methods
                    if method.name not in self.GODOT_VIRTUAL_METHODS and not method.is_virtual:
                        # Check if it's a Popochiu virtual method (documented with ## and starts with _)
                        if not (method.description and method.name.startswith("_")):
                            continue
            
            result.append(method)
        return result
    
    def _format_type(self, type_hint: str) -> str:
        """Format a type hint with links."""
        if not type_hint:
            return "Variant"
        
        # Handle generic types like Array[String]
        if "[" in type_hint:
            base, inner = type_hint.split("[", 1)
            inner = inner.rstrip("]")
            return f"{self._format_type(base)}[{self._format_type(inner)}]"
        
        # Check if it's a known class
        if type_hint in self.config.known_classes or type_hint in BBCodeConverter.POPOCHIU_CLASSES:
            return f"[{type_hint}]({type_hint}.md)"
        
        if type_hint in BBCodeConverter.GODOT_CLASSES:
            return f"[{type_hint}](https://docs.godotengine.org/en/stable/classes/class_{type_hint.lower()}.html)"
        
        return type_hint
    
    def _format_type_inline(self, type_hint: str) -> str:
        """Format a type hint for inline use (no links in tables)."""
        return type_hint if type_hint else "Variant"


def generate_class_docs(class_info: ClassInfo, config: Optional[GeneratorConfig] = None) -> str:
    """Generate Markdown documentation for a single class."""
    generator = MarkdownGenerator(config)
    return generator.generate(class_info)


def generate_directory_docs(directory: Path, output_dir: Path,
                           config: Optional[GeneratorConfig] = None) -> list[str]:
    """
    Generate documentation for all classes in a directory.
    
    Returns list of generated file paths.
    """
    # First pass: collect all class names for cross-referencing
    classes = parse_directory(directory)
    
    if config is None:
        config = GeneratorConfig()
    
    config.known_classes = {cls.name for cls in classes}
    
    output_dir.mkdir(parents=True, exist_ok=True)
    generated = []
    
    for class_info in classes:
        generator = MarkdownGenerator(config)
        markdown = generator.generate(class_info)
        
        output_file = output_dir / f"{class_info.name}.md"
        output_file.write_text(markdown, encoding="utf-8")
        generated.append(str(output_file))
        print(f"Generated: {output_file}")
    
    # Generate index file only if requested
    if config.generate_index:
        index_content = _generate_index(classes)
        index_file = output_dir / "index.md"
        index_file.write_text(index_content, encoding="utf-8")
        generated.append(str(index_file))
        print(f"Generated: {index_file}")
    
    return generated


def _generate_index(classes: list[ClassInfo]) -> str:
    """Generate an index page for all classes."""
    lines = ["# Scripting Reference"]
    lines.append("")
    lines.append("This section contains the API reference for all Popochiu engine classes.")
    lines.append("")
    lines.append("## Classes")
    lines.append("")
    
    # Sort classes alphabetically
    sorted_classes = sorted(classes, key=lambda c: c.name)
    converter = BBCodeConverter()
    
    for cls in sorted_classes:
        desc = cls.description.split("\n")[0][:100] if cls.description else ""
        if len(cls.description) > 100:
            desc += "..."
        # Convert BBCode in description
        desc = converter.convert(desc)
        lines.append(f"- [{cls.name}]({cls.name}.md) — {desc}")
    
    return "\n".join(lines)


if __name__ == "__main__":
    import sys
    
    if len(sys.argv) < 2:
        print("Usage: markdown_generator.py <file_or_directory> [output_directory]")
        sys.exit(1)
    
    input_path = Path(sys.argv[1])
    output_path = Path(sys.argv[2]) if len(sys.argv) > 2 else Path("./docs_output")
    
    if input_path.is_file():
        parser = GDScriptParser()
        class_info = parser.parse_file(input_path)
        if class_info:
            config = GeneratorConfig()
            markdown = generate_class_docs(class_info, config)
            
            output_file = output_path / f"{class_info.name}.md"
            output_path.mkdir(parents=True, exist_ok=True)
            output_file.write_text(markdown, encoding="utf-8")
            print(f"Generated: {output_file}")
    elif input_path.is_dir():
        generate_directory_docs(input_path, output_path)
    else:
        print(f"Path not found: {input_path}")
        sys.exit(1)
