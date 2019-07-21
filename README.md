# dynamic-platforms-godot
A plugin to create dynamic platforms in godot using curves.

Currently in development for first release.

A plugin for the godot game engine. It creates platforms using curves using predefined textures for edge, filling and corners. Collision shape is also automaticly created. 

## installation
just clone the repository in the addons folder in your project (if you dont have the folder create it) make sure the folder name is dynamicplatforms otherwise some dependency errors occur (godot does no longer support relative dependecy paths for scenes) then go to project settings-> plugins and change status to active. 

## Explanation/tutorial in progress
There are 2 parts to this plugin. The *tyle editor* and the *dynamicplatform node*. Platforms use styles to define how they look.

### Alternatives and similar plugins

There are some similar plugins for the engine that i am going to list here. I had either problems running them or they didnt have the features and flexibility i wanted so i made my own.

* https://github.com/remorse107/rmsmartshape2d
* https://github.com/RodZill4/godot-platform2d
