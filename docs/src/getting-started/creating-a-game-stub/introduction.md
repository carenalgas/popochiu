---
weight: 1510
---

# Introduction

This section will guide you through the process of creating a very small stub for a game.

You will set up a quick game with a single location, a couple of interacting characters and items, plus dialogs and inventory.

You can use the resulting stub to experiment and tinker as you read the documentation. If you are already familiar with Popochiu and have already created your project, you can jump to the [Tutorials](/getting-started/tutorials) section to learn more about more advanced features.

!!! info
    If you are moving your first steps in Adventure Games development, or just evaluating if Popochiu is for you, you may want to download the [Example Game Assets [Pack](/getting-started/example-resources#example-assets), which contains all the assets used in this tutorial.

    If you just want to tinker with Popochiu or experiment on a throw-away project, you can just clone the [Example Game](/getting-started/example-resources#example-game), that's already complete and ready to run.

## Table of contents

!!! warning
    To follow this introductory guide you must have already created a new Godot project and [installed Popochiu](/getting-started/installing-popochiu).  

To create our game stub we will:

- [Game setup](/getting-started/creating-a-game-stub/game-setup)
    - [Set game resolution](/getting-started/creating-a-game-stub/game-setup#set-game-resolution)
    - [Select game GUI](/getting-started/creating-a-game-stub/game-setup#select-game-gui)
- [Create characters](/getting-started/creating-a-game-stub/create-characters)
    - [Add another character](/getting-started/creating-a-game-stub/create-characters#add-another-character)
    - [Select the main character](/getting-started/creating-a-game-stub/create-characters#select-the-main-character)
- [Create the first room](/getting-started/creating-a-game-stub/create-the-first-room)
    - [Add a Walkable Area](/getting-started/creating-a-game-stub/create-the-first-room#add-a-walkable-area)
    - [Add a hotspot](/getting-started/creating-a-game-stub/create-the-first-room#add-a-hotspot)
    - [Script your first interaction](/getting-started/creating-a-game-stub/create-the-first-room#script-your-first-interaction)
    - [Add a prop](/getting-started/creating-a-game-stub/create-the-first-room#add-a-prop)
- [Add an inventory item](/getting-started/creating-a-game-stub/add-an-inventory-item)
- [Script your first dialogue](/getting-started/creating-a-game-stub/script-your-first-dialogue)
    - [Script a dialog](/getting-started/creating-a-game-stub/script-your-first-dialogue#script-a-dialog)
- [Use inventory items](/getting-started/creating-a-game-stub/use-inventory-items)
- [Customize the Game UI](/getting-started/creating-a-game-stub/customize-the-game-ui)
- [Conclusions](/getting-started/creating-a-game-stub/conclusions)
- [Homeworks](/getting-started/creating-a-game-stub/conclusions#homeworks)
    - [Add a prop and an inventory item](/getting-started/creating-a-game-stub/conclusions#add-a-prop-and-an-inventory-item)
    - [Prevent losing the key](/getting-started/creating-a-game-stub/conclusions#prevent-losing-the-key)
    - [Solve a problem with the implemented dialog](/getting-started/creating-a-game-stub/conclusions#solve-a-problem-with-the-implemented-dialog)
- [What's next](/getting-started/creating-a-game-stub/conclusions#whats-next)

There is more to Popochiu, but this will showcase the fundamental building blocks of how the engine works.

Let's start!
