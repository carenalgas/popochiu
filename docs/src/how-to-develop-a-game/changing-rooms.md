---
weight: 2025
---

## How to change rooms

You can change a room by using ```E.goto_room('RoomName')``` or ```R.current_room = R.RoomName```. The room names can be easily found in the Main tab of the Popochiu Dock under the rooms section.

In this example I have a hotspot called 'RoomTwoExit' and switching to a room called 'RoomTwo' in real life you would use more meaningful and descriptive names:
```
func _on_click() -> void:
    await C.player.walk_to_clicked()
    await C.player.face_down()
    E.goto_room('RoomTwo')

# Allows the player to double click hot spot to change rooms without walking to the hotspot
func _on_double_click() -> void:
    # Just change room
    E.goto_room('RoomTwo')
```

In the 'RoomOne' room script you can do the following to position the player on entry of that room:
```
func _on_room_entered() -> void:
    # Example of changing the player starting location to a marker the first time the room is visited.
    # You can also use this for writing cutscenes the first time the room is visited.
    if state.visited_first_time:
        await C.player.teleport_to_marker('PlayerStart')
    
    # Example of checking the last room the player was in and moving the player to different
    # hotspots and changing the direction the player is facing
    if C.player.last_room == 'RoomTwo':
        await C.player.teleport_to_hotspot('RoomTwoExit')
        await C.player.face_right()
    elif C.player.last_room == 'RoomThree':
        await C.player.teleport_to_hotspot('RoomThreeExit')
        await C.player.face_left()
```
