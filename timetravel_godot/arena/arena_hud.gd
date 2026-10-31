extends "res://scripts/hud.gd"
# arena_hud.gd - the combat test arena's HUD (Stage 8a). It is the game's HUD (hud.gd) with only the fight's parts: top left the hero's
# bars and level, bottom left the round Q (the lasso, or the weapon's special filling with focus) and Shift buttons, bottom right the
# weapon badge, bottom centre the boss bar (all hud.gd's own since the Stage 8e port); and, top right,
# the readouts (arena_combat.gd: damage per second over the last few seconds and since the last reset, the damage and hits, the last hit,
# the enemies standing, the cheats on). No objective, place names, companions or toasts (the arena has no quest, dialogue or squad).

const Dialogue = preload("res://scripts/dialogue.gd")

const READ_X := 352.0         # the readout box, top right
const READ_W := 124.0

func _draw() -> void:
	var y := _draw_bars(4.0)
	_txt("Lv %d" % progress.level, 4, y + 8, XP_COL)
	_draw_skills()
	_draw_weapon()
	_draw_boss()
	_draw_readout()
	_draw_notice()
	_draw_overlays()
	if hint_time > 0.0:
		_txt("LMB light   RMB heavy   Space block   1 weapon   Tab panel   T tuning   C clear   R restart", 0, 262, Color.WHITE, 480.0,
			HORIZONTAL_ALIGNMENT_CENTER)

# (hud.gd's own reads the boss's name from the Dialogue node; the arena has none, only its BOSSES names)
func _draw_boss() -> void:
	var b = combat.boss()
	if b == null:
		return
	var x := (480.0 - BOSS_W) / 2.0
	var y := 258.0 if hint_time <= 0.0 else 246.0
	_txt("%s   Lv %d" % [Dialogue.BOSSES.get(b.kind, b.kind), b.level], 0, y - 4, Menu.TEXT, 480.0, HORIZONTAL_ALIGNMENT_CENTER)
	_bar(x, y, BOSS_W, 5, float(b.hp) / b.max_hp, HP_COL, b.flash > 0.0)
	draw_rect(Rect2(x + BOSS_W / 2.0, y, 1, 5), Color(0, 0, 0, 0.6))

# the readouts (the panel's "DPS readout")
func _draw_readout() -> void:
	if not combat.view["readout"]:
		return
	var lines := [
		["DPS 5 s", "%.1f" % combat.dps_recent()],
		["DPS all", "%.1f" % combat.dps_total()],
		["Damage", "%d in %d hits" % [combat.total_dmg, combat.total_hits]],
	]
	if not combat.hits.is_empty():
		var last: Dictionary = combat.hits[-1]
		lines.append(["Last", "%s %d on %s" % [last["move"], last["dmg"], last["on"]]])
	lines.append(["Enemies", str(combat.rats_alive())])
	var cheats := []
	if combat.god:
		cheats.append("no death")
	if combat.endless_stamina:
		cheats.append("stamina")
	if combat.endless_focus:
		cheats.append("focus")
	if combat.no_q_cooldown:
		cheats.append("no Q cd")
	if not cheats.is_empty():
		lines.append(["Cheats", ", ".join(cheats)])
	var h := 8.0 + 10.0 * lines.size()
	draw_rect(Rect2(READ_X, 4, READ_W, h), Color(Menu.BG, 0.75))
	draw_rect(Rect2(READ_X, 4, READ_W, h), Menu.EDGE_DARK.lightened(0.2), false)
	var y := 14.0
	for l in lines:
		_txt(l[0], READ_X + 5, y, Menu.DIM)
		_txt(l[1], READ_X + 46, y, Menu.ACCENT if l[0].begins_with("DPS") else Menu.TEXT)
		y += 10.0

# the red flash when hurt; while he is down (he gets up by himself, arena_combat.gd GET_UP) a word instead of the fade to black
func _draw_overlays() -> void:
	if combat.hurt_flash > 0.0:
		draw_rect(Rect2(0, 0, 480, 270), Color(0.8, 0.1, 0.1, 0.35 * combat.hurt_flash / 0.3))
	if combat.over_t >= 0.0:
		draw_rect(Rect2(0, 0, 480, 270), Color(0, 0, 0, 0.35))
		_txt("DOWN", 0, 120, HP_COL, 480.0, HORIZONTAL_ALIGNMENT_CENTER)
