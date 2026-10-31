extends Node2D
# npc.gd - one character (the town's are built from npc_data.gd, the other maps' from their NPCS data). rider.gd extends it.
# Ambient ones walk routes / do idle work and mutter lines in a white oval bubble when you are close.
# Talkable ones (Arshan, Nidu, Datis) show a small E tag when you are near; Datis wears a "?" while he has a quest, and a shopkeeper
# (Nidu) a coin.
# Moves only along data routes, so there is no pathfinding; it never steps into a prop and it waits for the hero.

const Sprites = preload("res://scripts/sprites.gd")
const Drawn = preload("res://scripts/drawn.gd")
const CP = preload("res://scripts/castle_props.gd")
const Items = preload("res://scripts/items.gd")

const HEAR := 60.0          # distance at which ambient chatter appears
const TALK_RANGE := 26.0    # distance at which E works
const SHOW_TIME := 3.0      # a chatter line is visible this long...
const CYCLE_TIME := 4.2     # ...then the next one starts after this long

var id := ""
var talk := false
var talk_id := ""           # the TALK entry to use instead of the id's own ("" = the id's): a squad mate's waiting / home talk
var sprite := "person"
var look := {}
var look_name := ""
var dir := "down"
var idle := "none"
var acc: Array = []         # things carried (jar, spear, scroll, plate); the data may give one name or a list
var mode := "stay"
var route: Array = []
var speed := 22.0
var pause := 2.0
var follow_id := ""
var follow
var sc := 1.0
var world
var lines: Array = []

var t := 0.0
var wp := 0
var wait := 0.0
var moving := false
var anim := 0.0
var chat_i := 0
var chat_t := 0.0
var bub
var shout_text := ""        # a line floating over the head, shown even while the world is "talking" (the king's call)
var shout_t := 0.0

func setup(d: Dictionary, w) -> void:
	world = w
	id = d["id"]
	talk = d["type"] == "talk"
	sprite = d.get("sprite", "person")
	look_name = d.get("look", "")
	look = Sprites.PALETTES.get(look_name, {})
	dir = d.get("face", "down")
	idle = d.get("idle", "none")
	var a = d.get("acc", [])
	acc = a if a is Array else [a]
	mode = d.get("mode", "stay")
	speed = d.get("speed", 22.0)
	pause = d.get("pause", 2.0)
	follow_id = d.get("follow", "")
	sc = d.get("scale", 1.0)
	scale = Vector2(sc, sc)
	position = Vector2(d["pos"][0], d["pos"][1])
	for p in d.get("route", []):
		route.append(Vector2(p[0], p[1]))
	lines = world.chatter_for(id)
	t = randf() * 5.0
	if d.has("solid"):
		var body := StaticBody2D.new()
		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		var sz: Array = d["solid"]
		rs.size = Vector2(sz[0], sz[1])
		cs.shape = rs
		cs.position = Vector2(0, -sz[1] / 2.0)
		body.add_child(cs)
		body.scale = Vector2(1.0 / sc, 1.0 / sc)
		add_child(body)
	bub = Drawn.new()
	bub.animated = true
	bub.draw_fn = _draw_bubble
	bub.position = Vector2(0, -30 if sprite != "king" else -58)     # the seated king sits on a raised throne, so his head is higher
	bub.scale = Vector2(1.0 / sc, 1.0 / sc)
	bub.z_index = 60
	bub.process_mode = Node.PROCESS_MODE_ALWAYS   # keeps redrawing while paused so bubbles vanish when a dialogue opens
	add_child(bub)

# float a line over this person for `secs` seconds
func shout(text: String, secs: float) -> void:
	shout_text = text
	shout_t = secs

func _process(delta: float) -> void:
	t += delta
	if shout_t > 0.0:
		shout_t -= delta
	moving = false
	if follow == null and follow_id != "":
		follow = world.npc_by_id(follow_id)
	if mode == "patrol" or mode == "dash":
		_walk_route(delta)
	elif mode == "chase" and follow != null:
		var to: Vector2 = follow.position - position
		if to.length() > 14.0:
			_move(to.normalized(), speed, delta)
	_update_chat(delta)
	queue_redraw()

func _walk_route(delta: float) -> void:
	if wait > 0.0:
		wait -= delta
		return
	var to: Vector2 = route[wp] - position
	if to.length() < 1.5:
		wait = pause
		wp = (wp + 1) % route.size()
		return
	_move(to.normalized(), speed, delta)

func _move(v: Vector2, sp: float, delta: float) -> void:
	var pl = world.player
	if pl != null and pl.position.distance_to(position + v * 9.0) < 13.0:
		return    # wait for the hero to pass
	var np: Vector2 = position + v * sp * delta
	if world.feet_blocked(np):
		return
	position = np
	moving = true
	anim += delta * sp * 0.13
	if absf(v.x) > absf(v.y):
		dir = "right" if v.x > 0.0 else "left"
	else:
		dir = "down" if v.y > 0.0 else "up"

func _update_chat(delta: float) -> void:
	var pl = world.player
	if lines.is_empty() or talk or pl == null or world.talking:
		return
	if pl.position.distance_to(position) > HEAR:
		chat_t = 0.0
		return
	chat_t += delta
	if chat_t >= CYCLE_TIME:
		chat_t -= CYCLE_TIME
		chat_i = (chat_i + 1) % lines.size()

# what the bubble above the head should say right now ("" = nothing)
func chat_text() -> String:
	if shout_t > 0.0:
		return shout_text
	if lines.is_empty() or talk or world.talking or chat_t <= 0.0 or chat_t > SHOW_TIME:
		return ""
	return lines[chat_i % lines.size()]

func near_hero() -> bool:
	var pl = world.player
	return pl != null and pl.position.distance_to(position) < TALK_RANGE

# ---------- drawing ----------
func _draw() -> void:
	var bob := 0
	var sx := 0.0
	match idle:
		"bob": bob = 1 if int(t * 1.6) % 2 == 1 else 0
		"work": bob = 1 if int(t * 5.0) % 2 == 1 else 0
		"stir": bob = 1 if int(t * 4.0) % 2 == 1 else 0
		"sway": sx = 1.0 if fmod(t, 3.2) > 2.7 else 0.0
		"brush": sx = float(int(t * 3.0) % 2) if dir == "left" else 0.0
	match sprite:
		"camel":
			Sprites.camel(self, 0, 0, 1 if dir == "right" else -1, t * 1.2)
		"lizard":
			Sprites.lizard(self, 0, 0, -1 if dir == "left" else 1, anim * 2.0)
		"sleeper":
			Sprites.sleeper(self, 0, 0, look)
			_draw_zzz()
		"king":
			CP.king_seated(self, 0, 0, t)
		_:
			Sprites.person(self, sx, -bob, dir, int(anim), moving, look)
			_draw_extras(sx, bob)

func _draw_extras(sx: float, bob: int) -> void:
	var f := int(t * 6.0) % 2
	var flip := -1.0 if dir == "left" else 1.0
	if "jar" in acc:
		var jy := -26 - bob
		Sprites.R(self, -3 + sx, jy, 6, 6, Color("#b8744a")); Sprites.R(self, -2 + sx, jy - 2, 4, 2, Color("#c8825a"))
	if "spear" in acc:      # a royal guard's spear, held upright at his side
		var sx2 := flip * 8.0
		Sprites.R(self, sx2 - 1, -40, 2, 40, Color("#3a2517")); Sprites.R(self, sx2 - 1, -40, 1, 40, Color("#8a5a32"))
		Sprites.R(self, sx2 - 2, -46, 4, 7, Color("#3a2517")); Sprites.R(self, sx2 - 1, -45, 2, 5, Color("#d2cfc3"))
		Sprites.R(self, sx2 - 3, -36, 6, 1, Color("#e8b838"))
	if "plate" in acc:      # a dish of flat bread and pomegranates held out in one hand (the servant)
		var px := flip * (8.0 if dir == "down" or dir == "up" else 7.0)
		var py := -9.0 - bob
		draw_colored_polygon(Sprites._ellipse(Vector2(px, py), 11.0, 5.0, 14), Color("#3a2614"))
		draw_colored_polygon(Sprites._ellipse(Vector2(px, py), 9.0, 3.0, 14), Color("#e8e0c8"))
		Sprites.R(self, px - 4, py - 3, 4, 3, Color("#b07a3a")); Sprites.R(self, px - 4, py - 3, 3, 1, Color("#d8a05a"))     # bread
		Sprites.R(self, px + 1, py - 2, 2, 2, Color("#8a2420")); Sprites.R(self, px + 2, py - 3, 2, 2, Color("#c8402e"))     # pomegranates
		Sprites.R(self, px + 3, py - 3, 1, 1, Color("#e8786a"))
	if "scroll" in acc:     # an open scroll held at chest height in front of him (a reading scholar)
		var px := 3.0 if flip > 0.0 else -10.0
		var py := -13 - bob
		Sprites.R(self, px, py, 7, 5, Color("#3a2614"))
		Sprites.R(self, px + 1, py + 1, 5, 3, Color("#e8dcc0")); Sprites.R(self, px + 2, py + 2, 3, 1, Color("#8a7a5a"))
		Sprites.R(self, px, py - 1, 1, 7, Color("#8a5a32")); Sprites.R(self, px + 6, py - 1, 1, 7, Color("#8a5a32"))   # the two rollers
	if idle == "stir":
		Sprites.R(self, flip * 7 - 1, -14 + f, 2, 6, Color("#6b4a2b")); Sprites.R(self, flip * 7 - 1, -8 + f, 3, 2, Color("#c9c9c9"))
	if idle == "brush":
		var bx := -10 + int(t * 3.0) % 2 * 2
		Sprites.R(self, bx, -12, 4, 3, Color("#6b4a2b")); Sprites.R(self, bx, -9, 4, 1, Color("#e8dcc0"))

func _draw_zzz() -> void:
	var font := ThemeDB.fallback_font
	for i in range(3):
		var ph := fmod(t * 0.7 + i * 0.33, 1.0)
		var a := 1.0 - ph
		draw_string(font, Vector2(14 + i * 3 + ph * 4, -16 - ph * 18), "z", HORIZONTAL_ALIGNMENT_LEFT, -1, 8 + i * 2, Color(1, 1, 1, a))

# bubble layer (own node so it sits above everything)
func _draw_bubble(n) -> void:
	if world.talking and shout_t <= 0.0:
		return
	var txt := chat_text()
	var mark: String = world.mark_for(id) if talk else ""
	if txt != "":
		_oval(n, txt, false)
	elif mark == "quest":
		_oval(n, "?", true)
	elif mark == "shop":
		_oval(n, "", false, "coins")
	elif mark == "chat":
		_oval(n, "...", false)
	if talk and near_hero():
		_etag(n)

# icon: an items.gd icon drawn in the oval instead of text (the shopkeeper's coin)
func _oval(n, txt: String, quest: bool, icon := "") -> void:
	var font := ThemeDB.fallback_font
	var fs := 10 if quest else 8
	var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var w := maxf(16.0, tw * 1.35 + 10.0) if icon == "" else 20.0
	var h := 13.0 if not quest and icon == "" else 15.0
	var by := -sin(t * 3.0) * 1.0 if quest else 0.0
	var cy := -8.0 + by
	var dark := Color("#3a2614")
	n.draw_colored_polygon(Sprites._ellipse(Vector2(0, cy), w + 2.0, h + 2.0, 28), dark)
	n.draw_colored_polygon(PackedVector2Array([Vector2(-3, cy + h / 2.0 - 1.0), Vector2(3, cy + h / 2.0 - 1.0), Vector2(0, cy + h / 2.0 + 5.0)]), dark)
	n.draw_colored_polygon(Sprites._ellipse(Vector2(0, cy), w, h, 28), Color.WHITE)
	n.draw_colored_polygon(PackedVector2Array([Vector2(-2, cy + h / 2.0 - 2.0), Vector2(2, cy + h / 2.0 - 2.0), Vector2(0, cy + h / 2.0 + 3.0)]), Color.WHITE)
	var col := Color("#c0561a") if quest else dark
	var pos := Vector2(-tw / 2.0, cy + (4.0 if quest else 3.0))
	n.draw_string(font, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
	if icon != "":
		Items.icon(n, icon, -Items.ICON / 2.0, cy - Items.ICON / 2.0)
	if quest:
		n.draw_string(font, pos + Vector2(0.6, 0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)

func _etag(n) -> void:
	var font := ThemeDB.fallback_font
	var p := Vector2(11, 20)
	Sprites.R(n, p.x - 1, p.y - 1, 13, 13, Color("#3a2614"))
	Sprites.R(n, p.x, p.y, 11, 11, Color("#f4ead0"))
	n.draw_string(font, Vector2(p.x + 2, p.y + 9), "E", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("#3a2614"))
