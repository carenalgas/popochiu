---
weight: 1510
---

# Introduction

This section will guide you through the process of creating a very small stub for a game.

You will set up a quick game with a single location, a couple of interacting characters and items, plus dialogs and inventory.

You can use the resulting stub to experiment and tinker as you read the documentation. If you are already familiar with Popochiu and have already created your project, you can jump to the [Tutorials](../../../getting-started/tutorials) section to learn more about more advanced features.

!!! info
    If you are moving your first steps in Adventure Games development, or just evaluating if Popochiu is for you, you may want to download the [Example Game Assets [Pack](../../../getting-started/example-resources#example-assets), which contains all the assets used in this tutorial.

    If you just want to tinker with Popochiu or experiment on a throw-away project, you can just clone the [Example Game](../../../getting-started/example-resources#example-game), that's already complete and ready to run.

## Table of contents

!!! warning
    To follow this introductory guide you must have already created a new Godot project and [installed Popochiu](../../../getting-started/installing-popochiu).  

To create our game stub we will:

- [Game setup](../game-setup)
    - [Set game resolution](../game-setup#set-game-resolution)
    - [Select game GUI](../game-setup#select-game-gui)
- [Create characters](../create-characters)
    - [Add another character](../create-characters#add-another-character)
    - [Select the main character](../create-characters#select-the-main-character)
- [Create the first room](../create-the-first-room)
    - [Add a Walkable Area](../create-the-first-room#add-a-walkable-area)
    - [Add a hotspot](../create-the-first-room#add-a-hotspot)
    - [Script your first interaction](../create-the-first-room#script-your-first-interaction)
    - [Add a prop](../create-the-first-room#add-a-prop)
- [Add an inventory item](../add-an-inventory-item)
- [Script your first dialogue](../script-your-first-dialogue)
    - [Script a dialog](../script-your-first-dialogue#script-a-dialog)
- [Use inventory items](../use-inventory-items)
- [Customize the Game UI](../customize-the-game-ui)
- [Conclusions](../conclusions)
- [Homeworks](../conclusions#homeworks)
    - [Add a prop and an inventory item](../conclusions#add-a-prop-and-an-inventory-item)
    - [Prevent losing the key](../conclusions#prevent-losing-the-key)
    - [Solve a problem with the implemented dialog](../conclusions#solve-a-problem-with-the-implemented-dialog)
- [What's next](../conclusions#whats-next)

There is more to Popochiu, but this will showcase the fundamental building blocks of how the engine works.

Let's start!
