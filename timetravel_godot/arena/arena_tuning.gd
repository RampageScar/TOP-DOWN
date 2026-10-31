extends "res://scripts/tuning.gd"
# arena_tuning.gd - the combat test arena's tuning panel (Stage 8b, T). The game's tuning.gd (same keys: W/S select, A/D change, X back
# to the default, E print to the console, T or Esc close; it pauses the fight) with the arena's own page:
#  - WEAPON IN HAND: every move of the weapon held now (arena_combat.gd ARENA_WEAPONS), its damage and stamina (the bow's held "aimed":
#    a full draw's damage, stamina a second of drawing; the volley: each arrow's), and its block (Stage 8c: % let through, stamina a
#    blocked hit). 1 (outside the panel) changes which weapon's moves are listed.
#  - HERO: the dodge and lasso stamina, the refill per second, the focus numbers (the bow's volley's cost too), the parry's window
#    (ms) and the focus it gives (Stage 8d), how long Q is held to charge the strong lasso (ms), and the Q cooldown after a special
#    or a strong lasso (ms), and a finisher's focus cost (Stage 8f). A special's focus cost is its move row's second number (Stage 8d).
#  - ENEMIES: each kind's HP and its hit damage, what its attacks take from the hero (the giant's slam and the chief's charge and sweep
#    too; arena_combat.gd keeps the enemy tables as live copies for this, foe_table()). Beside them, for the weapon in hand: light hits
#    to kill (its first light move), plain strings to kill, seconds of non-stop plain strings, and how many of its first attack the hero
#    takes from full HP.
# No XP, drops or rider rows: the arena gives no XP, has no drops and no companion. The values last until R restarts the arena;
# E prints them in arena_combat.gd form.

const HERO_CELLS := [["stamina", "dodge", "dodge st"], ["stamina", "lasso", "lasso st"], ["stamina", "regen", "refill/s"],
	["focus", "per_hit", "focus/hit"], ["focus", "combo", "full string"], ["focus", "strong", "strong lasso"], ["focus", "volley", "volley"],
	["parry", "window", "parry ms"], ["parry", "focus", "parry focus"], ["special", "charge", "lasso charge"],
	["special", "cooldown", "Q cooldown"], ["focus", "finisher", "finisher"]]
const HERO_ROWS := 7          # the HERO cells are drawn in two columns of this many
# each kind's attacks on the hero: [key in its table (arena_combat.gd foe_table), label]
const FOE_HITS := {
	"rat": [["dmg", "bite"]], "bandit": [["dmg", "hit"]], "slinger": [["dmg", "stone"]], "scorpion": [["dmg", "sting"]],
	"giant": [["dmg", "lunge"], ["slam_dmg", "slam"]], "chief": [["sweep_dmg", "sweep"], ["charge_dmg", "charge"]],
}
const ACOLS := [130.0, 196.0, 268.0, 304.0, 344.0, 388.0]    # x of: the attacks, a second attack, light hits, strings, swing s, you last

func _c():
	return main.combat

# the editable values in W/S order: the weapon's moves (damage, stamina), the hero's, then each enemy's HP and attacks. An enemy attack
# is ["foe", kind, key]: it lives in the enemy's table, not in combat.tune.
func _cells() -> Array:
	var out := []
	for m in _c()._moves().keys():
		out.append([m])
		out.append(_second(m))
	if not _c().guard().is_empty():         # its block (Stage 8c): % let through, stamina a blocked hit
		out.append(["block", _c().weapon, "cut"])
		out.append(["block", _c().weapon, "stamina"])
	for c in HERO_CELLS:
		out.append(_path(c))
	for k in KINDS:
		out.append(["hp", k])
		for h in FOE_HITS[k]:
			out.append(["foe", k, h[0]])
	return out

# a move's second number: its stamina, or for a special (Stage 8d; it costs no stamina) its focus cost
func _second(m: String) -> Array:
	return ["focus", m] if _c()._moves()[m].get("special", false) else ["stamina", m]

func _read(path: Array) -> int:
	if path[0] == "foe":
		return _c().foe_table(path[1])[path[2]]
	return super(path)

func _write(path: Array, v: int) -> void:
	if path[0] == "foe":
		_c().foe_table(path[1])[path[2]] = v
	else:
		super(path, v)

func _step(path: Array) -> int:
	match path[0]:
		"hp": return 10
		"focus": return 1
		"parry": return 10 if path[1] == "window" else 1
		"special": return 500 if path[1] == "cooldown" else 50
	return 5

# A/D and X are this page's own (its moves and enemy attacks aren't in tuning.gd's STEPS or default_tune); the rest is tuning.gd's
func _unhandled_input(event: InputEvent) -> void:
	if not open:
		super(event)
		return
	var cells := _cells()
	sel = mini(sel, cells.size() - 1)      # (the weapon may have changed since the panel was last open)
	var path: Array = cells[sel]
	if event.is_action_pressed("move_left") or event.is_action_pressed("move_right"):
		var lo := 1 if path.size() == 1 or path[0] in ["hp", "foe"] else 0
		var d := _step(path) if event.is_action_pressed("move_right") else -_step(path)
		var hi := 100 if path[0] == "block" and path[2] == "cut" else 9999
		_write(path, clampi(_read(path) + d, lo, hi))
	elif _is_key(event, KEY_X):
		if path[0] == "foe":
			_c().reset_foe(path[1], path[2])
		else:
			_write(path, _at(_c().default_tune(), path))
	else:
		super(event)
		return
	get_viewport().set_input_as_handled()

func _print_values() -> void:
	var c = _c()
	var t: Dictionary = c.tune
	print("# arena tuning values, in arena_combat.gd form")
	for w in c.WEAPON_LIST:
		var parts := []
		for m in c.ARENA_WEAPONS[w]["moves"].keys():
			if t["focus"].has(m):
				parts.append('"%s" "dmg": %d, "stamina": %d, "focus": %d' % [m, t[m], t["stamina"][m], t["focus"][m]])
			else:
				parts.append('"%s" "dmg": %d, "stamina": %d' % [m, t[m], t["stamina"][m]])
		if t["block"].has(w):
			parts.append('"block": {"cut": %d, "stamina": %d}' % [t["block"][w]["cut"], t["block"][w]["stamina"]])
		print("%s: %s" % [c.ARENA_WEAPONS[w]["name"], "   ".join(parts)])
	for k in KINDS:
		var parts := ['"hp": %d' % t["hp"][k]]
		for h in FOE_HITS[k]:
			parts.append('"%s": %d' % [h[0], c.foe_table(k)[h[0]]])
		print("_%s  %s" % [CONST_NAMES[k], ", ".join(parts)])
	var s: Dictionary = t["stamina"]
	var fo: Dictionary = t["focus"]
	print('DODGE "stamina": %d   LASSO "stamina": %d   STAMINA "regen": %d   FOCUS "per_hit": %d, "combo": %d   LASSO "focus": %d   volley "focus": %d'
		% [s["dodge"], s["lasso"], s["regen"], fo["per_hit"], fo["combo"], fo["strong"], fo["volley"]])
	print('PARRY "window": %d, "focus": %d   SPECIAL "charge": %d, "cooldown": %d' % [t["parry"]["window"], t["parry"]["focus"],
		t["special"]["charge"], t["special"]["cooldown"]])

# ---------------------------------------------------------------- what a value does to a fight (the weapon in hand)
# the weapon's plain string (the one marked "plain"; else its first) and its first light move
func _plain() -> Array:
	var strings: Dictionary = _c().ARENA_WEAPONS[_c().weapon]["strings"]
	for s in strings.keys():
		if strings[s].get("plain", false):
			return [s, strings[s]]
	var first: String = strings.keys()[0]
	return [first, strings[first]]

func _first_light() -> String:
	return _c()._move_of("L")

func _light_hits(hp: int) -> int:
	return ceili(float(hp) / maxi(1, _c().hit_dmg(_first_light())))

func _strings_to_kill(hp: int) -> float:
	var sum := 0
	for m in _plain()[1]["moves"]:
		sum += _c().hit_dmg(m)
	return float(hp) / maxi(1, sum)

# seconds of non-stop plain strings (each press at the end of the swing before, the string's pause after its last) until hp is dealt
func _swing_time(hp: int) -> float:
	var row: Dictionary = _plain()[1]
	var moves: Array = row["moves"]
	var t := 0.0
	var dealt := 0
	var n := 0
	while dealt < hp and n < 300:
		var m: String = moves[n % moves.size()]
		t += _c()._moves()[m]["dur"]
		dealt += _c().hit_dmg(m)
		if n % moves.size() == moves.size() - 1 and dealt < hp:
			t += row["pause"]
		n += 1
	return t

# ---------------------------------------------------------------- drawing
func _draw_ui() -> void:
	if not open:
		return
	var font := ThemeDB.fallback_font
	var c = _c()
	var cells := _cells()
	sel = mini(sel, cells.size() - 1)
	var cur: Array = cells[sel]
	var t: Dictionary = c.tune
	ui.draw_rect(Rect2(0, 0, 480, 270), Menu.BACKDROP)
	ui.draw_rect(Rect2(PX, PY, PW, PH), Menu.BG)
	ui.draw_rect(Rect2(PX, PY, PW, PH), Menu.EDGE, false)
	ui.draw_string(font, Vector2(PX + 10, PY + 14), "ARENA TUNING  (until R restarts)", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Menu.TEXT)
	ui.draw_string(font, Vector2(PX, PY + 14), "T close", HORIZONTAL_ALIGNMENT_RIGHT, PW - 10.0, 8, Menu.DIM)
	ui.draw_rect(Rect2(PX + 6, PY + 20, PW - 12, 1), Menu.EDGE_DARK)
	# the weapon in hand: one row a move
	var y := PY + 34.0
	ui.draw_string(font, Vector2(PX + 10, y), "WEAPON IN HAND: %s" % c.ARENA_WEAPONS[c.weapon]["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Menu.DIM)
	ui.draw_string(font, Vector2(PX + 116, y), "dmg", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Menu.DIM)
	ui.draw_string(font, Vector2(PX + 160, y), "stamina", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Menu.DIM)
	for m in c._moves().keys():
		y += ROW
		var special: bool = c._moves()[m].get("special", false)      # (Stage 8d: its second number is its focus cost)
		ui.draw_string(font, Vector2(PX + 14, y), m + (" (Q, focus)" if special else ""), HORIZONTAL_ALIGNMENT_LEFT, -1, 9,
			Menu.ACCENT if special else Menu.TEXT)
		_value(font, PX + 116, y, t[m], cur == [m])
		_value(font, PX + 160, y, _read(_second(m)), cur == _second(m))
	y += ROW
	if c.guard().is_empty():
		ui.draw_string(font, Vector2(PX + 14, y), "block: none (dodge)", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Menu.DIM)
	else:
		ui.draw_string(font, Vector2(PX + 14, y), "block  % through", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Menu.TEXT)
		_value(font, PX + 116, y, t["block"][c.weapon]["cut"], cur == ["block", c.weapon, "cut"])
		_value(font, PX + 160, y, t["block"][c.weapon]["stamina"], cur == ["block", c.weapon, "stamina"])
	var y_left := y
	# the hero's costs and focus, on the right
	y = PY + 34.0
	ui.draw_string(font, Vector2(PX + 228, y), "HERO", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Menu.DIM)
	for i in range(HERO_CELLS.size()):      # two columns (Stage 8d: the parry's two numbers made one too long)
		var h: Array = HERO_CELLS[i]
		var col := i / HERO_ROWS
		var hy: float = y + ROW * (i % HERO_ROWS + 1)
		var hx: float = PX + 228.0 + 104.0 * col
		ui.draw_string(font, Vector2(hx, hy), h[-1], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Menu.TEXT)
		_value(font, hx + 60.0, hy, _read(_path(h)), cur == _path(h))
	y += ROW * HERO_ROWS
	# the enemies
	y = maxf(y, y_left) + 16.0
	ui.draw_string(font, Vector2(PX + 10, y), "ENEMIES", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Menu.DIM)
	var heads := ["HP", "hits the hero for", "", "light", "strings", "swing s", "you last"]
	ui.draw_string(font, Vector2(PX + 90, y), heads[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Menu.DIM)
	for i in range(1, heads.size()):
		ui.draw_string(font, Vector2(PX + ACOLS[i - 1], y), heads[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Menu.DIM)
	for k in KINDS:
		y += ROW
		var hp: int = t["hp"][k]
		ui.draw_string(font, Vector2(PX + 14, y), KIND_NAMES[k], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Menu.TEXT)
		_value(font, PX + 90, y, hp, cur == ["hp", k])
		var hits: Array = FOE_HITS[k]
		for i in range(hits.size()):
			var x: float = PX + ACOLS[i]
			ui.draw_string(font, Vector2(x, y), hits[i][1], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Menu.DIM)
			_value(font, x + 26.0, y, _read(["foe", k, hits[i][0]]), cur == ["foe", k, hits[i][0]])
		var first: int = c.foe_table(k)[hits[0][0]]
		var vals := [str(_light_hits(hp)), "%.1f" % _strings_to_kill(hp), "%.1f" % _swing_time(hp),
			str(ceili(float(main.player.max_hp) / maxi(1, first)))]
		for i in range(vals.size()):
			ui.draw_string(font, Vector2(PX + ACOLS[i + 2], y), vals[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Menu.TEXT)
	y += 14.0
	var plain: Array = _plain()
	var notes := ("light / strings / swing s: the %s (%s, the plain %s string). you last: its first attack from full HP. Hero %d HP, "
		+ "%d stamina.") % [c.ARENA_WEAPONS[c.weapon]["name"].to_lower(), _first_light(), plain[0], main.player.max_hp,
		main.player.max_stamina]
	ui.draw_multiline_string(font, Vector2(PX + 10, y), notes, HORIZONTAL_ALIGNMENT_LEFT, PW - 20.0, 8, 2, Menu.DIM)
	if note_t > 0.0:
		ui.draw_string(font, Vector2(PX, PY + PH - 20), note, HORIZONTAL_ALIGNMENT_RIGHT, PW - 10.0, 9, Menu.ACCENT)
	ui.draw_rect(Rect2(PX + 6, PY + PH - 15, PW - 12, 1), Menu.EDGE_DARK)
	ui.draw_string(font, Vector2(PX + 10, PY + PH - 5), "W/S select   A/D change   X reset   E print to console   T close",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Menu.DIM)
