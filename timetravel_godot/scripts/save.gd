extends RefCounted
# save.gd - the save slots: one autosave and four slots the player picks in the menu (Stage 7d, slots added after it). Each is a file in
# `dir`: user://save_auto.json, user://save_1.json .. save_4.json (on Windows, %APPDATA%\Godot\app_userdata\<project name>\).
# The autosave is written by main.gd when the hero rests, goes through a door, or the main objective moves on; the four slots only from
# the menu's System tab.
# Saved: the map, the hero's spot, facing, HP, stamina and focus, the weapon in hand (7l), his XP, level cap and weapon XP and caps (progress.gd state()), foes
# slain (in all and by kind), the quest (stage, flags, journal), the inventory, the squad (per era: who, their order, HP, focus and whether they have fallen;
# never a map or a spot: a fallen one is put back lying beside the hero), and each
# map's own state (level.save_state(): which planned enemies are dead, the living ones a map added during play, and the map's scripted
# bits). Living enemies come back at home at full health (the design's healing rule). The hero's level and maximums are not saved: they
# follow from his XP (progress.gd).
# main.gd decides when a save may be made (save_block) and rebuilds the game from one (a reload, then main._ready).
# JSON turns every number into a float and every key into a string: read() hands the raw data on, and the apply_* helpers convert.
# A save from an older VERSION is brought up to date as it is read (_upgrade), so the player's slots survive a change of format.

const Quest = preload("res://scripts/quest.gd")

const VERSION := 6
# version 1 -> 2 (Stage 7e): hearts became HP (one heart = 20 HP), and these items were renamed
const V1_HEART := 20
const V1_IDS := {"flatbread": "bread", "pomegranate": "apple", "silver": "coins"}
# version 2 -> 3 (Stage 7f): the hero's XP was kill XP only; story steps, side quests and journal entries now give XP too, so the ones
# already done are added (the weapons start at 0 and the caps at their start)
# version 3 -> 4 (Stage 7i): companions can be hurt and have focus; each squad member gets "hp" (-1 = full), "focus" and "down"
# version 4 -> 5 (Stage 7k): the foes slain are also counted by kind ("kills_by", the journal's Enemies list)
# version 5 -> 6 (Stage 7l): the weapon in hand ("weapon" in the hero block; the side quests' counters are in the quest flags)
const SLOTS := ["auto", "1", "2", "3", "4"]
static var dir := "user://"      # a variable only so the test suites and check scripts can point it at a scratch folder

static func path_for(slot: String) -> String:
	return dir + "save_%s.json" % slot

static func exists(slot: String) -> bool:
	return FileAccess.file_exists(path_for(slot))

static func write(main, slot: String) -> bool:
	var f := FileAccess.open(path_for(slot), FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(snapshot(main), "\t"))
	f.close()
	return true

# {} if there is no save in the slot, it can't be read, or it is from a version this game can't bring up to date
static func read(slot: String) -> Dictionary:
	if not exists(slot):
		return {}
	var f := FileAccess.open(path_for(slot), FileAccess.READ)
	if f == null:
		return {}
	var v = JSON.parse_string(f.get_as_text())
	f.close()
	if not (v is Dictionary):
		return {}
	return _upgrade(v)

# an older save brought up to VERSION, step by step ({} if it is from an unknown version)
static func _upgrade(v: Dictionary) -> Dictionary:
	if int(v.get("version", 0)) == 1:
		var h: Dictionary = v["hero"]
		h["hp"] = int(h["hp"]) * V1_HEART
		var inv := {}
		for id in v["inv"].keys():
			inv[V1_IDS.get(id, id)] = v["inv"][id]
		v["inv"] = inv
		v["version"] = 2
	if int(v.get("version", 0)) == 2:
		var flags: Dictionary = v["quest"]["flags"]
		var xp := int(v["hero"]["xp"])
		for s in Quest.STEPS:
			if s["done"] != "" and flags.get(s["done"], false):
				xp += s.get("xp", 0)
		for id in Quest.SIDE.keys():
			if Quest.SIDE[id]["done"] != "" and flags.get(Quest.SIDE[id]["done"], false):
				xp += Quest.SIDE[id].get("xp", 0)
		xp += Quest.LOG_XP * v["quest"]["journal"].size()
		v["hero"]["xp"] = xp
		v["version"] = 3
	if int(v.get("version", 0)) == 3:
		for era in v.get("squad", {}).keys():
			for m in v["squad"][era]:
				m.merge({"hp": -1, "focus": 0, "down": false})
		v["version"] = 4
	if int(v.get("version", 0)) == 4:
		v["kills_by"] = {}         # the old total can't be split by kind, so the journal's Enemies list starts empty
		v["version"] = 5
	if int(v.get("version", 0)) == 5:
		v["hero"]["weapon"] = "unarmed"       # there was no sword before 7l
		v["version"] = 6
	return v if int(v.get("version", 0)) == VERSION else {}

# one line for the menu's System tab: where and when the slot was saved ("" if it is empty)
static func info(slot: String) -> String:
	var d := read(slot)
	if d.is_empty():
		return ""
	return "%s, %s" % [d.get("place", d.get("map", "?")), String(d.get("saved_at", "")).replace("T", " ").left(16)]

# the one-slot save of Stage 7d (save.json) becomes slot 1, once
static func migrate() -> void:
	var old := dir + "save.json"
	if FileAccess.file_exists(old) and not exists("1"):
		DirAccess.rename_absolute(old, path_for("1"))

static func snapshot(main) -> Dictionary:
	var p = main.player
	var hero: Dictionary = main.progress.state()
	hero.merge({"hp": p.hp, "stamina": p.stamina, "focus": p.focus, "weapon": main.combat.weapon})
	var sq := {}
	for era in main.squad.by_era.keys():
		var list := []
		for m in main.squad.by_era[era]:
			var n = m["node"]
			list.append({"id": m["id"], "order": m["order"], "hp": n.hp, "focus": n.focus, "down": n.down})
		sq[str(era)] = list
	var maps := {}
	for key in main.levels.keys():
		maps[key] = main.levels[key].save_state()
	for key in main.saved_maps.keys():          # maps not visited since the last load keep the state they were saved with
		if not maps.has(key):
			maps[key] = main.saved_maps[key]
	return {
		"version": VERSION,
		"saved_at": Time.get_datetime_string_from_system(false, true),
		"map": main.world.key,
		"place": main.world.place_at(p.position),
		"pos": [p.position.x, p.position.y],
		"dir": p.dir,
		"hero": hero,
		"kills": main.combat.kills,
		"kills_by": main.combat.kills_by,
		"quest": {"stage": main.quest.stage, "flags": main.quest.flags, "journal": main.quest.journal},
		"inv": main.inv.counts,
		"squad": sq,
		"maps": maps,
	}

# ---------------------------------------------------------------- putting a save back (main.gd _ready, in this order)
static func apply_hero(player, progress, d: Dictionary) -> void:
	var h: Dictionary = d["hero"]
	progress.load_state(h)          # the level, and from it the maximums the bars are clamped to
	player.hp = clampi(int(h["hp"]), 1, player.max_hp)
	player.stamina = clampi(int(h.get("stamina", player.max_stamina)), 0, player.max_stamina)
	player.focus = clampi(int(h.get("focus", player.max_focus)), 0, player.max_focus)
	player.position = Vector2(d["pos"][0], d["pos"][1])
	player.dir = d.get("dir", "down")

static func apply_progress(quest, inv, d: Dictionary) -> void:
	var q: Dictionary = d["quest"]
	quest.stage = int(q["stage"])
	quest.flags = q["flags"].duplicate()
	quest.journal = []
	for id in q["journal"]:
		quest.journal.append(String(id))
	inv.counts = {}
	for id in d["inv"].keys():
		inv.counts[id] = int(d["inv"][id])

# the squad's saved members per era: [[era, id, order, hp (-1 = full), focus, down]...] (main.gd rebuilds their nodes)
static func squad_list(d: Dictionary) -> Array:
	var out := []
	for era in d.get("squad", {}).keys():
		for m in d["squad"][era]:
			out.append([int(era), String(m["id"]), String(m["order"]), int(m["hp"]), int(m["focus"]), bool(m["down"])])
	return out

# a map's saved state with its numbers made whole again
static func map_state(d: Dictionary, key: String) -> Dictionary:
	var s: Dictionary = d.get("maps", {}).get(key, {})
	if s.is_empty():
		return {}
	var dead := []
	for i in s.get("dead", []):
		dead.append(int(i))
	s["dead"] = dead
	return s
