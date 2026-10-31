extends RefCounted
# progress.gd - how the hero grows (Stage 7f, the user's decisions of 2026-10-28; design doc section 9). Two kinds of XP:
#  - the hero's XP and level. XP comes from kills (combat.gd rat_killed; a foe below the hero's level gives less, kill_xp), main-story
#    steps and side quests (quest.gd "xp") and new journal entries (quest.gd LOG_XP). Each level raises max HP, stamina and focus
#    (PER_LEVEL) and fills them;
#  - each weapon's own XP and level (WEAPONS), from using that weapon on an enemy (combat.gd WEAPON_XP). A weapon level makes the weapon
#    stronger; it never unlocks a move (moves come from teachers, section 13).
# The rare finds carried (items.gd "bonus", Stage 7g) add to the maximums too.
# Both stop at a cap (START_CAP, WEAPON_START_CAP) that only teachers raise (raise_cap, raise_weapon_cap; no teacher yet). At a cap XP
# stops counting.
# Saved (save.gd): xp, cap, wxp, wcap. The level is worked out from xp, and the hero's maximums from the level, so neither is saved. A
# weapon an older save doesn't know (the spear and the bow, Stage 8e) starts at 0 XP and the start cap (load_state).
# main.gd makes one (main.progress) and shows "Level N!" over the hero on `leveled`; the HUD shows the toasts in `news`.

const Items = preload("res://scripts/items.gd")

signal leveled(level: int)
signal weapon_leveled(w: String, level: int)

const START_CAP := 10
const WEAPON_START_CAP := 5
# XP from one level to the next: STEP_BASE + STEP_GROW x (level - 1). The totals are 100, 250, 450, 700, 1000, 1350, 1750, 2200, 2700.
const STEP_BASE := 100
const STEP_GROW := 50
# what each level above the first adds to the hero's maximums (all three fill on a level-up)
const PER_LEVEL := {"hp": 10, "stamina": 10, "focus": 5}
# kill XP from a foe below the hero's level: x (1 - KILL_CUT per level between them), never under KILL_MIN of it. At or above: all of it.
const KILL_CUT := 0.25
const KILL_MIN := 0.1
# The weapons, in the order the Player tab lists them. "xp": the weapon-XP totals for levels 2, 3, 4 and 5; "per": what each level above
# the first adds, keyed by a move's "lv" (combat.gd: unarmed punch / kick damage; sword slash / thrust; spear jab / thrust; bow arrow /
# aimed; lasso: px of reach, s off its cooldowns); "key": how it is used in play; "item": the inventory item that is this weapon (it is
# listed here instead of under the items), "" for none. Each weapon's moves and strings are combat.gd WEAPON_KIT (the Combos tab).
const WEAPONS := {
	"unarmed": {"name": "Unarmed", "key": "LMB / RMB", "item": "", "xp": [30, 80, 150, 250], "per": {"punch": 1, "kick": 2},
		"desc": "Punches, kicks and knees. Every light blow that lands on a foe teaches a little, every heavy one a little more. The strings are in the Combos tab."},
	"lasso": {"name": "Lasso", "key": "Q", "item": "lasso", "xp": [15, 40, 80, 130], "per": {"range": 8, "cool": 0.15},
		"desc": "Plaited rope, Q with the fists out. Tap Q to pull a small foe in and stun it; heavy foes resist. Hold Q, then let go: the strong lasso (focus) reaches further and pulls in even a bandit."},
	# Stage 7l: Datis's side quest gives it (the user's decision). Key 1 goes through the weapons carried.
	"sword": {"name": "Sword", "key": "1", "item": "sword", "xp": [40, 100, 180, 300], "per": {"slash": 2, "thrust": 3},
		"desc": "The garrison's old sword, put together again by Datis. Heavier than fists: more damage, more stamina a swing. Q: a flurry of thrusts that leaves foes bleeding."},
	# Stage 8e: bought at Nidu's stall (items.gd "price")
	"spear": {"name": "Spear", "key": "1", "item": "spear", "xp": [40, 100, 180, 300], "per": {"jab": 1, "thrust": 2},
		"desc": "The longest reach, on a narrow line: keep foes at the point. Q: the shaft swung right round you, hitting everyone near."},
	"bow": {"name": "Bow", "key": "1", "item": "bow", "xp": [40, 100, 180, 300], "per": {"arrow": 1, "aimed": 3},
		"desc": "Quick arrows on the light attack; hold the heavy attack to draw, aim with the move keys, let go to shoot. Q: a heavy arrow that goes through every foe in its line."},
}
const WEAPON_ORDER := ["unarmed", "sword", "spear", "bow", "lasso"]
const NEWS_TIME := 3.0      # seconds a toast stays ("+40 XP", "Level 3: ...")

var player              # player.gd: its maximums are set here (apply_max)
var inv                 # inventory.gd (Stage 7g: rare finds carried add to the maximums)
var xp := 0             # all the XP ever earned (stops at the cap's total)
var level := 1          # worked out from xp
var cap := START_CAP
var wxp := {"unarmed": 0, "sword": 0, "spear": 0, "bow": 0, "lasso": 0}
var wcap := {"unarmed": WEAPON_START_CAP, "sword": WEAPON_START_CAP, "spear": WEAPON_START_CAP, "bow": WEAPON_START_CAP,
	"lasso": WEAPON_START_CAP}
var news: Array = []     # [{"text": String, "at": msec}], oldest first: the HUD's toasts

# ---------------------------------------------------------------- the hero's level
# the XP total needed to reach level `l`
static func total_for(l: int) -> int:
	var t := 0
	for k in range(1, l):
		t += STEP_BASE + STEP_GROW * (k - 1)
	return t

func _level_for(x: int) -> int:
	var l := 1
	while l < cap and x >= total_for(l + 1):
		l += 1
	return l

func at_cap() -> bool:
	return level >= cap

# 0..1: how far into the current level (1 at the cap)
func frac() -> float:
	if at_cap():
		return 1.0
	var a := total_for(level)
	return float(xp - a) / float(total_for(level + 1) - a)

# toast = true: a HUD toast "+N XP" (story steps, side quests, the journal; a kill shows its own floating number instead)
func add_xp(n: int, toast := false) -> void:
	if n <= 0 or at_cap():
		return
	xp = mini(xp + n, total_for(cap))
	if toast:
		_news("+%d XP" % n)
	var l := _level_for(xp)
	if l > level:
		level = l
		apply_max()
		player.refill()
		_news("Level %d: max HP %d, stamina %d, focus %d" % [level, player.max_hp, player.max_stamina, player.max_focus])
		leveled.emit(level)

# the XP for killing a foe of level foe_lv worth `base` XP: less when the hero is above it (story XP is never cut)
func kill_xp(base: int, foe_lv: int) -> int:
	if level <= foe_lv:
		return base
	return maxi(1, roundi(base * maxf(KILL_MIN, 1.0 - KILL_CUT * (level - foe_lv))))

# only a teacher calls this (none yet): the hero can go on to level `to`
func raise_cap(to: int) -> void:
	cap = maxi(cap, to)

# max HP, stamina and focus from the level and the rare finds carried (items.gd "bonus", Stage 7g; main.gd calls this again whenever
# the inventory changes). The bars never end up over their maximum.
func apply_max() -> void:
	var b := carried_bonus()
	player.max_hp = player.BASE_HP + PER_LEVEL["hp"] * (level - 1) + b["hp"]
	player.max_stamina = player.BASE_STAMINA + PER_LEVEL["stamina"] * (level - 1) + b["stamina"]
	player.max_focus = player.BASE_FOCUS + PER_LEVEL["focus"] * (level - 1) + b["focus"]
	player.hp = mini(player.hp, player.max_hp)
	player.stamina = mini(player.stamina, player.max_stamina)
	player.focus = mini(player.focus, player.max_focus)

# what the rare finds carried add: {"hp": .., "stamina": .., "focus": ..}
func carried_bonus() -> Dictionary:
	var b := {"hp": 0, "stamina": 0, "focus": 0}
	if inv == null:
		return b
	for id in inv.counts.keys():
		var add: Dictionary = Items.info(id).get("bonus", {})
		for k in add.keys():
			b[k] += int(add[k])
	return b

# ---------------------------------------------------------------- weapons
# the weapon's level: one more for every "xp" total reached, up to its cap
func wlevel(w: String) -> int:
	var l := 1
	for t in WEAPONS[w]["xp"]:
		if wxp[w] < t:
			break
		l += 1
	return mini(l, wtop(w))

# the highest level the weapon can reach now: its cap, or the last level its data has
func wtop(w: String) -> int:
	return mini(wcap[w], WEAPONS[w]["xp"].size() + 1)

# the weapon-XP total for level l (0 for level 1)
func wtotal(w: String, l: int) -> int:
	return 0 if l <= 1 else WEAPONS[w]["xp"][l - 2]

# 0..1: how far into the weapon's current level (1 at its top)
func wfrac(w: String) -> float:
	var l := wlevel(w)
	if l >= wtop(w):
		return 1.0
	return float(wxp[w] - wtotal(w, l)) / float(wtotal(w, l + 1) - wtotal(w, l))

func add_wxp(w: String, n: int) -> void:
	var l := wlevel(w)
	if n <= 0 or l >= wtop(w):
		return
	wxp[w] = mini(wxp[w] + n, wtotal(w, wtop(w)))
	var l2 := wlevel(w)
	if l2 > l:
		_news("%s Lv %d: %s" % [WEAPONS[w]["name"], l2, bonus_text(w, l2)])
		weapon_leveled.emit(w, l2)

# what the weapon's levels add now: bonus("unarmed", "kick") = extra kick damage, bonus("lasso", "range") = extra px of reach
func bonus(w: String, what: String) -> float:
	return WEAPONS[w]["per"][what] * (wlevel(w) - 1)

# the bonus at level l in words ("punches +1, kicks +2"; "reach +8, cooldown -0.15 s"), for the toasts and the Player tab
func bonus_text(w: String, l: int) -> String:
	var per: Dictionary = WEAPONS[w]["per"]
	var k := l - 1
	match w:
		"unarmed":
			return "punches +%d, kicks +%d" % [per["punch"] * k, per["kick"] * k]
		"sword":
			return "slashes +%d, thrusts +%d" % [per["slash"] * k, per["thrust"] * k]
		"spear":
			return "jabs +%d, thrusts +%d" % [per["jab"] * k, per["thrust"] * k]
		"bow":
			return "arrows +%d, aimed +%d" % [per["arrow"] * k, per["aimed"] * k]
		"lasso":
			return "reach +%d, cooldown -%.2f s" % [per["range"] * k, per["cool"] * k]
	return ""

# only a teacher calls this (none yet): the weapon can go on to level `to`
func raise_weapon_cap(w: String, to: int) -> void:
	wcap[w] = maxi(wcap[w], to)

# ---------------------------------------------------------------- toasts
func _news(t: String) -> void:
	news.append({"text": t, "at": Time.get_ticks_msec()})

# toasts still young enough to show (and forget the old ones)
func recent() -> Array:
	var now := Time.get_ticks_msec()
	while not news.is_empty() and now - news[0]["at"] > NEWS_TIME * 1000.0:
		news.pop_front()
	return news

# ---------------------------------------------------------------- saving (save.gd)
func state() -> Dictionary:
	return {"xp": xp, "cap": cap, "wxp": wxp.duplicate(), "wcap": wcap.duplicate()}

# a save's hero block (JSON makes every number a float); the maximums follow
func load_state(h: Dictionary) -> void:
	cap = int(h.get("cap", START_CAP))
	xp = mini(int(h.get("xp", 0)), total_for(cap))
	level = _level_for(xp)
	for w in WEAPONS.keys():
		wcap[w] = int(h.get("wcap", {}).get(w, WEAPON_START_CAP))
		wxp[w] = int(h.get("wxp", {}).get(w, 0))
	apply_max()
