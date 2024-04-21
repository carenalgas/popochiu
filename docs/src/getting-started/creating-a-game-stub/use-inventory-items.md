---
weight: 1560
---

## Use inventory items

The last common task in an adventure game is to use inventory items. Giving them to characters, combining them together or with elements in the game world.

We are going to give the item we collected earlier to our secondary character. This will disable the dialog line forever and remove the item from our inventory.

Fortunately, we already have all the elements we need to achieve this. Every Popochiu clickable object (characters, props, hotspots, and inventory items) exposes a function named `_on_item_used()`, that is invoked by the engine when the player tries to combine an inventory item with that object. Of course, the engine passes the inventory item that the player is using as a parameter so that the target object can react differently to different items.

We'll give the toy car to Popsy, so open the script of the secondary character, locate the `_on_item_used()` function and change it like this:

```gdscript
# When the node is clicked and there is an inventory item selected
func _on_item_used(item: PopochiuInventoryItem) -> void:
	if item == I.ToyCar:
		await C.player.walk_to_clicked()
		await C.player.face_clicked()
		await C.player.say("Honey, here is your toy car!")
		await C.Popsy.say("YAY! Thanks a lot!!!")
		I.ToyCar.remove()
		D.PopsyHouseChat.turn_off_options(["AskBored"])
```

Save the script and run the game. Pick the toy car up, select it from the inventory (note how the cursor takes the shape of the item) and click on Popsy.

You should see the dialog happen, and the car is removed from your inventory.

**Congratulations! You've got to the end of this introductory guide!**
