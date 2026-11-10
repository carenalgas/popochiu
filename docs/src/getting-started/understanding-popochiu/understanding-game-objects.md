---
weight: 1033
title: "Understanding Game Objects"
---

# Understanding Game Objects

Popochiu games are built from a small set of objects. Each one has a clear responsibility, and together they form the structure of your game.

| Object | Responsibility | Key relationships |
| :----- | :------------- | :---------------- |
| **Room** | A place the player can visit. It contains the room's background and its interactive objects. | Contains props, hotspots, walkable areas, regions, and markers. Characters can be linked into a room. |
| **Character** | A person in the game, with animations, a position, and dialog behavior. | Can be the player character (PC) or a non-player character (NPC). Can be linked into rooms. |
| **Prop** | A visible object in a room that can be interactive or decorative. | Lives in a room. Can use the same interaction callbacks as other objects. |
| **Hotspot** | An invisible or visible area that represents something the player can interact with. | Lives in a room. Usually drawn with a polygon. |
| **Walkable Area** | The area where characters are allowed to walk. | Lives in a room. Defines the navigable floor. |
| **Region** | A rectangular or polygonal area used for gameplay logic, such as scaling or triggers. | Lives in a room. Can affect characters and props. |
| **Marker** | A named point in a room, used as a destination or reference. | Lives in a room. Useful for scripted movement. |
| **Inventory Item** | An object the player can carry, combine, and use. | Can be added to the inventory at the start or during play. |
| **Dialog Tree** | A branching conversation between characters. | References characters and can trigger game events. |
| **GUI** | The interface layer: inventory bar, dialog box, menus, and custom controls. | Reacts to engine commands and can be customized or replaced. |

## How the objects relate

A **room** is the stage. It contains the **props**, **hotspots**, **walkable areas**, **regions**, and **markers** that make up the scene. **Characters** move through rooms and interact with those objects.

The player's actions are routed to the object that was clicked or used. That object decides what happens by running your script code. **Inventory items** and **dialog trees** are game-wide objects that can be used from any room.

## Where to go next

- [Create the first room](../../your-first-adventure/rooms-and-interactions/create-the-first-room.md)
- [Create characters](../../your-first-adventure/characters/create-characters.md)
- [Add an inventory item](../../your-first-adventure/inventory/add-an-inventory-item.md)
- [Script your first dialogue](../../your-first-adventure/dialogues/script-your-first-dialogue.md)
- [Scripting Overview](../../guides/scripting/scripting-overview.md)
