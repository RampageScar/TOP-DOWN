extends "res://tests/suite.gd"
# world.gd - everything that is not a fight: the town layout, NPCs and talking, dialogue choices, map changes and frozen maps,
# the castle courtyard, and the great hall with the king scene.
# Run (from the project root): <godot console exe> --headless --fixed-fps 60 --path timetravel_godot -s tests/world.gd

var max_alpha := 0.0

func _sections() -> Array:
	return [
		{"name": "town: spawn, walking, every important place reachable", "run": _town},
		{"name": "town people: routes clear, talking pauses the game, quest stage", "run": _people},
		{"name": "dialogue: two-choice path", "run": _choices},
		{"name": "maps: storeroom door, fade, frozen town, sleeping groups, the death screen per map", "run": _maps, "pre": _fade_sample},
		{"name": "courtyard: bridge door both ways, guards, reachability", "run": _courtyard},
		{"name": "hall: gate both ways, collisions, the king scene (once)", "run": _hall},
	]

# ---------------------------------------------------------------- town
func _town() -> void:
	var w = main.world
	var p = main.player
	if f == 3:
		ok(not w.feet_blocked(p.position), "spawn spot is free")
		ok(w.nests.size() == 5 and w.bandit_spots.size() == 3, "5 rat nests and 3 bandit spots")
		snap["start"] = p.position
		press("move_up")
	elif f == 3 + 60 * 3:
		release("move_up")
		ok(snap["start"].y - p.position.y > 150.0, "walking up for 3 s moves the hero along the road (%.0f px)" % (snap["start"].y - p.position.y))
		var seen := reachable(w, w.spawn)
		var places := {
			"town gate": Vector2(422, 700), "town plaza": Vector2(425, 520), "training yard": Vector2(540, 570), "stable": Vector2(200, 380),
			"market": Vector2(590, 440), "storeroom door": Vector2(442, 392), "cook camp": Vector2(262, 610), "north-west ruins": Vector2(420, 190), "ruins north": Vector2(560, 90),
			"south-east ruins": Vector2(930, 930), "bottom-left ruin": Vector2(150, 880), "cave road end": Vector2(1030, 165),
			"bridge start": Vector2(1050, 620), "bridge middle": Vector2(1120, 620), "bridge far end": Vector2(1190, 620), "east fork": Vector2(900, 440),
		}
		for k in places.keys():
			ok(reach(seen, places[k]), "reach " + k)
		for i in range(w.nests.size()):
			ok(reach(seen, w.nests[i] + Vector2(0, 14)), "reach rat nest %d" % i)
		for b in w.bandit_spots:
			ok(reach(seen, b[0]), "reach bandit spot " + str(b[0]))
		ok(w.feet_blocked(Vector2(1120, 540)), "the river blocks")
		ok(w.feet_blocked(Vector2(1030, 100)), "the cave mouth is blocked")
		ok(not w.feet_blocked(Vector2(1120, 620)), "the bridge deck is open")
		w.toggle_debug()             # draw the debug overlay and the gallery once (they must not error)
		main.hud.gallery = true
	elif f == 3 + 60 * 3 + 5:
		done()

# ---------------------------------------------------------------- town people and talking
func _people() -> void:
	var w = main.world
	if f == 3:
		for n in w.npcs:
			if n.sprite != "lizard":
				ok(not w.feet_blocked(n.position), n.id + " does not start inside a prop")
			for i in range(n.route.size()):
				var a: Vector2 = n.route[i]
				var b: Vector2 = n.route[(i + 1) % n.route.size()]
				ok(seg_clear(w, a, b), "%s route leg %d is clear" % [n.id, i])
		ok(w.npcs.size() == 14, "14 people in the town (%d)" % w.npcs.size())
		var d = w.npc_by_id("datis")
		main.player.position = d.position + Vector2(-16, 0)
		ok(w.mark_for("datis") == "quest" and main.quest.stage == 0, "Datis wears the quest mark at stage 0")
		tap_interact()
	elif f == 8:
		ok(main.dialogue.open and paused and w.talking, "E opens the conversation and pauses the game")
		snap["p0"] = main.player.position
		press("move_right")
	elif f == 40:
		release("move_right")
		ok(main.player.position == snap["p0"], "the hero cannot move while the game is paused")
		for i in range(8):
			main.dialogue._advance()
		ok(not main.dialogue.open and not paused, "conversation closed, game running again")
		ok(main.quest.stage == 1 and w.mark_for("datis") == "chat", "quest moved to stage 1, Datis now only chats")
		ok(main.quest.text() == "Find King Rostam", "objective reads 'Find King Rostam'")
	elif f == 60:
		done()

# ---------------------------------------------------------------- dialogue choices
func _choices() -> void:
	if f != 3:
		return
	var dl = main.dialogue
	var n = main.world.npc_by_id("arshan")
	main.player.position = n.position + Vector2(0, 14)
	dl._start(n)
	dl.lines = [{"t": "Water?", "choices": [{"label": "Yes", "lines": ["Here you go."]}, {"label": "No", "lines": ["Suit yourself.", "Bye."]}]}, "end"]
	dl.idx = 0
	dl._begin_line()
	dl._advance()
	ok(not dl.choosing, "first E finishes typing the question")
	dl._advance()
	ok(dl.choosing, "second E shows the choices")
	dl.sel = 1
	dl._advance()
	ok(dl.idx == 1 and dl._line_text() == "Suit yourself." and dl.lines.size() == 3, "picking 'No' continues with its own lines")
	for i in range(6):
		dl._advance()
	ok(not dl.open and not paused, "conversation closes and the game runs again")
	done()

# ---------------------------------------------------------------- maps: storeroom, frozen town, groups, respawn
func _fade_sample() -> void:
	if main != null:
		max_alpha = maxf(max_alpha, main.fade_rect.color.a)

func _maps() -> void:
	var p = main.player
	var c = main.combat
	match step:
		0:   # start state
			ok(main.world.key == "town", "starts in the town")
			ok(main.world.doors.size() == 3, "town has the storeroom door, the bridge door and the cave mouth")
			var town = main.world
			ok(not town.feet_blocked(town.spawns["storeroom_door"]["pos"]), "town door exit spot is free")
			snap["town"] = town
			snap["rats0"] = town.rats.size()
			var rat = null
			for r in town.rats:
				if r.kind == "rat" and rat == null: rat = r
			snap["rat"] = rat
			snap["rat_i"] = rat.plan_i
			rat.hit(999, Vector2.RIGHT, 0.0)
			snap["alive_before"] = c.rats_alive()
			# walk to the door and press E (the real path)
			p.position = Vector2(443, 392)
			p.dir = "up"
			wait = 3
			step = 1
		1:
			tap_interact()
			wait = 2
			step = 2
		2:
			ok(main.travelling, "E at the door starts a transition")
			ok(p.lock, "hero is locked during the fade")
			max_alpha = 0.0
			step = 3
		3:
			if main.travelling:
				return
			ok(max_alpha > 0.95, "screen went fully black during the change (max alpha %.2f)" % max_alpha)
			ok(main.fade_rect.color.a < 0.01, "screen is clear again")
			var s = main.world
			ok(s.key == "storeroom", "now in the storeroom")
			ok(p.position.distance_to(Vector2(320, 826)) < 1.0, "hero is at the storeroom entry (%s)" % str(p.position))
			ok(p.get_parent() == s.ysort, "hero lives in the storeroom's node tree")
			ok(not snap["town"].is_inside_tree(), "town is out of the tree (frozen)")
			# snapshot every town enemy NOW (the town is frozen from here on)
			snap["frozen"] = []
			for r in snap["town"].rats:
				snap["frozen"].append([r, r.hp, r.state, r.position, r.alive])
			ok(p.cam.limit_right == s.W and p.cam.limit_bottom == s.H, "camera limits follow the map")
			ok(c.rats == s.rats and c.world == s, "combat is attached to the storeroom")
			ok(s.rats.size() == 10, "storeroom has 10 enemies (9 small + giant): %d" % s.rats.size())
			var giants := 0
			var awake := 0
			for r in s.rats:
				if r.kind == "giant": giants += 1
				if not r.dormant: awake += 1
			ok(giants == 1, "exactly one giant rat")
			ok(awake == 3, "only the 3 entrance rats start awake (%d)" % awake)
			ok(not s.feet_blocked(s.spawns["entry"]["pos"]), "storeroom entry spot is free")
			ok(s.rats_flee == false and snap["town"].rats_flee == true, "storeroom rats never flee, town rats still can")
			ok(s.groups["boss"]["aggro"] and s.groups["boss"]["radius"] <= 70.0, "boss group wakes only near the middle of the barn and all at once")
			_store_reach(s)
			snap["store"] = s
			snap["srat"] = s.rats[0]
			snap["srat_i"] = s.rats[0].plan_i
			s.rats[0].hit(999, Vector2.RIGHT, 0.0)    # kill an entrance rat here
			p.position = Vector2(320, 640)
			wait = 3
			step = 4
		4:
			var side_asleep := 0
			var boss_asleep := 0
			for r in main.world.rats:
				if r.group == "side" and r.dormant: side_asleep += 1
				if r.group == "boss" and r.dormant: boss_asleep += 1
			ok(side_asleep == 3 and boss_asleep == 4, "far groups still asleep at the lower room (%d,%d)" % [side_asleep, boss_asleep])
			p.position = Vector2(320, 560)
			wait = 3
			step = 5
		5:
			var side_awake := 0
			var boss_asleep := 0
			for r in main.world.rats:
				if r.group == "side" and not r.dormant: side_awake += 1
				if r.group == "boss" and r.dormant: boss_asleep += 1
			ok(side_awake == 3, "side group woke when entering the corridor (%d)" % side_awake)
			ok(boss_asleep == 4, "boss group still asleep (%d)" % boss_asleep)
			p.position = Vector2(320, 262)       # just inside the barn, near the gate: still outside the middle trigger
			wait = 3
			step = 6
		6:
			var boss_awake := 0
			for r in main.world.rats:
				if r.group == "boss" and not r.dormant: boss_awake += 1
			ok(boss_awake == 0, "boss group is still asleep near the gate of the barn (%d awake)" % boss_awake)
			p.position = Vector2(320, 214)       # the middle of the barn
			wait = 3
			step = 61
		61:
			var boss_awake := 0
			var charging := 0
			for r in main.world.rats:
				if r.group == "boss" and not r.dormant: boss_awake += 1
				if r.group == "boss" and r.state == "chase": charging += 1
			ok(boss_awake == 4, "whole boss group woke at once in the middle of the barn (%d)" % boss_awake)
			ok(charging == 4, "and all of them are charging immediately (%d)" % charging)
			# death inside the storeroom: the death screen (Stage 7j), which names the storeroom and offers the saves
			p.position = Vector2(320, 800)
			for r in main.world.rats: r._enter("return")
			p.hp = 1; p.inv_t = 0.0
			c.hurt_player(1, p.position + Vector2(10, 0))
			ok(p.dead, "hero fell in the storeroom")
			wait = 220
			step = 7
		7:
			ok(p.dead and main.death.open and paused, "the death screen is up after the fall and the game is paused (no getting up on the map)")
			ok(main.world.key == "storeroom", "still in the storeroom after falling")
			var want := Save.SLOTS.filter(func(sl): return Save.info(sl) != "") + ["new"]
			ok(main.death.place == "The Storeroom" and main.death.rows == want,
				"it says where he fell (%s) and lists the saves, the autosave first, then New game (%s)" % [main.death.place, str(main.death.rows)])
			get_up()                         # (the suite can't load a save: see suite.gd get_up)
			# leave through the exit door
			p.position = Vector2(320, 850)
			p.dir = "down"
			p.inv_t = 0.0
			wait = 3
			step = 8
		8:
			tap_interact()
			wait = 3
			step = 9
		9:
			if main.world.key == "town" and not snap.has("checked"):
				snap["checked"] = true
				var same := true
				for e in snap["frozen"]:
					if not is_instance_valid(e[0]) or e[0].hp != e[1] or e[0].state != e[2] or e[0].position.distance_to(e[3]) > 1.0 or e[0].alive != e[4]:
						same = false
				ok(same, "every town enemy (hp, state, position) is exactly as it was when we left")
			if main.travelling:
				return
			var t = main.world
			ok(t.key == "town" and t == snap["town"], "back in the SAME town map (not rebuilt)")
			ok(p.position.distance_to(Vector2(443, 392)) < 1.0, "hero stands outside the storeroom door (%s)" % str(p.position))
			ok(t.rats.size() >= snap["rats0"] - 1, "town enemy list kept (%d)" % t.rats.size())
			ok(not is_instance_valid(snap["rat"]) or not snap["rat"].alive, "the town rat I killed is still dead (that body)")
			ok(_alive_plan(t, snap["rat_i"]), "walking back in, a new rat stands at the killed one's home (respawn)")
			ok(c.rats_alive() == snap["alive_before"] + 1, "the town enemies alive are the ones left plus the one come back (%d)" % c.rats_alive())
			ok(c.rats == t.rats, "combat is attached to the town again")
			# death in town: the death screen again, naming the town (the hero stands just outside the storeroom door)
			p.hp = 1; p.inv_t = 0.0
			c.hurt_player(1, p.position + Vector2(10, 0))
			wait = 220
			step = 10
		10:
			ok(p.dead and main.death.open and main.world.key == "town", "fell in town, still in town, the death screen is up")
			ok(main.death.place == "Waystation Town" and (main.death.rows[0] == "auto" or Save.info("auto") == ""),
				"it names the town (%s), the autosave first if there is one (%s)" % [main.death.place, str(main.death.rows)])
			get_up()
			# go back in: the storeroom kept its dead rat and awake groups
			main.travel("storeroom", "entry")
			wait = 5
			step = 11
		11:
			if main.travelling:
				return
			var s = main.world
			ok(s == snap["store"], "storeroom is the same map as before")
			ok(not is_instance_valid(snap["srat"]) or not snap["srat"].alive, "storeroom rat I killed is still dead (that body)")
			ok(_alive_plan(s, snap["srat_i"]) and not s.dead_plan.has(snap["srat_i"]), "going back in, the killed entrance rat has come back (respawn)")
			var side_awake := 0
			for r in s.rats:
				if r.group == "side" and not r.dormant: side_awake += 1
			ok(side_awake == 3, "groups woken earlier stay awake")
			done()

# a living enemy on map lv that stands for its enemy_plan() row i
func _alive_plan(lv, i: int) -> bool:
	for r in lv.rats:
		if r.alive and r.plan_i == i:
			return true
	return false

# storeroom: every enemy home, the barn, both pens, the side room and the door are reachable from the entrance
func _store_reach(s) -> void:
	var seen := reachable(s, Vector2(320, 826))
	var bad := 0
	for r in s.rats:
		var near := false
		for dx in range(-8, 9, 4):
			for dy in range(-8, 9, 4):
				if reach(seen, r.home + Vector2(dx, dy)): near = true
		if not near:
			print("   unreachable: ", r.kind, " ", r.home); bad += 1
	ok(bad == 0, "all enemy spots reachable from the entrance")
	ok(reach(seen, Vector2(320, 200)), "the barn is reachable")
	ok(reach(seen, Vector2(130, 240)) and reach(seen, Vector2(510, 240)), "both southern pens are reachable")
	ok(reach(seen, Vector2(320, 150)), "the open sacks below the pile are reachable")
	ok(not reach(seen, Vector2(320, 95)), "the pile itself is solid")
	ok(reach(seen, Vector2(500, 440)), "the side room is reachable")
	ok(reach(seen, Vector2(320, 850)), "the exit door spot is reachable")

# ---------------------------------------------------------------- courtyard
func _courtyard() -> void:
	var p = main.player
	match step:
		0:
			var town = main.world
			ok(town.key == "town", "starts in the town")
			ok(not town.feet_blocked(town.spawns["castle"]["pos"]), "town: spot where you come back from the castle is free")
			ok(not town.bridge_exit.has_point(town.spawns["castle"]["pos"]), "town: that spot is outside the bridge door (no ping-pong)")
			ok(town.near_door().get("to", "") != "courtyard", "the bridge door is not an E door")
			snap["town"] = town
			p.position = Vector2(1150, 620)      # on the bridge, west of the door
			step = 1
			wait = 5
		1:
			ok(main.world.key == "town", "still in town while west of the door")
			p.position = Vector2(1188, 620)      # inside the door rect
			step = 2
			wait = 90
		2:
			ok(main.world.key == "courtyard", "walking into the bridge end loads the courtyard")
			ok(p.position.distance_to(Vector2(28, 310)) < 6.0, "arrived at the west end of the bridge " + str(p.position))
			ok(p.dir == "right", "facing the courtyard")
			ok(not main.travelling and not main.world.talking, "control returned after the fade")
			var w = main.world
			ok(w.npcs.size() == 3, "3 guards in the courtyard")
			ok(w.npc_by_id("cguard3") != null, "bridge guard exists")
			ok(w.chatter_for("cguard1").size() == 3, "guard chatter lines found")
			ok(main.combat.rats.size() == 0, "no enemies in the castle")
			ok(w.auto_door().is_empty(), "not standing in a door right after arriving")
			ok(p.cam.limit_right == 960 and p.cam.limit_bottom == 640, "camera limits match the courtyard")
			# everything important is reachable on foot
			var seen := reachable(w, w.spawn)
			ok(reach(seen, Vector2(540, 120)), "reach the foot of the gate")
			ok(reach(seen, Vector2(540, 266)), "reach the ring road north of the statue")
			ok(reach(seen, Vector2(540, 354)), "reach the ring road south of the statue")
			ok(reach(seen, Vector2(470, 308)), "reach the ring road west of the statue")
			ok(reach(seen, Vector2(610, 308)), "reach the ring road east of the statue")
			ok(reach(seen, Vector2(740, 300)), "reach the supplies east of the statue")
			ok(reach(seen, Vector2(370, 145)), "reach the fountain")
			ok(reach(seen, Vector2(836, 312)), "reach the front of the armoury")
			ok(reach(seen, Vector2(760, 160)), "reach the front of the colonnade")
			ok(not reach(seen, Vector2(540, 304)) and not reach(seen, Vector2(500, 308)), "cannot walk into the raised planter")
			ok(reach(seen, Vector2(800, 520)), "reach the south-east corner")
			ok(reach(seen, Vector2(300, 540)), "reach the south-west corner")
			ok(reach(seen, Vector2(300, 140)), "reach the north-west corner")
			ok(reach(seen, Vector2(250, 310)), "reach the gatehouse between the towers")
			ok(w.doors.size() == 2 and w.doors[1]["to"] == "hall", "the open gate is a door to the hall")
			ok(reach(seen, Vector2(540, 90)), "reach the inside of the gate tunnel")
			ok(not reach(seen, Vector2(540, 324)), "cannot walk through the statue")
			ok(not w.feet_blocked(Vector2(128, 310)), "bridge deck is walkable")
			ok(w.feet_blocked(Vector2(128, 288)) and w.feet_blocked(Vector2(128, 330)), "bridge rails block")
			# patrol routes are clear along every leg
			for n in w.npcs:
				for i in range(n.route.size()):
					var a: Vector2 = n.route[i]
					var b: Vector2 = n.route[(i + 1) % n.route.size()]
					var clear := true
					for s in range(0, 41):
						if w.feet_blocked(a.lerp(b, s / 40.0)):
							clear = false
					ok(clear, n.id + " leg " + str(i) + " is clear")
			snap["g1"] = w.npc_by_id("cguard1").position
			snap["g2"] = w.npc_by_id("cguard2").position
			snap["w"] = w
			wait = 240
			step = 3
		3:
			var w = snap["w"]
			ok(w.npc_by_id("cguard1").position.distance_to(snap["g1"]) > 8.0, "guard 1 walks his lap")
			ok(w.npc_by_id("cguard2").position.distance_to(snap["g2"]) > 8.0, "guard 2 walks his lap")
			ok(w.npc_by_id("cguard3").position.distance_to(Vector2(298, 352)) < 1.0, "bridge guard stays put")
			p.position = Vector2(60, 310)        # walk west off the bridge
			wait = 3
			step = 4
		4:
			ok(main.world.key == "courtyard", "still in the courtyard east of the door")
			p.position = Vector2(8, 310)
			wait = 90
			step = 5
		5:
			ok(main.world.key == "town", "walking west off the bridge returns to the town")
			ok(main.world == snap["town"], "same town map as before")
			ok(p.position.distance_to(Vector2(1156, 620)) < 6.0, "back at the town side of the bridge " + str(p.position))
			ok(p.dir == "left", "facing west, away from the castle")
			wait = 20
			step = 6
		6:
			ok(main.world.key == "town", "no ping-pong back into the courtyard")
			p.position = Vector2(1188, 620)      # second visit: same courtyard, people not duplicated
			wait = 90
			step = 7
		7:
			ok(main.world.key == "courtyard", "second visit loads the courtyard again")
			ok(main.world.npcs.size() == 3, "guards not duplicated on the second visit")
			done()

# ---------------------------------------------------------------- great hall and the king scene
func _hall() -> void:
	var p = main.player
	var d = main.dialogue
	match step:
		0:
			main.travel("courtyard", "bridge")
			wait = 80
			step = 1
		1:
			ok(main.world.key == "courtyard", "in the courtyard")
			p.position = Vector2(540, 128)
			wait = 4
			step = 2
		2:
			ok(main.world.key == "courtyard", "standing below the gate does nothing")
			p.position = Vector2(540, 92)       # inside the tunnel mouth
			wait = 90
			step = 3
		3:
			var h = main.world
			ok(h.key == "hall", "walking into the open gate loads the great hall")
			ok(p.position.distance_to(Vector2(360, 716)) < 6.0, "arrived at the hall entrance " + str(p.position))
			ok(p.dir == "up", "facing the throne")
			ok(h.npcs.size() == 5, "king, two royal guards, servant and scholar")
			ok(h.npc_by_id("king") != null and not h.npc_by_id("king").talk, "king is not talkable before the scene")
			ok(not h.intro_done and h.scene_state == 0, "scene not started yet")
			ok(main.combat.rats.size() == 0, "no enemies in the hall")
			var seen := reachable(h, h.spawn)
			ok(reach(seen, Vector2(360, 260)), "reach the foot of the steps")
			ok(reach(seen, Vector2(360, 180)), "reach the throne dais through the steps")
			ok(reach(seen, Vector2(120, 150)), "reach the west end of the dais")
			ok(reach(seen, Vector2(640, 150)), "reach the east end of the dais")
			ok(reach(seen, Vector2(190, 430)), "reach the dining side")
			ok(reach(seen, Vector2(586, 500)), "reach the library")
			ok(reach(seen, Vector2(540, 560)), "reach the library doorway")
			ok(not reach(seen, Vector2(360, 130)), "cannot walk through the throne")
			ok(not reach(seen, Vector2(130, 430)), "cannot walk through the dining table")
			ok(not reach(seen, Vector2(586, 458)), "cannot walk through the round table")
			ok(h.feet_blocked(Vector2(100, 206)) and h.feet_blocked(Vector2(620, 206)), "dais front face blocks (only the steps lead up)")
			ok(reach(seen, Vector2(200, 230)), "hall floor below the dais is reachable")
			p.position = Vector2(200, 300)       # outside the scene zone
			wait = 5
			step = 4
		4:
			ok(main.world.scene_state == 0, "no scene while outside the zone")
			p.position = Vector2(360, 270)       # inside the zone
			wait = 5
			step = 5
		5:
			var h = main.world
			ok(h.scene_state == 1, "entering the zone starts the scene")
			ok(h.talking and p.scripted, "control is locked")
			ok(h.king.shout_t > 0.0 and h.king.chat_text() == "Come forward.", "king calls out (floating line): " + h.king.chat_text())
			ok(not d.open, "the parchment box is not open yet")
			p.position.x = 340.0                 # simulate being off-centre; the walk must centre him
			wait = 330
			step = 6
		6:
			var h = main.world
			ok(h.scene_state == 3 or d.open, "hero walked up and the dialogue opened (state " + str(h.scene_state) + ")")
			ok(p.position.distance_to(Vector2(360, 174)) < 4.0, "hero stands in front of the throne " + str(p.position))
			ok(d.open and d.npc == h.king and paused, "parchment box open, game paused")
			ok(d.lines.size() == 4, "4 placeholder lines")
			var guard := 0
			while d.open and guard < 40:         # first press finishes the typewriter, second moves on
				d._advance()
				guard += 1
			ok(not d.open and not paused, "dialogue closed, game running again")
			wait = 3
			step = 7
		7:
			var h = main.world
			ok(h.intro_done, "scene marked as played")
			ok(not h.talking and not p.scripted and not p.lock, "control returned")
			ok(h.king.talk, "king is now talkable")
			ok(d._nearest_talkable() == h.king, "E would talk to the king")
			d._start(h.king)                     # second conversation = the normal NPC one
			ok(d.open and d.lines.size() == 2, "normal king conversation (2 lines)")
			var g2 := 0
			while d.open and g2 < 20:
				d._advance()
				g2 += 1
			p.position = Vector2(200, 300)       # walk away and come back: no second scene
			wait = 3
			step = 8
		8:
			p.position = Vector2(360, 270)
			wait = 20
			step = 9
		9:
			var h = main.world
			ok(h.scene_state == 4 and not h.talking and not p.scripted, "the scene does not play twice")
			p.position = Vector2(360, 785)       # leave through the south entrance
			wait = 90
			step = 10
		10:
			ok(main.world.key == "courtyard", "walking out of the entrance returns to the courtyard")
			ok(p.position.distance_to(Vector2(540, 128)) < 6.0, "back just below the gate " + str(p.position))
			ok(p.dir == "down", "facing into the courtyard")
			wait = 20
			step = 11
		11:
			ok(main.world.key == "courtyard", "no ping-pong back into the hall")
			done()
