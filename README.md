# Godot Platformer

A small 2D platformer built with **Godot 4.7** and the Oak Woods asset pack.
The project started as a tutorial (lesson 5) and has been cleaned up to use
current Godot nodes and project settings.

## Run

1. Open `project.godot` in Godot 4.7 or newer.
2. Press **F5**. The main scene is `Menu.tscn`.

The project uses the **Mobile** renderer and nearest-neighbour texture
filtering, so the pixel art stays sharp.

## Controls

| Action | Keyboard | Gamepad |
| --- | --- | --- |
| Move | `A` / `D` or Left / Right | Left stick or D-pad |
| Jump | `Space`, `W`, or Up | A |
| Menu | Mouse / keyboard focus | D-pad + A |

The actions are defined in **Project Settings → Input Map** as `move_left`,
`move_right`, and `jump`. Scripts only use these actions, never raw key codes.

## Project layout

```
Menu.tscn / Menu.gd        Main menu (Control layout)
level.tscn                 Test level (TileMapLayer + Player + Skeleton)
bg.tscn / bg.gd            Shared parallax background
Player/player.tscn         Player scene
Player/CharacterBody2D.gd  Player controller (class_name Player)
Mobs/Skeleton.tscn         Skeleton enemy scene
Mobs/CharacterBody2D.gd    Skeleton AI (class_name SkeletonEnemy)
oak_woods_v1.0/            Art assets (Oak Woods v1.0)
```

The background is a single reusable scene, instanced by both the menu and the
level. In the menu it drifts slowly because there is no camera; in the level
the `Camera2D` drives the `ParallaxBackground` automatically.

## Current state

This is still the tutorial's test level: a long flat strip with a wall at the
end. It is useful for exercising movement, jumping, animation, and the skeleton
detector, but it is not a finished game.

Known limitations:

- The TileSet is configured for **16×16** cells while the Oak Woods tileset art
  is drawn on a **24×24** grid, so ground tiles are cropped. Fixing that means
  rebuilding the TileSet and repainting the level.
- There is no win/lose condition, health, combat, or audio yet.
- The player and skeleton scripts still live in files named
  `CharacterBody2D.gd` (a tutorial leftover); they expose `Player` and
  `SkeletonEnemy` class names.

See [ANALYSIS.md](ANALYSIS.md) for the full audit and the changes already made.

## Assets

Oak Woods v1.0 by **brullov**. The pack's own notes are in
`oak_woods_v1.0/readme.TXT`. This repository is a learning project; check the
asset pack licence before redistributing the art.

## Tutorial

Lesson 5: https://www.youtube.com/watch?v=S_9eoLGliwk&list=PLpp4UXjsd_VeN7FrIbk7suElcL3bm6eLB&index=5
