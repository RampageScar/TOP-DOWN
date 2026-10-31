extends "res://scripts/rat.gd"
# chief.gd - the band's chief, the boss of the cave (Stage 6c). Numbers: combat.gd CHIEF.
# Built on rat.gd (patrol, sense, return, dying, the hit flash), kind "chief": a big bandit (drawn 1.3x) in dark wool with a fur over
# one shoulder and a sagaris, the long-handled war axe of the steppe riders (period-credible, unlike a curved sword).
# He sits asleep on his seat until the hero walks into the room (cave.gd WAKE["boss"]). His moves, on top of rat.gd's states:
# Like every enemy he goes after the nearest of the hero and his companions once the fight is on (rat.gd foe), and his charge and
# sweep hurt everyone they reach.
#   charge_wind -> charge -> daze | recover   from mid range: a red line on the ground follows the hero, then freezes for the last
#                                              charge_lock s; he rushes along it. Something tall in the way (rock, a strongbox) dazes him.
#   sweep_wind -> sweep -> recover            up close: a red arc in front of him, fixed when the wind-up starts; it hurts only inside.
#   enrage                                    once, at half health: a roar; afterwards he is faster (enrage_mul).
# Armour: hits hurt but never interrupt a wind-up, a charge, a sweep or the roar (like the giant). Dazed, he just takes them.
# Too heavy to lasso. Like every enemy he heals back to full once he is home on his seat: a fresh fight, so he can enrage again. (A fall
# in his fight opens the death screen; the save it loads is from before his room, so the fight starts over.)
# His warnings (charge line, sweep arc) are drawn on combat's fx layer (draw_telegraph), in world space.

const ARMOURED := ["charge_wind", "charge", "sweep_wind", "sweep", "enrage"]

var enraged := false
var charge_dir := Vector2.DOWN
var charge_from := Vector2.ZERO
var charge_cool := 0.0
var charge_hit := false       # this charge has hurt the hero
var _run_over: Array = []     # the companions this charge has already hurt (each only once)
var sweep_dir := Vector2.DOWN
var charges := 0          # how many charges he has made, how many ended dazed, how many sweeps (for checks)
var dazes := 0
var sweeps := 0
var sweep_hit := false    # the last sweep hurt the hero

func setup(c, w, p, h: Vector2, k := "chief", ax := Vector2.RIGHT, sp := 30.0) -> void:
	super.setup(c, w, p, h, k, ax, sp)
	R = c.CHIEF
	heavy = true
	person = true
	top = -37.0               # in the body's own (unscaled) space: the body node is scaled by R.sc
	leash = R["leash"]
	lose = R["lose"]
	max_hp = c.enemy_hp(kind)
	hp = max_hp
	face = Vector2.DOWN
	flip = 1
	charge_cool = R["charge_start_cd"]
	body.scale = Vector2(R["sc"], R["sc"])

# enraged, he is enrage_mul times as fast (speeds x, times /)
func _k() -> float:
	return R["enrage_mul"] if enraged else 1.0

func _physics_process(dt: float) -> void:
	charge_cool = maxf(0.0, charge_cool - dt)
	super._physics_process(dt)

func _enter(s: String) -> void:
	super._enter(s)
	match s:
		"charge_wind", "sweep_wind":
			var to: Vector2 = foe.position - position
			var d := to.normalized() if to.length() > 0.01 else face
			charge_dir = d
			sweep_dir = d
		"charge":
			charge_from = position
			charge_hit = false
			_run_over.clear()
			charges += 1
			charge_cool = R["charge_cd"] / _k()

# asleep on his seat: he just sits there (no roaming)
func _patrol(dt: float, pd: float, pdir: Vector2) -> void:
	if dormant:
		face = Vector2.DOWN
		return
	super._patrol(dt, pd, pdir)

# back home he is healed (rat.gd _return); then his roar at half health is ready again
func _return(dt: float, pd: float, pdir: Vector2) -> void:
	super._return(dt, pd, pdir)
	if state == "patrol" and hp == max_hp:
		enraged = false

func _chase(dt: float, pd: float, pdir: Vector2) -> void:
	face = pdir
	if _give_up(pd):              # rat.gd: the leash counts only when he isn't engaged
		_enter("return")
		return
	if pd < R["sweep_range"] and cool <= 0.0:
		_enter("sweep_wind")
		return
	if charge_cool <= 0.0 and pd >= R["charge_min"] and pd <= R["charge_max"] and world.los(position, foe.position):
		_enter("charge_wind")
		return
	if pd > 14.0:
		_move(pdir, R["chase_speed"] * _k(), dt)

func _recover() -> void:
	if t >= R["recover_time"] / _k():
		_after_action()

func _state_more(dt: float, _pd: float, pdir: Vector2) -> void:
	match state:
		"charge_wind":
			var wind: float = R["charge_wind"] / _k()
			if t < wind - R["charge_lock"]:       # the line follows the hero, then freezes: step out of it
				charge_dir = pdir
			face = charge_dir
			if t >= wind:
				_enter("charge")
		"charge":
			_charge(dt)
		"daze":
			if t >= R["daze_time"]:
				_after_action()
		"sweep_wind":
			face = sweep_dir
			if t >= R["sweep_wind"] / _k():
				_sweep_lands()
				_enter("sweep")
		"sweep":
			if t >= R["sweep_time"]:
				cool = R["cool"] / _k()
				_enter("recover")
		"enrage":
			face = pdir
			if t >= R["enrage_time"]:
				_enter("chase")

func _charge(dt: float) -> void:
	var step: Vector2 = charge_dir * R["charge_speed"] * _k() * dt
	var ahead := position + step + charge_dir * 6.0
	if world.sight_blocked(ahead) or world.sight_blocked(position + step):     # rock, a tent, a strongbox: he runs into it
		dazes += 1
		player.shake(2.5, 0.2)
		combat.spark(position + charge_dir * 8.0 + Vector2(0, -14), -charge_dir, 8, Color("#c8b89a"))
		_enter("daze")
		return
	if world.feet_blocked(position + step):    # something low (a fire ring, a stool): he pulls up
		_enter("recover")
		return
	position += step
	flip = 1 if charge_dir.x >= 0.0 else -1
	# hurt the hero (and any companion in his way) once on the way; while a dodge (or a fresh hurt) makes the hero invulnerable the
	# chief passes straight through
	for b in combat.targets():
		if position.distance_to(b.position) >= R["charge_hit"]:
			continue
		if b == player:
			if not charge_hit:
				charge_hit = combat.hurt_player(R["charge_dmg"], position)
		elif not _run_over.has(b):
			_run_over.append(b)
			combat.hurt_body(b, R["charge_dmg"], position)
	if position.distance_to(charge_from) >= R["charge_len"]:
		_enter("recover")

# the one and only damage check of a sweep: who is inside the arc right now? (the hero and any companion standing there)
func _sweep_lands() -> void:
	sweeps += 1
	sweep_hit = false
	for b in combat.targets():
		var rel: Vector2 = b.position - position
		var inside: bool = rel.length() <= R["sweep_radius"] and (rel.length() < 8.0 or absf(sweep_dir.angle_to(rel)) <= deg_to_rad(R["sweep_arc"]) / 2.0)
		if inside:
			var landed: bool = combat.hurt_body(b, R["sweep_dmg"], position)
			if b == player:
				sweep_hit = landed
	player.shake(1.5, 0.12)

# where the charge line ends: its full length, or the first tall thing in the way
func _charge_end() -> Vector2:
	var n := int(R["charge_len"] / 4.0)
	for i in range(1, n + 1):
		var p := position + charge_dir * 4.0 * i
		if world.sight_blocked(p):
			return p
	return position + charge_dir * R["charge_len"]

# ---------------------------------------------------------------- things done to him
func hit(dmg: int, dirv: Vector2, power: float, interrupt := true) -> void:
	if not alive:
		return
	hp -= dmg
	wake()
	flash = 0.14
	kb = dirv * power * R["kb_mul"]
	combat.spark(position + Vector2(0, -8), dirv, 6, Color("#fff2c0"))
	if hp <= 0:
		_die()
		return
	if not enraged and hp <= int(max_hp * R["enrage_frac"]):
		enraged = true
		_enter("enrage")
		player.shake(3.0, 0.4)
		combat.spark(position + Vector2(0, -20), Vector2.ZERO, 14, Color("#ff6a4a"))
		combat.text(position + Vector2(0, -56), "He's enraged!", Color("#ff8a6a"), 1.4)
		return
	if state in ARMOURED or state == "daze":
		return
	if not interrupt:
		wake(true)
	else:
		_enter("stagger")

# ---------------------------------------------------------------- drawing
func _tint() -> void:
	if flash > 0.0:
		body.modulate = Color(2.4, 2.4, 2.4)
	elif state == "charge_wind" or state == "sweep_wind":
		body.modulate = Color(1.8, 0.55, 0.55) if int(t * 20.0) % 2 == 0 else Color(1.35, 0.8, 0.8)
	elif state == "enrage":
		body.modulate = Color(1.9, 0.6, 0.5)
	elif state == "daze":
		body.modulate = Color(0.85, 0.85, 1.0)
	elif enraged:
		body.modulate = Color(1.2, 0.85, 0.8)
	else:
		body.modulate = base_tint

func _dir4() -> String:
	if absf(face.y) > absf(face.x) * 1.1:
		return "down" if face.y > 0.0 else "up"
	return "right" if face.x >= 0.0 else "left"

# the body node (scaled by R.sc): the person, his fur, his axe, the markers and the boss health bar
func _draw_body(n) -> void:
	var font := ThemeDB.fallback_font
	var d := _dir4()
	var sg := -1.0 if d == "left" or d == "up" else 1.0       # which side his axe hand is on
	var moving := state in ["patrol", "chase", "return", "charge"] and (state != "patrol" or wait <= 0.0) and not dormant
	var ox := 0.0
	if state == "charge_wind" or state == "sweep_wind":
		ox = -sg * 1.5 * minf(1.0, t / 0.3)                   # leans back, gathering himself
	elif state == "enrage":
		ox = sin(t * 60.0) * 1.0                              # shakes with the roar
	if state == "charge":
		for i in range(4):
			var a := Vector2(-charge_dir.x * (8 + i * 4), -10 - i * 3 - charge_dir.y * (8 + i * 4))
			n.draw_line(a, a - charge_dir * 7.0, Color(1, 1, 1, 0.35), 1.0)
	Sprites.person(n, ox, 0.0, d, int(anim), moving, Sprites.PALETTES["chief"])
	_draw_fur(n, d, ox)
	_draw_axe(n, sg, ox)
	# markers
	if dormant:
		for i in range(3):
			var ph := fmod(t * 0.7 + i * 0.33, 1.0)
			n.draw_string(font, Vector2(8 + i * 3 + ph * 4, -26 - ph * 14), "z", HORIZONTAL_ALIGNMENT_LEFT, -1, 7 + i, Color(1, 1, 1, 1.0 - ph))
	elif state == "alert":
		n.draw_rect(Rect2(-6, top + 2, 12, 2), Color(0, 0, 0, 0.6))
		n.draw_rect(Rect2(-6, top + 2, 12.0 * alert, 2), Color("#ffd24a"))
		_mark(n, font, "?", Color("#ffd24a"))
	elif state in ["charge_wind", "sweep_wind", "enrage"] or (state == "chase" and t < 0.5):
		_mark(n, font, "!", Color("#ff4a3a"))
	elif state == "daze":
		for i in range(3):
			var a2 := TAU * i / 3.0 + Time.get_ticks_msec() / 180.0
			n.draw_rect(Rect2(roundf(cos(a2) * 6.0) - 1, roundf(sin(a2) * 2.0) - 30, 2, 2), Color("#ffe14a"))
	# boss health bar (once he is awake), unless the big bar at the bottom of the screen shows it (hud.gd, while he is after the hero);
	# the notch marks half health, where he enrages
	if not dormant and state != "alert" and combat.boss() != self:
		n.draw_rect(Rect2(-13, top + 3, 26, 4), Color(0, 0, 0, 0.85))
		n.draw_rect(Rect2(-12, top + 4, 24.0 * hp / max_hp, 2), Color("#e0392b"))
		n.draw_rect(Rect2(-12, top + 4, 24.0 * hp / max_hp, 1), Color("#ff7a66"))
		n.draw_rect(Rect2(0, top + 4, 1, 2), Color(0, 0, 0, 0.6))
	if world.debug_node.visible:
		n.draw_string(font, Vector2(-14, 10), state + (" dormant" if dormant else ""), HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color.WHITE)

# a sheepskin thrown over the shoulder away from the axe hand: shaggy pale wool with a dark outline
func _draw_fur(n, d: String, ox: float) -> void:
	var x := ox + (-7.0 if d == "right" or d == "down" else 1.0)
	if d == "up":
		x = ox - 6.0
	Sprites.R(n, x - 1, -19, 8, 7, Color("#2a1e14"))
	Sprites.R(n, x, -18, 6, 5, Color("#a89474"))
	Sprites.R(n, x, -18, 6, 1, Color("#c8b494"))
	Sprites.R(n, x + 1, -14, 1, 2, Color("#a89474"))
	Sprites.R(n, x + 4, -14, 1, 2, Color("#8a7658"))

# the sagaris: a long haft held near its butt, a narrow blade on one side of the head and a point on the other.
# Its angle shows the move: resting on the shoulder, raised back for a charge, pointed ahead in the rush, drawn back and then swung
# across for a sweep, dragging when dazed.
func _draw_axe(n, sg: float, ox: float) -> void:
	var hand := Vector2(ox + sg * 6.0, -11.0)
	var v := Vector2(sg * 0.35, -1.0)
	match state:
		"charge_wind": v = Vector2(-sg * 0.7, -1.0)
		"charge": v = Vector2(charge_dir.x, charge_dir.y - 0.4)
		"sweep_wind": v = Vector2.from_angle(sweep_dir.angle() - sg * deg_to_rad(R["sweep_arc"]) / 2.0 - sg * 0.6)
		"sweep":
			var k := clampf(t / R["sweep_time"], 0.0, 1.0)
			var half := deg_to_rad(R["sweep_arc"]) / 2.0
			v = Vector2.from_angle(sweep_dir.angle() + sg * lerpf(-half, half, k))
		"recover", "stagger": v = Vector2(sg, 0.5)
		"daze": v = Vector2(sg * 0.8, 1.0)
	v = v.normalized()
	var head := hand + v * 16.0
	var butt := hand - v * 4.0
	n.draw_line(butt, head, Color("#2a1e14"), 3.0)
	n.draw_line(butt, head, Color("#8a5a32"), 1.0)
	var w := v.orthogonal() * sg
	var blade := PackedVector2Array([head + w * 1.0 + v * 1.5, head + w * 5.0 + v * 2.5, head + w * 5.0 - v * 2.5, head + w * 1.0 - v * 1.5])
	n.draw_colored_polygon(blade, Color("#2a2a30"))
	n.draw_colored_polygon(PackedVector2Array([head + w * 1.5 + v * 0.8, head + w * 4.2 + v * 1.6, head + w * 4.2 - v * 1.6, head + w * 1.5 - v * 0.8]), Color("#c8ccd4"))
	n.draw_line(head, head - w * 3.5, Color("#2a2a30"), 2.0)            # the point on the back of the head
	n.draw_rect(Rect2(hand.x - 1, hand.y - 1, 3, 2), Color("#b8862a"))  # bronze grip band

# on combat's fx layer, in world space: the charge line and the sweep arc
func draw_telegraph(n) -> void:
	if state == "charge_wind":
		var wind: float = R["charge_wind"] / _k()
		var locked: bool = t >= wind - R["charge_lock"]
		var a := 0.25 + 0.5 * clampf(t / wind, 0.0, 1.0)
		var from := position + Vector2(0, -2)
		var to := _charge_end() + Vector2(0, -2)
		n.draw_line(from, to, Color(1.0, 0.2, 0.15, a * 0.35), 12.0)
		n.draw_line(from, to, Color(1.0, 0.75, 0.55, a) if locked else Color(1.0, 0.3, 0.2, a), 2.0 if locked else 1.0)
		var bk := to - charge_dir * 7.0
		n.draw_colored_polygon(PackedVector2Array([to, bk + charge_dir.orthogonal() * 5.0, bk - charge_dir.orthogonal() * 5.0]), Color(1.0, 0.3, 0.2, a))
	elif state == "sweep_wind" or (state == "sweep" and t < R["sweep_time"]):
		var half := deg_to_rad(R["sweep_arc"]) / 2.0
		var a0 := sweep_dir.angle()
		var rad: float = R["sweep_radius"]
		var pts := PackedVector2Array([position])
		for i in range(17):
			pts.append(position + Vector2.from_angle(a0 - half + 2.0 * half * i / 16.0) * rad)
		if state == "sweep":
			n.draw_colored_polygon(pts, Color(1.0, 0.95, 0.8, 0.45 * (1.0 - t / R["sweep_time"])))
		else:
			var k := clampf(t / (R["sweep_wind"] / _k()), 0.0, 1.0)
			n.draw_colored_polygon(pts, Color(1.0, 0.2, 0.15, 0.10 + 0.25 * k))
			n.draw_arc(position, rad, a0 - half, a0 + half, 16, Color(1.0, 0.4, 0.3, 0.5 + 0.5 * k), 1.5)
			n.draw_arc(position, rad * k, a0 - half, a0 + half, 16, Color(1.0, 0.7, 0.5, 0.6), 1.0)
