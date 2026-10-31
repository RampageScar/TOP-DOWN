extends "res://tests/suite.gd"
# fight.gd - everything about combat: a rat fight (telegraph, combo, lasso, kill, fall + the death screen), dodging and escaping,
# the bandits, the giant rat boss (sleep, armour, summon once) and its jump + ground slam.
# Run (from the project root): <godot console exe> --headless --fixed-fps 60 --path timetravel_godot -s tests/fight.gd

var boss
var seen := {}
var n0 := 0
var before_ids := []

func _sections() -> Array:
	return [
		{"name": "rat fight: telegraph, lunge, combo, lasso, kill, fall and the death screen", "run": _rat_fight},
		{"name": "dodge and escape: i-frames, the rat gives up and walks home", "run": _escape},
		{"name": "bandits: pacing, noticing, beaten, too heavy for the lasso", "run": _bandits},
		{"name": "giant rat: sleeping at the pile, armour, summon once, XP", "run": _boss, "pre": _watch_boss},
		{"name": "giant rat: jump + ground slam", "run": _slam, "pre": _watch_boss},
	]

func _watch_boss() -> void:
	if boss != null and is_instance_valid(boss):
		seen[boss.state] = true

# ---------------------------------------------------------------- a small rat, start to finish
func _rat_fight() -> void:
	var c = main.combat
	var p = main.player
	var w = main.world
	var rat = snap.get("rat")
	if f == 2:
		var bad := 0
		for r in c.rats:
			if w.feet_blocked(r.home): bad += 1
		ok(bad == 0, "no enemy home is inside a prop (%d blocked)" % bad)
		rat = c.rats[0]
		snap["rat"] = rat
		p.position = rat.position + Vector2(-60, 0)
		p.dir = "right"
		for r in c.rats:
			if r != rat: r.position = Vector2(-500, -500)    # keep the others out of the way
		rat.face = Vector2.LEFT; rat.flip = -1
	elif f > 30 and f < 400:
		if rat.state == "wind": snap["wind"] = true
		if rat.state == "lunge": snap["lunge"] = true
	elif f == 400:
		ok(snap.has("wind"), "the rat telegraphs (wind-up) before attacking")
		ok(snap.has("lunge"), "then it lunges")
		ok(p.hp < p.max_hp, "standing still, the lunges hurt the hero (hp %d)" % p.hp)
		p.hp = p.max_hp; p.inv_t = 0.0
		rat.hp = rat.max_hp; rat._enter("stagger"); rat.position = p.position + Vector2(18, 0); rat.kb = Vector2.ZERO
		p.dir = "right"
		press("light")
	elif f == 402:
		release("light")
	elif f == 412:
		ok(rat.hp == 20 and rat.state == "stagger", "punch 1 hits and staggers (hp %d, %s)" % [rat.hp, rat.state])
		press("light")
	elif f == 414:
		release("light")
	elif f == 440:
		ok(rat.hp == 10 and rat.state == "flee", "punch 2 hits; at 10 HP the town rat runs away (hp %d, %s)" % [rat.hp, rat.state])
		p.position = rat.position + Vector2(-50, 0)
		p.dir = "right"
		press("lasso")
	elif f == 442:
		release("lasso")
	elif f == 455:
		ok(rat.state == "pulled" or rat.state == "stun", "the lasso catches the fleeing rat (%s)" % rat.state)
	elif f == 500:
		ok(rat.state == "stun", "the pulled rat is stunned (%s)" % rat.state)
		ok(c.lasso_ready_frac() < 1.0, "the lasso is on cooldown after a catch")
		rat.position = p.position + Vector2(18, 0)
		p.dir = "right"
		c.chain = "LL"; c.chain_t = 0.3      # next light press ends the string LLL: the kick
		press("light")
	elif f == 502:
		release("light")
	elif f == 530:
		ok(not rat.alive, "the kick finishes the rat")
		ok(c.kills == 1 and main.progress.xp == c.XP_RAT, "1 kill, +%d XP (kills %d, xp %d)" % [c.XP_RAT, c.kills, main.progress.xp])
		p.inv_t = 0.0
		c.hurt_player(p.max_hp, Vector2.ZERO)
		ok(p.dead, "a big hit makes the hero fall")
	elif f == 530 + 60 * 3:
		# Stage 7j: no getting up on the map; the death screen offers the saves there are (the autosave first), then New game
		var want := Save.SLOTS.filter(func(s): return Save.info(s) != "") + ["new"]
		ok(p.dead and main.death.open and paused, "the death screen is up and the game is paused (dead %s, open %s)" % [p.dead, main.death.open])
		ok(main.death.rows == want and main.death.sel == 0, "it lists the saves on disk, then New game (%s)" % str(main.death.rows))
		ok(main.progress.xp == c.XP_RAT, "nothing changes until a save is picked (XP %d)" % main.progress.xp)
		done()

# ---------------------------------------------------------------- dodge through a lunge, then run away
func _escape() -> void:
	var c = main.combat
	var p = main.player
	var rat = snap.get("rat")
	if f == 2:
		rat = c.rats[0]
		snap["rat"] = rat
		for o in c.rats:
			if o != rat: o.position = Vector2(-500, -500)
		p.position = rat.position + Vector2(-30, 0); p.dir = "right"
		rat.face = Vector2.LEFT
		return
	if f < 2:
		return
	if not snap.has("dodged") and rat.state == "wind" and rat.t > rat.R["wind_time"] - 0.1:
		snap["dodged"] = true
		snap["hp0"] = p.hp
		press("dodge")
	elif snap.has("dodged") and not snap.has("recover") and rat.state == "recover":
		snap["recover"] = true
		release("dodge")
		ok(p.hp == snap["hp0"], "dodging through the lunge: no damage (hp %d)" % p.hp)
		p.position = rat.position + Vector2(260, 0)      # run far away
	elif snap.has("recover") and not snap.has("gave_up") and rat.state == "return":
		snap["gave_up"] = true
		ok(true, "the rat gives up the chase when the hero is far away")
	elif snap.has("gave_up") and rat.state == "patrol":
		ok(rat.position.distance_to(rat.home) < 4.0, "the rat walks home and patrols again (%.0f px from home)" % rat.position.distance_to(rat.home))
		done()
	elif f > 1500:
		ok(false, "timed out waiting for dodge / give up / return (state %s)" % rat.state)
		done()

# ---------------------------------------------------------------- bandits on the road
func _bandits() -> void:
	var c = main.combat
	var p = main.player
	var w = main.world
	var b = snap.get("b")
	if f == 2:
		var bandits := []
		for r in c.rats:
			if r.kind == "bandit": bandits.append(r)
		var scorpions: int = c.rats.filter(func(r): return r.kind == "scorpion").size()
		ok(bandits.size() == 3 and scorpions == 3 and c.rats.size() - bandits.size() - scorpions == 6,
			"3 bandits, 3 scorpions (the ruins' den) and 6 rats on the town map")
		for r in bandits:
			ok(not w.feet_blocked(r.home) and r.hp == 60 and r.heavy, "bandit at %s: free spot, 60 HP, too heavy to lasso" % str(r.home))
		snap["b"] = bandits[0]
		snap["xs"] = []
		p.position = Vector2(598, 1226)      # far away at the start of the road
		return
	if f > 2 and f < 60 * 12 and f % 20 == 0:
		snap["xs"].append(b.position.x)
	if f == 60 * 12:
		var mn: float = snap["xs"].min()
		var mx: float = snap["xs"].max()
		ok(mx - mn >= b.span, "the bandit paces back and forth (x %.0f .. %.0f, beat +-%.0f)" % [mn, mx, b.span])
		p.position = b.position + Vector2(-90, 0); p.dir = "right"
		b.face = Vector2.LEFT; b.wait = 1.0     # pausing at the end of a beat, looking this way (a walking bandit faces its goal)
		for r in c.rats:                        # the other two sit this fight out (one paces close by), so the kill count is about b
			if r.kind == "bandit" and r != b: r.dormant = true
	elif f == 60 * 12 + 40 * 6:
		ok(b.state in ["chase", "wind", "lunge", "recover"], "the bandit noticed the hero and attacks (%s)" % b.state)
		p.hp = p.max_hp; p.inv_t = 3.0
		b.hp = b.max_hp; b._enter("stagger"); b.position = p.position + Vector2(18, 0); b.kb = Vector2.ZERO
		p.dir = "right"
		snap["t"] = f
	if not snap.has("t"):
		return
	var k: int = f - snap["t"]
	for i in range(8):         # eight swings, a combo and a bit
		var at := 2 + i * 22
		if k == at:
			if is_instance_valid(b):
				p.position = b.position + Vector2(-18, 0); p.dir = "right"; b.kb = Vector2.ZERO
				if b.alive: b._enter("stagger")
			press("light")
		if k == at + 2:
			release("light")
	if k == 8 * 22 + 60:
		ok((not is_instance_valid(b)) or (not b.alive), "two combos beat a bandit")
		ok(c.kills == 1 and main.progress.xp == c.XP_BANDIT, "1 kill, +%d XP (kills %d, xp %d)" % [c.XP_BANDIT, c.kills, main.progress.xp])
		var o = null
		for r in c.rats:
			if r.kind == "bandit" and r.alive: o = r; break
		snap["o"] = o
		p.inv_t = 0.0
		p.position = o.position + Vector2(-50, 0); p.dir = "right"
		o.face = Vector2.RIGHT
		c.lasso_cd = 0.0
		press("lasso")
	elif k == 8 * 22 + 62:
		release("lasso")
	elif k == 8 * 22 + 75:
		var heavy := false
		for t in c.texts:
			if t["s"] == "Too heavy!": heavy = true
		ok(heavy, "lasso on a bandit says 'Too heavy!'")
	elif k == 8 * 22 + 100:
		ok(snap["o"].state != "pulled" and c.lasso_phase == 0, "the bandit is not pulled and the rope comes back")
		done()

# ---------------------------------------------------------------- the giant rat
func _small_alive(s) -> int:
	var n := 0
	for r in s.rats:
		if r.alive and r.kind == "rat": n += 1
	return n

func _boss() -> void:
	var p = main.player
	var c = main.combat
	match step:
		0:
			boss = null
			seen = {}
			main.travel("storeroom", "entry")
			wait = 60
			step = 1
		1:
			var s = main.world
			for r in s.rats:
				if r.kind == "giant": boss = r
			ok(boss != null, "boss exists")
			ok(boss.max_hp == 120 and boss.hp == 120, "boss HP 120 (twice the bandit's 60): %d" % boss.max_hp)
			ok(c.BANDIT["hp"] * 2 == boss.max_hp, "boss HP is exactly double a bandit's")
			ok(boss.heavy, "boss is too heavy to lasso")
			ok(boss.dormant, "boss starts asleep")
			# the barn before the fight: everyone is eating at the pile and stays put
			var munchers := 0
			var start_pos := {}
			for r in s.rats:
				if r.group == "boss":
					if r.munching and r.dormant: munchers += 1
					start_pos[r] = r.position
			ok(munchers == 4, "the giant and its 3 rats are all eating at the pile (%d)" % munchers)
			snap["pos"] = start_pos
			# a storeroom rat that is hurt to 10 HP (where a town rat runs) must not run away
			var fr = null
			for r in s.rats:
				if r.kind == "rat" and r.group == "" and r.alive:
					fr = r
					break
			fr.hit(20, Vector2.RIGHT, 0.0)
			ok(fr.hp == 10 and fr.state != "flee", "storeroom rat at 10 HP does not flee (state %s)" % fr.state)
			p.position = Vector2(320, 262)
			wait = 60
			step = 12
		12:
			var s = main.world
			var moved := 0
			for r in snap["pos"].keys():
				if r.position.distance_to(snap["pos"][r]) > 0.5: moved += 1
			ok(moved == 0, "eating rats and boss did not wander while asleep (%d moved)" % moved)
			ok(boss.dormant, "boss still asleep near the gate of the barn")
			ok(not (seen.has("flee") or seen.has("cower")), "boss never flees")
			for r in s.rats:        # kill the small rats (keep this about the boss), then walk to the middle of the barn
				if r.kind == "rat": r.hit(999, Vector2.RIGHT, 0.0)
			p.position = Vector2(320, 216)
			p.dir = "up"
			p.hp = p.max_hp
			wait = 3
			step = 2
		2:
			ok(not boss.dormant, "boss woke when the hero reached the middle of the barn")
			ok(boss.state == "chase" or boss.state == "wind" or boss.state == "jump_wind", "...and charges at once (state %s)" % boss.state)
			p.position = Vector2(320, 190)       # in its face
			p.dir = "up"
			p.hp = p.max_hp; p.inv_t = 0.0
			boss.slam_cool = 99.0               # this part is about the lunge only
			wait = 150
			step = 3
		3:
			ok(seen.has("wind") and seen.has("lunge"), "boss telegraphs (wind) then lunges: " + str(seen.keys()))
			ok(p.hp < p.max_hp, "boss lunge hurt the hero (hp %d)" % p.hp)
			ok(p.max_hp - p.hp >= 40, "boss hit is a heavy hit (40 HP): hp %d" % p.hp)
			p.hp = p.max_hp; p.inv_t = 3.0         # lasso on the boss
			boss.position = p.position + Vector2(0, -50)
			boss.slam_cool = 99.0
			boss._enter("chase")
			p.dir = "up"
			press("lasso")
			wait = 2
			step = 4
		4:
			release("lasso")
			wait = 45
			step = 5
		5:
			ok(boss.state != "pulled", "lasso does not pull the boss (state %s)" % boss.state)
			boss._enter("wind")                  # armour: hit while winding up -> state unchanged
			var hp0 = boss.hp
			boss.hit(10, Vector2.UP, 70.0)
			ok(boss.hp == hp0 - 10, "hit lands during wind-up")
			ok(boss.state == "wind", "boss is not interrupted while attacking (armour)")
			boss.hp = 120; boss.summoned = false   # heal to full, take it to 70 -> no summon yet
			boss._enter("chase")
			n0 = _small_alive(main.world)
			for i in range(5):
				boss.hit(10, Vector2.UP, 0.0)
				boss._enter("chase")
			ok(boss.hp == 70 and not boss.summoned, "no summon above half health")
			ok(_small_alive(main.world) == n0, "no extra rats yet")
			p.inv_t = 5.0
			before_ids = main.world.rats.duplicate()
			boss.hit(10, Vector2.UP, 0.0)        # 60 = half
			ok(boss.summoned, "summon triggers at 50% health")
			ok(boss.state == "summon", "boss roars (summon state)")
			wait = 34
			step = 55
		55:
			# the rats exist now (the summon fires 0.45 of the way through the roar): where did they come from?
			var s = main.world
			var fresh := []
			for r in s.rats:
				if not before_ids.has(r) and r.kind == "rat": fresh.append(r)
			var l := 0
			var rt := 0
			var bad := 0
			for r in fresh:
				if r.home.x < 160.0 and r.home.y > 195.0: l += 1
				elif r.home.x > 480.0 and r.home.y > 195.0: rt += 1
				else: bad += 1
			ok(fresh.size() >= 5 and fresh.size() <= 6, "summoned 5-6 small rats in total (%d)" % fresh.size())
			ok(l >= 2 and l <= 4 and rt >= 2 and rt <= 4, "2-4 from the left pen and 2-4 from the right pen (left %d, right %d)" % [l, rt])
			ok(bad == 0, "every summoned rat came out of a southern pen")
			ok(boss.summon_split[0] == l and boss.summon_split[1] == rt, "boss reports the same split " + str(boss.summon_split))
			var awake := 0
			for r in fresh:
				if not r.dormant and r.state in ["chase", "wind", "lunge", "recover"]: awake += 1
			ok(awake == fresh.size(), "all summoned rats are awake and fighting (%d)" % awake)
			n0 = _small_alive(s) - fresh.size()
			wait = 56
			step = 6
		6:
			var added := _small_alive(main.world) - n0
			ok(added >= 5 and added <= 6, "summoned 5-6 small rats still alive (%d)" % added)
			var still := 0
			for r in main.world.rats:
				if r.kind == "rat" and r.alive and r.state == "return": still += 1
			ok(still == 0, "the summoned rats did not give up and walk home (leash) (%d returning)" % still)
			boss.hp = 120                        # once only: heal and cross 50% again
			boss._enter("chase")
			var again := false
			for i in range(8):
				boss.hit(10, Vector2.UP, 0.0)
				if boss.state == "summon": again = true
				boss._enter("chase")
			ok(not again, "no second summon when crossing half health again")
			wait = 90
			step = 7
		7:
			var added2 := _small_alive(main.world) - n0
			ok(added2 <= 6, "summon happened only once (%d extra rats total)" % added2)
			var xp0 = main.progress.xp
			boss.hit(999, Vector2.UP, 0.0)
			ok(not boss.alive, "boss dies")
			ok(main.progress.xp == xp0 + c.XP_GIANT, "giant gives %d XP" % c.XP_GIANT)
			done()

# ---------------------------------------------------------------- the giant's jump + ground slam
func _slam() -> void:
	var p = main.player
	match step:
		0:
			boss = null
			seen = {}
			main.travel("storeroom", "entry")
			wait = 60
			step = 1
		1:
			for r in main.world.rats:
				if r.kind == "giant": boss = r
				elif r.kind == "rat": r.hit(999, Vector2.RIGHT, 0.0)
			boss.dormant = false
			boss.munching = false
			boss.position = Vector2(320, 150)
			boss.home = boss.position
			# CASE A: stand still 100 px away: the slam must hit us
			p.position = Vector2(320, 250)
			p.dir = "up"
			p.hp = p.max_hp; p.inv_t = 0.0
			boss.slam_cool = 0.0
			boss._enter("chase")
			wait = 2
			step = 2
		2:
			ok(boss.state == "jump_wind", "boss starts a slam from mid range (state %s)" % boss.state)
			wait = 40
			step = 3
		3:
			ok(boss.state == "jump_wind", "still crouching/telegraphing (circle visible)")
			ok(boss.slam_target.distance_to(p.position) < 1.0, "circle follows the hero while crouching")
			wait = 8         # past the lock point (0.6 s) but not yet the jump (0.9 s)
			step = 4
		4:
			ok(boss.state == "jump_wind" and boss.t > 0.6, "circle is now frozen (t=%.2f)" % boss.t)
			snap["frozen"] = boss.slam_target
			p.position = p.position + Vector2(30, 0)   # move after the lock: the circle must NOT follow
			wait = 25
			step = 5
		5:
			ok(boss.state == "jump" or boss.state == "slam", "boss is in the air / landing (%s)" % boss.state)
			ok(boss.jump_to.distance_to(snap["frozen"]) < 1.0 and boss.jump_to.distance_to(p.position) > 20.0, "it lands where the frozen circle was, not on the hero's new spot")
			if boss.state == "jump":
				var hp1 = p.hp
				var before = boss.hp
				boss.hit(3, Vector2.UP, 0.0)
				ok(boss.hp == before, "boss cannot be hurt while airborne")
				ok(p.hp == hp1, "no damage before landing")
				ok(boss.body.position.y < -5.0, "boss is visibly in the air (%.1f)" % boss.body.position.y)
			wait = 30
			step = 6
		6:
			ok(boss.slams == 1, "one slam landed")
			ok(boss.slam_hit, "standing in the circle -> hero was hurt")
			ok(p.hp == p.max_hp - 40, "slam does 40 damage (hp %d)" % p.hp)
			ok(boss.body.position.y == 0.0, "boss is back on the ground")
			# CASE B: get out of the circle after it freezes -> no damage
			boss.slam_cool = 0.0
			p.hp = p.max_hp; p.inv_t = 0.0
			boss.position = Vector2(320, 150); boss.home = boss.position
			p.position = Vector2(320, 250)
			boss._enter("chase")
			wait = 2
			step = 7
		7:
			ok(boss.state == "jump_wind", "second slam telegraphs")
			wait = 56        # t ~0.95: it has just jumped
			step = 8
		8:
			var tgt = boss.jump_to
			p.position = tgt + Vector2(0, 70)
			if main.world.feet_blocked(p.position):
				p.position = tgt + Vector2(70, 0)
			ok(p.position.distance_to(tgt) > boss.R["slam_radius"] + 20.0, "hero stepped out of the circle")
			wait = 40
			step = 9
		9:
			ok(boss.slams == 2, "second slam landed")
			ok(not boss.slam_hit and p.hp == p.max_hp, "outside the impact radius -> no damage (hp %d)" % p.hp)
			# CASE C: edge of the circle: 30 px in -> hurt; 56 px out -> safe (radius 42)
			boss.slam_cool = 0.0
			boss._enter("slam"); boss.t = 0.0
			boss.position = Vector2(320, 150)
			p.inv_t = 0.0; p.hp = p.max_hp
			p.position = boss.position + Vector2(30, 0)
			boss.jump_to = boss.position
			boss._land()
			ok(boss.slam_hit and p.hp == p.max_hp - 40, "30 px from the landing spot -> hurt")
			p.inv_t = 0.0; p.hp = p.max_hp
			p.position = boss.position + Vector2(56, 0)
			boss._land()
			ok(not boss.slam_hit and p.hp == p.max_hp, "56 px from the landing spot -> safe (radius 42)")
			p.inv_t = 0.28; p.hp = p.max_hp         # dodge roll invulnerability also protects
			p.position = boss.position + Vector2(10, 0)
			boss._land()
			ok(not boss.slam_hit and p.hp == p.max_hp, "invulnerable (dodge roll) hero is not hurt")
			boss._enter("chase")                   # slam cooldown stops it from chaining jumps
			boss.slam_cool = 3.0
			p.position = boss.position + Vector2(0, 100)
			wait = 3
			step = 10
		10:
			ok(boss.state != "jump_wind", "no new slam while on cooldown (state %s)" % boss.state)
			done()
