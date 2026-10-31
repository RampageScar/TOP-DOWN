extends "res://scripts/player.gd"
# arena_player.gd - the combat test arena's hero. Since Stage 8e it is the game's player.gd as it is: the 8-way aim, the guard, the
# slow walk while blocking or drawing, and every drawing the arena added in 8b-8f (shoulder, knee, hammer, rise, overhead, the spear,
# the bow, the specials) moved into scripts/player.gd with the port. A drawing for a new arena-only move goes here, as an override of
# player.gd's _draw_swing() / _draw_sword_swing(), until it is ported too.
