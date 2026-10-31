extends "res://scripts/rat.gd"
# slinger.gd - the chief's slingers (Stage 6c). Numbers: combat.gd SLINGER.
# Built on rat.gd, kind "slinger": a lean bandit in a drab tunic with a sling and no sword. They are never on the map before the chief
# wakes: cave.gd brings them in at the edges of the boss room (SLINGER_SPOTS), already after the hero.
# A slinger keeps its distance (backs off inside `near`, closes in beyond `keep_max`). When its sling is ready and it can see the hero
# it spins the sling overhead for spin_time s ("spin": a thin aim line shows on the fx layer), then throws a stone with combat.shoot
# (tall solids stop it, a dodge lets it fly past). A hit interrupts the spin; it is light, so the lasso pulls it.
# Its target is rat.gd `foe`: the hero, or a companion who is nearer once the fight is on.

var throws := 0           # stones thrown (for checks)

func setup(c, w, p, h: Vector2, k := "slinger", ax := Vector2.RIGHT, sp := 30.0) -> void:
	super.setup(c, w, p, h, k, ax, sp)
	R = c.SLINGER
	person = true
	top = -37.0
	leash = R["leash"]
	lose = R["lose"]
	max_hp = c.enemy_hp(kind)
	hp = max_hp
	cool = randf_range(R["first_min"], R["first_max"])     # so the three don't throw all at once

func _chase(dt: float, pd: float, pdir: Vector2) -> void:
	if _give_up(pd):              # rat.gd: the leash counts only when it isn't engaged
		_enter("return")
		return
	if pd < R["near"]:
		_move(-pdir, R["back_speed"], dt)
	elif pd > R["keep_max"]:
		_move(pdir, R["chase_speed"], dt)
	face = pdir                # backing off, it still watches its target
	if cool <= 0.0 and pd <= R["throw_range"] and world.los(position, foe.position):
		_enter("spin")

func _state_more(_dt: float, _pd: float, pdir: Vector2) -> void:
	if state != "spin":
		return
	face = pdir
	if t >= R["spin_time"]:
		combat.shoot(_hand(), foe.position + Vector2(0, -10), "enemy", "stone", R["dmg"], R["stone_speed"])
		throws += 1
		cool = R["throw_cd"]
		_enter("chase")

# where the stone leaves the sling: above its head
func _hand() -> Vector2:
	return position + Vector2(0, -24)

# ---------------------------------------------------------------- drawing
func _draw_body(n) -> void:
	var font := ThemeDB.fallback_font
	var d := "right"
	if absf(face.y) > absf(face.x) * 1.1:
		d = "down" if face.y > 0.0 else "up"
	else:
		d = "right" if face.x >= 0.0 else "left"
	var moving := state in ["patrol", "chase", "return", "pulled"] and (state != "patrol" or wait <= 0.0)
	Sprites.person(n, 0.0, 0.0, d, int(anim), moving, Sprites.PALETTES["slinger"])
	var hx := 6.0 if d == "right" or d == "down" else -6.0
	if state == "spin":
		# the arm up, the sling whirling in a flat circle over the head with the stone in its pouch
		var hand := Vector2(hx * 0.4, -24.0)
		Sprites.R(n, hx * 0.6 - 1, -22, 2, 8, Color("#c99a70"))
		var a := t * 24.0
		var stone := hand + Vector2(cos(a) * 8.0, sin(a) * 2.5 - 1.0)
		n.draw_line(hand, stone, Color("#c9b48a"), 1.0)
		n.draw_rect(Rect2(stone.round() - Vector2(1, 1), Vector2(3, 3)), Color("#3a2517"))
		n.draw_rect(Rect2(stone.round() - Vector2(1, 1), Vector2(2, 2)), Color("#9a8a74"))
	else:
		# the sling hanging from the hand: two cords and the empty pouch
		var hand2 := Vector2(hx, -11.0)
		n.draw_line(hand2, hand2 + Vector2(-1, 7), Color("#c9b48a"), 1.0)
		n.draw_line(hand2, hand2 + Vector2(1, 7), Color("#c9b48a"), 1.0)
		n.draw_rect(Rect2(hand2.x - 1, hand2.y + 6, 3, 2), Color("#6a4a2a"))
	_person_marks(n, font, state == "spin")
	if world.debug_node.visible:
		n.draw_string(font, Vector2(-14, 8), state, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)

# on combat's fx layer: a thin aim line from the sling toward its target (the hero or a companion) while it spins
func draw_telegraph(n) -> void:
	if state != "spin":
		return
	var from := _hand()
	var to: Vector2 = foe.position + Vector2(0, -10)
	var k := clampf(t / R["spin_time"], 0.0, 1.0)
	var len := minf(from.distance_to(to), 120.0)
	n.draw_line(from, from + (to - from).normalized() * len, Color(1.0, 0.35, 0.25, 0.2 + 0.4 * k), 1.0)
