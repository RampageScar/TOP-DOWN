extends CharacterBody2D
# player.gd - silent protagonist. WASD / arrows move. Mouse 1 light and Mouse 2 heavy attacks (the bow: Mouse 2 held draws), Space
# block (a fresh press parries), Shift dodge, Q the weapon's special or the lasso (held: the strong lasso), 1 the next weapon. combat.gd
# runs those; this file moves the body and draws it, with every attack pose, the weapons and the guard.
#  - aim (Stage 8e, from the arena's 8b): the direction every attack goes, 8 ways (the move keys, diagonals too, as the dodge reads
#    them). facing_vec() returns it. The body itself is drawn facing 4 ways (`dir`, sprites.gd person); on a diagonal it faces sideways,
#    as walking does.
#  - pose: the move being swung (combat.gd's move rows "pose"); pose_hits: how many thrusts it has (the flurry).
#  - blocking: the guard is up. He walks at GUARD_WALK and still turns to face the aim; the weapon is held across in front.
#  - bow_draw: the bow is drawn. He walks at DRAW_WALK, and walking turns the aim (combat.gd draws the dotted reticle).

const Sprites = preload("res://scripts/sprites.gd")
const Drawn = preload("res://scripts/drawn.gd")
const SPEED := 70.0
const CAM_OFFSET := Vector2(0, -12)
# the hero's three bars (Stage 7e): HP, stamina (every swing, dodge and throw spends it; combat.gd STAMINA) and focus (special moves
# only, such as the strong lasso; combat.gd FOCUS). These are the maximums at level 1; progress.gd apply_max() sets max_* from the
# hero's level (Stage 7f). His XP and level live in progress.gd.
const BASE_HP := 100
const BASE_STAMINA := 100
const BASE_FOCUS := 50
const GUARD_WALK := 0.4    # walking speed behind the guard, a share of SPEED
const DRAW_WALK := 0.5     # walking speed while drawing the bow (the user's play-test: 60 % was too fast); walking turns the aim

var world_size := Vector2(1600, 1000)
var dir := "down"
var anim := 0.0
var moving := false
var hp := BASE_HP
var max_hp := BASE_HP
var stamina := BASE_STAMINA
var max_stamina := BASE_STAMINA
var focus := BASE_FOCUS
var max_focus := BASE_FOCUS
var body_node
var cam
var aim := Vector2.DOWN    # 8-way, normalised: where attacks go (facing_vec)

# set by combat.gd
var swing_n := -1          # -1 none, else the swing's place in its string (0, 1, 2)
var pose := ""             # the move being swung: its drawing
var pose_hits := 1         # how many thrusts the move on now has (the flurry: 4, or 5 as the Inferno finisher)
var weapon := "unarmed"    # the weapon in hand (combat.gd keeps it, this only draws it)
var has_sword := false     # carries the sword: with another weapon out it hangs at his hip
var swing_p := 0.0         # 0..1 progress of the current swing
var blocking := false      # the guard is up
var bow_draw := -1.0       # how far the bow is drawn now, 0..1 (< 0: not drawing)
var dodging := false
var dodge_p := 0.0
var dodge_dir := Vector2.ZERO
var dodge_speed := 170.0
var lock := false          # planted while throwing the lasso
var aiming := false        # holding Q for the strong lasso, or drawing the bow: he can turn on the spot to aim
var scripted := false      # a cutscene is walking the hero (hall.gd): keys are ignored, script_v is the velocity
var cam_extra := Vector2.ZERO   # a cutscene can look away from the hero (the king call) by moving the camera
var script_v := Vector2.ZERO   # direction, as a fraction of SPEED (so 0.8 = 80 % of walking speed)
var impulse := Vector2.ZERO
var inv_t := 0.0
var hurt_t := 0.0
var poison := 0            # poison ticks left (Stage 7j, the scorpion's sting; combat.gd POISON ticks them), 0 = not poisoned
var poison_t := 0.0        # seconds to the next tick
var dead := false
var shake_t := 0.0
var shake_amp := 0.0

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	# small feet-only collision box so the hero can walk close behind props
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(8, 4)
	cs.shape = rs
	cs.position = Vector2(0, -2)
	add_child(cs)

	body_node = Drawn.new()
	body_node.animated = true
	body_node.draw_fn = _draw_body
	add_child(body_node)

	cam = Camera2D.new()
	cam.offset = CAM_OFFSET
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(world_size.x)
	cam.limit_bottom = int(world_size.y)
	cam.position_smoothing_enabled = false
	add_child(cam)

# map size: keeps the hero and the camera inside the current map
func set_bounds(size: Vector2) -> void:
	world_size = size
	if cam != null:
		cam.limit_right = int(size.x)
		cam.limit_bottom = int(size.y)

# Where the hero aims (8 ways): his attacks, the lasso and the guard go this way. Something that turns his body from outside (a door's
# spawn, a load, a cutscene, the tests) sets only `dir`; an aim that no longer agrees with it gives way to it here, and follows it at
# the next physics frame (_physics_process), so none of those places needs to know about the aim.
func facing_vec() -> Vector2:
	var d := _dir_vec()
	return aim if aim.dot(d) > 0.5 else d

# the 4 ways the body faces, as a vector
func _dir_vec() -> Vector2:
	match dir:
		"up": return Vector2.UP
		"down": return Vector2.DOWN
		"left": return Vector2.LEFT
	return Vector2.RIGHT

# aim the way the body faces (the arena's start, and whenever the body was turned from outside)
func aim_from_dir() -> void:
	aim = _dir_vec()

func shake(amp: float, time: float) -> void:
	if amp >= shake_amp or shake_t <= 0.0:
		shake_amp = amp
	shake_t = maxf(shake_t, time)

func _process(delta: float) -> void:
	if shake_t > 0.0:
		shake_t -= delta
		cam.offset = CAM_OFFSET + cam_extra.round() + Vector2(roundf(randf_range(-1.0, 1.0) * shake_amp), roundf(randf_range(-1.0, 1.0) * shake_amp))
	else:
		shake_amp = 0.0
		cam.offset = CAM_OFFSET + cam_extra.round()
	# colour feedback: red/white blink when hurt, faint while dodging, a slow purple pulse while poisoned, grey when fallen
	if dead:
		body_node.modulate = Color(0.55, 0.55, 0.6)
		body_node.rotation = PI / 2.0
	else:
		body_node.rotation = 0.0
		if dodging:
			body_node.modulate = Color(1, 1, 1, 0.55)
		elif hurt_t > 0.0:
			body_node.modulate = Color(1.8, 0.5, 0.5) if int(hurt_t * 25.0) % 2 == 0 else Color.WHITE
		elif inv_t > 0.0:
			body_node.modulate = Color(1, 1, 1, 0.5 if int(inv_t * 12.0) % 2 == 0 else 1.0)
		elif poison > 0 and int(Time.get_ticks_msec() / 300.0) % 2 == 0:
			body_node.modulate = Color(1.15, 0.8, 1.3)
		else:
			body_node.modulate = Color.WHITE

# HP, stamina and focus back to full (a rest spot, a level-up). A rest also cures poison (main.gd rest).
func refill() -> void:
	hp = max_hp
	stamina = max_stamina
	focus = max_focus

func _physics_process(delta: float) -> void:
	if aim.dot(_dir_vec()) <= 0.5:
		aim_from_dir()             # the body was turned from outside (see facing_vec): the aim follows
	var guarded := blocking and not dead and not dodging
	var drawing := bow_draw >= 0.0 and not dead and not dodging
	if guarded or drawing:
		# behind the guard, or drawing the bow, he walks slowly: the scripted walk moves him at script_v x SPEED without turning him (the
		# aim does, below) and past the `aiming` stop. The block is refused while drawing, so only one of the two is ever on.
		scripted = true
		script_v = _keys().normalized() * (GUARD_WALK if guarded else DRAW_WALK)
	_move(delta)
	if guarded or drawing:
		scripted = false
		script_v = Vector2.ZERO
		if _turn():
			_face_aim()
		return
	# the same rule as `dir`: no turning mid-swing, in a dodge, while throwing the lasso (lock) or down
	if dead or scripted or dodging or lock or swing_n >= 0:
		return
	if _turn():
		_face_aim()

func _move(delta: float) -> void:
	inv_t = maxf(0.0, inv_t - delta)
	hurt_t = maxf(0.0, hurt_t - delta)
	var v := Vector2.ZERO
	moving = false
	if scripted and not dead:
		v = script_v
		moving = v != Vector2.ZERO
		if moving:
			anim += delta * 9.0
	elif not dead and not lock and not dodging:
		var mx := Input.get_axis("move_left", "move_right")
		var my := Input.get_axis("move_up", "move_down")
		v = Vector2(mx, my)
		moving = v != Vector2.ZERO
		if moving:
			if swing_n < 0:        # no turning mid-swing
				if mx != 0.0 and my == 0.0:
					dir = "right" if mx > 0.0 else "left"
				elif my != 0.0 and mx == 0.0:
					dir = "down" if my > 0.0 else "up"
				elif dir == "up" or dir == "down":
					dir = "right" if mx > 0.0 else "left"   # diagonal: keep current axis
			v = v.normalized()
			anim += delta * 9.0
		if aiming:
			v = Vector2.ZERO
			moving = false
	var spd := SPEED * (0.35 if swing_n >= 0 else 1.0)
	velocity = v * spd
	if dodging:
		velocity = dodge_dir * dodge_speed
		anim += delta * 16.0
	velocity += impulse
	impulse = impulse.move_toward(Vector2.ZERO, 500.0 * delta)
	move_and_slide()
	position.x = clampf(position.x, 6.0, world_size.x - 6.0)
	position.y = clampf(position.y, 20.0, world_size.y - 4.0)

func _keys() -> Vector2:
	return Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_up", "move_down"))

# the move keys held turn the aim (8 ways); false when none are held
func _turn() -> bool:
	var v := _keys()
	if v == Vector2.ZERO:
		return false
	aim = Vector2(signf(v.x), signf(v.y)).normalized()
	return true

# the body faces the aim, 4 ways: on a diagonal sideways, as walking does (so the body always faces one of the aim's two sides)
func _face_aim() -> void:
	if aim.x != 0.0:
		dir = "right" if aim.x > 0.0 else "left"
	else:
		dir = "down" if aim.y > 0.0 else "up"

func _draw_body(n) -> void:
	if dodging:
		# dust kicked up behind the roll
		for i in range(3):
			n.draw_circle(-dodge_dir * (5.0 + i * 5.0) + Vector2(0, -2), 3.0 - i * 0.8, Color(0.9, 0.78, 0.5, 0.55 - i * 0.15))
		n.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.12, 0.82))
	Sprites.person(n, 0.0, 0.0, dir, int(anim), moving or dodging, {})
	n.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if blocking and not dead and not dodging:
		_draw_guard(n)
	elif weapon == "sword":
		if swing_n >= 0:
			_draw_sword_swing(n)
		elif not dodging and not dead:
			_draw_sword_held(n)
	elif weapon == "spear":
		if not dead and not dodging:
			if swing_n >= 0:
				_draw_swing(n)
			else:
				_draw_spear_held(n)
	elif weapon == "bow":
		if not dead and not dodging:
			_draw_bow_now(n)
	elif swing_n >= 0:
		_draw_swing(n)
	if weapon != "sword" and has_sword and not dodging and not dead:
		_draw_sheath(n)

# ---- the sword (Stage 7l): drawn in code like the rest of him, a dark outline under a two-tone blade and a bronze guard
const BLADE := Color("#c8d0d6")
const BLADE_LIT := Color("#f0f4f6")
const BLADE_DARK := Color("#2a2a30")
const GUARD := Color("#c8963a")
const GRIP := Color("#6a4024")
const SHAFT := Color("#8a5a30")
const BOW_WOOD := Color("#7a4a26")
const BOW_STRING := Color("#e8e0c8")

# which side of him the sword hand is on screen: right when he faces right or down, left otherwise
func _hand_side() -> float:
	return 1.0 if dir == "right" or dir == "down" else -1.0

func _blade(n, from: Vector2, to: Vector2) -> void:
	n.draw_line(from, to, BLADE_DARK, 3.0)
	n.draw_line(from, to, BLADE, 1.5)
	n.draw_line(from, from.lerp(to, 0.6), BLADE_LIT, 1.0)
	var across := (to - from).normalized().orthogonal() * 2.5
	n.draw_line(from - across, from + across, GUARD, 1.5)          # the guard
	n.draw_line(from, from - (to - from).normalized() * 3.0, GRIP, 2.0)

# drawn, at rest: held down along his side, point to the ground
func _draw_sword_held(n) -> void:
	var s := _hand_side()
	var hand := Vector2(5.0 * s, -11.0)
	_blade(n, hand, hand + Vector2(3.0 * s, 10.0))

# put away: the scabbard at his hip
func _draw_sheath(n) -> void:
	var s := -_hand_side()
	var top := Vector2(4.0 * s, -10.0)
	var tip := top + Vector2(2.0 * s, 8.0)
	n.draw_line(top, tip, BLADE_DARK, 3.0)
	n.draw_line(top, tip, GRIP, 1.5)
	n.draw_line(top - Vector2(2, 0), top + Vector2(2, 0), GUARD, 1.5)

# the guard: the weapon held across in front of him, along the aim
func _draw_guard(n) -> void:
	var f := facing_vec()
	var c := Vector2(0, -11) + f * 6.0
	var across := f.orthogonal()
	match weapon:
		"sword":
			_blade(n, c - across * 7.0, c + across * 9.0)
		"spear":
			_spear(n, c - across * 12.0, c + across * 14.0)
		"bow":
			_bow(n, c, f, 0.0, false)          # the stave held up across the front
		_:
			var skin: Color = Sprites.K(Sprites.BASE["skin"])
			for s in [-1.0, 1.0]:
				var fist: Vector2 = c + across * 3.0 * s
				n.draw_rect(Rect2(roundf(fist.x) - 2, roundf(fist.y) - 2, 4, 4), skin)

# ---- the swings: each pose its drawing; the four the game started with (punch, kick, slash, thrust) are below
func _draw_swing(n) -> void:
	match pose:
		"shoulder": _draw_shoulder(n)
		"knee": _draw_knee(n)
		"hammer": _draw_hammer(n)
		"jab", "long_thrust", "drive", "lunge": _draw_spear_thrust(n)
		"sweep": _draw_spear_sweep(n)
		"whirl": _draw_spear_whirl(n)
		_:
			_as_first_swing(n, false)

func _draw_sword_swing(n) -> void:
	match pose:
		"rise": _draw_rise(n)
		"overhead": _draw_overhead(n)
		"flurry": _draw_flurry(n)
		_:
			_as_first_swing(n, true)

# The punch / kick and slash / thrust drawings pick their look by swing_n (0 / 1: from either side, 2: the kick or thrust). A string can
# put a punch or slash third (the sword's LHL), so for the draw swing_n becomes what the pose needs, then goes back.
func _as_first_swing(n, sword: bool) -> void:
	var keep := swing_n
	swing_n = 2 if pose in ["kick", "thrust"] else swing_n % 2
	if sword:
		_draw_slash_thrust(n)
	else:
		_draw_punch_kick(n)
	swing_n = keep

func _ext() -> float:
	return sin(clampf(swing_p, 0.0, 1.0) * PI)

# slash (swings 0 and 1, from opposite sides): the blade sweeps an arc in front of him with a white trail; thrust (2): straight out
func _draw_slash_thrust(n) -> void:
	var f := facing_vec()
	var p := clampf(swing_p, 0.0, 1.0)
	var base := Vector2(0, -12)
	if swing_n < 2:
		var side := 1.0 if swing_n == 0 else -1.0
		var a0 := f.angle() - 1.3 * side
		var a := a0 + 2.6 * side * p
		var hand := base + Vector2.from_angle(a) * 5.0
		_blade(n, hand, base + Vector2.from_angle(a) * 19.0)
		var from := minf(a0, a)
		var to := maxf(a0, a)
		if to - from > 0.2:
			n.draw_arc(base, 17.0, from, to, 12, Color(1, 1, 1, 0.7 * sin(p * PI)), 2.0)
	else:
		var ext := sin(p * PI)
		var hand := base + f * (3.0 + 8.0 * ext)
		_blade(n, hand, hand + f * 14.0)
		if ext > 0.5:
			n.draw_line(hand + f * 15.0, hand + f * 21.0, Color(1, 1, 1, 0.7), 1.0)

func _draw_punch_kick(n) -> void:
	var f := facing_vec()
	var ext := sin(clampf(swing_p, 0.0, 1.0) * PI)
	var skin := Sprites.K(Sprites.BASE["skin"])
	if swing_n < 2:
		var side := 1.0 if swing_n == 0 else -1.0
		var perp := f.orthogonal() * side * 2.0
		var base := Vector2(0, -13)
		if dir == "up":
			base.y = -15
		elif dir == "down":
			base.y = -11
		var fist := base + f * (3.0 + 11.0 * ext) + perp
		n.draw_line(base + perp, fist, Sprites.K(Sprites.BASE["jac"]), 2.0)
		n.draw_rect(Rect2(roundf(fist.x) - 2, roundf(fist.y) - 2, 4, 4), skin)
		if ext > 0.55:
			n.draw_line(fist + f * 2.0, fist + f * 7.0, Color(1, 1, 1, 0.7), 1.0)
	else:
		var base := Vector2(0, -6)
		var foot := base + f * (4.0 + 13.0 * ext) + Vector2(0, -2.0 * ext)
		n.draw_line(base, foot, Sprites.K(Sprites.BASE["pants"]), 3.0)
		n.draw_rect(Rect2(roundf(foot.x) - 2, roundf(foot.y) - 2, 5, 4), Sprites.K(Sprites.BASE["boot"]))
		var a := f.angle()
		n.draw_arc(base, 16.0, a - 0.9, a + 0.9, 10, Color(1, 1, 1, 0.75 * ext), 1.5)

# shoulder charge (fists' LLH): the shoulder driven forward, dust thrown up behind, speed lines either side
func _draw_shoulder(n) -> void:
	var f := facing_vec()
	var ext := _ext()
	var base := Vector2(0, -12)
	var tip := base + f * (3.0 + 7.0 * ext)
	n.draw_line(base, tip, Sprites.K(Sprites.BASE["jac"]), 5.0)
	for i in range(3):
		n.draw_circle(-f * (6.0 + i * 5.0) + Vector2(0, -2), 2.6 - i * 0.7, Color(0.9, 0.78, 0.5, 0.5 * ext))
	if ext > 0.4:
		var side := f.orthogonal() * 6.0
		n.draw_line(tip + side, tip + side - f * 8.0, Color(1, 1, 1, 0.6), 1.0)
		n.draw_line(tip - side, tip - side - f * 8.0, Color(1, 1, 1, 0.6), 1.0)

# knee (fists' HH): a short kick driven upward
func _draw_knee(n) -> void:
	var f := facing_vec()
	var ext := _ext()
	var hip := Vector2(0, -7)
	var knee := hip + f * (3.0 + 7.0 * ext) + Vector2(0, -4.0 * ext)
	var pants: Color = Sprites.K(Sprites.BASE["pants"])
	n.draw_line(hip, knee, pants, 3.0)
	n.draw_rect(Rect2(roundf(knee.x) - 2, roundf(knee.y) - 2, 4, 4), pants.darkened(0.25))
	if ext > 0.6:
		n.draw_arc(knee, 5.0, f.angle() - 0.8, f.angle() + 0.8, 8, Color(1, 1, 1, 0.7 * ext), 1.0)

# hammer fist (fists' HHH): the fist raised over his head comes down in front of him, with a ring where it lands
func _draw_hammer(n) -> void:
	var f := facing_vec()
	var p := clampf(swing_p, 0.0, 1.0)
	var shoulder := Vector2(0, -14)
	var top := shoulder + Vector2(0, -9) - f * 2.0
	var low := shoulder + f * 13.0 + Vector2(0, 5)
	var fist := top.lerp(low, p * p)
	n.draw_line(shoulder, fist, Sprites.K(Sprites.BASE["jac"]), 2.0)
	n.draw_rect(Rect2(roundf(fist.x) - 2, roundf(fist.y) - 2, 5, 5), Sprites.K(Sprites.BASE["skin"]))
	if p > 0.3:
		n.draw_line(top, fist, Color(1, 1, 1, 0.5 * (1.0 - p)), 1.0)
	if p > 0.55:
		n.draw_arc(low, 3.0 + 10.0 * (p - 0.55), 0.0, TAU, 12, Color(1, 1, 1, 0.8 * (1.0 - p) / 0.45), 1.0)

# rising cut (sword's LH): a short sweep the other way round from a slash while the hand lifts, with sparks flicking up
func _draw_rise(n) -> void:
	var f := facing_vec()
	var p := clampf(swing_p, 0.0, 1.0)
	var c := Vector2(0, -12.0 - 6.0 * p)
	var a0 := f.angle() + 1.0
	var a := a0 - 2.0 * p
	_blade(n, c + Vector2.from_angle(a) * 5.0, c + Vector2.from_angle(a) * 18.0)
	if p > 0.1:
		n.draw_arc(c, 16.0, a, a0, 10, Color(1, 1, 1, 0.7 * sin(p * PI)), 2.0)
	if p > 0.5:
		var tip := c + Vector2.from_angle(a) * 18.0
		n.draw_line(tip, tip + Vector2(0, -6.0 * p), Color(1, 0.95, 0.7, 0.8 * (1.0 - p) * 2.0), 1.0)

# overhead cut (sword's HHH): a wider, longer sweep than a slash, from either side in turn, with a heavy trail and a mark where it ends
func _draw_overhead(n) -> void:
	var f := facing_vec()
	var p := clampf(swing_p, 0.0, 1.0)
	var base := Vector2(0, -13)
	var side := 1.0 if swing_n % 2 == 0 else -1.0
	var a0 := f.angle() - 1.7 * side
	var a := a0 + 3.4 * side * p * p
	_blade(n, base + Vector2.from_angle(a) * 5.0, base + Vector2.from_angle(a) * 22.0)
	if absf(a - a0) > 0.2:
		n.draw_arc(base, 20.0, minf(a0, a), maxf(a0, a), 16, Color(1, 1, 1, 0.75 * sin(p * PI)), 3.0)
	if p > 0.7:
		var hit := base + f * 21.0
		n.draw_line(hit - f.orthogonal() * 4.0, hit + f.orthogonal() * 4.0, Color(1, 1, 1, (1.0 - p) * 2.5), 1.0)

# ---- the specials
# the sword's flaming flurry: quick fencing thrusts (pose_hits of them, a little to either side in turn), the blade wrapped in
# flickering flame. The flame is only how the special looks (the user's choice in 8e): the foes it cuts bleed (combat.gd BLEED).
func _draw_flurry(n) -> void:
	var f := facing_vec()
	var p := clampf(swing_p, 0.0, 1.0)
	var k := float(maxi(pose_hits, 1))
	var seg := mini(int(p * k), int(k) - 1)
	var ext := sin((p * k - seg) * PI)
	var hand := Vector2(0, -12) + f * (3.0 + 10.0 * ext) + f.orthogonal() * (1.5 if seg % 2 == 0 else -1.5)
	var tip := hand + f * 15.0
	_blade(n, hand, tip)
	var ms := Time.get_ticks_msec()
	for i in range(4):
		var along := hand.lerp(tip, 0.3 + 0.2 * i)
		var lick := f.orthogonal() * (2.0 if (ms / 60 + i) % 2 == 0 else -2.0) + Vector2(0, -2.0 - i)
		n.draw_line(along, along + lick, Color(1.0, 0.45 + 0.12 * i, 0.1, 0.85), 2.0)
	if ext > 0.5:
		n.draw_line(tip + f * 2.0, tip + f * 9.0, Color(1.0, 0.7, 0.25, 0.8), 2.0)

# the spear's whirlwind: the shaft swung once right round him, a full white ring trailing it
func _draw_spear_whirl(n) -> void:
	var f := facing_vec()
	var p := clampf(swing_p, 0.0, 1.0)
	var base := Vector2(0, -11)
	var a := f.angle() + TAU * (p * p * (3.0 - 2.0 * p))
	var d := Vector2.from_angle(a)
	_spear(n, base - d * 10.0, base + d * 24.0)
	var span := minf(TAU * p, TAU - 0.3)
	if span > 0.2:
		n.draw_arc(base, 22.0, a - span, a, 24, Color(1, 1, 1, 0.65 * sin(p * PI)), 2.0)

# ---- the spear: a long wooden shaft with a metal head, outlined like the sword
func _spear(n, butt: Vector2, tip: Vector2) -> void:
	var d := (tip - butt).normalized()
	n.draw_line(butt, tip, BLADE_DARK, 3.0)
	n.draw_line(butt, tip - d * 4.0, SHAFT, 1.5)
	n.draw_line(tip - d * 5.0, tip, BLADE, 2.0)
	n.draw_line(tip - d * 5.0, tip - d * 2.0, BLADE_LIT, 1.0)

# at rest: upright at his side, the head above his shoulder
func _draw_spear_held(n) -> void:
	var s := _hand_side()
	var hand := Vector2(5.0 * s, -11.0)
	_spear(n, hand + Vector2(1.0 * s, 9.0), hand + Vector2(-1.0 * s, -19.0))

# jab, long thrust, drive, lunge: the spear driven straight out along the aim, further for the longer moves, with a line past the head
func _draw_spear_thrust(n) -> void:
	var f := facing_vec()
	var ext := _ext()
	var out: float = {"jab": 10.0, "long_thrust": 16.0, "drive": 13.0, "lunge": 18.0}.get(pose, 10.0)
	var hand := Vector2(0, -11) + f * (2.0 + out * ext)
	_spear(n, hand - f * 12.0, hand + f * 18.0)
	if ext > 0.5:
		n.draw_line(hand + f * 20.0, hand + f * 27.0, Color(1, 1, 1, 0.7), 1.0)

# sweep: the shaft swung flat across his front from either side in turn, with a wide trail
func _draw_spear_sweep(n) -> void:
	var f := facing_vec()
	var p := clampf(swing_p, 0.0, 1.0)
	var base := Vector2(0, -11)
	var side := 1.0 if swing_n % 2 == 0 else -1.0
	var a0 := f.angle() - 1.4 * side
	var a := a0 + 2.8 * side * p
	var d := Vector2.from_angle(a)
	_spear(n, base - d * 8.0, base + d * 24.0)
	if absf(a - a0) > 0.2:
		n.draw_arc(base, 22.0, minf(a0, a), maxf(a0, a), 16, Color(1, 1, 1, 0.7 * sin(p * PI)), 2.0)

# ---- the bow: a recurved stave held out along the aim, its string pulled back by k (0..1), an arrow on it when nocked
func _bow(n, c: Vector2, f: Vector2, k: float, nocked: bool) -> void:
	var across := f.orthogonal()
	var a := c + across * 8.0 - f * 2.0
	var b := c - across * 8.0 - f * 2.0
	var limbs := PackedVector2Array([a, c + across * 5.0 + f * 2.0, c + f * 3.0, c - across * 5.0 + f * 2.0, b])
	n.draw_polyline(limbs, BLADE_DARK, 3.0)
	n.draw_polyline(limbs, BOW_WOOD, 1.5)
	var nock := c - f * (2.0 + 7.0 * k)
	n.draw_line(a, nock, BOW_STRING, 1.0)
	n.draw_line(nock, b, BOW_STRING, 1.0)
	if nocked:
		var head := nock + f * 15.0
		n.draw_line(nock, head, Color("#e0d4b0"), 1.0)
		n.draw_rect(Rect2(roundf(head.x) - 1, roundf(head.y) - 1, 2, 2), Color("#c89a48"))

# the bow now: drawn (H held), mid-shot (a quick arrow pulled a little and loosed; the aimed one's string snapping back), or at his side
func _draw_bow_now(n) -> void:
	var f := facing_vec()
	var c := Vector2(0, -11) + f * 7.0
	if bow_draw >= 0.0:
		_bow(n, c, f, bow_draw, true)
	elif swing_n >= 0:
		var p := clampf(swing_p, 0.0, 1.0)
		if pose == "quick" and p < 0.45:
			_bow(n, c, f, 0.5 * p / 0.45, true)
		elif pose == "piercer" and p < 0.6:      # the special: a full, quick draw before the heavy arrow goes
			_bow(n, c, f, p / 0.6, true)
		else:
			_bow(n, c, f, 0.0, false)
	else:
		var s := _hand_side()
		_bow(n, Vector2(6.0 * s, -12.0), Vector2(s, 0.0), 0.0, false)
