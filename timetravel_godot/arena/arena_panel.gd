extends CanvasLayer
# arena_panel.gd - the combat test arena's panel (Stage 8a; Tab opens it, Tab or Esc closes it; it pauses the fight like the tuning
# panel). One page in two columns, walked through with W/S:
#  - SPAWN: which enemy (any kind, the bosses too), how many, their level, awake (they come at once) or not (they patrol and must spot
#    the hero); "Spawn" puts them in a ring round the hero (arena.gd spawn) and closes the panel; "Clear field" removes every enemy.
#  - HERO: the cheats (can't die, endless stamina, endless focus, no Q cooldown), the hero's level and each weapon's level, a full heal.
#  - WEAPON IN HAND: the weapon picker (arena_combat.gd WEAPON_LIST), with the weapon's strings under it (L light, H heavy: the moves
#    each plays and its name; its Q finishers on one line, Stage 8f; the bow's held H), its Q move (Stage 8d: the special, or the lasso), its block and whether it parries
#    (Stage 8c-8d), then its moves (damage and stamina as the tuning panel has them now; length, reach and knock-back).
#  - SHOW: what the readouts show (arena_combat.gd `view`) and a reset of the DPS counters.
# A/D change the selected value, E flips a yes / no or does an action. Uses the menu's era-neutral colours, like every panel.

const Menu = preload("res://scripts/menu.gd")

const KINDS := ["rat", "bandit", "slinger", "scorpion", "giant", "chief"]
const KIND_NAMES := {"rat": "Rat", "bandit": "Bandit", "slinger": "Slinger", "scorpion": "Scorpion", "giant": "Giant rat", "chief": "Chief"}
const MAX_COUNT := 8
const MAX_FOE_LEVEL := 10
# the rows in W/S order: the left column, then the right one. Section heads go before the rows named here.
const LEFT := ["kind", "count", "level", "awake", "spawn", "clear", "god", "stamina", "focus", "q_cool", "hero_lv", "lv_unarmed",
	"lv_sword", "lv_lasso", "heal"]
const RIGHT := ["weapon", "numbers", "readout", "timeline", "boxes", "reset"]
const HEADS := {"kind": "SPAWN", "god": "HERO", "weapon": "WEAPON IN HAND", "numbers": "SHOW"}
const LABELS := {"kind": "Enemy", "count": "How many", "level": "Level", "awake": "Awake", "spawn": "Spawn  (E)",
	"clear": "Clear field  (E, or C)", "god": "Can't die", "stamina": "Endless stamina", "focus": "Endless focus", "q_cool": "No Q cooldown",
	"hero_lv": "Hero level",
	"lv_unarmed": "Unarmed level", "lv_sword": "Sword level", "lv_lasso": "Lasso level", "heal": "Full heal  (E)", "weapon": "Weapon",
	"numbers": "Damage numbers", "readout": "DPS readout", "timeline": "Combo timeline", "boxes": "Hit boxes", "reset": "Reset DPS  (E)"}
const ACTIONS := ["spawn", "clear", "heal", "reset"]
const TOGGLES := ["awake", "god", "stamina", "focus", "q_cool", "numbers", "readout", "timeline", "boxes"]

const PX := 24.0
const PY := 6.0
const PW := 432.0
const PH := 258.0
const ROW := 11.0
const COL_X := [PX + 10.0, PX + 222.0]     # each column's left edge
const VAL_DX := 100.0                      # its values, this far in

var main                    # arena.gd
var open := false
var sel := 0                # index into LEFT + RIGHT
var kind_i := 1             # the spawner's settings
var count := 3
var foe_level := 2
var awake := true
var note := ""              # a short status line ("Field cleared.")
var note_t := 0.0
var ui: Control

func _ready() -> void:
	layer = 8
	process_mode = Node.PROCESS_MODE_ALWAYS
	ui = Control.new()
	ui.size = Vector2(480, 270)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.draw.connect(_draw_ui)
	add_child(ui)

func _process(delta: float) -> void:
	note_t = maxf(0.0, note_t - delta)
	ui.queue_redraw()

func _rows() -> Array:
	return LEFT + RIGHT

func _say(s: String) -> void:
	note = s
	note_t = 2.0

func _close() -> void:
	open = false
	main.world.talking = false
	get_tree().paused = false

# ---------------------------------------------------------------- input
func _unhandled_input(event: InputEvent) -> void:
	if not open:
		if event.is_action_pressed("arena_panel") and not main.world.talking and not get_tree().paused:
			open = true
			main.world.talking = true
			get_tree().paused = true
			get_viewport().set_input_as_handled()
		return
	var rows := _rows()
	var id: String = rows[sel]
	if event.is_action_pressed("menu"):
		_close()
	elif event.is_action_pressed("move_up"):
		sel = (sel - 1 + rows.size()) % rows.size()
	elif event.is_action_pressed("move_down"):
		sel = (sel + 1) % rows.size()
	elif event.is_action_pressed("move_left"):
		_change(id, -1)
	elif event.is_action_pressed("move_right"):
		_change(id, 1)
	elif event.is_action_pressed("interact"):
		if id in TOGGLES:
			_change(id, 1)
		elif id in ACTIONS:
			_act(id)
	else:
		return
	get_viewport().set_input_as_handled()

# A/D on row id (d = -1 / +1); a yes / no flips either way
func _change(id: String, d: int) -> void:
	var c = main.combat
	var p = main.progress
	match id:
		"kind":
			kind_i = (kind_i + d + KINDS.size()) % KINDS.size()
			foe_level = c.FOE_LEVEL.get(KINDS[kind_i], 1)      # each kind starts at its own level (combat.gd FOE_LEVEL)
		"count":
			count = clampi(count + d, 1, MAX_COUNT)
		"level":
			foe_level = clampi(foe_level + d, 1, MAX_FOE_LEVEL)
		"awake":
			awake = not awake
		"god":
			c.god = not c.god
		"stamina":
			c.endless_stamina = not c.endless_stamina
		"focus":
			c.endless_focus = not c.endless_focus
		"q_cool":
			c.no_q_cooldown = not c.no_q_cooldown
		"hero_lv":
			main.set_hero_level(clampi(p.level + d, 1, p.cap))
		"lv_unarmed", "lv_sword", "lv_lasso":
			var w := id.trim_prefix("lv_")
			main.set_weapon_level(w, clampi(p.wlevel(w) + d, 1, p.wtop(w)))
		"weapon":
			var list: Array = c.WEAPON_LIST
			var i := (list.find(c.weapon) + d + list.size()) % list.size()
			c.cancel_all()              # (the panel can open in the middle of a swing)
			c.equip(list[i])
		"numbers", "readout", "timeline", "boxes":
			c.view[id] = not c.view[id]

func _act(id: String) -> void:
	match id:
		"spawn":
			main.spawn(KINDS[kind_i], count, foe_level, awake)
			_close()
		"clear":
			main.combat.clear_field()
			_say("Field cleared.")
		"heal":
			main.player.refill()
			main.player.poison = 0
			_say("HP, stamina and focus full.")
		"reset":
			main.combat.reset_readout()
			_say("DPS counters reset.")

# what row id shows as its value ("" for an action)
func _value_text(id: String) -> String:
	var c = main.combat
	var p = main.progress
	match id:
		"kind": return KIND_NAMES[KINDS[kind_i]]
		"count": return str(count)
		"level": return str(foe_level)
		"awake": return _yes(awake)
		"god": return _yes(c.god)
		"stamina": return _yes(c.endless_stamina)
		"focus": return _yes(c.endless_focus)
		"q_cool": return _yes(c.no_q_cooldown)
		"hero_lv": return str(p.level)
		"lv_unarmed", "lv_sword", "lv_lasso": return str(p.wlevel(id.trim_prefix("lv_")))
		"weapon": return c.ARENA_WEAPONS[c.weapon]["name"]
		"numbers", "readout", "timeline", "boxes": return _yes(c.view[id])
	return ""

func _yes(b: bool) -> String:
	return "yes" if b else "no"

# ---------------------------------------------------------------- drawing
func _draw_ui() -> void:
	if not open:
		return
	var font := ThemeDB.fallback_font
	ui.draw_rect(Rect2(0, 0, 480, 270), Menu.BACKDROP)
	ui.draw_rect(Rect2(PX, PY, PW, PH), Menu.BG)
	ui.draw_rect(Rect2(PX, PY, PW, PH), Menu.EDGE, false)
	ui.draw_string(font, Vector2(PX + 10, PY + 14), "COMBAT ARENA  (test ground)", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Menu.TEXT)
	ui.draw_string(font, Vector2(PX, PY + 14), "Tab close", HORIZONTAL_ALIGNMENT_RIGHT, PW - 10.0, 8, Menu.DIM)
	ui.draw_rect(Rect2(PX + 6, PY + 20, PW - 12, 1), Menu.EDGE_DARK)
	var cur: String = _rows()[sel]
	var y := _column(font, LEFT, COL_X[0], PY + 34.0, cur)
	y = _column(font, RIGHT.slice(0, 1), COL_X[1], PY + 34.0, cur)
	y = _combo_table(font, COL_X[1], y + 2.0)
	_column(font, RIGHT.slice(1), COL_X[1], y + 8.0, cur)
	# (under the left column: the right one runs to the bottom with the spear's strings and moves, Stage 8d)
	ui.draw_string(font, Vector2(COL_X[0], PY + PH - 24), "Enemies standing: %d" % main.combat.rats_alive(), HORIZONTAL_ALIGNMENT_LEFT, -1, 8,
		Menu.DIM)
	if note_t > 0.0:
		ui.draw_string(font, Vector2(PX, PY + PH - 24), note, HORIZONTAL_ALIGNMENT_RIGHT, PW - 10.0, 9, Menu.ACCENT)
	ui.draw_rect(Rect2(PX + 6, PY + PH - 15, PW - 12, 1), Menu.EDGE_DARK)
	ui.draw_string(font, Vector2(PX + 10, PY + PH - 5), "W/S select   A/D change   E use / flip   Tab or Esc close   (T: the tuning panel)",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Menu.DIM)

# the rows `ids` from y down at x, each section head first; returns the y under the last row
func _column(font: Font, ids: Array, x: float, y: float, cur: String) -> float:
	for id in ids:
		if HEADS.has(id):
			if y > PY + 40.0:
				y += 4.0
			ui.draw_string(font, Vector2(x, y), HEADS[id], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Menu.DIM)
			y += ROW
		var on: bool = id == cur
		if on:
			ui.draw_rect(Rect2(x - 4, y - 9, 196, 12), Color(Menu.ACCENT, 0.15))
		ui.draw_string(font, Vector2(x + 4, y), LABELS[id], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Menu.ACCENT if on else Menu.TEXT)
		var v := _value_text(id)
		if v != "":
			var s := ("< %s >" % v) if on else v
			ui.draw_string(font, Vector2(x + VAL_DX, y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Menu.ACCENT if on else Menu.TEXT)
		y += ROW
	return y

# the weapon in hand: one line a string (its letters, the moves it plays, its name), then one line a move: its name, damage and
# stamina (the tuning panel's values now), length, reach, knock-back
func _combo_table(font: Font, x: float, y: float) -> float:
	var c = main.combat
	var w: Dictionary = c.ARENA_WEAPONS[c.weapon]
	var finishers := []         # (Stage 8f: the Q strings go on one line of their own, to keep the column short)
	for s in w["strings"].keys():
		var row: Dictionary = w["strings"][s]
		if s.ends_with("Q"):
			finishers.append(s)
			continue
		var moves: Array = row["moves"]
		var same := moves.count(moves[0]) == moves.size()
		var played: String = ("%s x%d" % [moves[0], moves.size()]) if same else " ".join(moves)
		ui.draw_string(font, Vector2(x + 4, y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Menu.ACCENT)
		ui.draw_string(font, Vector2(x + 26, y), played, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Menu.TEXT)
		if row["name"] != "":
			var after := font.get_string_size(played, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
			ui.draw_string(font, Vector2(x + 32 + after, y), row["name"], HORIZONTAL_ALIGNMENT_LEFT, 160.0 - after, 8, Menu.DIM)
		y += 9.0
	if not finishers.is_empty():
		ui.draw_string(font, Vector2(x + 4, y), "Finish", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Menu.ACCENT)
		ui.draw_string(font, Vector2(x + 34, y), "%s  (%d focus)" % [" ".join(finishers), c.focus_val("finisher")], HORIZONTAL_ALIGNMENT_LEFT,
			160.0, 8, Menu.TEXT)
		y += 9.0
	if w.has("hold"):          # the bow: H is held to draw
		ui.draw_string(font, Vector2(x + 4, y), "H held", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Menu.ACCENT)
		ui.draw_string(font, Vector2(x + 36, y), "%s: draw, let go to shoot" % w["hold"], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Menu.TEXT)
		y += 9.0
	# Q (Stage 8d): the weapon's special (its damage and focus cost; it isn't in the moves table below), or the fists' lasso
	ui.draw_string(font, Vector2(x + 4, y), "Q", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Menu.ACCENT)
	var q := "lasso; hold %.1f s: strong, %d focus, %d s" % [c.q_charge(), c.focus_val("strong"), roundi(c.special_cd_max())]
	if w.has("special"):
		var sp: Dictionary = w["moves"][w["special"]]
		q = "%s, %d%s, %d focus, %d s" % [sp["name"], c.tune[w["special"]], (" x%d" % sp["hits"]) if sp.has("hits") else "",
			c.focus_val(w["special"]), roundi(c.special_cd_max())]
	ui.draw_string(font, Vector2(x + 16, y), q, HORIZONTAL_ALIGNMENT_LEFT, 180.0, 8, Menu.TEXT)
	y += 9.0
	var g: Dictionary = c.tune["block"].get(c.weapon, {})
	var block := "Block: none (dodge)"
	if not g.is_empty():
		block = "Block: %d%% through, %d stamina a hit; %s" % [g["cut"], g["stamina"], "parry" if w.get("parry", true) else "no parry"]
	ui.draw_string(font, Vector2(x + 4, y), block, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Menu.DIM)
	y += 9.0
	y += 2.0
	var cols := [0.0, 54.0, 78.0, 104.0, 136.0, 164.0]
	var heads := ["move", "dmg", "stam", "dur s", "reach", "kb"]
	for i in range(heads.size()):
		ui.draw_string(font, Vector2(x + 4 + cols[i], y), heads[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Menu.DIM)
	for m in w["moves"].keys():
		if w["moves"][m].get("special", false):
			continue
		y += 9.0
		var cfg: Dictionary = w["moves"][m]
		var reach := "shot" if cfg.get("shot", false) else "%d" % int(cfg.get("reach", c.REACH_FRONT))
		var vals := [m, str(c.tune[m]), str(c.tune["stamina"][m]), "%.2f" % cfg["dur"], reach, "%d" % int(cfg["kb"])]
		for i in range(vals.size()):
			ui.draw_string(font, Vector2(x + 4 + cols[i], y), vals[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Menu.TEXT)
	return y + ROW
