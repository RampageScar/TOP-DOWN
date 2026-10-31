extends RefCounted
# quest.gd - the story's progress: the main thread's steps (data), the optional objectives, the story flags and the journal.
# Maps and conversations report what happened with note(event); the objective is the step after the furthest one whose event has
# happened, so going out of order (into the cave before meeting Datis or the king) still shows the right objective, and it never goes back.
# flags: things that happened. The step events below, plus:
#   rider_joined   the freed rider was with the hero when the chief fell (false if he stayed caged)
#   saw_cage       the hero has been in the cave's jail (shows the optional "free the rider")
#   rider_freed    the cage was opened
#   saw_prints / found_object / found_log   the ruins (Stage 7b)
#   found_log_2    the second torn page, by the scorpions' den in the ruins (Stage 7j; optional, not part of ruins_searched)
#   read_tablet    the clay tablet on Utana's desk in the hall's library (7j)
#   found_note     the rider's note in the cave's jail (7j)
#   talked_<id>_<stage>   a conversation's "first" version has been had (dialogue.gd)
#   sword_asked / sword_parts / sword_given / bounty_met / bounty_paid   Datis's sword and his bandit bounty (Stage 7l)
#   bounty_kills   a NUMBER, not a flag: the band's members cut down since the bounty began (count_kill)
# The words of the journal (logs, clues and records) are in dialogue.gd LOGS; this file only keeps which ones were found, in order.
# XP (Stage 7f): a step's or a side quest's "xp", and LOG_XP for each new journal entry, go to progress.gd the first time (never cut by
# level, unlike kill XP). A load sets the flags directly, so nothing is given twice.

const THREAD := "The King's Lost Riders"      # the main thread's title in the Quests tab
const LOG_XP := 20                            # XP for each new journal entry (a log or a clue)

# the main thread, in order: the objective text shown while this step is the current one, the event that completes it, and its XP
const STEPS := [
	{"text": "", "done": "met_datis", "xp": 20},                                # stage 0: Datis wears the "?" instead
	{"text": "Find King Rostam", "done": "met_king", "xp": 30},                 # 1
	{"text": "Find the band's hideout in the north-east hills", "done": "cave_entered", "xp": 40},
	{"text": "Defeat the band's chief", "done": "chief_down", "xp": 100},
	{"text": "Cut the captain down", "done": "captain_found", "xp": 40},
	{"text": "Return to King Rostam", "done": "return_done", "xp": 100},        # (the cave sends the hero straight there)
	{"text": "Search the ancient ruins north of the town", "done": "ruins_searched", "xp": 80},
	{"text": "The trail goes on...", "done": ""},                               # the end of the Era 1 slice so far
]

# optional objectives: shown once `show` has happened, ticked on `done` (its "xp" given), missed on `fail` (if it came first; "" never).
# Since 7l a row may also have
#   "items" (ids to carry: shown as "(n/2)"; once all are carried check_items() notes "items_done", and the line becomes "items_text"),
#   "count" (a number kept in flags), "kinds" (the enemy kinds that count, count_kill), "of" (the goal: shown as "(n/10)"), and "met"
#   (noted at the goal; the line becomes "met_text").
# Datis's two (the user's quest, Stage 7l): find the sword's parts in the storeroom, then cut down 10 of the band for him.
const SIDE := {
	"free_rider": {"text": "Free the caged rider", "show": "saw_cage", "done": "rider_freed", "fail": "captain_found", "xp": 60},
	"sword": {"text": "Find the blade and hilt of Datis's sword in the storeroom", "show": "sword_asked", "done": "sword_given",
		"fail": "", "xp": 60, "items": ["sword_blade", "sword_hilt"], "items_done": "sword_parts",
		"items_text": "Bring the blade and hilt to Datis"},
	"bounty": {"text": "Defeat the band's men for Datis", "show": "sword_given", "done": "bounty_paid", "fail": "", "xp": 100,
		"count": "bounty_kills", "kinds": ["bandit", "slinger", "chief"], "of": 10, "met": "bounty_met",
		"met_text": "Return to Datis for your reward"},
}

# companions the story still needs: from flag `from` until flag `until` the squad order Disband is refused (menu, talk, any map),
# with `why` as the reason. A later escort or guide quest adds a row here. Nothing to save: it follows from the flags.
const NEEDS := [
	{"mate": "farnaka", "from": "rider_freed", "until": "return_done", "why": "escort him safely to the king first"},
]

const JOURNAL_TOAST := 2.5    # seconds a new journal entry shows in the HUD

var stage := 0
var flags := {}
var journal: Array = []       # LOGS ids, in the order they were found
var journal_at := -100000     # ticks when the last entry was added (HUD toast)
var changed_at := -100000     # ticks when the stage last changed (HUD flashes the tracker)
var progress                  # progress.gd (set by main.gd): where the XP of steps, side quests and journal entries goes
var inv                       # inventory.gd (set by main.gd): what an objective's "items" are counted against

func set_stage(s: int) -> void:
	if s == stage:
		return
	stage = s
	changed_at = Time.get_ticks_msec()

# something happened: note it, and move the objective on if a step is now done (never back)
func note(event: String) -> void:
	if event == "":
		return
	var first: bool = not flags.get(event, false)
	flags[event] = true
	var s := 0
	for i in range(STEPS.size()):
		if STEPS[i]["done"] != "" and flags.get(STEPS[i]["done"], false):
			s = i + 1
	if s > stage:
		set_stage(s)
	if first:
		_reward(event)

# the XP of the step or side quest that `event` completes (a side quest already missed gives none)
func _reward(event: String) -> void:
	if progress == null:
		return
	var n := 0
	for st in STEPS:
		if st["done"] == event:
			n += st.get("xp", 0)
	for id in SIDE.keys():
		if SIDE[id]["done"] == event and not flags.get(SIDE[id]["fail"], false):
			n += SIDE[id].get("xp", 0)
	progress.add_xp(n, true)

func text() -> String:
	return STEPS[stage]["text"] if stage < STEPS.size() else ""

# "hidden" | "open" | "done" | "missed"
func side_state(id: String) -> String:
	var q: Dictionary = SIDE[id]
	if flags.get(q["done"], false):
		return "done"
	if flags.get(q["fail"], false):
		return "missed"
	return "open" if flags.get(q["show"], false) else "hidden"

# the optional objectives to show in the HUD (open ones only)
func side_open() -> Array:
	var out := []
	for id in SIDE.keys():
		if side_state(id) == "open":
			out.append(side_label(id))
	return out

# an optional objective's line, with how far along it is: "(1/2)", "(4/10)", or its next words once the goal is reached
func side_label(id: String) -> String:
	var q: Dictionary = SIDE[id]
	if q.has("items"):
		if flags.get(q["items_done"], false):
			return q["items_text"]
		var have := 0
		for it in q["items"]:
			if inv != null and inv.has(it):
				have += 1
		return "%s (%d/%d)" % [q["text"], have, q["items"].size()]
	if q.has("count"):
		if flags.get(q["met"], false):
			return q["met_text"]
		return "%s (%d/%d)" % [q["text"], int(flags.get(q["count"], 0)), q["of"]]
	return q["text"]

# the inventory changed (main.gd): an open objective whose items are all carried notes its "items_done"
func check_items() -> void:
	for id in SIDE.keys():
		var q: Dictionary = SIDE[id]
		if not q.has("items") or flags.get(q["items_done"], false) or flags.get(q["done"], false) or inv == null:
			continue
		var all := true
		for it in q["items"]:
			all = all and inv.has(it)
		if all:
			note(q["items_done"])

# an enemy of `kind` was cut down (combat.gd rat_killed): it counts toward every open objective that wants that kind
func count_kill(kind: String) -> void:
	for id in SIDE.keys():
		var q: Dictionary = SIDE[id]
		if not q.has("count") or side_state(id) != "open" or flags.get(q["met"], false) or not kind in q["kinds"]:
			continue
		flags[q["count"]] = int(flags.get(q["count"], 0)) + 1
		if int(flags[q["count"]]) >= q["of"]:
			note(q["met"])

# why companion `mate` can't be disbanded right now ("" if he can)
func needed(mate: String) -> String:
	for n in NEEDS:
		if n["mate"] == mate and flags.get(n["from"], false) and not flags.get(n["until"], false):
			return n["why"]
	return ""

func add_journal(id: String) -> void:
	if not journal.has(id):
		journal.append(id)
		journal_at = Time.get_ticks_msec()
		if progress != null:
			progress.add_xp(LOG_XP, true)
