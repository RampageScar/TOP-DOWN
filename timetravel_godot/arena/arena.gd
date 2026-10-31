extends Node2D
# arena.gd - the combat test arena (Stage 8a, the user's request): a light stand-in for main.gd, run on its own (open arena/arena.tscn
# in the editor and press F6, or see the README). It builds only what a fight needs: the arena map (arena_map.gd), the hero
# (arena_player.gd: the game's player.gd with an 8-way aim), his progress and what he carries (scripts/progress.gd,
# scripts/inventory.gd: the levels and the sword), the arena's own copy of the combat code (arena_combat.gd), a small HUD
# (arena_hud.gd), the arena's tuning panel (arena_tuning.gd, T: every move's numbers, enemy HP and enemy damage) and the arena panel
# (arena_panel.gd, Tab: the spawner, the cheats and the hero's levels, the weapon picker, the readouts).
# Keys (Stages 8b-8c): Mouse 1 light, Mouse 2 heavy (held with the bow: draw), Space block, Shift dodge, Q lasso,
# 1 next weapon (fists, sword, spear, bow).
# No quest, dialogue, squad, saves, menu or death screen: nothing here touches the story game or the user's saves.
# combat, world, player, levels and travelling have the same names as on main.gd, so tuning.gd works with this node as its `main`.

const ArenaMap = preload("res://arena/arena_map.gd")
const ArenaCombat = preload("res://arena/arena_combat.gd")
const ArenaHud = preload("res://arena/arena_hud.gd")
const ArenaPanel = preload("res://arena/arena_panel.gd")
const ArenaPlayer = preload("res://arena/arena_player.gd")
const ArenaTuning = preload("res://arena/arena_tuning.gd")
const Progress = preload("res://scripts/progress.gd")
const Inventory = preload("res://scripts/inventory.gd")

const SPAWN_RING := 110.0     # spawned enemies stand in a ring this far round the hero (nudged off walls and columns)
const BOSS_RING := 140.0      # the giant and the chief a little further off
const EDGE := 20.0            # and at least this far inside the floor

var world
var levels := {}
var travelling := false       # (never: there is one map; tuning.gd reads it)
var player
var progress
var inv
var combat
var hud
var tuning
var panel

func _ready() -> void:
	_setup_input()
	world = ArenaMap.new()
	levels[world.key] = world
	add_child(world)

	player = ArenaPlayer.new()
	player.set_bounds(Vector2(world.W, world.H))
	player.position = world.spawn
	player.dir = world.spawns["start"]["face"]
	player.aim_from_dir()
	world.ysort.add_child(player)
	world.player = player

	inv = Inventory.new()
	inv.add("lasso", 1, false)
	inv.add("sword", 1, false)        # every weapon is in hand from the start (the weapon picker)
	progress = Progress.new()
	progress.player = player
	progress.inv = inv

	combat = ArenaCombat.new()
	combat.world = world
	combat.player = player
	combat.progress = progress
	combat.inv = inv
	add_child(combat)
	combat.setup()

	var layer := CanvasLayer.new()
	add_child(layer)
	hud = ArenaHud.new()
	hud.player = player
	hud.world = world
	hud.combat = combat
	hud.inv = inv
	hud.progress = progress
	layer.add_child(hud)

	tuning = ArenaTuning.new()
	tuning.main = self
	add_child(tuning)
	panel = ArenaPanel.new()
	panel.main = self
	add_child(panel)

# count enemies of `kind` at `level` in a ring round the hero; awake = they come at him at once (else they patrol and must spot him)
func spawn(kind: String, count: int, level: int, awake: bool) -> void:
	var ring := BOSS_RING if kind in combat.BOSSES else SPAWN_RING
	var a0 := randf() * TAU
	var lo: Vector2 = world.FLOOR.position + Vector2(EDGE, EDGE)
	var hi: Vector2 = world.FLOOR.end - Vector2(EDGE, EDGE)
	for i in range(count):
		var p: Vector2 = player.position + Vector2.RIGHT.rotated(a0 + TAU * i / count) * ring
		p = p.clamp(lo, hi)
		combat.spawn_enemy({"kind": kind, "pos": p, "level": level}, awake)

# the hero's level (1..10): his XP set to that level's total, his maximums from it, all three bars full
func set_hero_level(l: int) -> void:
	progress.xp = Progress.total_for(l)
	progress.level = l
	progress.apply_max()
	player.refill()

# a weapon's level (1..its top): its weapon XP set to that level's total
func set_weapon_level(w: String, l: int) -> void:
	progress.wxp[w] = progress.wtotal(w, l)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug"):
		world.toggle_debug()
	elif event.is_action_pressed("restart"):
		get_tree().reload_current_scene()
	elif event.is_action_pressed("clear_field"):
		combat.clear_field()
		hud.notice("Field cleared.")
	elif event.is_action_pressed("switch_weapon") and not player.dead:
		var w: String = combat.switch_weapon()      # 1: the next weapon (arena_combat.gd WEAPON_LIST)
		if w != "":
			hud.notice(w)

func _bind(action: String, keys: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for k in keys:
		var e := InputEventKey.new()
		e.physical_keycode = k
		InputMap.action_add_event(action, e)

func _bind_mouse(action: String, button: MouseButton) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	var e := InputEventMouseButton.new()
	e.button_index = button
	InputMap.action_add_event(action, e)

# the keys a fight needs (as main.gd binds them, but the attacks on the mouse: Stage 8b), and the arena's own
func _setup_input() -> void:
	_bind("move_left", [KEY_A, KEY_LEFT])
	_bind("move_right", [KEY_D, KEY_RIGHT])
	_bind("move_up", [KEY_W, KEY_UP])
	_bind("move_down", [KEY_S, KEY_DOWN])
	_bind("interact", [KEY_E])
	_bind_mouse("light", MOUSE_BUTTON_LEFT)
	_bind_mouse("heavy", MOUSE_BUTTON_RIGHT)
	_bind("block", [KEY_SPACE])
	_bind("dodge", [KEY_SHIFT])
	_bind("lasso", [KEY_Q])
	_bind("restart", [KEY_R])
	_bind("debug", [KEY_B])
	_bind("menu", [KEY_TAB, KEY_ESCAPE])    # closes a panel (the arena panel, the tuning panel)
	_bind("switch_weapon", [KEY_1])
	_bind("tuning", [KEY_T])
	_bind("arena_panel", [KEY_TAB])
	_bind("clear_field", [KEY_C])
