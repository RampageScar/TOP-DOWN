extends RefCounted
# squad.gd - the hero's companions (Stage 7c). The squad is kept per era, never per map (the user's rule, design doc section 7): a
# companion of Era 1 never follows the hero into another era, and leaving an era sends every companion of it home.
# Each member has an order:
#   "follow"  stays with the hero out of a fight and moves on his own in one (rider.gd); every door brings him along (main.gd
#             _switch_level carries him to the new map), a fallen one too, still down
#   "wait"    holds his spot while the hero is on this map (and still shoots), even while he is hurt; a door brings him along again,
#             as "follow"
#   "home"    "Disband": he goes to his home spot in the era (MATES home) and stays in the squad; the hero passes him by when
#             changing maps. Talk to him there, or pick Follow in the Squad tab (then he catches up at the hero's next door).
#             Refused while the story still needs him (quest.gd NEEDS, checked in main.gd squad_order).
# This file only keeps who is in the squad and their orders; main.gd moves the companions' nodes between the maps.

# who can join, and what the Squad tab says about them. "person" = the PEOPLE id in dialogue.gd (name, portrait); "home" = where
# "Disband" sends him (map key, spot, and the place's name for the Squad tab); "stats" = the detail lines the Squad tab shows, two to a
# row (menu.gd _stat), "gear" = his equipment (menu.gd ICONS). His HP, focus and whether he has fallen live on his node (rider.gd).
const MATES := {
	"farnaka": {"person": "rider", "role": "Archer", "era": 1,
		"home": {"map": "hall", "pos": Vector2(388, 182), "name": "The Great Hall"},
		"stats": ["hp", "focus", "arrow_dmg", "shot_every"], "gear": ["bow"]},
}

var by_era := {}            # era -> [{"id": String, "node": Node, "order": "follow" | "wait" | "home"}]

func join(id: String, node) -> void:
	if has(id):
		return
	var era: int = MATES[id]["era"]
	if not by_era.has(era):
		by_era[era] = []
	by_era[era].append({"id": id, "node": node, "order": "follow"})

func has(id: String) -> bool:
	return not find(id).is_empty()

# a member by id or by its node ({} if none)
func find(who) -> Dictionary:
	var by_id: bool = who is String
	for era in by_era.keys():
		for m in by_era[era]:
			if (m["id"] == who) if by_id else (m["node"] == who):
				return m
	return {}

func node(id: String):
	var m := find(id)
	return m["node"] if not m.is_empty() else null

# the members of an era (only these ever appear while the hero is in it)
func current(era: int) -> Array:
	return by_era.get(era, [])

# the hero leaves an era: every companion of it goes home, whatever his order (no caller yet: there is one era so far). This is the
# story's own move, so it ignores quest.gd NEEDS: a quest must not let the hero leave an era while it still needs a companion.
func leave_era(era: int) -> void:
	for m in current(era):
		m["order"] = "home"
