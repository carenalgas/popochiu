---
weight: 7510
---

# Popochiu Subsystems

Popochiu is divided into two main subsystems:

- An **Editor Plugin**, which initializes and manages a series of other plugins (for the Inspector, Toolbar, various pop-up windows, viewport Gizmos, etc.), and provides integrated interfaces within the Godot Editor to streamline the primary tasks involved in creating a graphic adventure game. The Editor Plugin is also responsible for setting up a project, configuring its parameters, and creating, updating, and deleting resources that will make up the final game.

- A **Game Engine**, which offers a set of functions, classes, templates, and objects used to build an adventure game. The engine handles all the logic for interactions between these elements and with the player, as well as recurring features of the genre such as dialogues, inventory management, scene transitions, and more. Additionally, the Game Engine takes care of lower-level functions, such as managing audio (music and sound effects), moving characters within and between rooms, saving/loading game states, and rendering the interface through which players interact with the game. Finally, the Game Engine provides an **API** with functions and scripts that make orchestrating all these features intuitive and straightforward.

Together, these features aim to **enable anyone to create graphic adventures without needing to learn Godot** (beyond a few basic concepts).

At the same time, its architecture is developer-friendly, suitable for code-driven workflows, and perfectly viable for larger and more structured teams.

The following sections provide an overview of the specific subsystems, their responsibilities, and their relationships. This is a high-level overview to help contributors make themselves at home, without delving into too much detail.

For specific questions, feel free to [get in touch](../../get-in-touch).
