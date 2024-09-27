---
weight: 1510
---

# Introduction

This section will guide you through the process of creating a very small stub for a game.

You will set up a quick game with a single location, a couple of interacting characters and items, plus dialogs and inventory.

You can use the resulting stub to experiment and tinker as you read the documentation. If you are already familiar with Popochiu and have already created your project, you can jump to the [Tutorials](/popochiu/getting-started/tutorials) section to learn more about more advanced features.

!!! info
    If you are moving your first steps in Adventure Games development, or just evaluating if Popochiu is for you, you may want to download the [Example Game Assets [Pack](/popochiu/getting-started/example-resources#example-assets), which contains all the assets used in this tutorial.

    If you just want to tinker with Popochiu or experiment on a throw-away project, you can just clone the [Example Game](/popochiu/getting-started/example-resources#example-game), that's already complete and ready to run.

## Table of contents

!!! warning
    To follow this introductory guide you must have already created a new Godot project and [installed Popochiu](/popochiu/getting-started/installing-popochiu).  

To create our game stub we will:

- [Game setup](/popochiu/getting-started/creating-a-game-stub/game-setup)
    - [Set game resolution](/popochiu/getting-started/creating-a-game-stub/game-setup#set-game-resolution)
    - [Select game GUI](/popochiu/getting-started/creating-a-game-stub/game-setup#select-game-gui)
- [Create characters](/popochiu/getting-started/creating-a-game-stub/create-characters)
    - [Add another character](/popochiu/getting-started/creating-a-game-stub/create-characters#add-another-character)
    - [Select the main character](/popochiu/getting-started/creating-a-game-stub/create-characters#select-the-main-character)
- [Create the first room](/popochiu/getting-started/creating-a-game-stub/create-the-first-room)
    - [Add a Walkable Area](/popochiu/getting-started/creating-a-game-stub/create-the-first-room#add-a-walkable-area)
    - [Add a hotspot](/popochiu/getting-started/creating-a-game-stub/create-the-first-room#add-a-hotspot)
    - [Script your first interaction](/popochiu/getting-started/creating-a-game-stub/create-the-first-room#script-your-first-interaction)
    - [Add a prop](/popochiu/getting-started/creating-a-game-stub/create-the-first-room#add-a-prop)
- [Add an inventory item](/popochiu/getting-started/creating-a-game-stub/add-an-inventory-item)
- [Script your first dialogue](/popochiu/getting-started/creating-a-game-stub/script-your-first-dialogue)
    - [Script a dialog](/popochiu/getting-started/creating-a-game-stub/script-your-first-dialogue#script-a-dialog)
- [Use inventory items](/popochiu/getting-started/creating-a-game-stub/use-inventory-items)
- [Customize the Game UI](/popochiu/getting-started/creating-a-game-stub/customize-the-game-ui)
- [Conclusions](/popochiu/getting-started/creating-a-game-stub/conclusions)
- [Homeworks](/popochiu/getting-started/creating-a-game-stub/conclusions#homeworks)
    - [Add a prop and an inventory item](/popochiu/getting-started/creating-a-game-stub/conclusions#add-a-prop-and-an-inventory-item)
    - [Prevent losing the key](/popochiu/getting-started/creating-a-game-stub/conclusions#prevent-losing-the-key)
    - [Solve a problem with the implemented dialog](/popochiu/getting-started/creating-a-game-stub/conclusions#solve-a-problem-with-the-implemented-dialog)
- [What's next](/popochiu/getting-started/creating-a-game-stub/conclusions#whats-next)

There is more to Popochiu, but this will showcase the fundamental building blocks of how the engine works.

Let's start!
