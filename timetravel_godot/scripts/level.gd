extends Node2D
# level.gd - base for every map (town, storeroom, courtyard, hall, cave).
# A level owns its own collision grid, props, doors and enemies. main.gd keeps ONE level in the scene tree at a time;
# a level that is not in the tree is frozen exactly as you left it (dead rats stay dead, hurt rats stay hurt).
# It also has the light helpers the dark maps share (point_light, flicker_lights).
#
# What a map has to provide:   W, H, key, spawn / spawns, doors, enemy_plan(c), place_name / places
# (all optional except W, H, key). A map has no respawn spot: since Stage 7j a fall opens the death screen, which loads a save.

const Drawn = preload("res://scripts/drawn.gd")
const Sprites = preload("res://scripts/sprites.gd")
const Items = preload("res://scripts/items.gd")

const CELL := 64
const PICKUP_R := 10.0      # walking this close (px, feet to the item's foot) to something lying on the ground takes it
const PICKUP_TAG_R := 56.0  # a story item lying here shows its name while the hero is this close
const PICKUP_LIGHT := {"radius": 40.0, "color": Color(1.0, 0.95, 0.8), "energy": 0.7}   # a story item's own light on a dark map

var W := 1200
var H := 1340
var key := ""                       # "town", "storeroom" ... (main.gd looks levels up by this)
var spawn := Vector2.ZERO           # where a new game starts on this map
var spawns := {}                    # name -> {"pos": Vector2, "face": String}: where a door from another map puts you
# doors: [{"rect": Rect2 (stand here and press E), "prompt": Vector2 (where the E box is drawn), "to": level key, "spawn": spawn name}]
# a door with "auto": true has no E box: walking into its rect takes you through (bridges, open gates)
var doors: Array = []
# other things you use with E (the cave's cage door): [{"id": String, "rect": Rect2 (stand here), "prompt": Vector2 (the E box)}].
# The map says when one can be used (usable(id)) and what happens (use_spot(id)).
var uses: Array = []
# Place names (hud.gd shows one top-right for a few seconds when the hero's place changes): the map's own name, and named parts of it,
# [name, Rect2, note] where note is a quest event noted the first time the hero walks in ("" for none). The first part that holds the
# hero wins; outside all of them the map's own name applies. Each map sets these from a PLACES data const. Only well-known places get
# a name (the user's rule): a town, the ruins, a whole cave, not a room inside one.
var place_name := ""
var places: Array = []
# unnamed spots that tell the quest something the first time the hero walks in: [Rect2, quest event] (the cave's jail: "saw_cage").
# Each map sets these from a NOTES data const.
var notes: Array = []
var era := 1                        # which era the map belongs to (squad.gd: companions only appear in their own era)
# rest spots (a well, a fire): stand in `rect` and press E to rest, which restores the hero's hearts and autosaves (main.gd rest()).
# Resting only works while no enemy is hunting the hero (rest_open()); until then the prompt is dimmed with the reason.
# [{"rect": Rect2, "prompt": Vector2 (the E box), "name": String}]. Each map sets these from a RESTS data const.
var rests: Array = []
var dead_plan: Array = []           # enemy_plan() indices of the planned enemies that are dead (saved; combat.attach skips them;
                                    # combat.respawn brings the ordinary ones back on the hero's next visit or rest)
# Things lying on the ground (Stage 7g): walk over one to take it (check_pickups). Each map sets `pickup_plan` from a PICKUPS data const
# of [id, item, n, Vector2 (its foot)] rows, with an optional 5th field naming a look the map draws itself (draw_look: the cave's coin
# bags), and builds them with _make_pickups(). An enemy's drops (combat.gd DROPS) lie where it fell (drop()) and never vanish.
# Saved: the ids taken, and the drops still lying here.
var pickup_plan: Array = []
var taken: Array = []               # pickup_plan ids already taken
var pickups: Array = []             # what lies here now: {"id": String ("" for a drop), "item", "n", "pos": Vector2, "look", "node"}

var solid_rects: Array[Rect2] = []
var ysort: Node2D
var solids_body: StaticBody2D
var debug_node
var player            # set by main.gd
var dialogue          # set by main.gd (text data + quest marks)
var combat            # set by combat.gd when the fight moves to this map (maps that spawn enemies later, like the cave's ambush, need it)
var talking := false  # true while a dialogue box is open or a map fade is running
var npcs: Array = []
var rats: Array = []  # every enemy that lives on this map (rats, bandits, the giant rat)
# things the hero can hit that are not enemies (the training dummy): {"pos": Vector2 (foot), "t": seconds since the last hit,
# "dir": +1 / -1 (which way it tips), "lean": how far it tips, px sideways per px of height}. combat.gd hits them and updates lean;
# the prop just draws it.
var hittables: Array = []
# enemy groups that sleep until the hero comes close: name -> {"center": Vector2, "radius": float, "active": bool, "aggro": bool}
# (aggro = the whole group charges the moment it wakes, instead of just starting to look around)
var groups := {}
var fx_node           # combat's spark / text layer for this map
var populated := false
var rats_flee := true   # false: the rats of this map fight to the death (storeroom)

var _grid := {}       # spatial hash of solid rects (fast collision / line-of-sight for the AI)
var _see_through := {}  # solid rects that block feet but not sight: low props an enemy sees over (see solid())
var _shapes := {}       # solid rect -> its CollisionShape2D (so unsolid() can take a solid away again)
var _light_tex: Texture2D   # one soft round texture shared by every light of this map (see point_light())
var _flicker: Array = []    # lights that flicker like a flame (their steady energy is in meta "base")

# ---------------------------------------------------------------- set-up helpers (called from the map's _ready)
func _make_nodes() -> void:
	ysort = Node2D.new()
	ysort.y_sort_enabled = true
	add_child(ysort)
	solids_body = StaticBody2D.new()
	add_child(solids_body)

func _make_debug() -> void:
	debug_node = Drawn.new()
	debug_node.z_index = 100
	debug_node.visible = false
	debug_node.draw_fn = func(n):
		for r in solid_rects:
			n.draw_rect(r, Color(1, 0.75, 0, 0.8) if _see_through.has(r) else Color(1, 0, 0, 0.8), false)    # orange: see-through
		for d in doors:
			n.draw_rect(d["rect"], Color(0.2, 1, 0.4, 0.8), false)
		for g in groups.values():
			n.draw_arc(g["center"], g["radius"], 0.0, TAU, 40, Color(0.4, 0.7, 1, 0.7) if not g["active"] else Color(0.4, 0.7, 1, 0.25), 1.0)
	add_child(debug_node)

# a boxed E that floats over each door while the hero stands at it
func _make_door_prompts() -> void:
	for d in doors:
		var dd: Dictionary = d
		if dd.get("auto", false):
			continue
		var tag := prop(dd["prompt"].y + 1.0, func(n): _draw_door_prompt(n, dd), true, 0.1)
		tag.z_index = 60

func _draw_door_prompt(n, d: Dictionary) -> void:
	if player == null or talking or player.dead or not d["rect"].has_point(player.position):
		return
	_draw_e_box(n, d["prompt"])

# the same boxed E over each rest spot
func _make_rest_prompts() -> void:
	for r in rests:
		var rr: Dictionary = r
		var tag := prop(rr["prompt"].y + 1.0, func(n): _draw_rest_prompt(n, rr), true, 0.1)
		tag.z_index = 60

# "E Rest" while resting works, else the box dimmed with why not, so the player knows what is going on
func _draw_rest_prompt(n, r: Dictionary) -> void:
	if player == null or talking or player.dead or not r["rect"].has_point(player.position):
		return
	if busy():
		_draw_e_box(n, r["prompt"], "Not now", true)
	elif not rest_open():
		_draw_e_box(n, r["prompt"], "Enemies nearby", true)
	else:
		_draw_e_box(n, r["prompt"], "Rest")

# the map's PICKUPS (pickup_plan); a load takes the taken ones away again (load_state)
func _make_pickups() -> void:
	for row in pickup_plan:
		_add_pickup(row[0], row[1], row[2], row[3], row[4] if row.size() > 4 else "")

func _add_pickup(id: String, item: String, n: int, pos: Vector2, look := "") -> void:
	var p := {"id": id, "item": item, "n": n, "pos": pos, "look": look}
	p["node"] = prop(pos.y, func(nd): _draw_pickup(nd, p), true, 0.05)
	pickups.append(p)
	_light_pickup.call_deferred(p)     # deferred: a map adds its CanvasModulate after its pickups

# A story item (a quest part) on a dark map gets a small light of its own, so its halo shows through the dark (the user's play-test:
# the sword's hilt was a speck in the storeroom). Freed with the pickup (_remove_pickup).
func _light_pickup(p: Dictionary) -> void:
	if not pickups.has(p) or Items.info(p["item"])["kind"] != "story" or not _dark():
		return
	p["light"] = point_light(p["pos"] + Vector2(0, -10), PICKUP_LIGHT["radius"], PICKUP_LIGHT["color"], PICKUP_LIGHT["energy"])

func _dark() -> bool:
	for c in get_children():
		if c is CanvasModulate:
			return true
	return false

func _draw_pickup(n, p: Dictionary) -> void:
	if p["look"] != "":
		draw_look(p["look"], n, p["pos"].x, p["pos"].y)
		return
	Items.pickup(n, p["item"], p["pos"].x, p["pos"].y)
	# a story item says what it is while the hero is close, so it can't be mistaken for rubble
	if Items.info(p["item"])["kind"] == "story" and player != null and player.position.distance_to(p["pos"]) <= PICKUP_TAG_R:
		var font := ThemeDB.fallback_font
		var at := Vector2(p["pos"].x - 60.0, p["pos"].y - 32.0)
		n.draw_string_outline(font, at, Items.info(p["item"])["name"], HORIZONTAL_ALIGNMENT_CENTER, 120.0, 8, 3, Color.BLACK)
		n.draw_string(font, at, Items.info(p["item"])["name"], HORIZONTAL_ALIGNMENT_CENTER, 120.0, 8, Color("#fff0c0"))

# take a pickup off the map (taken, or already taken in a loaded save), with its light
func _remove_pickup(p: Dictionary) -> void:
	p["node"].queue_free()
	if p.has("light"):
		p["light"].queue_free()
	pickups.erase(p)

# a map that gives a pickup a look of its own draws it here (the cave's coin bags)
func draw_look(_look: String, _n, _x: float, _y: float) -> void:
	pass

# an enemy's drop: n of item where it fell, nudged aside from the drops already lying there so each can be seen
func drop(item: String, n: int, at: Vector2) -> void:
	var k := 0
	for p in pickups:
		if p["id"] == "" and p["pos"].distance_to(at) < 14.0:
			k += 1
	var pos := at + Vector2((k % 3 - 1) * 9.0, 2.0 + 6.0 * floorf(k / 3.0))
	_add_pickup("", item, n, pos if not feet_blocked(pos) else at)

# called by main.gd every frame of play: the hero takes whatever he walks over
func check_pickups() -> void:
	if player == null or pickups.is_empty():
		return
	for p in pickups.duplicate():
		if player.position.distance_to(p["pos"]) <= PICKUP_R:
			_take(p)

func _take(p: Dictionary) -> void:
	dialogue.inv.add(p["item"], p["n"])
	if p["id"] != "":
		taken.append(p["id"])
	_remove_pickup(p)

# the same boxed E over each use spot, while the hero stands at it and it can be used
func _make_use_prompts() -> void:
	for u in uses:
		var uu: Dictionary = u
		var tag := prop(uu["prompt"].y + 1.0, func(n): _draw_use_prompt(n, uu), true, 0.1)
		tag.z_index = 60

func _draw_use_prompt(n, u: Dictionary) -> void:
	if player == null or talking or player.dead or not u["rect"].has_point(player.position) or not usable(u["id"]):
		return
	_draw_e_box(n, u["prompt"])

# the boxed E; with a label, a small tag beside it says what E does ("Rest"); dim = it can't be done right now
func _draw_e_box(n, at: Vector2, label := "", dim := false) -> void:
	var font := ThemeDB.fallback_font
	var px: float = at.x - 6.0
	var py: float = at.y - 12.0
	var ink := Color("#3a2614")
	var paper := Color("#9a9080") if dim else Color("#f4ead0")
	Sprites.R(n, px - 1, py - 1, 13, 13, ink)
	Sprites.R(n, px, py, 11, 11, paper)
	n.draw_string(font, Vector2(px + 2, py + 9), "E", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, ink)
	if label == "":
		return
	var w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	Sprites.R(n, px + 12, py - 1, w + 6, 13, ink)
	Sprites.R(n, px + 13, py, w + 4, 11, Color(0.1, 0.08, 0.06, 0.85))
	n.draw_string(font, Vector2(px + 15, py + 8), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, paper)

func toggle_debug() -> void:
	debug_node.visible = not debug_node.visible

# ---------------------------------------------------------------- light (the dark indoor maps: storeroom, hall, cave)
# A dark map adds a CanvasModulate for its ambient colour, then point lights. flicker = true makes it a flame (torch, brazier, fire);
# the map's _process calls flicker_lights() every frame.
func point_light(pos: Vector2, radius: float, col: Color, energy: float, flicker := false) -> PointLight2D:
	if _light_tex == null:
		_light_tex = _gradient_tex()
	var l := PointLight2D.new()
	l.texture = _light_tex
	l.texture_scale = radius * 2.0 / 128.0
	l.color = col
	l.energy = energy
	l.position = pos
	add_child(l)
	if flicker:
		l.set_meta("base", energy)
		_flicker.append(l)
	return l

# depth = how far a flame dips below its steady energy (0.12 = between 76% and 100%)
func flicker_lights(depth := 0.12) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for l in _flicker:
		l.energy = l.get_meta("base") * (1.0 - depth + depth * sin(t * 11.0 + l.position.x * 0.13) * sin(t * 7.3 + l.position.y * 0.07))

func _gradient_tex() -> Texture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.45), Color(1, 1, 1, 0)])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 128
	tex.height = 128
	return tex

# ---------------------------------------------------------------- collision grid
func _cells(r: Rect2) -> Array:
	var out := []
	for gx in range(int(floorf(r.position.x / CELL)), int(floorf(r.end.x / CELL)) + 1):
		for gy in range(int(floorf(r.position.y / CELL)), int(floorf(r.end.y / CELL)) + 1):
			out.append(gx * 4096 + gy)
	return out

# low = true: a low prop (nest, dead tree, cactus, fallen column drum, agave, small rock) that you can't walk through but enemies
# can see over, so it is no cover. Walls, buildings, cliffs, pillars and big rocks are not low: they hide the hero.
func solid(x: float, y: float, w: float, h: float, low := false) -> void:
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(w, h)
	cs.shape = rs
	cs.position = Vector2(x + w / 2.0, y + h / 2.0)
	solids_body.add_child(cs)
	var r := Rect2(x, y, w, h)
	solid_rects.append(r)
	_shapes[r] = cs
	if low:
		_see_through[r] = true
	for k in _cells(r):
		if not _grid.has(k):
			_grid[k] = []
		_grid[k].append(r)

# take away a solid made by solid() with the same rect (a door swung open, a barricade cleared)
func unsolid(r: Rect2) -> void:
	solid_rects.erase(r)
	_see_through.erase(r)
	for k in _cells(r):
		if _grid.has(k):
			_grid[k].erase(r)
	if _shapes.has(r):
		_shapes[r].queue_free()
		_shapes.erase(r)

func prop(sort_y: float, fn: Callable, animated := false, interval := 0.0) -> Node2D:
	var n = Drawn.new()
	n.position = Vector2(0, sort_y)
	n.rebase_y = true
	n.animated = animated
	n.interval = interval
	n.draw_fn = fn
	ysort.add_child(n)
	return n

func _rect_blocked(r: Rect2) -> bool:
	for k in _cells(r):
		if _grid.has(k):
			for s in _grid[k]:
				if s.intersects(r):
					return true
	return false

# would a pair of feet standing here overlap a prop or wall?
func feet_blocked(p: Vector2) -> bool:
	return _rect_blocked(Rect2(p.x - 4.0, p.y - 3.0, 8.0, 3.0))

# clear line of sight between two ground points? (walls, buildings, cliffs, pillars and big props block it; low solids don't)
func los(a: Vector2, b: Vector2) -> bool:
	var steps := int(a.distance_to(b) / 4.0) + 1
	for i in range(1, steps):
		var p := a.lerp(b, float(i) / steps)
		var k := int(floorf(p.x / CELL)) * 4096 + int(floorf(p.y / CELL))
		if _grid.has(k):
			for r in _grid[k]:
				if r.has_point(p) and not _see_through.has(r):
					return false
	return true

# is this point inside something tall (it stops a flying arrow or stone, as it stops sight)?
func sight_blocked(p: Vector2) -> bool:
	var k := int(floorf(p.x / CELL)) * 4096 + int(floorf(p.y / CELL))
	if _grid.has(k):
		for r in _grid[k]:
			if r.has_point(p) and not _see_through.has(r):
				return true
	return false

# ---------------------------------------------------------------- doors, signs, people (the town overrides the last three)
func near_door() -> Dictionary:
	if player == null:
		return {}
	for d in doors:
		if not d.get("auto", false) and d["rect"].has_point(player.position):
			return d
	return {}

# the auto door the hero is standing in ({} if none); main.gd checks this every frame
func auto_door() -> Dictionary:
	if player == null:
		return {}
	for d in doors:
		if d.get("auto", false) and d["rect"].has_point(player.position):
			return d
	return {}

func near_sign() -> Dictionary:
	return {}

# the use spot the hero is standing at that can be used now ({} if none); dialogue.gd checks it when E is pressed
func near_use() -> Dictionary:
	if player == null:
		return {}
	for u in uses:
		if u["rect"].has_point(player.position) and usable(u["id"]):
			return u
	return {}

# the rest spot the hero is standing at ({} if none); dialogue.gd checks it when E is pressed
# no living enemy on this map is hunting the hero (rest spots and saving both need this; main.gd save_block). One that is running
# off or cowering doesn't count, or a wounded rat hiding in a corner would block resting for good.
func rest_open() -> bool:
	for r in rats:
		if r.alive and r.hunting():
			return false
	return true

# the rest spot the hero stands in, whatever the enemies are doing: E then reaches main.gd rest(), which says why it can't rest
func near_rest() -> Dictionary:
	if player == null:
		return {}
	for r in rests:
		if r["rect"].has_point(player.position):
			return r
	return {}

func usable(_id: String) -> bool:      # maps with use spots override these two
	return true

func use_spot(_id: String) -> void:
	pass

# a conversation with a "then" key has ended (dialogue.gd TALK): the map reacts (the cave's rider joins the hero)
func talk_done(_what: String) -> void:
	pass

func start_npcs() -> void:    # maps with people override this (main.gd calls it once, when the map is first built)
	pass

# the hero has just come in through `spawn_name` and the fade is over (main.gd travel): a map can start a scene here
# (the hall's return from the cave)
func arrived(_spawn_name: String) -> void:
	pass

func place_at(p: Vector2) -> String:
	for pl in places:
		if pl[1].has_point(p):
			return pl[0]
	return place_name

# main.gd calls this every frame: walking into a place or a spot with a note tells the quest (the cave's jail: "saw_cage")
func check_places() -> void:
	if player == null or dialogue == null:
		return
	for pl in places:
		if pl.size() > 2 and pl[2] != "" and not dialogue.quest.flags.get(pl[2], false) and pl[1].has_point(player.position):
			dialogue.quest.note(pl[2])
	for n in notes:
		if not dialogue.quest.flags.get(n[1], false) and n[0].has_point(player.position):
			dialogue.quest.note(n[1])

func npc_by_id(id: String):
	for n in npcs:
		if n.id == id:
			return n
	return null

func chatter_for(id: String) -> Array:
	return dialogue.chatter_for(id) if dialogue != null else []

func mark_for(id: String) -> String:
	return dialogue.mark_for(id) if dialogue != null else ""

# ---------------------------------------------------------------- saving (save.gd)
# a scripted fight or scene is running, so no save may be made (the cave's ambush and boss fight, the hall's scenes)
func busy() -> bool:
	return false

# what this map needs to come back as it was: the dead planned enemies, the living ones it added during play (they come back at
# home), the pickups taken and the drops still lying here. Maps with scripted state add their own keys (and read them back in load_state).
func save_state() -> Dictionary:
	var spawned := []
	for r in rats:
		if r.alive and r.plan_i < 0:
			spawned.append({"kind": r.kind, "pos": [r.home.x, r.home.y], "axis": [r.axis.x, r.axis.y], "span": r.span, "leash": r.leash})
	var drops := []
	for p in pickups:
		if p["id"] == "":
			drops.append([p["item"], p["n"], p["pos"].x, p["pos"].y])
	return {"dead": dead_plan.duplicate(), "spawned": spawned, "taken": taken.duplicate(), "drops": drops}

# called once, right after the map is built and its planned enemies spawned (combat.attach skips the dead ones by dead_plan)
func load_state(d: Dictionary) -> void:
	for id in d.get("taken", []):
		taken.append(String(id))
	for p in pickups.duplicate():
		if taken.has(p["id"]):
			_remove_pickup(p)
	for e in d.get("drops", []):
		_add_pickup("", String(e[0]), int(e[1]), Vector2(e[2], e[3]))
	for e in d.get("spawned", []):
		var r = combat.spawn_enemy({"kind": e["kind"], "pos": Vector2(e["pos"][0], e["pos"][1]),
			"axis": Vector2(e["axis"][0], e["axis"][1]), "span": float(e["span"])})
		r.leash = float(e["leash"])
		r.lose = r.leash + 80.0

# ---------------------------------------------------------------- enemies
# Which enemies live here. Returns [{"kind": "rat"|"bandit"|"giant", "pos": Vector2, "group": "", "axis": Vector2, "span": float}].
# c = combat.gd (for its tuning tables). Groups named in `groups` start asleep; everything else starts awake.
func enemy_plan(_c) -> Array:
	return []

# where the giant's summoned rats appear: {"left": [Vector2...], "right": [Vector2...]} (empty = around the giant)
func summon_points() -> Dictionary:
	return {}

# called by combat every frame: wake a sleeping group once the hero comes within its radius
func update_groups() -> void:
	if player == null:
		return
	for name in groups.keys():
		var g: Dictionary = groups[name]
		if g["active"]:
			continue
		if player.position.distance_to(g["center"]) <= g["radius"]:
			g["active"] = true
			for r in rats:
				if r.group == name:
					r.wake(g.get("aggro", false))
