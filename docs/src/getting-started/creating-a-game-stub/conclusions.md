---
weight: 1570
---

## Conclusions

It has been a long journey, and we learned a lot.

We know how to:

* **Setup a game** in Popochiu
* **Select a GUI** among the available ones
* **Create locations** for our characters to explore
* **Add characters** to our game and make them interact with dialogues and actions
* **Move and control** our game character
* **Add interactions** to our locations, both via **hotspots** and actual **props**
* Collect and get rid of stuff in **the inventory**
* We can create interesting, dynamic **dialogues**

These are the basics of every adventure game and an inch of what Popochiu can do for you.  
We hope that this appetizer was enough to understand if Popochiu is the game engine that you need for your project, and that you are enticed to learn more!

## Homeworks

If you want to tinker with this first game a bit, get your hands dirty and learn by doing, here is a list of assignments you can try to solve by yourself, with some hints in case you get lost.

### Add a prop and an inventory item

Add a cabinet with a drawer to the scene and a key as an inventory item. When the character interacts with the cabinet, it says something about having found a key in the drawer and the key is added to the inventory

!!! tip "Hint"
    Find the sprites for [the key](https://github.com/carenalgas/popochiu-sample-game/blob/801bdbb5cdc9139e05e496e7a703f5f4e37bc861/game/inventory_items/key/key.png) and [the cabinet](https://github.com/carenalgas/popochiu-sample-game/blob/801bdbb5cdc9139e05e496e7a703f5f4e37bc861/game/rooms/house/props/drawer/house_drawer.png) in the example project GitHub repository.

### Prevent losing the key

If the player tries to give the key to Popsy, the main character will say something to make clear it doesn't want to give away the key.

!!! tip "Hint"
    Introduce another block dedicated to the new inventory item in `_on_item_used()` for Popsy character.

### Solve a problem with the implemented dialog

If you start the game, give the toy car to Popsy, then talk to him and select the line about the messy room, the line "Popsy, are you bored?" will appear again. That's a bug, Popsy already has its toy. Find a way to fix this.

!!! tip "Hint"
    You can tie the "give toy car" action to the state of the second dialog line (so that the main character refuses to give Popsy the toy unless it **knows** that the little one is bored). Or you can disable the second line forever so even after exploring the first line of dialogue, it will never pop up again; there is a way to achieve this, find it ;)

## What's next

Now that you've broken the ice with the basic concepts, you can learn more.

* Go and get our [example resources](/getting-started/example-resources) to learn directly from code and find a quick start in your experimentation.
* Throughout this guide, we've given you a taste of the plugin interface, but you may want to learn everything there is to know about Popochiu's editor functions, by reading [the editor handbook](/the-editor-handbook).
* At the same time, the engine (the part of Popochiu that will ship with your game) deserves its own deep dive. Read [the engine handbook](/the-engine-handbook) and keep [the scripting API reference](/the-engine-handbook/scripting-reference) at hand while you code your game.
* This tutorial overlooks many important parts, among which [animations](/how-to-develop-a-game/playing-animations) and [audio management](/how-to-develop-a-game/adding-sounds) certainly stand out. The [How to Develop a Game](/how-to-develop-a-game) section contains basics and advanced techniques that will help you get the most out of Godot and Popochiu.
* Last but not least, Popochiu is a community effort. Learn [how to get help](/getting-started/getting-help) and, if you feel like contributing, read our [contribution guidelines](/contributing-to-popochiu).