extends "res://scripts/npc.gd"
# rider.gd - Farnaka, the king's rider held in the cave's cage (Stage 6b), and since Stage 7c the first member of the hero's squad
# (squad.gd). One node for his whole story; main.gd moves it from map to map with the hero:
#   "caged"   sits in the cage and mutters (an ambient NPC, chatter from dialogue.gd)
#   "out"     the cage door is open: he steps out in front of it and waits to be spoken to (talkable, "?" mark)
#   "follow"  after the talk (dialogue.gd TALK "rider", then "rider_join") he has his bow back, joins the squad and follows the hero
#             through every door. Out of a fight he walks the hero's own trail, so he never needs pathfinding; in a fight (combat.gd
#             fighting(), Stage 7i) he moves on his own (_skirmish): he keeps his distance from the enemies, comes back toward the hero
#             when he has no shot, and never strays far from him; when it is over he walks back to the hero and takes up the trail.
#             Every RIDER.shot_every s, if an enemy in the fight is in range and in sight, he steps out to the side, draws and shoots it,
#             then steps back in. If the hero is suddenly far away (moved by a scene) he joins him at once.
#   "wait"    the squad order Wait: he holds his spot (and still shoots), even while he is being hurt; talk to him to have him follow,
#             or send him home
#   "leaving" "Disband": he stops while main.gd fades him out, then he is "home"
#   "home"    standing at his home spot (by the throne in the hall), talkable: "Come with me." makes him follow again
#   "walk"    walked by a scene to a spot (the hall's return: up the steps beside the hero)
#   "behind"  the chief fell before he was freed (the lesser return): he stays where he is, muttering, and cannot be spoken to
# Since 7i he can be hurt: enemies in the fight go after him when he is nearer than the hero (rat.gd foe). At 0 HP he falls (`down`, a
# flag on top of the state, so an order given meanwhile keeps him down) and lies there, through doors too, until the hero uses a Reviving
# Potion on him (E beside him, or the menu: main.gd revive_mate) or rests. His arrows that land fill his focus; a full bar makes his next
# shot a volley. Bread and potions can be given to him (main.gd use_item). Numbers: combat.gd RIDER.
# Since 7j a scorpion's sting can poison him like the hero (`poison`, ticked by combat.gd); falling or a rest cures it.

const Combat = preload("res://scripts/combat.gd")
const Menu = preload("res://scripts/menu.gd")     # the bar colours his bars share with the HUD

var state := "caged"
var armed := false            # has his bow (from the jail table) and shoots
var hp: int = Combat.RIDER["hp"]
var max_hp: int = Combat.RIDER["hp"]
var focus := 0
var max_focus: int = Combat.RIDER["focus"]
var down := false             # fallen: lies where he fell until revived or rested (whatever his squad order)
var poison := 0               # poison ticks left (Stage 7j; combat.gd POISON ticks them), 0 = not poisoned
var poison_t := 0.0           # seconds to the next tick
var _out_to := Vector2.ZERO
var _base := Vector2.ZERO     # where he walks; the drawn position adds the step-out offset
var _off := Vector2.ZERO
var _trail: Array = []        # the hero's recent positions (oldest first): the path he walks
var _shot_t := 0.0            # time until he may shoot again
var _aim_t := 0.0             # > 0 while stepping out and drawing the bow
var _aim_target               # the enemy he is drawing on
var _aim_dir := Vector2.DOWN
var _side := Vector2.ZERO     # which way he steps out for this shot
var _rejoin := false          # a fight has ended (or he got up): walk back to the hero before taking up the trail again
var _stuck_t := 0.0           # moving on his own and getting nowhere (a wall): after RIDER.stuck_snap s he joins the hero at once
var _inv_t := 0.0             # just hurt: a moment before the next hit can land
var _hurt_t := 0.0            # red blink after a hit

# the cage door is open: walk out to `to` (in front of the cage) and wait to be spoken to
func free_from_cage(to: Vector2) -> void:
	state = "out"
	_out_to = to
	lines = []               # no more muttering from the cage
	idle = "none"

# after the talk: take the bow and follow the hero
func join() -> void:
	armed = true
	follow_again()
	_shot_t = 0.4

# (the squad order Follow, or the first join) walk the hero's trail from where he stands
func follow_again() -> void:
	state = "follow"
	talk = false             # E never lands on him while he follows (he walks right behind you)
	talk_id = ""
	lines = []
	idle = "none"
	modulate.a = 1.0
	_base = position
	_off = Vector2.ZERO
	_trail = [world.player.position]

# carried through a door by main.gd: follow, starting just behind the hero at the spawn (a fallen one is carried along, still down)
func arrive(pl) -> void:
	follow_again()
	_aim_t = 0.0
	_aim_target = null
	_rejoin = false
	_snap_to(pl)

# the squad order Wait: hold this spot, still shooting; talkable (dialogue.gd TALK "rider_wait"), unless he is down
func hold() -> void:
	state = "wait"
	talk = not down
	talk_id = "rider_wait"

# the squad order Disband: stand still while main.gd fades him out and sends him home
func leave() -> void:
	state = "leaving"
	talk = false
	_aim_t = 0.0
	_off = Vector2.ZERO

# standing at his home spot (squad.gd MATES), talkable (dialogue.gd TALK "rider_home")
func at_home(pos: Vector2) -> void:
	state = "home"
	position = pos
	_base = pos
	_off = Vector2.ZERO
	dir = "down"
	idle = "none"
	talk = true
	talk_id = "rider_home"

# a scene walks him from `from` to `to` (hall.gd, the return to the king). A story scene never has him lying on the floor: if he is down,
# he gets up first (as a Reviving Potion would leave him).
func walk_to(from: Vector2, to: Vector2) -> void:
	if down:
		revive(Combat.RIDER["revive"])
	state = "walk"
	position = from
	_base = from
	_off = Vector2.ZERO
	_out_to = to
	talk = false

# the chief fell before anyone talked to him: no rescue in this build, he just mutters where he is
func stay_behind() -> void:
	state = "behind"
	talk = false
	lines = world.chatter_for("rider")
	idle = "bob"

# a fallen man says nothing (cave.gd's shouts ask any squad mate who is with the hero)
func shout(text: String, secs: float) -> void:
	if not down:
		super.shout(text, secs)

# ---------------------------------------------------------------- hurt, fallen, revived (Stage 7i)
# can an enemy go after him? (only while he fights beside the hero, standing)
func can_be_hurt() -> bool:
	return armed and not down and (state == "follow" or state == "wait")

# a hit from an enemy: true if it landed. No knock-back: on Wait he never moves, whatever hits him.
func hurt(dmg: int, from_pos: Vector2) -> bool:
	if not can_be_hurt() or _inv_t > 0.0:
		return false
	hp = maxi(0, hp - dmg)
	_inv_t = Combat.RIDER["invuln"]
	_hurt_t = 0.35
	var c = world.combat
	if c != null:
		c.spark(position + Vector2(0, -12), (position - from_pos).normalized(), 6, Color("#e03a3a"))
	if hp <= 0:
		fall()
	return true

# 0 HP: he drops where he stands and stays down (quiet = putting a save back, no words)
func fall(quiet := false) -> void:
	down = true
	hp = 0
	poison = 0
	talk = false
	_aim_t = 0.0
	_aim_target = null
	_off = Vector2.ZERO
	_rejoin = false
	position = _base
	moving = false
	if not quiet and world.combat != null:
		world.combat.text(position + Vector2(0, -30), "Farnaka is down!", Color("#ff8a6a"), 1.6)

# back on his feet with pct % of his HP (a Reviving Potion: combat.gd RIDER.revive), and a moment before he can be hurt again
func revive(pct: int) -> void:
	if not down:
		return
	down = false
	hp = clampi(ceili(max_hp * pct / 100.0), 1, max_hp)
	_inv_t = 1.5
	_shot_t = 0.6
	talk = state == "wait"
	_rejoin = state == "follow"     # he walks back to the hero, then takes up the trail
	if world.combat != null:
		world.combat.spark(position + Vector2(0, -12), Vector2.UP, 8, Color("#9ae07a"))

# a rest: up, if he was down, HP full and no poison. His focus stays as it is.
func rest() -> void:
	if down:
		revive(100)
	hp = max_hp
	poison = 0

# what he is given (main.gd use_item): returns how much was added (0: he needs none, or he is down)
func heal(n: int) -> int:
	if down:
		return 0
	var add := mini(n, max_hp - hp)
	hp += add
	return add

func add_focus(n: int) -> int:
	if down:
		return 0
	var add := mini(n, max_focus - focus)
	focus += add
	return add

# one of his arrows hit an enemy (combat.gd _update_shots): it feeds his focus
func arrow_landed() -> void:
	focus = mini(max_focus, focus + Combat.RIDER["focus_per_hit"])

func _process(delta: float) -> void:
	super._process(delta)    # chatter, shout timer, redraw
	_inv_t = maxf(0.0, _inv_t - delta)
	_hurt_t = maxf(0.0, _hurt_t - delta)
	# grey while fallen (like the fallen hero), a red blink when hurt, a slow purple pulse while poisoned; self_modulate leaves the
	# bubble layer (a child) alone
	if down:
		self_modulate = Color(0.55, 0.55, 0.6)
	elif _hurt_t > 0.0 and int(_hurt_t * 25.0) % 2 == 0:
		self_modulate = Color(1.8, 0.5, 0.5)
	elif poison > 0 and int(Time.get_ticks_msec() / 300.0) % 2 == 0:
		self_modulate = Color(1.15, 0.8, 1.3)
	else:
		self_modulate = Color.WHITE
	if down:
		moving = false
		return
	match state:
		"out":
			var to := _out_to - position
			if to.length() > 1.0:
				position += to.normalized() * minf(to.length(), 30.0 * delta)
				moving = true
				anim += delta * 6.0
				dir = "down"
			else:
				talk = true
		"walk":
			var to := _out_to - position
			if to.length() > 1.0:
				position += to.normalized() * minf(to.length(), 40.0 * delta)
				_base = position
				moving = true
				anim += delta * 9.0
				dir = _dir_of(to)
			else:
				dir = "up"
		"follow":
			_follow(delta)
		"wait":
			_hold(delta)

# ---------------------------------------------------------------- following, moving in a fight, and shooting
func _follow(delta: float) -> void:
	var pl = world.player
	var c = world.combat
	if pl == null or c == null:
		return
	var R: Dictionary = c.RIDER
	if _base.distance_to(pl.position) > R["snap_dist"]:
		_snap_to(pl)
		_rejoin = false
	if c.fighting():
		_skirmish(delta, pl, c, R)
	elif _rejoin:
		_walk_back(delta, pl, R)
	else:
		_walk_trail(delta, pl, R)
	_shoot(delta, pl, c, R)

# out of a fight: walk along the hero's trail while more than follow_gap of it lies between him and the hero
func _walk_trail(delta: float, pl, R: Dictionary) -> void:
	if _trail.is_empty() or _trail[-1].distance_to(pl.position) >= 4.0:
		_trail.append(pl.position)
	var left := _path_left(pl.position)
	if left > R["follow_gap"] and not _trail.is_empty() and _aim_t <= 0.0:
		var spd: float = R["speed"] if left < R["follow_gap"] + 30.0 else R["catch_speed"]
		var budget := minf(spd * delta, left - R["follow_gap"])
		var moved := Vector2.ZERO
		while budget > 0.01 and not _trail.is_empty():
			var to: Vector2 = _trail[0] - _base
			if to.length() <= budget:
				_base = _trail[0]
				budget -= to.length()
				moved += to
				_trail.pop_front()
			else:
				_base += to.normalized() * budget
				moved += to.normalized() * budget
				budget = 0.0
		if moved.length() > 0.05:
			moving = true
			anim += delta * 9.0
			dir = _dir_of(moved)

# In a fight he is free (the user's rule, 2026-10-28): back away from an enemy closer than keep_min, come back toward the hero when he
# is more than `leash` away or has no shot from here, otherwise stand and shoot. He stands still while drawing his bow.
func _skirmish(delta: float, pl, c, R: Dictionary) -> void:
	_rejoin = true
	if _aim_t > 0.0:
		return
	var hero: Vector2 = pl.position - _base
	var want := Vector2.ZERO
	var near = _nearest_in_fight(c)
	if near != null and _base.distance_to(near.position) < R["keep_min"]:
		want = (_base - near.position).normalized()
		if hero.length() > R["leash"] * 0.75:          # backing off, but not away from the hero
			want = (want + hero.normalized()).normalized()
	elif hero.length() > R["leash"]:
		want = hero.normalized()
	elif hero.length() > R["follow_gap"] * 2.0 and _pick_target(R["range"]) == null:
		want = hero.normalized()                         # no shot from here: closer to the hero
	if want == Vector2.ZERO:
		_stuck_t = 0.0
		return
	_go(want, R["speed"], delta, pl, R)

# the fight is over (or he has just got up): walk straight back to the hero, round what is in the way, then take up the trail
func _walk_back(delta: float, pl, R: Dictionary) -> void:
	var to: Vector2 = pl.position - _base
	if to.length() <= R["follow_gap"] + 6.0:
		_rejoin = false
		_stuck_t = 0.0
		_trail = [pl.position]
		return
	if _aim_t <= 0.0:
		_go(to.normalized(), R["speed"] if to.length() < R["follow_gap"] + 30.0 else R["catch_speed"], delta, pl, R)

# one step of his own (not along the trail): straight on, or turned a little either way round a prop; stuck for stuck_snap s, he joins
# the hero at once (there is no pathfinding)
func _go(v: Vector2, spd: float, delta: float, pl, R: Dictionary) -> void:
	for a in [0.0, 0.7, -0.7, 1.4, -1.4]:
		var np: Vector2 = _base + v.rotated(a) * spd * delta
		if not world.feet_blocked(np):
			_base = np
			moving = true
			anim += delta * 9.0
			dir = _dir_of(v.rotated(a))
			_stuck_t = 0.0
			return
	_stuck_t += delta
	if _stuck_t > R["stuck_snap"]:
		_stuck_t = 0.0
		_snap_to(pl)

# the order Wait: stand on his spot, but keep shooting
func _hold(delta: float) -> void:
	var pl = world.player
	var c = world.combat
	if pl == null or c == null:
		return
	_shoot(delta, pl, c, c.RIDER)

# shooting: step out, draw, release, step back
func _shoot(delta: float, pl, c, R: Dictionary) -> void:
	_shot_t = maxf(0.0, _shot_t - delta)
	if _aim_t > 0.0:
		if _aim_target != null and is_instance_valid(_aim_target) and _aim_target.alive:
			_aim_dir = (c.body_point(_aim_target) - (position + Vector2(0, -12))).normalized()
			dir = _dir_of(_aim_dir)
		_aim_t -= delta
		if _aim_t <= 0.0:
			_release(c, R)
	elif _shot_t <= 0.0 and not pl.dead and not world.talking:
		var e = _pick_target(R["range"])
		if e != null:
			_aim_target = e
			_aim_t = R["draw_time"]
			_shot_t = R["shot_every"]
			_side = _step_side(e, pl, R["step_out"])
	var want: Vector2 = _side * R["step_out"] if _aim_t > 0.0 else Vector2.ZERO
	_off = _off.move_toward(want, 90.0 * delta)
	position = _base + _off

# how much trail is left between him and the hero (px)
func _path_left(hero: Vector2) -> float:
	var total := 0.0
	var prev := _base
	for p in _trail:
		total += prev.distance_to(p)
		prev = p
	return total + prev.distance_to(hero)

func _snap_to(pl) -> void:
	var back: Vector2 = -pl.facing_vec() * 16.0
	var spot: Vector2 = pl.position
	for cand in [pl.position + back, pl.position + back.orthogonal(), pl.position - back.orthogonal(), pl.position]:
		if not world.feet_blocked(cand):
			spot = cand
			break
	_base = spot
	_off = Vector2.ZERO
	_trail = [pl.position]
	position = _base

# the nearest enemy he can see within range that is in the fight (rat.gd in_fight): never a sleeping one, a patrol that hasn't noticed
# you or one whose "?" is still rising, so he never wakes the chief or starts a fight you didn't choose
func _pick_target(rng: float):
	var best = null
	var bd := rng
	var eye := _base + Vector2(0, -6)
	for r in world.rats:
		if not r.in_fight():
			continue
		var d := _base.distance_to(r.position)
		if d < bd and world.los(eye, r.position):
			bd = d
			best = r
	return best

# the nearest enemy in the fight, seen or not (the one he keeps his distance from)
func _nearest_in_fight(c):
	var best = null
	var bd := INF
	for r in c.rats:
		if r.in_fight() and _base.distance_to(r.position) < bd:
			bd = _base.distance_to(r.position)
			best = r
	return best

# step out to the side away from the hero, so he shoots past him rather than through him (unless that side is blocked)
func _step_side(e, pl, dist: float) -> Vector2:
	var d: Vector2 = (e.position - _base).normalized()
	var perp := d.orthogonal()
	if perp.dot(pl.position - _base) > 0.0:
		perp = -perp
	for s in [perp, -perp]:
		if not world.feet_blocked(_base + s * dist):
			return s
	return Vector2.ZERO

# one arrow, or with a full focus bar a volley (RIDER.volley arrows fanned out), which empties it
func _release(c, R: Dictionary) -> void:
	if _aim_target == null or not is_instance_valid(_aim_target) or not _aim_target.alive:
		return
	var from := position + Vector2(0, -12) + _aim_dir * 6.0
	var at: Vector2 = c.body_point(_aim_target)
	if focus >= max_focus:
		focus = 0
		var n: int = R["volley"]
		for i in range(n):
			c.shoot(from, at, "ally", "arrow", c.arrow_dmg(), R["arrow_speed"], self, (i - (n - 1) / 2.0) * R["volley_spread"])
		c.text(position + Vector2(0, -34), "Volley!", Color("#8cc8ff"), 1.0)
	else:
		c.shoot(from, at, "ally", "arrow", c.arrow_dmg(), R["arrow_speed"], self)
	_aim_target = null

func _dir_of(v: Vector2) -> String:
	if absf(v.x) > absf(v.y):
		return "right" if v.x > 0.0 else "left"
	return "down" if v.y > 0.0 else "up"

# ---------------------------------------------------------------- drawing: the person (npc.gd), plus his bow and bow case
func _draw() -> void:
	if down:
		# fallen: on his side (greyed in _process), like the hero when he falls
		draw_set_transform(Vector2(-14, -3), PI / 2.0, Vector2.ONE)
		super._draw()
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	super._draw()
	if not armed:
		return
	var flip := -1.0 if dir == "left" else 1.0
	# the gorytos (bow case) on his hip, behind him unless he faces away
	var cx := -8.0 * flip if dir != "up" else -3.0
	Sprites.R(self, cx - 1, -15, 5, 10, Color("#3a2517"))
	Sprites.R(self, cx, -14, 3, 8, Color("#8a3a2a")); Sprites.R(self, cx, -14, 1, 8, Color("#b05a40"))
	Sprites.R(self, cx, -17, 1, 3, Color("#e8dcc0")); Sprites.R(self, cx + 2, -16, 1, 2, Color("#e8dcc0"))
	if _aim_t > 0.0:
		# the bow held out toward the target, its string drawn back with an arrow on it
		var hand := Vector2(0, -12) + _aim_dir * 7.0
		var a := _aim_dir.angle()
		draw_arc(hand - _aim_dir * 3.0, 7.0, a - 1.2, a + 1.2, 8, Color("#3a2517"), 3.0)
		draw_arc(hand - _aim_dir * 3.0, 7.0, a - 1.2, a + 1.2, 8, Color("#8a5a32"), 1.0)
		var tip1 := hand - _aim_dir * 3.0 + Vector2.from_angle(a - 1.2) * 7.0
		var tip2 := hand - _aim_dir * 3.0 + Vector2.from_angle(a + 1.2) * 7.0
		var nock := hand - _aim_dir * 7.0
		draw_line(tip1, nock, Color("#e0d4b0"), 1.0)
		draw_line(nock, tip2, Color("#e0d4b0"), 1.0)
		draw_line(nock, hand + _aim_dir * 4.0, Color("#e0d4b0"), 1.0)
		draw_rect(Rect2((hand + _aim_dir * 4.0).round() - Vector2(1, 1), Vector2(2, 2)), Color("#c89a48"))
	else:
		# the bow slung across his back: a short dark curve over the shoulder
		var bx := 3.0 * flip if dir != "up" else 0.0
		draw_arc(Vector2(bx, -16), 6.0, -2.4, 0.4, 7, Color("#3a2517"), 2.0)
		draw_arc(Vector2(bx, -16), 6.0, -2.4, 0.4, 7, Color("#8a5a32"), 1.0)
	# his HP and focus over his head while a fight is on, and his HP whenever he is hurt (green and blue, apart from the enemies' red)
	var c = world.combat
	var in_fight: bool = c != null and c.fighting() and (state == "follow" or state == "wait")
	if in_fight or hp < max_hp:
		_head_bar(-37.0, float(hp) / max_hp, Menu.MATE_HP_COL)
		if in_fight:
			_head_bar(-34.0, float(focus) / max_focus, Menu.FOCUS_COL)

func _head_bar(y: float, frac: float, col: Color) -> void:
	draw_rect(Rect2(-9, y - 1, 18, 4), Color(0, 0, 0, 0.85))
	draw_rect(Rect2(-8, y, 16.0 * clampf(frac, 0.0, 1.0), 2), col)
	draw_rect(Rect2(-8, y, 16.0 * clampf(frac, 0.0, 1.0), 1), col.lightened(0.35))

# the bubble layer: while he is down and the hero stands beside him, "E Revive" (dimmed without a Reviving Potion)
func _draw_bubble(n) -> void:
	if not down:
		super._draw_bubble(n)
		return
	if world.talking or not near_hero() or world.dialogue == null:
		return
	world._draw_e_box(n, Vector2(0, 14), "Revive", not world.dialogue.inv.has("revive_potion"))
