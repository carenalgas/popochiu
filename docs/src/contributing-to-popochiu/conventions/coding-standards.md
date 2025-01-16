---
weight: 7320
---

# Coding standards

## GDScript code

Popochiu adheres to the [official GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html) for both code and [file and folder naming conventions](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html).

To ensure your code complies with these guidelines, you can use the [GDScript Toolkit](https://github.com/Scony/godot-gdscript-toolkit) by [Pawel Lampe](https://github.com/Scony).

As of now, no automatic linting is available as a pre-commit hook or during PR submission. Please verify that your code is compliant before submitting your PRs.

---

## Python code

Some scripts and automation, mostly related to the documentation, are written in Python.  
We’re quite permissive when it comes to Python code, as it’s only used for secondary scripts and automation tasks, and the amount of code involved is minimal. However, when in doubt, it’s always a good idea to adhere to the [PEP 8 style guide](https://peps.python.org/pep-0008/), which is the widely accepted standard for Python code.

To ensure your code aligns with PEP 8, you can rely on one of the many available linters such as **[Black](https://black.readthedocs.io/en/stable/)**, **[Flake8](https://flake8.pycqa.org/en/latest/)** or **[Pylint](https://pylint.pycqa.org/en/latest/)** - or any other one you prefer.

---

## Markdown Code

The Popochiu documentation is entirely written in Markdown, with several syntax extensions to support advanced functionality such as Mermaid diagrams, code highlighting, admonition blocks, definition lists, and more. These extensions are provided as Python modules included in the documentation Docker image.

For Markdown files, we adhere to [CommonMark](https://spec.commonmark.org/0.31.2/) specification, augmented by the extensions provided by [GitHub Flavored Markdown](https://github.github.com/gfm/).

If you are using Visual Studio Code, we recommend installing the following extensions to ensure your Markdown code is properly reviewed during editing:

- [markdownlint](https://marketplace.visualstudio.com/items?itemName=DavidAnson.vscode-markdownlint): Linting for Markdown files to ensure adherence to both adopted specifications (specifically [this ruleset](https://github.com/DavidAnson/markdownlint?tab=readme-ov-file#rules--aliases)).
- [Markdown All in One](https://marketplace.visualstudio.com/items?itemName=yzhang.markdown-all-in-one): Provides shortcuts, table of contents generation, and other helpful features for Markdown editing.
- [Mermaid Markdown Syntax Highlighting](https://marketplace.visualstudio.com/items?itemName=bpruitt-goddard.mermaid-markdown-syntax-highlighting): Adds syntax highlighting support for Mermaid diagrams in Markdown files.
