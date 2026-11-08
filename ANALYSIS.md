# Project analysis and refactor notes

Audited with **Godot 4.7.2 stable** on 2026-11-08.

## Summary

The project is a valid Godot 4 project and already runs, but it carried several
tutorial-era patterns that make it fragile:

- a deprecated `TileMap` node in a 77 KB scene with an inline tile blob,
- a background duplicated inside `level.tscn` instead of reusing `bg.tscn`,
- input hard-coded to the editor's `ui_*` actions,
- the enemy finding the player through a hard-coded scene path,
- an animation named `Idele`, and no Walk animation in the enemy script,
- a menu built from a `Node2D` with absolute button positions,
- a leftover editor temp file.

The refactor below keeps the same art and level geometry. Movement speed and
jump height remain at the tutorial values; horizontal acceleration and friction
are now tunable exports. Nothing is drawn by code: everything is a Godot node,
scene, resource, or project setting.

## What was found

### 1. Deprecated TileMap

`level.tscn` used `[node name="TileMap" type="TileMap"]` with an inline
`TileSet` and `layer_0/tile_data` as a large `PackedInt32Array`. `TileMap` is
deprecated in Godot 4.3+ in favour of `TileMapLayer`.

**Impact:** future Godot versions can drop the node; the data is also awkward
to edit or merge.

**Change:** migrated with a Godot headless script that created a
`TileMapLayer`, copied all **1486** cells (`set_cell`), preserved the TileSet,
and saved the packed scene. The final scene has 1486 cells, one source, and 404
atlas tiles — the same as before.

### 2. Duplicated background

`level.tscn` embedded its own `ParallaxBackground` with three layers and three
texture references, while `bg.tscn` contained the same layers plus `bg.gd`.
The level copy did not have the script; the menu copy did.

`bg.gd` also decremented `scroll_offset` manually in `_process` while
`ParallaxBackground` already follows the active `Camera2D`. Instancing the same
scene in both places would therefore have double-scrolled the level.

**Change:** the level now instances `bg.tscn`. `bg.gd` only auto-scrolls when
there is no active camera (the menu), and leaves camera-driven parallax to the
engine in the level.

The menu also had a 648 px-tall backdrop in an 800 px window, leaving a grey
band at the bottom. The layers are now scaled 4.5× (1440×810) and centred, so
they cover the whole viewport.

### 3. Input map

The player used `ui_left`, `ui_right`, and `ui_accept`. Those are UI actions,
not gameplay actions, and they cannot be remapped independently of the editor.

**Change:** `project.godot` now defines `move_left`, `move_right`, and `jump`
with keyboard, D-pad, stick, and face-button bindings. The scripts use only
these actions.

### 4. Player controller

The old script mixed gravity, jumping, movement, animation, and flipping in one
function. On landing, `velocity.y > 0` could briefly play `Fall` after `Run`,
and the animation branch depended on `velocity.y == 0`.

**Change:** `Player/CharacterBody2D.gd` now exposes `speed`, `jump_velocity`,
`acceleration`, `friction`, `coyote_time`, and `jump_buffer_time`; animation
selection happens once after `move_and_slide()` and is based on floor state and
velocity. The player joins the `player` group in `_ready()`.

### 5. Enemy controller

The skeleton used `get_node("../../Node2D/Player")`, which breaks as soon as the
scene is instanced somewhere else, and it never played its Walk animation. Its
idle animation was misspelled `Idele` in `Skeleton.tscn`.

**Change:** `Mobs/CharacterBody2D.gd` finds the player through the `player`
group, flips the sprite, plays `Walk` while moving and `Idle` while waiting, and
uses the same exported gravity/speed setup. `Skeleton.tscn` now has `Idle` and
`Walk` animations, correct collision layers, and its detector only watches the
player layer. Empty placeholder child nodes were removed.

### 6. Menu and node structure

`Menu.tscn` was a `Node2D` with two buttons at fixed offsets in the top-left,
and `player.tscn` had a typo in its root name (`Playeer`) plus an empty `Player`
child node.

**Change:** the menu is now a full-rect `Control` with a centred `VBoxContainer`
(title, Play, Quit). The player root is named `Player`, the empty child nodes
are gone, and the player is a direct child of `Level` instead of being wrapped
in an otherwise empty `Node2D`.

### 7. TileSet size vs. art size (not changed)

The Oak Woods tileset image is 504×360 px, i.e. **21×15 tiles at 24×24 px**.
The scene's `TileSet` has no explicit size, so it uses the default **16×16** and
`TileSetAtlasSource.texture_region_size` is also 16×16. The 113×47-cell map is
therefore built on a 16 px grid while the art is drawn on a 24 px grid; each
ground tile shows only the top-left 16×16 crop of a 24×24 tile.

This is a real visual limitation, but fixing it means rebuilding the TileSet at
24×24 and repainting the level at a different scale. That is a level-design
change, not a safe refactor, so it was left alone and documented here.

### 8. Gameplay completeness

The level is the tutorial's test strip: a flat ground row from x = 0 to 112,
a solid wall at x = 99..112, one skeleton, and no goal, damage, health, respawn,
or audio. The player stops at the wall.

**Not changed in this pass.** The point of this pass was to make the existing
project clean and engine-correct without changing the game design.

### 9. Hygiene

- `Mobs/Ske9079.tmp` was an editor autosave leftover.
- `*.tmp` was not ignored.
- Script `.uid` files were untracked; they are generated by Godot 4.4+ and
  should normally be committed.

`.gitignore` now ignores `*.tmp` in addition to `.godot/`.

## Verification

Performed on a clean copy of the project (excluding `.git` and `.godot`):

```text
Godot_v4.7.2-stable_win64_console.exe --headless --path <copy> --import --quit
Godot_v4.7.2-stable_win64_console.exe --headless --path <copy> --quit-after 240 res://level.tscn
Godot_v4.7.2-stable_win64_console.exe --headless --path <copy> --quit-after 120 res://Menu.tscn
```

Results:

- import completed with no project errors (only the environment's missing
  `user://` directory / certificate-store messages were logged),
- both scenes ran with no script errors,
- level: `TileMapLayer` with 1486 cells, `Player` in the `player` group, camera
  present, `Background` using `res://bg.gd`,
- menu: `Control` root, both buttons present, `Background` instanced,
- the Play callback changed `current_scene` to `Level` successfully,
- input actions each have 4 events (keyboard bindings plus D-pad/stick or the A button); injected `D` and `Space` events matched `move_right` and `jump`,
- rendered menu and level frames were inspected.

## Recommended next steps

1. **Rebuild the level at the tileset's native 24×24 size.** Create a new
   `TileSet` resource with `tile_size = 24×24` and
   `texture_region_size = 24×24`, add the collision polygons in the TileSet
   editor, then paint a short level with platforms and pits. This is the single
   biggest visual improvement available.
2. **Add a small game loop** using engine nodes: a `Goal` `Area2D` with a
   `Sprite2D` sign, a respawn on falling below the map, a hitbox on the
   skeleton, a `CanvasLayer` HUD, and a pause menu. The existing `Attack.png`,
   `Take Hit.png`, and `Death.png` frames are ready for combat.
3. **Add audio** with `AudioStreamPlayer` nodes; no audio assets are currently
   in the project.
4. **Rename the tutorial script files** to `Player.gd`, `Skeleton.gd`, and
   `Background.gd` and update the `ext_resource` paths. Class names already make
   the scripts readable, so this is cosmetic.
5. **Add export presets** (Windows/Linux/Web) and run the import check in CI.
