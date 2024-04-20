---
weight: 1530
---

## Create characters

Characters are one of the basic elements of Popochiu, being the bread and butter of every adventure game.

Let's start creating the player character. In the Popochiu main dock, click the **Create character** button (_1_).

![Create Character button](/assets/images/getting-started/game_stub-character-1-create-button.png "Press the button to create a new character")

A popup will appear, asking for the character name. This is the machine name of your character, not the one the player will see ingame, and it needs to be written in `PascalCase` (no spaces or punctuation and all capitalized words).  
Once you entered the name, click the **OK** button (_2_).

![Confirmation button](/assets/images/getting-started/game_stub-character-2-creation-popup.png "Confirm the character's name")

As you can see the editor is giving you a preview of the files and assets that will be created. If everything went well, your editor should look like this now:

![New character created](/assets/images/getting-started/game_stub-character-3-editor.png "Your editor after creating a new character")

The new character appears in the main dock list (_3_) and the related scene is open in the editor (_4_).

Now click on the scene's root node (it should be named `Character<YourCharacterName>`) to access the character's properties in the inspector:

![Character inspector](/assets/images/getting-started/game_stub-character-5-inspector.png "The newly created character's inspector")

Set the **Flips when** parameter (_5_) to `Looking Left`, and leave the rest untouched.

!!! warning
    The suggested value is based on the example sprite direction (right). If you are using a self-made sprite for your character and it's facing left, you should set this property to `Looking right` instead.

The character scene shows nothing. That's because we've set no sprite for our character. Popochiu characters support a full set of standard and custom animations, but since we are only stubbing the game, we'll just set a static sprite for now.

If you don't have a sprite sheet ready for your character, you can download [this one](https://github.com/carenalgas/popochiu-sample-game/blob/16fc323f1c63388e6b97a30d678aa71e6e1d9db9/game/characters/goddiu/goddiu.png) from the demo game.  
Save it into your project, in the `game/characters/<your character name>/` folder, and rename it as you see fit.

!!! tip
    You can save the spritesheet anywhere in your project, but keeping it in the Character folder makes the project structure more tidy and maintainable. You may want to create subfolders to organize assets, but we strongly advise starting simple and reorganizing only when it's necessary.

To set the character sprite, go back to your editor and select the **Sprite2D** node in your character's scene (_6_), then locate your sprite sheet filename in your file manager (_7_). Select and drag it to the **Texture** property in the inspector (_8_).

![Set Character's sprite](/assets/images/getting-started/game_stub-character-6-set_texture.png "Drag and drop the spritesheet in the Sprite2D texture")

You can see from the screenshot that the entire image is now visible in the Character scene. Of course, we want to select just a single sprite from the sprite sheet. For that, head to the **Animation** section in the inspector and set **Hframes** and **Vframes** values to match the number of sprites in the sprite sheet, like this (_9_):

![Set Character's sprite frames](/assets/images/getting-started/game_stub-character-7-set_frames.png "The example asset is a four-by-four matrix of sprites, so we are setting horizontal and vertical frames accordingly")

Now the sprite on the scene should be OK, showing your character in the standing position. We just miss a little change to make things work as intended: when a new character is created, its sprite is centered on the scene origin:

![Set Character's sprite position](/assets/images/getting-started/game_stub-character-8-set_feet_center.png "Move the Character so its feet are in the scene's origin")

This is a problem because the scene origin point is the one that the engine will check to understand if the character is still inside a walking area, or if it reached a certain position when moving around the scene. In short, the scene origin should be where the character's feet are.  
Fixing this is as simple as selecting the **Sprite2D** node in the character scene (_10_), and moving it so that the origin is in between the two feet, like in the image below.

![Correct the Character's sprite position](/assets/images/getting-started/game_stub-character-9-set_feet_center.png "The character is now correctly positioned")

!!! tip "Tips for great character sprite positioning"
    Most game characters' idle position is depicted in a three-quarter view. In this type of shot, the foot facing the camera will be slightly lower than the foot pointing to the side of the sprite (look at Goddiu above). To achieve perfect results when positioning your sprite, you should position the side-facing foot on the zero line, and the camera-facing foot toe should be a bit lower.

    In the case of floating characters (ghosts, fairies, anti-gravity-powered mad scientists, etc), you should leave some vertical space between the scene's center and your character. Try to envision the scene line as the "floor" and decide how high above the floor the character should float.

The last thing to do is to position the place where the dialog text will be shown for the talking character. Popochiu can be customized to show dialog lines in many different positions or fashions, but its default is to show the dialogue lines somewhere above the character's head. Since the engine doesn't know how high your sprite is (see "Under the hood" note below), that's for you to decide.

Just select the **DialogPos** node in the scene tree (_11_). A small cross will be highlighted in the scene's origin. Drag it somewhere above the character's head (or wherever makes sense to you).

![Correct Character's text position](/assets/images/getting-started/game_stub-character-10-set_dialog_position.png "Position the dialogue where it's more convenient")

This may require a bit of experimentation, but for now, this will do.

!!! info "Under the hood"
    You may be wondering how exactly the text is positioned in relation to the **DialogPos** node. Here is an explanation of how Popochiu decides how your text is rendered.

    1. The baseline of the text will always match the vertical position of **DialogPos**, so the text will be rendered vertically **right above** that point.
    2. The dialog line length is calculated and the text is centered on the horizontal position of **DialogPos**, so the text will be rendered horizontally **around** that point.
    3. If the text spans multiple lines, Popochiu will expand it **towards the top**, so that it doesn't cover your character (this means if you want your text under the character for some reason, multiple lines will cover your character).
    4. If the character is near the window or screen border, the text will be repositioned so that it will be entirely visible, so you don't have to worry about it becoming unreadable. This is true both for horizontal and vertical coordinates.

### Add another character

We are almost done creating our player character. Before moving on, follow [the same steps](#create-characters) to create another one, to keep our main character company and test some interaction.

!!! tip
    In the example game, the second character is named _Popsy_ and [its sprite can be found here](https://github.com/carenalgas/popochiu-sample-game/blob/16fc323f1c63388e6b97a30d678aa71e6e1d9db9/game/characters/popsy/popsy.png).

### Select the main character

Now that we have two characters, it's time to tell Popochiu which one will be our main character. That's the one that will be used by the player.  
To do this, locate the first character you have created in Popochiu main dock (in our example it was _Goddiu_), open the drop-down menu, and select `Set as Player Character` (_12_).

![Set as Player Character](/assets/images/getting-started/game_stub-character-4-set_pc.png "Select our first character as the player character")

!!! info "Multiple character games"
    Even if we are not going to cover this detail, Popochiu supports multiple player characters in the style of _Maniac Mansion_ or _Day of the Tentacle_. It's as easy as programmatically changing a variable from your scripts.

Pat yourself a shoulder! You have successfully created your first characters.
