---
weight: 7050
---

# Wrapping up

If you've read through this handbook, you now have a working mental model of how Popochiu scripting hangs together.

You know that Popochiu organizes your game into well-defined objects (rooms, characters, props, dialogs, inventory items) and that **each object owns its own script**, where you fill in virtual functions to define how it behaves. You don't manage a game loop: Popochiu runs one for you and calls the right function at the right moment.

You know that when a GUI with commands is involved, player intent travels through a **dispatch chain** before it reaches your code, and that you can customize every step of that chain: from the per-object handler, all the way down to the template's global fallback.

You know that when you need actions to play out one after another (walk here, say that, play a sound), you use **`await`** to pause your script until each step finishes, and **queue functions** to build up sequences cleanly. You know how to mark a block of code as a cutscene so players can skip it, and how to fire things off in the background when you don't need to wait.

And you know that Popochiu keeps **game state** for you: room objects remember where they were left, custom properties on data resources survive room transitions and save/load cycles, and `Globals` is always there for anything that belongs to the whole game rather than a specific object.

## Now what?

Arrange your game world, create your objects, and start scripting their behavior.

Every time you ask yourself "how do I make this element do this thing?", remember: if it's a common point-and-click adventure trope, Popochiu almost certainly has it covered already. Before writing something from scratch, check the [Scripting Reference](scripting-reference/index.md) to see what each object can do for you out of the box.

The reference lists every class, every property, every method, and every signal. If you find a method that does what you need, just call it. If you find a virtual function stub, override it. If you find a signal, connect to it.

Good luck, and have fun with your game!
