extends Node2D
# rat.gd - small wildlife rat (Type A). One instance per rat; all numbers live in Combat.RAT (combat.gd).
# Also plays the BANDIT (kind == "bandit"): same states, own numbers (Combat.BANDIT), paces on a short back-and-forth beat.
# Also plays the GIANT RAT boss (kind == "giant", numbers in Combat.GIANT): a big rat with armour during its attacks, a one-time summon
# at half health ("summon" state) and a jump + ground slam ("jump_wind", "jump", "slam" states).
# Also plays the SCORPION (kind == "scorpion", Combat.SCORPION, Stage 7j): a rat's brain with a sting for a lunge. Its wind-up arches
# the tail over its back (_tail(), sprites.gd scorpion), and a sting that lands poisons (its table's "poison": combat.gd POISON).
# States: patrol, alert, chase, wind (lunge telegraph), lunge, recover, stagger, flee, cower, return, pulled (lasso), stun,
# bound (the strong lasso on a heavy foe: held where he stands), dead.
# Lives near a nest (home), roams a little, spots the hero with a vision cone + a small proximity bubble (alert meter rises),
# chases within a leash, gives up and walks home if the hero escapes or if it is stuck behind a wall or rock (no headway toward the hero
# for a while). Once in the fight (in_fight) it goes after the nearest of the hero and his standing companions (`foe`, combat.gd FOE),
# and its slam hurts everyone inside the circle; it still only ever notices the hero. When it joins the fight it raises the alarm
# (Stage 7k, combat.gd ALARM): its side nearby stops patrolling and joins too (join_fight). Flees at low health. One from the map's enemy_plan() comes back after it dies, when the hero walks into its map again or
# rests there (combat.gd respawn); bosses and enemies added during play never do. Its `level` cuts the XP it gives a stronger hero.
# The cave's chief (chief.gd) and slingers (slinger.gd) extend this script: they add their own states through _state_more() and
# override _chase / hit / drawing; `person` (drawn as a person: bandits, the chief, slingers) is the switch they share.
# Every enemy, bosses included, heals back to full once it walks home (it gave up the chase): a design-doc rule. When the hero falls
# they head home too, but the death screen (death.gd) loads a save, so nothing on the map carries on from there.

const Sprites = preload("res://scripts/sprites.gd")
const Drawn = preload("res://scripts/drawn.gd")

var combat
var world
var player
var foe                   # who it goes after: the hero, or (in a fight) the nearer of the companions (combat.gd FOE). Only the hero is noticed.
var foe_t := 0.0          # time until it looks again for the nearest one
var R: Dictionary
var home := Vector2.ZERO
var state := "patrol"
var hp := 3
var max_hp := 3
var heavy := false        # the big rat (Stage 4) and bandits are too heavy to lasso
var kind := "rat"         # "rat", "bandit", "giant", "scorpion" (and "chief" / "slinger" in their own scripts)
var person := false       # drawn as a person (faces all four ways, topples when it dies): bandits, the chief, slingers
var axis := Vector2.RIGHT # bandit: direction of the back-and-forth beat
var span := 30.0          # bandit: how far each way from home
var beat := 1.0
var look := "bandit"
var base_tint := Color.WHITE
var summoned := false     # giant: the half-health summon has happened (it only ever happens once)
var slam_cool := 0.0      # giant: time until it may jump again
var slam_target := Vector2.ZERO
var jump_from := Vector2.ZERO
var jump_to := Vector2.ZERO
var slam_hit := false     # giant: the last slam hurt the hero (for tests / feedback)
var slams := 0            # giant: how many slams have landed
var summon_split := [0, 0] # giant: how many rats came from [left, right] in the summon
var helped := false       # giant: the summoned rats have been spawned in the current summon
var stun_extra := 0.0     # the strong lasso: this many more seconds of stun after the pull
var bind_t := 0.0         # the strong lasso on a heavy foe: how long he stays bound
var top := -17.0          # height of the overhead markers
var alive := true
var group := ""           # enemy group name (storeroom): the group sleeps until the hero comes near
var plan_i := -1          # its index in the map's enemy_plan() (-1: added during play); a save notes the dead ones (level.dead_plan)
var level := 1            # combat.gd FOE_LEVEL (or the plan row's "level"): a foe below the hero's level gives less XP
var dormant := false      # asleep: patrols its spot but never notices the hero
var munching := false     # asleep AND eating at a sack: stands still, head bobbing, facing munch_at
var munch_at := Vector2.ZERO
var leash := 0.0          # how far from home it will chase (per rat, so summoned rats can be given more)
var lose := 0.0           # how far from the hero before it gives up
var face := Vector2.RIGHT
var flip := 1
var alert := 0.0
var t := 0.0
var cool := 0.0
var anim := 0.0
var flash := 0.0
var kb := Vector2.ZERO
var goal := Vector2.ZERO
var wait := 1.0
var lunge_dir := Vector2.RIGHT
var lunge_hit := false
var stuck_t := 0.0
var gain := 0.0           # chase: how far it moved toward the hero in the current progress window
var prog_t := 0.0         # chase: time into the current progress window
var lost_t := 0.0         # gave up a chase it could not win: ignores the hero until this runs out
var side := 1.0           # which way it goes round an obstacle (+1 / -1), kept while blocked and for side_t seconds after
var side_t := 0.0
var walk_t := 0.0         # patrol: time spent walking to the current goal, and the most it may take before turning back
var walk_max := 99.0
var sense_t := 0.0
var los_ok := false
var hit_t := 0.0          # seconds left in which a recent hit keeps it "engaged" (combat.gd ENGAGE): it won't walk off mid-fight
var calm_t := 0.0         # cower: how long the hero has stayed away; after the table's calm_time it walks home to heal
var _flipped_at := 0.0    # chase: stuck_t when it last tried the other way round (_give_up)
var _called := false    # it is joining the fight because another raised the alarm (combat.alarm): it doesn't call others in turn
var body

func setup(c, w, p, h: Vector2, k := "rat", ax := Vector2.RIGHT, sp := 30.0) -> void:
	combat = c
	world = w
	player = p
	foe = p
	kind = k
	axis = ax
	span = sp
	R = c.RAT
	if kind == "bandit":
		R = c.BANDIT
	elif kind == "giant":
		R = c.GIANT
	elif kind == "scorpion":
		R = c.SCORPION
	if kind == "bandit":
		heavy = true
		person = true
		top = -37.0
		look = ["bandit", "bandit2", "bandit3"][int(h.x + h.y) % 3]
	elif kind == "giant":
		heavy = true
		top = -46.0
		base_tint = Color(0.9, 0.82, 0.78)
		slam_cool = R["slam_start_cd"]
	elif kind == "scorpion":
		top = -22.0               # over its curled tail
	home = h
	position = h
	leash = R["leash"]
	lose = R["lose"]
	goal = h
	max_hp = c.enemy_hp(kind)     # R["hp"], unless the tuning panel has changed it
	hp = max_hp
	face = Vector2.RIGHT.rotated(randf() * TAU) if kind in ["rat", "scorpion"] else (Vector2.DOWN if kind == "giant" else axis)
	flip = 1 if face.x >= 0.0 else -1
	wait = randf_range(0.2, 2.0) if kind != "bandit" else randf_range(0.2, 0.8)
	body = Drawn.new()
	body.animated = true
	body.draw_fn = _draw_body
	add_child(body)

# ---------------------------------------------------------------- movement helpers
func _clamp_world(p: Vector2) -> Vector2:
	return Vector2(clampf(p.x, 8.0, world.W - 8.0), clampf(p.y, 22.0, world.H - 6.0))

# move by `step`; if a prop is in the way slide along it (unless slide is false). Returns true if it really got somewhere.
func _try_step(step: Vector2, slide := true) -> bool:
	var want := step.length()
	if want < 0.001:
		return true
	var tries := [step, Vector2(step.x, 0.0), Vector2(0.0, step.y)] if slide else [step]
	for s in tries:
		var np := _clamp_world(position + s)
		if not world.feet_blocked(np) and (np - position).length() > want * 0.25:
			position = np
			return true
	return false

# Straight ahead if it can. When something is in the way it steers round it on one side and keeps to that side for as long as it is
# blocked, plus side_time s after, so it never turns back halfway along a wall (which leaves it sliding back and forth forever).
# If that side is blocked too it reports "stuck" (patrol then turns back, chase counts it as stuck) instead of jittering in place.
# The old turn-and-slide is all the giant does.
func _move(dir: Vector2, spd: float, dt: float) -> bool:
	var step := dir * spd * dt
	var moved := _try_step(step, false)
	var keep: float = R.get("side_time", 0.0)
	if not moved and keep > 0.0:
		if side_t <= 0.0:
			side = _pick_side(step)
		side_t = keep
		for a in [0.7, 1.4, PI / 2.0]:
			if _try_step(step.rotated(a * side)):     # (sliding allowed: flush against a face, that slide is what gets it round)
				moved = true
				break
		if not moved:
			return false
	if not moved:
		for a in [0.0, 0.7, -0.7, 1.4, -1.4]:
			if _try_step(step.rotated(a)):
				moved = true
				break
	if moved and absf(dir.x) > 0.2:
		flip = 1 if dir.x > 0.0 else -1
	return moved

# which way round an obstacle: the side that needs the smaller turn; if both need the same, the side it took last time
func _pick_side(step: Vector2) -> float:
	for a in [0.7, 1.4, PI / 2.0]:
		var l: bool = not world.feet_blocked(_clamp_world(position + step.rotated(a)))
		var r: bool = not world.feet_blocked(_clamp_world(position + step.rotated(-a)))
		if l != r:
			return 1.0 if l else -1.0
		if l:
			return side
	return side

func _slide(v: Vector2) -> bool:
	return _try_step(v)

# can it walk from a to b in a straight line? (feet clear every 3 px)
func _walkable(a: Vector2, b: Vector2) -> bool:
	var n := int(a.distance_to(b) / 3.0) + 1
	for i in range(1, n + 1):
		if world.feet_blocked(_clamp_world(a.lerp(b, float(i) / n))):
			return false
	return true

# ---------------------------------------------------------------- the brain
func _enter(s: String) -> void:
	var was_out := not in_fight()
	state = s
	if was_out and in_fight() and not _called:
		combat.alarm(self)          # it just joined the fight: its side nearby joins too (combat.gd ALARM)
	t = 0.0
	stuck_t = 0.0
	_flipped_at = 0.0
	calm_t = 0.0
	gain = 0.0
	prog_t = 0.0
	if s in ["patrol", "return", "flee", "cower"]:
		foe = player             # out of the fight (or running from it): back to minding the hero alone
	if s == "chase":
		alert = 1.0
	elif s == "wind":
		lunge_dir = (foe.position - position).normalized()
	elif s == "lunge":
		lunge_hit = false
	elif s == "jump_wind":
		slam_target = foe.position

# below this many HP it runs away (0 = never): rats of a map with rats_flee == false (the storeroom) fight to the death
func _flee_hp() -> int:
	return R["flee_hp"] if world.rats_flee else 0

func _sense(dt: float, pd: float, pdir: Vector2) -> bool:
	if dormant or lost_t > 0.0:      # asleep, or just gave up a chase it could not win (so the proximity bubble can't pull it straight back)
		alert = 0.0
		return false
	if player.dead:
		alert = maxf(0.0, alert - dt)
		return false
	var seen := false
	var rate := 0.0
	if pd < R["prox"]:
		seen = true
		rate = 2.5
	elif pd < R["vision"] and (face.dot(pdir) > cos(R["cone"]) or _drawn_looking_at(pdir)):
		sense_t -= dt
		if sense_t <= 0.0:
			sense_t = 0.1
			los_ok = world.los(position, player.position)
		if los_ok:
			seen = true
			rate = 1.4 + (1.0 - pd / R["vision"]) * 1.6
	if seen:
		alert = minf(1.0, alert + rate * dt)
	else:
		alert = maxf(0.0, alert - 0.5 * dt)
	return alert >= 1.0

# Rats (and the giant) are drawn side-on, facing only left or right, so they also see what their head is drawn pointing at.
# Otherwise a rat walking up or down would look straight at the hero on screen while its vision cone points away.
# People (bandits) are drawn facing all four ways, so their cone already matches.
func _drawn_looking_at(pdir: Vector2) -> bool:
	return not person and pdir.x * flip > cos(R["cone"])

# has it noticed the hero and come after him? (the rider only shoots these, so he never wakes a sleeping group or starts a fight
# with a patrol that hasn't seen you)
func after_hero() -> bool:
	return alive and not dormant and state != "patrol" and state != "return"

# is it in the fight? The fight starts only once it has spotted the hero (the "?" meter is full) or he struck first (the user's rule,
# 2026-10-28): an enemy still in "alert" is only suspicious, so companions don't shoot it and it doesn't pick a target yet.
func in_fight() -> bool:
	return after_hero() and state != "alert"

# is it still coming for the hero? (after him and not running off or cowering): a hunting enemy blocks resting and saving
# (level.gd rest_open), while a wounded one hiding in a corner doesn't
func hunting() -> bool:
	return after_hero() and state != "flee" and state != "cower"

func _physics_process(dt: float) -> void:
	if not alive:
		_dying(dt)
		return
	t += dt
	cool = maxf(0.0, cool - dt)
	slam_cool = maxf(0.0, slam_cool - dt)
	lost_t = maxf(0.0, lost_t - dt)
	side_t = maxf(0.0, side_t - dt)
	hit_t = maxf(0.0, hit_t - dt)
	flash = maxf(0.0, flash - dt)
	anim += dt * 8.0
	if kb.length() > 2.0:
		_slide(kb * dt)
		kb = kb.move_toward(Vector2.ZERO, 700.0 * dt)
	if state == "chase":
		_pick_foe(dt)
	if foe != player and not combat.targets().has(foe):
		foe = player             # the companion it was after has fallen (or left the map)
	var to_p: Vector2 = foe.position - position
	var pd := to_p.length()
	var pdir := to_p.normalized() if pd > 0.01 else face
	match state:
		"patrol": _patrol(dt, pd, pdir)
		"alert": _alert(dt, pd, pdir)
		"chase": _chase(dt, pd, pdir)
		"wind": _wind(dt, pdir)
		"lunge": _lunge(dt)
		"recover": _recover()
		"stagger": _stagger()
		"flee": _flee(dt, pd, pdir)
		"cower": _cower(dt, pd)
		"return": _return(dt, pd, pdir)
		"pulled": _pulled(dt)
		"stun": _stun(pdir)
		"bound": _bound(pdir)
		"summon": _summon_state(dt, pdir)
		"jump_wind": _jump_wind(pdir)
		"jump": _jump()
		"slam": _slam_state()
		_: _state_more(dt, pd, pdir)
	if kind == "giant" and state != "jump":
		body.position.y = 0.0       # back on the ground
	_tint()

# the states a script built on this one adds (the chief's charge and sweep, a slinger's throw)
func _state_more(_dt: float, _pd: float, _pdir: Vector2) -> void:
	pass

# While it chases (never mid-attack, so a telegraph never swings to someone else): go after the nearest of the hero and the companions
# standing with him (combat.gd FOE: the hero wins a close call). Only in the fight; before that it only knows about the hero.
func _pick_foe(dt: float) -> void:
	foe_t -= dt
	if foe_t > 0.0:
		return
	foe_t = combat.FOE["recheck"]
	foe = player
	if not in_fight() or player.dead:
		return
	var bd: float = position.distance_to(player.position) - combat.FOE["tie"]
	for b in combat.targets():
		if b != player and position.distance_to(b.position) < bd:
			bd = position.distance_to(b.position)
			foe = b

func _patrol(dt: float, pd: float, pdir: Vector2) -> void:
	if munching and dormant:      # busy eating: no roaming
		var to_m := munch_at - position
		if absf(to_m.x) > 1.0:
			flip = 1 if to_m.x > 0.0 else -1
			face = Vector2(flip, 0)
		return
	if wait > 0.0:
		wait -= dt
		if wait <= 0.0:
			goal = _pick_goal()
			walk_t = 0.0
			walk_max = position.distance_to(goal) / R["patrol_speed"] + 2.0    # time to get there, plus room to go round something
	else:
		var to_g := goal - position
		walk_t += dt
		if to_g.length() < 3.0:
			wait = randf_range(1.0, 2.5) if kind in ["rat", "scorpion"] else randf_range(0.5, 1.1)
		else:
			face = to_g.normalized()
			if not _move(face, R["patrol_speed"], dt) or walk_t > walk_max:     # blocked, or taking far too long: turn back
				wait = randf_range(0.8, 1.6)
	if _sense(dt, pd, pdir):
		_enter("chase")
	elif alert > 0.25:
		_enter("alert")

func _pick_goal() -> Vector2:
	if kind == "bandit":    # pace to the other end of the beat
		beat = -beat
		var e: Vector2 = home + axis * span * beat
		return e if not world.feet_blocked(e) else home
	# a random spot near home that it can walk to in a straight line (so it doesn't roam into the far side of its own nest or a tree)
	for i in range(6):
		var g: Vector2 = home + Vector2.RIGHT.rotated(randf() * TAU) * randf_range(10.0, R["roam"])
		if _walkable(position, g):
			return g
	return home if _walkable(position, home) else position

func _alert(dt: float, pd: float, pdir: Vector2) -> void:
	face = pdir
	if absf(pdir.x) > 0.2:
		flip = 1 if pdir.x > 0.0 else -1
	if _sense(dt, pd, pdir):
		_enter("chase")
	elif alert <= 0.0:
		_enter("patrol")
		wait = 0.6

# Is it still trading blows? (its foe within ENGAGE.near, or it was hit in the last ENGAGE.hit_time s)
func engaged(pd: float) -> bool:
	return pd < combat.ENGAGE["near"] or hit_t > 0.0

# Should it give up the chase and walk home? (the chief and the slingers use this too). The leash and getting stuck count only while it
# isn't engaged, so a fight dragged a little past its home, or round a tent in the cave, doesn't end with it walking off as if the hero
# had run (the user's play-test, Stage 7l). Engaged and stuck, it tries the other way round instead, and gives up only after
# ENGAGE.stuck_max s; leash x ENGAGE.hard from home ends any chase.
func _give_up(pd: float) -> bool:
	if player.dead or pd > lose or position.distance_to(home) > leash * combat.ENGAGE["hard"]:
		return true
	if not engaged(pd):
		return position.distance_to(home) > leash or stuck_t > 1.5
	if stuck_t - _flipped_at > 1.5:
		side = -side                 # round the other side of whatever is in the way, every 1.5 s stuck
		side_t = R.get("side_time", 0.0)
		_flipped_at = stuck_t
	return stuck_t > combat.ENGAGE["stuck_max"]

func _chase(dt: float, pd: float, pdir: Vector2) -> void:
	face = pdir
	if _give_up(pd):
		_enter("return")
		return
	if kind == "giant" and slam_cool <= 0.0 and pd >= R["slam_min"] and pd <= R["slam_max"] and world.los(position, foe.position):
		_enter("jump_wind")
		return
	if pd < R["wind_range"] and cool <= 0.0:
		_enter("wind")
		return
	if pd > 12.0:
		var before := position
		if _move(pdir, R["chase_speed"], dt):
			stuck_t = maxf(0.0, stuck_t - dt)
		else:
			stuck_t += dt
		gain += (position - before).dot(pdir)
	_watch_progress(dt, pd)

# Stuck behind a wall or rock: sliding back and forth along it still counts as moving, so stuck_t never fires. Instead, every
# progress_time s, check how far it actually moved toward the hero; under progress_gain px, it gives up, walks home and ignores the
# hero for lost_time s. Close to the hero (waiting to bite) is never stuck. The giant has no progress_time and never gives up this way.
func _watch_progress(dt: float, pd: float) -> void:
	if not R.has("progress_time"):
		return
	if pd < R["wind_range"] or engaged(pd):
		gain = 0.0                # close to its foe, or just hit: still in the fight, never "lost" (_give_up handles being stuck)
		prog_t = 0.0
		return
	prog_t += dt
	if prog_t < R["progress_time"]:
		return
	if gain < R["progress_gain"]:
		lost_t = R["lost_time"]
		_enter("return")
	else:
		gain = 0.0
		prog_t = 0.0

func _wind(_dt: float, pdir: Vector2) -> void:
	# tracks the hero, then freezes its aim for the last moments so a sidestep / dodge works
	if t < R["wind_time"] - R["wind_lock"]:
		lunge_dir = pdir
		face = pdir
		if absf(pdir.x) > 0.2:
			flip = 1 if pdir.x > 0.0 else -1
	if t >= R["wind_time"]:
		_enter("lunge")

func _lunge(dt: float) -> void:
	var moved := _slide(lunge_dir * R["lunge_speed"] * dt)
	if not lunge_hit and not (foe == player and player.dead) and position.distance_to(foe.position) < R["hit_dist"]:
		lunge_hit = true
		if combat.hurt_body(foe, R["dmg"], position) and R.get("poison", false):
			combat.poison_body(foe)      # the scorpion's sting: the hurt goes on (combat.gd POISON)
	if t >= R["lunge_time"] or not moved:
		cool = R["cool"]
		_enter("recover")

func _recover() -> void:
	if t >= R["recover_time"]:
		_after_action()

func _stagger() -> void:
	if t >= R["stagger"]:
		_after_action()

func _after_action() -> void:
	_enter("flee" if hp <= _flee_hp() else "chase")

func _flee(dt: float, pd: float, pdir: Vector2) -> void:
	if player.dead:
		_enter("return")
		return
	if pd > R["flee_safe"]:
		_enter("cower")
		return
	var away := (-pdir + (home - position).normalized() * 0.35).normalized()
	face = away
	if _move(away, R["flee_speed"], dt):
		stuck_t = maxf(0.0, stuck_t - dt)
	else:
		stuck_t += dt
		if stuck_t > 0.5 and pd < 40.0:
			_enter("wind")   # cornered: bites back

# Hiding, hurt. Once the hero has stayed away for the table's calm_time s it walks home, where it heals (before 7l it hid for good,
# keeping its part-empty bar: the user's play-test).
func _cower(dt: float, pd: float) -> void:
	if player.dead:
		_enter("return")
	elif pd < R["flee_wake"]:
		_enter("flee")
	else:
		calm_t += dt
		if calm_t >= R.get("calm_time", 4.0):
			_enter("return")

func _return(dt: float, pd: float, pdir: Vector2) -> void:
	var d := home - position
	if d.length() < 4.0 or stuck_t > 3.0:
		if stuck_t > 3.0:
			position = home
		hp = max_hp                  # every enemy that walks home heals to full (the design doc), a hurt one that fled too
		alert = 0.0
		_enter("patrol")
		wait = 1.0
		return
	face = d.normalized()
	var before := position
	if not _move(face, R["return_speed"], dt):
		stuck_t += dt
	elif R.has("progress_time"):
		# sliding along something without getting nearer home also counts: after twice progress_time it is put back home
		gain += (position - before).dot(face)
		prog_t += dt
		if prog_t >= R["progress_time"] * 2.0:
			if gain < R["progress_gain"]:
				stuck_t = 3.1
			gain = 0.0
			prog_t = 0.0
	if t > 1.5 and hp > _flee_hp() and position.distance_to(home) < leash * 0.6 and _sense(dt, pd, pdir):
		_enter("chase")

func _pulled(dt: float) -> void:
	var to_p: Vector2 = player.position - position
	var d: float = to_p.length() - R["pull_stop"]
	face = to_p.normalized() if to_p.length() > 0.01 else face
	if d <= 1.0 or t > R["pull_max"]:
		_enter("stun")
		return
	var step := minf(R["pull_speed"] * dt, d)
	if not _slide(face * step):
		_enter("stun")

func _stun(pdir: Vector2) -> void:
	face = pdir
	if t >= R["stun_time"] + stun_extra:
		stun_extra = 0.0
		_after_action()

func _bound(pdir: Vector2) -> void:
	face = pdir                     # he can glare, not move
	if t >= bind_t:
		_after_action()

# ---------------------------------------------------------------- things done to the rat
# aggro: the rat charges the hero at once (used when a whole group is woken); otherwise it just stops sleeping / eating
func wake(aggro := false) -> void:
	dormant = false
	munching = false
	if aggro and alive and (state == "patrol" or state == "alert") and not player.dead:
		var to_p: Vector2 = player.position - position
		face = to_p.normalized() if to_p.length() > 0.01 else face
		if absf(face.x) > 0.2:
			flip = 1 if face.x > 0.0 else -1
		_enter("chase")

# another of its side nearby joined the fight (combat.gd alarm): stop patrolling (or walking home) and come after the hero
func join_fight() -> void:
	if not alive or dormant or player.dead or not (state in ["patrol", "alert", "return"]):
		return
	munching = false
	var to_p: Vector2 = player.position - position
	face = to_p.normalized() if to_p.length() > 0.01 else face
	if absf(face.x) > 0.2:
		flip = 1 if face.x > 0.0 else -1
	lost_t = 0.0
	_called = true
	_enter("chase")
	_called = false

# the lasso: a light foe is pulled to the hero and stunned (strong: stunned for twice as long). Heavy ones resist.
func pull(strong := false) -> bool:
	if heavy or not alive:
		return false
	wake()
	stun_extra = R["stun_time"] if strong else 0.0
	_enter("pulled")
	return true

# the strong lasso on a heavy foe (a bandit): his arms are bound where he stands for `secs`. Light foes are pulled instead (pull),
# and bosses shrug it off.
func bind(secs: float) -> bool:
	if not heavy or not alive or kind in combat.BOSSES:
		return false
	wake()
	bind_t = secs
	_enter("bound")
	return true

# interrupt = false (the rider's arrows): it hurts, and sends the enemy after the hero if it wasn't already, but never staggers it
func hit(dmg: int, dirv: Vector2, power: float, interrupt := true) -> void:
	if not alive or (kind == "giant" and state == "jump"):    # the giant cannot be hurt while it is in the air
		return
	hp -= dmg
	hit_t = combat.ENGAGE["hit_time"]
	wake()              # hit while asleep: wide awake
	flash = 0.14
	kb = dirv * power * R.get("kb_mul", 1.0)
	combat.spark(position + Vector2(0, -5), dirv, 6, Color("#fff2c0"))
	if hp <= 0:
		_die()
	elif kind == "giant" and _giant_hit():
		pass
	elif not interrupt:
		if hp <= _flee_hp() and state != "flee" and state != "cower":
			_enter("flee")
		else:
			wake(true)
	elif state == "pulled":
		_enter("stun")
	elif state == "stun" or state == "bound":
		pass
	elif hp <= _flee_hp():
		_enter("flee")
	else:
		_enter("stagger")

# ---- the giant's jump and ground slam
func _jump_wind(pdir: Vector2) -> void:
	if t < R["slam_wind"] - R["slam_lock"]:
		slam_target = foe.position               # the circle follows you (or the companion it is after) ...
		face = pdir
		if absf(pdir.x) > 0.2:
			flip = 1 if pdir.x > 0.0 else -1
	if t >= R["slam_wind"]:                      # ... then freezes: run out of it
		jump_from = position
		jump_to = _land_pos(slam_target)
		_enter("jump")

func _land_pos(target: Vector2) -> Vector2:
	if not world.feet_blocked(target):
		return target
	for i in range(1, 11):
		var q := target.lerp(jump_from, i / 10.0)
		if not world.feet_blocked(q):
			return q
	return jump_from

func _jump() -> void:
	var k := minf(t / R["slam_air"], 1.0)
	position = jump_from.lerp(jump_to, k * k * (3.0 - 2.0 * k))
	body.position.y = -sin(k * PI) * R["slam_height"]
	if k >= 1.0:
		_land()

func _land() -> void:
	position = jump_to
	body.position.y = 0.0
	_enter("slam")
	slams += 1
	slam_cool = R["slam_cd_hurt"] if summoned else R["slam_cd"]
	# the one and only damage check: who is inside the impact circle right now? (the hero and any companion standing there)
	slam_hit = false
	for b in combat.targets():
		if b.position.distance_to(position) <= R["slam_radius"]:
			var landed: bool = combat.hurt_body(b, R["slam_dmg"], position)
			if b == player:
				slam_hit = landed
	player.shake(4.0, 0.3)
	for i in range(16):
		combat.spark(position + Vector2.RIGHT.rotated(TAU * i / 16.0) * R["slam_radius"] * 0.6, Vector2.RIGHT.rotated(TAU * i / 16.0), 1, Color("#c8b08a"))

func _slam_state() -> void:
	if t >= R["slam_recover"]:
		_after_action()

# the giant: returns true when the hit was fully handled (half-health summon, or armour during an attack)
func _giant_hit() -> bool:
	if not summoned and hp <= int(max_hp * R["summon_frac"]):
		summoned = true
		helped = false
		_enter("summon")
		return true
	return state in ["wind", "lunge", "summon", "jump_wind", "jump", "slam"]   # armoured: hurt, but never interrupted

func _summon_state(_dt: float, pdir: Vector2) -> void:
	face = pdir
	if not helped and t >= R["summon_time"] * 0.45:
		helped = true
		combat.summon_helpers(self)
	if t >= R["summon_time"]:
		_enter("chase")

func _die() -> void:
	alive = false
	t = 0.0
	combat.rat_killed(self)

func _dying(dt: float) -> void:
	t += dt
	var k := minf(t * 6.0, 1.0)      # flips onto its back
	if person:
		body.rotation = k * 1.5 * (1.0 if face.x >= 0.0 else -1.0)   # topples over
	else:
		body.scale.y = 1.0 - 2.0 * k
		body.position.y = -9.0 * k * (R["sc"] if kind == "giant" else 1.0)
	body.modulate = Color(1, 1, 1, 1.0 - clampf((t - 0.7) / 0.5, 0.0, 1.0))
	if t > 1.2:
		world.rats.erase(self)
		queue_free()

func _tint() -> void:
	if flash > 0.0:
		body.modulate = Color(2.4, 2.4, 2.4)
	elif state == "wind" or state == "jump_wind":
		body.modulate = Color(1.8, 0.55, 0.55) if int(t * 20.0) % 2 == 0 else Color(1.35, 0.8, 0.8)
	elif state == "stun" or state == "bound":
		body.modulate = Color(0.85, 0.85, 1.0)
	else:
		body.modulate = base_tint

# ---------------------------------------------------------------- drawing
func _draw_body(n) -> void:
	if kind == "bandit":
		_draw_bandit(n)
		return
	if kind == "giant":
		_draw_giant(n)
		return
	var f := flip
	var ox := 0.0
	var oy := 0.0
	if state == "wind":
		ox = -f * 3.0 * minf(1.0, t / 0.3)       # rears back
		oy = 0.0
	elif state == "cower":
		oy = 0.0
	if state == "lunge":
		for i in range(3):
			n.draw_line(Vector2(-lunge_dir.x * (8 + i * 4), -2 - i * 2 - lunge_dir.y * (8 + i * 4)),
				Vector2(-lunge_dir.x * (14 + i * 4), -2 - i * 2 - lunge_dir.y * (14 + i * 4)), Color(1, 1, 1, 0.35), 1.0)
	if state == "wind":
		var a := 0.2 + 0.45 * clampf(t / R["wind_time"], 0.0, 1.0)
		var tip: Vector2 = lunge_dir * R["lunge_speed"] * R["lunge_time"]
		n.draw_line(Vector2(0, -3), Vector2(0, -3) + tip, Color(1.0, 0.25, 0.2, a), 2.0)
		n.draw_circle(Vector2(0, -3) + tip, 3.0, Color(1.0, 0.25, 0.2, a))
	var moving := state in ["patrol", "chase", "flee", "return", "pulled"] and (state != "patrol" or wait <= 0.0)
	var eating := munching and dormant
	var step := anim if (moving or eating) else (anim * 0.25 if state != "stun" else 0.0)
	if kind == "scorpion":
		Sprites.scorpion(n, ox, oy, f, step, _tail())
	else:
		Sprites.rat(n, ox, oy, f, step, 1.0, 1.0 if eating else 0.0)
	# overhead markers (at `top`: a rat's are just over its back, a scorpion's over its tail)
	var font := ThemeDB.fallback_font
	if state == "alert":
		n.draw_rect(Rect2(-6, top, 12, 2), Color(0, 0, 0, 0.6))
		n.draw_rect(Rect2(-6, top, 12.0 * alert, 2), Color("#ffd24a"))
		_mark(n, font, "?", Color("#ffd24a"))
	elif state == "wind" or (state == "chase" and t < 0.5):
		_mark(n, font, "!", Color("#ff4a3a"))
	elif state == "stun":
		for i in range(3):
			var a := TAU * i / 3.0 + Time.get_ticks_msec() / 180.0
			n.draw_rect(Rect2(roundf(cos(a) * 6.0) - 1, roundf(sin(a) * 2.0) + top + 3, 2, 2), Color("#ffe14a"))
	if hp < max_hp and hp > 0 and state != "alert":
		n.draw_rect(Rect2(-6, top + 2, 12, 2), Color(0, 0, 0, 0.7))
		n.draw_rect(Rect2(-6, top + 2, 12.0 * hp / max_hp, 2), Color("#d9473a"))
	if world.debug_node.visible:
		var c := Color(1, 1, 0, 0.5)
		var a0 := face.angle()
		n.draw_line(Vector2.ZERO, Vector2.RIGHT.rotated(a0 - R["cone"]) * R["vision"], c, 1.0)
		n.draw_line(Vector2.ZERO, Vector2.RIGHT.rotated(a0 + R["cone"]) * R["vision"], c, 1.0)
		n.draw_arc(Vector2.ZERO, R["vision"], a0 - R["cone"], a0 + R["cone"], 12, c, 1.0)
		var ad := 0.0 if flip > 0 else PI          # it also sees the way its head is drawn (_drawn_looking_at)
		n.draw_arc(Vector2.ZERO, R["vision"], ad - R["cone"], ad + R["cone"], 12, Color(1, 1, 0, 0.25), 1.0)
		n.draw_arc(Vector2.ZERO, R["prox"], 0.0, TAU, 16, Color(1, 0.5, 0, 0.5), 1.0)
		n.draw_arc(home - position, R["leash"], 0.0, TAU, 32, Color(0.3, 1, 0.3, 0.4), 1.0)
		n.draw_string(font, Vector2(-14, 8), state, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)

# the scorpion's tail (sprites.gd scorpion): 0 resting, rising to 1 (arched over its head) through the wind-up, 2 as it stings,
# then easing back down while it recovers
func _tail() -> float:
	match state:
		"wind":
			return minf(1.0, t / (R["wind_time"] * 0.6))
		"lunge":
			return 2.0
		"recover":
			return 2.0 * maxf(0.0, 1.0 - t / 0.3)
	return 0.0

func _mark(n, font, s: String, col: Color) -> void:
	var y := top - 2.0
	n.draw_string_outline(font, Vector2(-6, y), s, HORIZONTAL_ALIGNMENT_CENTER, 12.0, 10, 3, Color.BLACK)
	n.draw_string(font, Vector2(-6, y), s, HORIZONTAL_ALIGNMENT_CENTER, 12.0, 10, col)

# the bandit: a person sprite with a red headband, a scimitar and an always-visible red health bar
func _draw_bandit(n) -> void:
	var font := ThemeDB.fallback_font
	var d := "right"
	if absf(face.y) > absf(face.x) * 1.1:
		d = "down" if face.y > 0.0 else "up"
	else:
		d = "right" if face.x >= 0.0 else "left"
	var moving := state in ["patrol", "chase", "flee", "return"] and (state != "patrol" or wait <= 0.0)
	var ox := 0.0
	if state == "wind":
		ox = -(1.0 if d != "left" else -1.0) * 2.0 * minf(1.0, t / 0.3)
	if state == "lunge":
		for i in range(3):
			n.draw_line(Vector2(-lunge_dir.x * (8 + i * 4), -8 - i * 3 - lunge_dir.y * (8 + i * 4)),
				Vector2(-lunge_dir.x * (14 + i * 4), -8 - i * 3 - lunge_dir.y * (14 + i * 4)), Color(1, 1, 1, 0.35), 1.0)
	if state == "wind":
		var a := 0.2 + 0.45 * clampf(t / R["wind_time"], 0.0, 1.0)
		var tip: Vector2 = lunge_dir * R["lunge_speed"] * R["lunge_time"]
		n.draw_line(Vector2(0, -3), Vector2(0, -3) + tip, Color(1.0, 0.25, 0.2, a), 2.0)
		n.draw_circle(Vector2(0, -3) + tip, 3.0, Color(1.0, 0.25, 0.2, a))
	Sprites.person(n, ox, 0.0, d, int(anim), moving, Sprites.PALETTES[look])
	# scimitar: low and ready, raised when winding up, thrust out when lunging
	var hx := 6.0 if d == "right" or d == "down" else -6.0
	if d == "up":
		hx = -6.0
	var hand := Vector2(ox + hx, -11.0)
	var tipv := hand + Vector2(hx * 0.9, 7.0)
	if state == "wind":
		tipv = hand + Vector2(hx * 0.2, -15.0 * minf(1.0, t / 0.35))
	elif state == "lunge" or state == "recover":
		tipv = hand + lunge_dir * 14.0 + Vector2(0, -2)
	n.draw_line(hand, tipv, Color("#2a2a30"), 3.0)
	n.draw_line(hand, tipv, Color("#d8dce4"), 1.0)
	n.draw_rect(Rect2(hand.x - 2, hand.y - 1, 4, 2), Color("#b8862a"))
	if state == "bound":       # the strong lasso's coils round his arms
		for yy in [-16.0, -12.0]:
			n.draw_line(Vector2(ox - 7, yy), Vector2(ox + 7, yy + 1), Color("#4a3018"), 3.0)
			n.draw_line(Vector2(ox - 7, yy - 0.5), Vector2(ox + 7, yy + 0.5), Color("#e8c888"), 1.0)
	_person_marks(n, font, state == "wind")
	if world.debug_node.visible:
		var c := Color(1, 1, 0, 0.5)
		var a0 := face.angle()
		n.draw_line(Vector2.ZERO, Vector2.RIGHT.rotated(a0 - R["cone"]) * R["vision"], c, 1.0)
		n.draw_line(Vector2.ZERO, Vector2.RIGHT.rotated(a0 + R["cone"]) * R["vision"], c, 1.0)
		n.draw_arc(Vector2.ZERO, R["vision"], a0 - R["cone"], a0 + R["cone"], 12, c, 1.0)
		n.draw_arc(Vector2.ZERO, R["prox"], 0.0, TAU, 16, Color(1, 0.5, 0, 0.5), 1.0)
		n.draw_arc(home - position, R["leash"], 0.0, TAU, 32, Color(0.3, 1, 0.3, 0.4), 1.0)
		n.draw_line(home - position - axis * span, home - position + axis * span, Color(0.3, 1, 0.3, 0.8), 1.0)
		n.draw_string(font, Vector2(-14, 8), state, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)

# over a person enemy (bandit, slinger): the "?" alert meter, a "!" while it winds up (`warn`) or has just spotted you, stun stars,
# and its health bar (always on, like a boss-lite)
func _person_marks(n, font, warn: bool) -> void:
	if state == "alert":
		n.draw_rect(Rect2(-6, top + 2, 12, 2), Color(0, 0, 0, 0.6))
		n.draw_rect(Rect2(-6, top + 2, 12.0 * alert, 2), Color("#ffd24a"))
		_mark(n, font, "?", Color("#ffd24a"))
	elif warn or (state == "chase" and t < 0.5):
		_mark(n, font, "!", Color("#ff4a3a"))
	elif state == "stun":
		for i in range(3):
			var a2 := TAU * i / 3.0 + Time.get_ticks_msec() / 180.0
			n.draw_rect(Rect2(roundf(cos(a2) * 6.0) - 1, roundf(sin(a2) * 2.0) - 33, 2, 2), Color("#ffe14a"))
	if state != "alert":
		n.draw_rect(Rect2(-9, -34, 18, 4), Color(0, 0, 0, 0.85))
		n.draw_rect(Rect2(-8, -33, 16.0 * hp / max_hp, 2), Color("#e0392b"))
		n.draw_rect(Rect2(-8, -33, 16.0 * hp / max_hp, 1), Color("#ff7a66"))

# the giant rat: the rat sprite scaled up, a wide health bar, and the same red telegraph before a lunge
func _draw_giant(n) -> void:
	var font := ThemeDB.fallback_font
	var sc: float = R["sc"]
	var f := flip
	var ox := 0.0
	var oy := 0.0
	if state == "wind":
		ox = -f * 5.0 * minf(1.0, t / 0.4)       # rears back
	elif state == "summon":
		oy = -2.0 * absf(sin(t * 12.0))          # rears up and shudders
	if state == "lunge":
		for i in range(4):
			n.draw_line(Vector2(-lunge_dir.x * (14 + i * 6), -4 - i * 3 - lunge_dir.y * (14 + i * 6)),
				Vector2(-lunge_dir.x * (24 + i * 6), -4 - i * 3 - lunge_dir.y * (24 + i * 6)), Color(1, 1, 1, 0.35), 1.0)
	if state == "wind":
		var a := 0.2 + 0.45 * clampf(t / R["wind_time"], 0.0, 1.0)
		var tip: Vector2 = lunge_dir * R["lunge_speed"] * R["lunge_time"]
		n.draw_line(Vector2(0, -4), Vector2(0, -4) + tip, Color(1.0, 0.25, 0.2, a), 3.0)
		n.draw_circle(Vector2(0, -4) + tip, 5.0, Color(1.0, 0.25, 0.2, a))
	var lift: float = -body.position.y               # how high it is in the air (the body node is raised by this much)
	if state == "jump_wind":
		oy = 3.0 * minf(1.0, t / 0.4)           # crouches
		# the impact circle on the ground
		var tg: Vector2 = slam_target - position + Vector2(0.0, lift)
		var ak := clampf(t / R["slam_wind"], 0.0, 1.0)
		n.draw_circle(tg, R["slam_radius"], Color(1.0, 0.2, 0.15, 0.10 + 0.28 * ak))
		n.draw_arc(tg, R["slam_radius"], 0.0, TAU, 36, Color(1.0, 0.35, 0.25, 0.5 + 0.5 * ak), 1.5)
		n.draw_arc(tg, R["slam_radius"] * ak, 0.0, TAU, 36, Color(1.0, 0.7, 0.5, 0.6), 1.0)
	elif state == "jump":
		var tg2: Vector2 = jump_to - position + Vector2(0, lift)
		n.draw_circle(tg2, R["slam_radius"], Color(1.0, 0.2, 0.15, 0.4))
		n.draw_arc(tg2, R["slam_radius"], 0.0, TAU, 36, Color(1.0, 0.45, 0.3, 1.0), 1.5)
		n.draw_circle(Vector2(0, lift), 12.0, Color(0, 0, 0, 0.35))       # its shadow on the ground
	elif state == "slam" and t < 0.35:
		var sk := t / 0.35
		n.draw_arc(Vector2.ZERO, lerpf(8.0, R["slam_radius"] * 1.25, sk), 0.0, TAU, 36, Color(1.0, 0.9, 0.7, 1.0 - sk), 2.0)
	var moving := state in ["patrol", "chase", "return", "pulled"] and (state != "patrol" or wait <= 0.0)
	var eating := munching and dormant
	Sprites.rat(n, ox, oy, f, anim if (moving or eating) else anim * 0.25, sc, 1.0 if eating else 0.0)
	if state == "jump_wind":
		_mark(n, font, "!", Color("#ff4a3a"))
	if state == "alert":
		n.draw_rect(Rect2(-10, top + 4, 20, 2), Color(0, 0, 0, 0.6))
		n.draw_rect(Rect2(-10, top + 4, 20.0 * alert, 2), Color("#ffd24a"))
		_mark(n, font, "?", Color("#ffd24a"))
	elif state == "wind" or (state == "chase" and t < 0.5):
		_mark(n, font, "!", Color("#ff4a3a"))
	# boss health bar (once it is awake), unless the big bar at the bottom of the screen shows it (hud.gd, while it is after the hero)
	if not dormant and state != "alert" and combat.boss() != self:
		n.draw_rect(Rect2(-17, top + 2, 34, 5), Color(0, 0, 0, 0.85))
		n.draw_rect(Rect2(-16, top + 3, 32.0 * hp / max_hp, 3), Color("#e0392b"))
		n.draw_rect(Rect2(-16, top + 3, 32.0 * hp / max_hp, 1), Color("#ff7a66"))
		n.draw_rect(Rect2(-1, top + 3, 1, 3), Color(0, 0, 0, 0.6))    # half-health mark: the summon
	if world.debug_node.visible:
		var c := Color(1, 1, 0, 0.5)
		var a0 := face.angle()
		n.draw_arc(Vector2.ZERO, R["vision"], a0 - R["cone"], a0 + R["cone"], 12, c, 1.0)
		n.draw_arc(Vector2.ZERO, R["prox"], 0.0, TAU, 16, Color(1, 0.5, 0, 0.5), 1.0)
		n.draw_arc(home - position, R["leash"], 0.0, TAU, 32, Color(0.3, 1, 0.3, 0.4), 1.0)
		n.draw_string(font, Vector2(-14, 12), state + (" dormant" if dormant else ""), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)
