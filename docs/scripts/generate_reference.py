#!/usr/bin/env python3
"""
Popochiu Documentation Reference Generator

Main entry point for generating API reference documentation from GDScript source files.
This script replaces the previous shell-based generation that required running Godot.
"""

import argparse
import sys
from pathlib import Path

# Add the scripts directory to the path for imports
SCRIPT_DIR = Path(__file__).parent
sys.path.insert(0, str(SCRIPT_DIR))

from gdscript_parser import parse_directory, GDScriptParser
from markdown_generator import generate_directory_docs, generate_class_docs, GeneratorConfig


def main():
    parser = argparse.ArgumentParser(
        description="Generate API reference documentation from GDScript source files.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Generate docs for the entire engine
  %(prog)s ../addons/popochiu/engine -o ../docs/src/the-engine-handbook/scripting-reference

  # Generate docs for a single file
  %(prog)s ../addons/popochiu/engine/objects/character/popochiu_character.gd -o ./output

  # Include private members
  %(prog)s ../addons/popochiu/engine --include-private -o ./output
        """
    )

    parser.add_argument(
        "input",
        type=Path,
        help="Path to a GDScript file or directory containing GDScript files"
    )

    parser.add_argument(
        "-o", "--output",
        type=Path,
        default=Path("./reference_output"),
        help="Output directory for generated Markdown files (default: ./reference_output)"
    )

    parser.add_argument(
        "--include-private",
        action="store_true",
        help="Include private properties (starting with _)"
    )

    parser.add_argument(
        "--include-private-methods",
        action="store_true",
        help="Include private methods (starting with _), except virtual overrides"
    )

    parser.add_argument(
        "--generate-index",
        action="store_true",
        help="Generate an index.md file listing all classes"
    )

    parser.add_argument(
        "-v", "--verbose",
        action="store_true",
        help="Enable verbose output"
    )

    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Parse files but don't write output (useful for testing)"
    )

    args = parser.parse_args()

    # Validate input path
    if not args.input.exists():
        print(f"Error: Input path does not exist: {args.input}", file=sys.stderr)
        return 1

    # Create configuration
    config = GeneratorConfig(
        include_private=args.include_private,
        include_private_methods=args.include_private_methods,
        generate_index=args.generate_index,
    )

    all_warnings = []

    if args.input.is_file():
        # Single file mode
        if args.verbose:
            print(f"Parsing single file: {args.input}")

        parser_obj = GDScriptParser()
        class_info = parser_obj.parse_file(args.input)

        if not class_info:
            print(f"Error: Could not parse file: {args.input}", file=sys.stderr)
            return 1

        # Collect warnings from parsing
        all_warnings.extend(parser_obj.get_warnings())

        if args.verbose:
            print(f"  Class: {class_info.name}")
            print(f"  Extends: {class_info.extends}")
            print(f"  Is ignored: {class_info.is_class_ignored}")
            print(f"  Signals: {len(class_info.signals)}")
            print(f"  Properties: {len(class_info.properties)}")
            print(f"  Methods: {len(class_info.methods)}")
            print(f"  Enums: {len(class_info.enums)}")
            print(f"  Constants: {len(class_info.constants)}")

        if not args.dry_run:
            markdown = generate_class_docs(class_info, config)
            args.output.mkdir(parents=True, exist_ok=True)
            output_file = args.output / f"{class_info.name}.md"
            output_file.write_text(markdown, encoding="utf-8")
            print(f"Generated: {output_file}")

    else:
        # Directory mode
        if args.verbose:
            print(f"Parsing directory: {args.input}")

        # First, collect all classes for cross-referencing
        classes, parse_warnings = parse_directory(args.input)
        all_warnings.extend(parse_warnings)

        if args.verbose:
            print(f"Found {len(classes)} classes:")
            for cls in classes:
                ignored_marker = " [IGNORED]" if cls.is_class_ignored else ""
                print(f"  - {cls.name} (extends {cls.extends}){ignored_marker}")

        if not classes:
            print("Warning: No classes found in the specified directory.")
            return 0

        if not args.dry_run:
            config.known_classes = {cls.name for cls in classes}
            generated, gen_warnings = generate_directory_docs(
                args.input, args.output, config, classes, all_warnings
            )
            # gen_warnings already includes parse warnings, so use it
            all_warnings = gen_warnings
            print(f"\nGenerated {len(generated)} documentation files.")

    # Print any warnings to stderr
    for warning in all_warnings:
        print(warning, file=sys.stderr)

    # Return non-zero exit code if there were warnings
    if all_warnings:
        print(f"\n{len(all_warnings)} warning(s) occurred.", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
