---
weight: 7380
---

# Dependencies

Godot does not yet have a mature dependency manager to handle composition and interdependencies between addons. As a result, our approach for Popochiu is to implement every feature as an internal feature.

A good example is the Aseprite Importer, which was inspired by (and partially based on) the excellent [Godot Aseprite Wizard](https://github.com/viniciusgerevini/godot-aseprite-wizard) by [Vinicius Gerevini](https://github.com/viniciusgerevini). However, the feature was rewritten and fully integrated into Popochiu to simplify distribution and avoid external dependencies.

For this reason, contributions that rely on third-party addons will not be accepted.
