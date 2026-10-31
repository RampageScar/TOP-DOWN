extends CanvasLayer
# tuning.gd - the live tuning panel (dev key T). Change the hero's punch and kick damage (and since 7l the sword's slash and thrust,
# damage and stamina, on the SWORD row), the rider's arrow damage, each enemy's HP
# and XP, what each move costs in stamina (and how fast it refills), the focus numbers (gained per hit, the full combo's extra, the
# strong lasso's cost) and the ordinary foes' drop chances while playing, and see what that does to a fight: punches and full combos to kill, seconds
# of non-stop swinging, seconds for the rider alone. The values live in combat.gd `tune` (they start as its constants); this panel only
# edits them. They last until the game restarts (R): E prints them in combat.gd form, so a value you like can be copied into the constants.
# Pauses the game while open. Uses the menu's era-neutral colours.
# Since Stage 8e the game has the arena's weapons, strings, specials, block and parry (combat.gd WEAPON_KIT); this panel still shows only
# the fists' punch / kick and the sword's slash / thrust. The arena's panel (arena/arena_tuning.gd) has every move.

const Menu = preload("res://scripts/menu.gd")

const KINDS := ["rat", "bandit", "slinger", "scorpion", "giant", "chief"]
const KIND_NAMES := {"rat": "Rat", "bandit": "Bandit", "slinger": "Slinger", "scorpion": "Scorpion", "giant": "Giant rat", "chief": "Chief"}
const CONST_NAMES := {"rat": "RAT", "bandit": "BANDIT", "slinger": "SLINGER", "scorpion": "SCORPION", "giant": "GIANT", "chief": "CHIEF"}
const XP_NAMES := {"rat": "XP_RAT", "bandit": "XP_BANDIT", "slinger": "XP_SLINGER", "scorpion": "XP_SCORPION", "giant": "XP_GIANT",
	"chief": "XP_CHIEF"}
const ROW := 12.0           # the enemy rows and the stamina / focus / drop rows (12 px since the scorpion's row, Stage 7j, so it all fits)
# how much A/D changes a value, by its first path key (HP and damage are in tens since Stage 7e)
const STEPS := {"punch": 5, "kick": 5, "slash": 5, "thrust": 5, "arrow": 5, "hp": 10, "xp": 5, "stamina": 5, "focus": 1, "drops": 5}
# the stamina, focus and drop rows: [path into combat.tune..., label]
const STAMINA_CELLS := [["stamina", "punch", "punch"], ["stamina", "kick", "kick"], ["stamina", "dodge", "dodge"],
	["stamina", "lasso", "lasso"], ["stamina", "regen", "refill/s"]]
# the sword (Stage 7l): its damage and stamina per swing, on one row
const SWORD_CELLS := [["slash", "slash"], ["thrust", "thrust"], ["stamina", "slash", "slash st"], ["stamina", "thrust", "thrust st"]]
const FOCUS_CELLS :=[["focus", "per_hit", "per hit"], ["focus", "combo", "full combo"], ["focus", "strong", "strong lasso"]]
# the ordinary foes' drop chances in % (combat.gd DROPS rows; the bosses' drops are fixed), on two rows
const DROP_CELLS := [["drops", "rat", 0, "rat bread"], ["drops", "bandit", 0, "bandit coins"], ["drops", "bandit", 1, "bread"],
	["drops", "bandit", 2, "potion"]]
const DROP_CELLS_2 := [["drops", "slinger", 0, "slinger coins"], ["drops", "slinger", 1, "potion"]]

const PX := 24.0
const PY := 6.0
const PW := 432.0
const PH := 258.0
const COLS := [150.0, 196.0, 236.0, 282.0, 330.0, 378.0]    # x of: HP, XP, punches, combos, swing s, rider s (from PX)

var main                    # main.gd
var open := false
var sel := 0                # index into _cells()
var note := ""              # a short status line ("Printed to the console.")
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

# the editable values, in the order W/S walks through them (a path into combat.tune)
func _cells() -> Array:
	var out := [["punch"], ["kick"], ["arrow"]]
	for k in KINDS:
		out.append(["hp", k])
		out.append(["xp", k])
	for c in SWORD_CELLS + STAMINA_CELLS + FOCUS_CELLS + DROP_CELLS + DROP_CELLS_2:
		out.append(_path(c))
	return out

# a row cell's path into combat.tune (all but its label)
func _path(c: Array) -> Array:
	return c.slice(0, c.size() - 1)

func _tune() -> Dictionary:
	return main.combat.tune

# the value at `path` in dictionary d (a path is 1 to 3 keys long)
func _at(d, path: Array):
	var v = d
	for k in path:
		v = v[k]
	return v

func _read(path: Array) -> int:
	return _at(_tune(), path)

func _write(path: Array, v: int) -> void:
	var holder = _at(_tune(), path.slice(0, path.size() - 1))     # the dictionary or list the value sits in
	holder[path[-1]] = mini(v, 100) if path[0] == "drops" else v
	if path[0] == "hp":
		_apply_hp(path[1], v)

# a new HP for a kind: every living enemy of that kind on every map built so far keeps its share of health
func _apply_hp(kind: String, v: int) -> void:
	for lv in main.levels.values():
		for r in lv.rats:
			if r.kind == kind and r.alive:
				var frac := float(r.hp) / float(r.max_hp)
				r.max_hp = v
				r.hp = clampi(roundi(frac * v), 1, v)

# ---------------------------------------------------------------- input
func _unhandled_input(event: InputEvent) -> void:
	if not open:
		if event.is_action_pressed("tuning") and not main.travelling and not main.world.talking and not get_tree().paused:
			open = true
			main.world.talking = true
			get_tree().paused = true
			get_viewport().set_input_as_handled()
		return
	var cells := _cells()
	var path: Array = cells[sel]
	if event.is_action_pressed("tuning") or event.is_action_pressed("menu"):
		open = false
		main.world.talking = false
		get_tree().paused = false
	elif event.is_action_pressed("move_up"):
		sel = (sel - 1 + cells.size()) % cells.size()
	elif event.is_action_pressed("move_down"):
		sel = (sel + 1) % cells.size()
	elif event.is_action_pressed("move_left") or event.is_action_pressed("move_right"):
		var step: int = STEPS[path[0]]
		var lo := 1 if path[0] in ["punch", "kick", "slash", "thrust", "arrow", "hp"] else 0
		var d := step if event.is_action_pressed("move_right") else -step
		_write(path, maxi(lo, _read(path) + d))
	elif _is_key(event, KEY_X):
		_write(path, _at(main.combat.default_tune(), path))
	elif event.is_action_pressed("interact"):
		_print_values()
		note = "Printed to the console."
		note_t = 2.0
	else:
		return
	get_viewport().set_input_as_handled()

func _is_key(event: InputEvent, code: Key) -> bool:
	var k := event as InputEventKey
	return k != null and k.pressed and not k.echo and k.physical_keycode == code

func _print_values() -> void:
	var t := _tune()
	print("# tuning panel values, in combat.gd form")
	print('FIST_MOVES "dmg": punch %d, kick %d' % [t["punch"], t["kick"]])
	print('RIDER "dmg": %d' % t["arrow"])
	for k in KINDS:
		print('%s "hp": %d        const %s := %d' % [CONST_NAMES[k], t["hp"][k], XP_NAMES[k], t["xp"][k]])
	var s: Dictionary = t["stamina"]
	print('FIST_MOVES "stamina": punch %d, kick %d   DODGE "stamina": %d   LASSO "stamina": %d   STAMINA "regen": %d'
		% [s["punch"], s["kick"], s["dodge"], s["lasso"], s["regen"]])
	print('SWORD_MOVES "dmg": slash %d, thrust %d   "stamina": slash %d, thrust %d'
		% [t["slash"], t["thrust"], s["slash"], s["thrust"]])
	var fo: Dictionary = t["focus"]
	print('FOCUS "per_hit": %d, "combo": %d   LASSO "focus": %d' % [fo["per_hit"], fo["combo"], fo["strong"]])
	var dr: Dictionary = t["drops"]
	print('DROPS chances: "rat" %s   "bandit" %s   "slinger" %s' % [str(dr["rat"]), str(dr["bandit"]), str(dr["slinger"])])

# ---------------------------------------------------------------- what a value does to a fight
func _punches(hp: int) -> int:
	return ceili(float(hp) / _tune()["punch"])

func _combos(hp: int) -> float:
	return float(hp) / float(2 * _tune()["punch"] + _tune()["kick"])

# seconds of non-stop swinging of the fists' plain string (punch, punch, kick, the pause after the kick, ...) until the damage dealt
# reaches hp (Stage 8e: read from combat.gd WEAPON_KIT)
func _swing_time(hp: int) -> float:
	var c = main.combat
	var row: Dictionary = c.WEAPON_KIT["unarmed"]["strings"]["LLL"]
	var moves: Array = row["moves"]
	var t := 0.0
	var dealt := 0
	var n := 0
	while dealt < hp and n < 300:
		var m: String = moves[n % moves.size()]
		t += c.FIST_MOVES[m]["dur"]
		dealt += _tune()[m]
		if n % moves.size() == moves.size() - 1 and dealt < hp:
			t += row["pause"]
		n += 1
	return t

func _rider_time(hp: int) -> float:
	return ceili(float(hp) / _tune()["arrow"]) * main.combat.RIDER["shot_every"]

# ---------------------------------------------------------------- drawing
func _draw_ui() -> void:
	if not open:
		return
	var font := ThemeDB.fallback_font
	var cells := _cells()
	var cur: Array = cells[sel]
	ui.draw_rect(Rect2(0, 0, 480, 270), Menu.BACKDROP)
	ui.draw_rect(Rect2(PX, PY, PW, PH), Menu.BG)
	ui.draw_rect(Rect2(PX, PY, PW, PH), Menu.EDGE, false)
	ui.draw_string(font, Vector2(PX + 10, PY + 14), "TUNING  (dev, this session only)", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Menu.TEXT)
	ui.draw_string(font, Vector2(PX, PY + 14), "T close", HORIZONTAL_ALIGNMENT_RIGHT, PW - 10.0, 8, Menu.DIM)
	ui.draw_rect(Rect2(PX + 6, PY + 20, PW - 12, 1), Menu.EDGE_DARK)
	var t := _tune()
	# weapons
	var y := PY + 34.0
	ui.draw_string(font, Vector2(PX + 10, y), "WEAPON DAMAGE", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Menu.DIM)
	var weapons := [["punch", "Punch (x2 in a combo)", ""], ["kick", "Kick (ends the combo)", "full combo = %d" % (2 * t["punch"] + t["kick"])],
		["arrow", "Rider's arrow", "one every %.1f s" % main.combat.RIDER["shot_every"]]]
	for w in weapons:
		y += 12.0
		ui.draw_string(font, Vector2(PX + 14, y), w[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Menu.TEXT)
		_value(font, PX + COLS[0], y, t[w[0]], cur == [w[0]])
		ui.draw_string(font, Vector2(PX + COLS[1], y), w[2], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Menu.DIM)
	# enemies
	y += 18.0
	ui.draw_string(font, Vector2(PX + 10, y), "ENEMIES", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Menu.DIM)
	var heads := ["HP", "XP", "punches", "combos", "swing s", "rider s"]
	for i in range(heads.size()):
		ui.draw_string(font, Vector2(PX + COLS[i], y), heads[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Menu.DIM)
	for k in KINDS:
		y += ROW
		var hp: int = t["hp"][k]
		ui.draw_string(font, Vector2(PX + 14, y), KIND_NAMES[k], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Menu.TEXT)
		_value(font, PX + COLS[0], y, hp, cur == ["hp", k])
		_value(font, PX + COLS[1], y, t["xp"][k], cur == ["xp", k])
		ui.draw_string(font, Vector2(PX + COLS[2], y), str(_punches(hp)), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Menu.TEXT)
		ui.draw_string(font, Vector2(PX + COLS[3], y), "%.1f" % _combos(hp), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Menu.TEXT)
		ui.draw_string(font, Vector2(PX + COLS[4], y), "%.1f" % _swing_time(hp), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Menu.TEXT)
		ui.draw_string(font, Vector2(PX + COLS[5], y), "%.1f" % _rider_time(hp), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Menu.TEXT)
	# the hero: what each move costs in stamina, and the focus numbers; then the drop chances
	y += 14.0
	_inline(font, y, "SWORD", SWORD_CELLS, cur)
	y += ROW
	_inline(font, y, "STAMINA", STAMINA_CELLS, cur)
	y += ROW
	_inline(font, y, "FOCUS", FOCUS_CELLS, cur)
	y += ROW
	_inline(font, y, "DROPS %", DROP_CELLS, cur)
	y += ROW
	_inline(font, y, "", DROP_CELLS_2, cur)
	# how to read it
	y += 12.0
	# one line since the sword's row (7l): the panel has no room for two
	var notes := "punches / combos / swing s: unarmed. rider s: Farnaka alone. Hero %d HP, %d stamina (full combo %d)." \
		% [main.player.max_hp, main.player.max_stamina, 2 * t["stamina"]["punch"] + t["stamina"]["kick"]]
	ui.draw_multiline_string(font, Vector2(PX + 10, y), notes, HORIZONTAL_ALIGNMENT_LEFT, PW - 20.0, 8, 1, Menu.DIM)
	if note_t > 0.0:
		ui.draw_string(font, Vector2(PX, PY + PH - 20), note, HORIZONTAL_ALIGNMENT_RIGHT, PW - 10.0, 9, Menu.ACCENT)
	ui.draw_rect(Rect2(PX + 6, PY + PH - 15, PW - 12, 1), Menu.EDGE_DARK)
	ui.draw_string(font, Vector2(PX + 10, PY + PH - 5), "W/S select   A/D change   X reset   E print to console   T close",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Menu.DIM)

# a row of small editable numbers, each after its label (the stamina and focus rows)
func _inline(font: Font, y: float, head: String, cells: Array, cur: Array) -> void:
	ui.draw_string(font, Vector2(PX + 10, y), head, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Menu.DIM)
	var x := PX + 58.0
	for c in cells:
		var label: String = c[-1]
		ui.draw_string(font, Vector2(x, y), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Menu.DIM)
		x += font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x + 6.0
		_value(font, x, y, _read(_path(c)), cur == _path(c))
		x += 40.0

# one editable number; the selected one is boxed in the accent colour
func _value(font: Font, x: float, y: float, v: int, selected: bool) -> void:
	if selected:
		ui.draw_rect(Rect2(x - 3, y - 9, 36, 12), Color(Menu.ACCENT, 0.18))
		ui.draw_rect(Rect2(x - 3, y - 9, 36, 12), Menu.ACCENT, false)
		ui.draw_string(font, Vector2(x - 2, y), "<", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Menu.ACCENT)
		ui.draw_string(font, Vector2(x + 27, y), ">", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Menu.ACCENT)
	ui.draw_string(font, Vector2(x + 4, y), str(v), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Menu.ACCENT if selected else Menu.TEXT)
