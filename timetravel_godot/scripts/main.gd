extends Node2D
# main.gd - wires everything together: the maps (LEVELS, travel between them, the foes that come back on a return), the hero, his
# progress (level and weapon XP), quest, inventory, dialogue, combat, the HUD, the menu, the shop, the dev tuning panel and the death
# screen, and the key bindings. It also moves the companions between maps and applies items to the hero or a companion (use_item,
# revive_mate). Saving and loading go through here too (save_game, autosave, rest, load_game, new_game).

const World = preload("res://scripts/world_waystation.gd")
const Storeroom = preload("res://scripts/storeroom.gd")
const Courtyard = preload("res://scripts/courtyard.gd")
const Hall = preload("res://scripts/hall.gd")
const Cave = preload("res://scripts/cave.gd")
const Player = preload("res://scripts/player.gd")
const Hud = preload("res://scripts/hud.gd")
const Quest = preload("res://scripts/quest.gd")
const Dialogue = preload("res://scripts/dialogue.gd")
const Combat = preload("res://scripts/combat.gd")
const Inventory = preload("res://scripts/inventory.gd")
const Menu = preload("res://scripts/menu.gd")
const Tuning = preload("res://scripts/tuning.gd")
const Shop = preload("res://scripts/shop.gd")
const Death = preload("res://scripts/death.gd")
const Squad = preload("res://scripts/squad.gd")
const Save = preload("res://scripts/save.gd")
const Rider = preload("res://scripts/rider.gd")
const Progress = preload("res://scripts/progress.gd")
const Items = preload("res://scripts/items.gd")
const MATE_SCRIPTS := {"farnaka": [Rider, Cave.RIDER]}     # how to rebuild a companion from a save: script, NPC data

# every map in the game: key -> script. A map is built the first time you walk into it and is then kept (frozen) for later.
const LEVELS := {"town": World, "storeroom": Storeroom, "courtyard": Courtyard, "hall": Hall, "cave": Cave}
const FADE_TIME := 0.25

var world            # the map the hero is on right now
var levels := {}     # key -> map node (built ones)
var fade_rect
var travelling := false
var player
var hud
var quest
var dialogue
var combat
var inv              # inventory.gd: what the hero carries
var squad            # squad.gd: the companions and their orders (their nodes are moved between the maps here)
var progress         # progress.gd: the hero's XP and level, each weapon's XP and level, and their caps
var saved_maps := {} # after a load: map key -> saved state, for the maps not built yet (each is applied when the map is first built)
var menu             # menu.gd: Tab / Esc / I
var tuning           # tuning.gd: the dev tuning panel (T)
var shop             # shop.gd: a keeper's stall (Nidu's), opened from a conversation
var death            # death.gd: the death screen (the hero fell: pick a save to go on from)
var autosave_due := false   # a door or a new objective asked for an autosave; it is written as soon as save_block() allows
var _seen_stage := 0        # the quest stage at the last check (a new one asks for an autosave)
var _seen_inv := -100000    # inv.changed_at at the last check (a rare find taken or sold changes the hero's maximums)

func _ready() -> void:
	_setup_input()
	# "Load" in the menu reloads the scene with the slot to load marked on the root; without it this is a new game
	Save.migrate()
	var data := {}
	if get_tree().root.has_meta("load_save"):
		data = Save.read(String(get_tree().root.get_meta("load_save")))
		get_tree().root.remove_meta("load_save")
	world = _make_level(data.get("map", "town"))
	add_child(world)

	player = Player.new()
	player.set_bounds(Vector2(world.W, world.H))
	player.position = world.spawn
	world.ysort.add_child(player)

	quest = Quest.new()
	inv = Inventory.new()
	squad = Squad.new()
	progress = Progress.new()
	progress.player = player
	progress.inv = inv
	quest.progress = progress
	quest.inv = inv
	if data.is_empty():
		inv.add("lasso", 1, false)       # the hero's one tool from the start
	else:
		Save.apply_progress(quest, inv, data)      # (before the hero: what he carries can change his maximums)
		Save.apply_hero(player, progress, data)
		for key in data.get("maps", {}).keys():
			saved_maps[key] = Save.map_state(data, key)
	world.player = player
	dialogue = Dialogue.new()
	dialogue.world = world
	dialogue.player = player
	dialogue.quest = quest
	dialogue.inv = inv
	dialogue.squad = squad
	dialogue.squad_order = squad_order
	dialogue.travel = travel
	dialogue.rest = rest
	dialogue.revive = revive_by_hand
	world.dialogue = dialogue
	add_child(dialogue)
	if not data.is_empty():
		_rebuild_squad(data)
	world.start_npcs()

	combat = Combat.new()
	combat.world = world
	combat.player = player
	combat.progress = progress
	combat.squad = squad
	combat.inv = inv
	combat.quest = quest
	add_child(combat)
	progress.leveled.connect(func(lv): combat.text(player.position + Vector2(0, -32), "Level %d!" % lv, Color("#ffe9a0"), 1.6))
	world.dead_plan = saved_maps.get(world.key, {}).get("dead", [])
	combat.setup()
	if not data.is_empty():
		combat.kills = int(data.get("kills", 0))
		for k in data.get("kills_by", {}).keys():
			combat.kills_by[String(k)] = int(data["kills_by"][k])
		var w := String(data["hero"].get("weapon", "unarmed"))
		combat.weapon = w if combat.WEAPON_KIT.has(w) and combat.has_weapon(w) else "unarmed"
		_apply_saved(world)
	_place_home(world)
	_seen_stage = quest.stage

	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Hud.new()
	hud.player = player
	hud.world = world
	hud.quest = quest
	hud.dialogue = dialogue
	hud.combat = combat
	hud.inv = inv
	hud.progress = progress
	layer.add_child(hud)

	menu = Menu.new()
	menu.main = self
	add_child(menu)
	dialogue.menu = menu
	shop = Shop.new()
	shop.main = self
	add_child(shop)
	dialogue.shop = shop
	tuning = Tuning.new()
	tuning.main = self
	add_child(tuning)
	death = Death.new()              # added last: it gets the keys before the other panels while it is up
	death.main = self
	add_child(death)

	# one black screen used for every fade (game start, going through a door)
	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 10
	add_child(fade_layer)
	fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.size = Vector2(480, 270)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(fade_rect)
	create_tween().tween_property(fade_rect, "color:a", 0.0, 0.5)

func _make_level(key: String):
	var lv = LEVELS[key].new()
	levels[key] = lv
	return lv

# Go through a door: fade to black, swap the map, put the hero at the named spawn of the new map, fade back in.
# Each map keeps its own enemies; the one you leave is removed from the scene tree, so it is frozen until you come back.
func travel(to_key: String, spawn_name: String) -> void:
	if travelling or player.dead or not LEVELS.has(to_key):
		return
	travelling = true
	world.talking = true
	combat.cancel_all()
	player.inv_t = maxf(player.inv_t, FADE_TIME * 4.0)
	player.lock = true
	var tw := create_tween()
	tw.tween_property(fade_rect, "color:a", 1.0, FADE_TIME)
	await tw.finished
	_switch_level(to_key, spawn_name)
	var tw2 := create_tween()
	tw2.tween_property(fade_rect, "color:a", 0.0, FADE_TIME)
	await tw2.finished
	player.lock = false
	world.talking = false
	travelling = false
	world.arrived(spawn_name)        # after the fade, so a scene the map starts here is not undone by the lines above
	autosave_due = true              # (after a scene the map starts here, since busy() holds it until then)

func _switch_level(key: String, spawn_name: String) -> void:
	var old = world
	var nw = levels.get(key)
	var fresh: bool = nw == null
	if fresh:
		nw = _make_level(key)
	old.talking = false
	old.ysort.remove_child(player)
	remove_child(old)
	add_child(nw)                    # the first time, this builds the map
	nw.player = player
	nw.dialogue = dialogue
	nw.talking = true
	if fresh:
		nw.start_npcs()              # people of a map are made once, the first time you arrive
	var sp: Dictionary = nw.spawns[spawn_name]
	player.set_bounds(Vector2(nw.W, nw.H))
	nw.ysort.add_child(player)
	player.position = sp["pos"]
	player.dir = sp["face"]
	player.impulse = Vector2.ZERO
	player.cam.make_current()
	player.cam.force_update_scroll()
	world = nw
	dialogue.world = nw
	hud.world = nw
	if fresh:
		nw.dead_plan = saved_maps.get(key, {}).get("dead", [])
	combat.attach(nw)
	if fresh:
		_apply_saved(nw)
	else:
		combat.respawn(nw)               # walking back in: the ordinary foes killed here are back
	_carry_squad(nw)
	_place_home(nw)

# ---------------------------------------------------------------- saving and loading (save.gd)
# a map built for the first time since a load gets its saved state (its dead enemies were already skipped by dead_plan)
func _apply_saved(lv) -> void:
	if saved_maps.has(lv.key):
		lv.load_state(saved_maps[lv.key])
		saved_maps.erase(lv.key)

# the squad from a save: each companion's node is made again on the map the game starts on (following ones beside the hero; ones at
# home are put on their home map by _place_home, or wait off the maps until it is built)
func _rebuild_squad(data: Dictionary) -> void:
	for e in Save.squad_list(data):
		var id: String = e[1]
		if not MATE_SCRIPTS.has(id):
			continue
		var node = MATE_SCRIPTS[id][0].new()
		world.ysort.add_child(node)
		world.npcs.append(node)
		node.setup(MATE_SCRIPTS[id][1], world)
		node.join()
		squad.join(id, node)
		node.hp = clampi(e[3], 0, node.max_hp) if e[3] >= 0 else node.max_hp
		node.focus = clampi(e[4], 0, node.max_focus)
		if e[2] == "home":
			squad.find(id)["order"] = "home"
			node.leave()
			_send_home(squad.find(id))
		else:
			node.arrive(player)
			if e[5] or node.hp <= 0:
				node.fall(true)       # fallen when the game was saved: still lying beside the hero

# "" when the game can be saved now, else why not (shown in the menu's System tab and at a rest spot)
func save_block() -> String:
	if player.dead or travelling or combat.over_t >= 0.0:
		return "Not now."
	if world.busy():
		return "Not in the middle of this."
	if not world.rest_open():
		return "Enemies nearby."
	return ""

# save into one of save.gd SLOTS (the menu's System tab)
func save_game(slot: String) -> bool:
	return save_block() == "" and Save.write(self, slot)

# write the autosave now if the game can be saved; false if it can't yet (autosave_due keeps asking)
func autosave() -> bool:
	if save_block() != "" or not Save.write(self, "auto"):
		return false
	autosave_due = false
	hud.notice("Autosaved.")
	return true

# E at a rest spot (a well, a fire): the hero rests (HP, stamina and focus back), the ordinary foes of this map come back (not next to
# him: combat.gd RESPAWN_CLEAR), and the autosave is written
func rest(_spot: Dictionary) -> void:      # (the notices are kept short: "Game saved." / "Enemies nearby.")
	var why := save_block()
	if why != "":
		hud.notice(why)
		return
	player.refill()
	player.poison = 0             # a rest cures a scorpion's poison too
	for m in combat.mates():      # the companions with him rest too: a fallen one gets up, and all are at full HP, unpoisoned
		m.rest()
	combat.respawn(world)
	if Save.write(self, "auto"):
		autosave_due = false
		hud.notice("Game saved.")
	else:
		hud.notice("The game could not be saved.")

# start again from a slot: reload the scene, and main._ready builds the game from it (the menu's Load, and the death screen)
func load_game(slot: String) -> void:
	if not Save.exists(slot):
		return
	get_tree().root.set_meta("load_save", slot)
	get_tree().paused = false
	get_tree().reload_current_scene()

func new_game() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

# the maps you left are out of the scene tree, so freeing main alone would leak them (a restart, a load): free them here
func _exit_tree() -> void:
	for lv in levels.values():
		if is_instance_valid(lv) and not lv.is_inside_tree():
			lv.free()

# ---------------------------------------------------------------- the squad (squad.gd keeps who and their orders; this moves their nodes)
# Every companion of this era who is following or waiting comes through the door with the hero (a waiting one follows again),
# wherever he was, so one told to follow from the Squad tab while at home catches up here.
func _carry_squad(nw) -> void:
	for m in squad.current(nw.era):
		if m["order"] == "home":
			continue
		m["order"] = "follow"
		_move_mate(m["node"], nw)
		m["node"].arrive(player)

# companions sent home whose home is this map stand at their home spot
func _place_home(lv) -> void:
	for m in squad.current(lv.era):
		var home: Dictionary = Squad.MATES[m["id"]]["home"]
		if m["order"] == "home" and home["map"] == lv.key and m["node"].get_parent() != lv.ysort:
			_move_mate(m["node"], lv)
			m["node"].at_home(home["pos"])

# take a companion off whatever holds him (a map, or main while his home map isn't built) and put him on map lv
func _move_mate(node, lv) -> void:
	for other in levels.values():
		other.npcs.erase(node)
	if node.get_parent() != null:
		node.get_parent().remove_child(node)
	lv.ysort.add_child(node)
	lv.npcs.append(node)
	node.world = lv
	node.visible = true
	node.modulate.a = 1.0
	node.process_mode = Node.PROCESS_MODE_INHERIT

# an order from the Squad tab or from talking to him (dialogue.gd): "follow" | "wait" | "home" (Disband). who = his id or his node.
# Disband is refused while the story still needs him (quest.gd NEEDS); this is the one guard every caller passes through.
func squad_order(who, order: String) -> void:
	var m: Dictionary = squad.find(who)
	if m.is_empty() or m["order"] == order:
		return
	if order == "home" and quest.needed(m["id"]) != "":
		hud.notice("Not now: " + quest.needed(m["id"]) + ".")
		return
	if order == "home" and m["node"].down:      # a fallen man can't walk home (Follow / Wait just keep him down where he lies)
		hud.notice("Not now: revive him first.")
		return
	var node = m["node"]
	m["order"] = order
	if m.has("fade") and m["fade"].is_valid():
		m["fade"].kill()                 # called back while fading out on his way home
		node.modulate.a = 1.0
	match order:
		"follow":
			if node.get_parent() == world.ysort:
				node.follow_again()
			# (at home on another map: he catches up at the hero's next door, _carry_squad)
		"wait":
			node.hold()
		"home":
			node.leave()
			var tw := create_tween()
			tw.tween_property(node, "modulate:a", 0.0, 0.5)
			tw.tween_callback(func(): _send_home(m))
			m["fade"] = tw

# ---------------------------------------------------------------- items for the hero and his companions (Stage 7i)
# a companion's name, from his node (dialogue.gd PEOPLE via squad.gd MATES)
func mate_name(node) -> String:
	var m: Dictionary = squad.find(node)
	return dialogue.PEOPLE[Squad.MATES[m["id"]]["person"]]["name"] if not m.is_empty() else "He"

# the companions with the hero on this map who have fallen
func fallen_mates() -> Array:
	return combat.mates().filter(func(n): return n.down)

# a Reviving Potion on a fallen companion: he gets up with combat.gd RIDER.revive % of his HP. false if he isn't down or there is no
# potion. Both ways of reviving come here: E beside him (revive_by_hand) and the menu (use_item).
func revive_mate(node) -> bool:
	if not node.down or not inv.remove("revive_potion"):
		return false
	node.revive(Combat.RIDER["revive"])
	return true

# E beside a fallen companion (dialogue.gd)
func revive_by_hand(node) -> void:
	if revive_mate(node):
		hud.notice("%s is back on his feet." % mate_name(node))
	else:
		hud.notice("You have no Reviving Potion.")

# Use one of item `id` on the hero (target == player) or give it to a companion (his node): healing food and potions give HP, focus
# potions focus, the Antidote cures poison, the Reviving Potion gets a fallen companion up. The item is used up only if it did something. Returns the line the
# menu shows.
func use_item(id: String, target) -> String:
	var it := Items.info(id)
	var hero: bool = target == player
	var verb: String = it.get("use", "eat")
	var what: String = String(it["name"]).to_lower()
	var who: String = "You %s" % verb if hero else "%s %ss" % [mate_name(target), verb]
	if it.get("revive", false):
		if hero:
			return "Only for a fallen companion."
		if not target.down:
			return "He's still on his feet."
		return "%s is back on his feet." % mate_name(target) if revive_mate(target) else "You have no Reviving Potion."
	if not hero and target.down:
		return "Revive him first."
	if it.get("cure", false):        # the Antidote (Stage 7k): ends a poison (combat.gd POISON), nothing else
		if target.poison <= 0:
			return "You're not poisoned." if hero else "He's not poisoned."
		target.poison = 0
		inv.remove(id)
		return "%s the %s. The poison is gone." % [who, what]
	if it.has("heal"):
		var got: int
		if hero:
			got = mini(int(it["heal"]), player.max_hp - player.hp)
			player.hp += got
		else:
			got = target.heal(int(it["heal"]))
		if got <= 0:
			return ("You're not hurt." if verb == "drink" else "You're not hungry.") if hero else "He's not hurt."
		inv.remove(id)
		return "%s the %s. +%d HP" % [who, what, got]
	if it.has("focus"):
		var got2: int
		if hero:
			got2 = mini(int(it["focus"]), player.max_focus - player.focus)
			player.focus += got2
		else:
			got2 = target.add_focus(int(it["focus"]))
		if got2 <= 0:
			return "Your head is already clear." if hero else "His head is already clear."
		inv.remove(id)
		return "%s the %s. +%d focus" % [who, what, got2]
	return ""

# after he has faded out: to his home spot if that map is built, else off the maps (under main, hidden) until it is (_place_home)
func _send_home(m: Dictionary) -> void:
	if m["order"] != "home":
		return          # called back to follow while he was fading
	var node = m["node"]
	var home: Dictionary = Squad.MATES[m["id"]]["home"]
	if levels.has(home["map"]):
		_move_mate(node, levels[home["map"]])
		node.at_home(home["pos"])
		return
	for other in levels.values():
		other.npcs.erase(node)
	node.get_parent().remove_child(node)
	add_child(node)
	node.visible = false
	node.process_mode = Node.PROCESS_MODE_DISABLED

# walking into an "auto" door (the bridge, the open castle gate) takes you through without pressing E; walking over something lying on
# the ground picks it up (level.gd check_pickups)
func _process(_dt: float) -> void:
	if inv.changed_at != _seen_inv:
		_seen_inv = inv.changed_at
		progress.apply_max()
		quest.check_items()       # all the parts an objective asks for are carried (Datis's sword: the blade and the hilt)
	if travelling or world.talking or player.dead:
		return
	if quest.stage != _seen_stage:     # the main objective moved on (maps only note events; saving is decided here)
		_seen_stage = quest.stage
		autosave_due = true
	if autosave_due:
		autosave()
	world.check_places()
	world.check_pickups()
	var d: Dictionary = world.auto_door()
	if not d.is_empty():
		travel(d["to"], d["spawn"])

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug"):
		world.toggle_debug()
	elif event.is_action_pressed("gallery"):
		hud.gallery = not hud.gallery
	elif event.is_action_pressed("restart"):
		get_tree().reload_current_scene()
	elif event.is_action_pressed("switch_weapon") and not world.talking and not player.dead:
		var said: String = combat.switch_weapon()     # 1: the next weapon carried (Stage 8e); the HUD's badge shows it too
		if said != "":
			hud.notice(said)

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

# Stage 8e (the arena's keys, the user's choice): the attacks on the mouse, Space blocks
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
	_bind("gallery", [KEY_G])
	_bind("menu", [KEY_TAB, KEY_ESCAPE])    # closes a panel (the menu, the shop, the tuning panel) or backs out of a choice in it
	# the menu's own tabs, each opened by its key (Stage 7k, the user's keys): I Player, M Map, Tab Squad, Esc System (and J Journal)
	_bind("inventory", [KEY_I])
	_bind("journal", [KEY_J])
	_bind("map", [KEY_M])
	_bind("squad_menu", [KEY_TAB])
	_bind("system_menu", [KEY_ESCAPE])
	_bind("switch_weapon", [KEY_1])      # the next weapon carried (Stage 7l: fists <-> the sword; 8e: the spear and the bow too)
	_bind("tuning", [KEY_T])
