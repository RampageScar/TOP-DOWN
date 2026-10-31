extends RefCounted
# items.gd - every item the hero can carry (data), its code-drawn icon, and how an item lying on the ground looks (pickup()).
# inventory.gd counts them; the menu and the HUD draw them; level.gd lays them on the maps (pickups and drops).
# The healing tiers and the money were decided with the user (2026-10-28): Bread (the lowest), Apple, a small and a large potion (Stage
# 7g), each tier more HP per coin; Coins (plain yellow coins for now; each era may get its own later); rare finds from the bosses, which
# help while carried and can be sold. Adding an item = one ITEMS entry + one ART entry.
#
# Stage 7i (the user's decisions): focus potions (the game's "mana" is focus) and the Reviving Potion, which only ever gets a fallen
# companion back up (the hero is never revived: he falls). Food and potions can be used on the hero or given to a companion (main.gd
# use_item).
#
# ITEMS: id -> {"name", "kind", "desc", "heal" (food: HP it restores), "focus" (food: focus it restores), "cure" (food: true = ends a poison), "revive" (food: true = gets a
#   fallen companion up, with combat.gd RIDER.revive % of his HP), "use" (food: "eat" (default) or "drink"), "key" (tool: the key
#   that uses it in play), "price" (what a shop asks, shop.gd), "bonus" (rare: what it adds to the hero's maximums while carried,
#   progress.gd apply_max), "sell" (rare: what a shop pays for it)}
#   kind: "tool" (always carried, used in play), "food" (E in the inventory eats or drinks it, or gives it to a companion),
#   "valuable" (coins, loot), "rare" (a boss's keepsake), "story" (clues, keys)

const ITEMS := {
	"lasso": {"name": "Lasso", "kind": "tool", "key": "Q",
		"desc": "A coil of plaited rope. With the fists out, tap Q: it pulls a small animal to you and stuns it; heavy foes resist. Hold Q, then let go: the strong lasso (focus) reaches further and pulls in even a bandit."},
	# Stage 7l: Datis's sword (his side quest; the user asked for a plain "Sword"), and the two broken parts found in the storeroom
	"sword": {"name": "Sword", "kind": "tool", "key": "1",
		"desc": "A straight iron blade on a new grip, put together by Datis from the pieces you found. Press 1 to take it in hand."},
	# Stage 8e: the spear and the bow, sold at Nidu's stall and costly on purpose (the user's prices). Their moves are combat.gd's.
	# The gold butt is the counterweight the king's spearmen carried; the bow is the short composite bow of the Persian archers.
	"spear": {"name": "Spear", "kind": "tool", "key": "1", "price": 800,
		"desc": "An ash shaft taller than you, with a leaf-shaped iron head and a round gold counterweight at the butt, like the king's guards carry. The longest reach of any weapon. Press 1 to take it in hand."},
	"bow": {"name": "Bow", "kind": "tool", "key": "1", "price": 1200,
		"desc": "A short composite bow of horn, wood and sinew, and a deep quiver you never seem to empty. Quick arrows, or hold the heavy attack to draw and aim. Press 1 to take it in hand."},
	"bread": {"name": "Bread", "kind": "food", "heal": 10, "price": 10,
		"desc": "Baked this morning against the hot wall of a clay oven. Restores 10 HP."},
	"apple": {"name": "Apple", "kind": "food", "heal": 30, "price": 25,
		"desc": "Crisp and sweet, from the orchards along the river. Restores 30 HP."},
	# the potions (placeholder words): a healer's draught in a stoppered flask
	"small_potion": {"name": "Small Potion", "kind": "food", "use": "drink", "heal": 75, "price": 50,
		"desc": "A small clay flask sealed with wax: a healer's draught of herbs and honey. Restores 75 HP."},
	"large_potion": {"name": "Large Potion", "kind": "food", "use": "drink", "heal": 150, "price": 80,
		"desc": "A glazed flask of the same draught, brewed stronger. Restores 150 HP."},
	# focus potions (placeholder words): a bitter herb tea, no magic. Like the healing tiers, the larger one is the better buy.
	"small_focus": {"name": "Small Focus Potion", "kind": "food", "use": "drink", "focus": 25, "price": 30,
		"desc": "A little flask of bitter tea, mountain herbs steeped with honey. It clears a tired head. Restores 25 focus."},
	"large_focus": {"name": "Large Focus Potion", "kind": "food", "use": "drink", "focus": 50, "price": 50,
		"desc": "A larger flask of the same bitter tea, steeped long and strong. Restores 50 focus."},
	# the user's request (Stage 7k): a cheap cure for the scorpion's poison. Vinegar with honey and herbs (oxymel) was an old remedy.
	"antidote": {"name": "Antidote", "kind": "food", "use": "drink", "cure": true, "price": 20,
		"desc": "A slim flask of vinegar, honey and bitter herbs. It burns going down, and stops a sting's poison at once."},
	# costly on purpose (the user's decision): it only gets a fallen companion up, and with little strength
	"revive_potion": {"name": "Reviving Potion", "kind": "food", "use": "drink", "revive": true, "price": 200,
		"desc": "A healer's strong cordial of wine, myrrh and herbs, with a strip of linen to bind a wound. For a fallen companion: it gets him back on his feet, barely."},
	"coins": {"name": "Coins", "kind": "valuable",
		"desc": "Yellow coins. Every trader on the road takes them."},
	# rare finds (placeholders): each boss leaves one. Carnelian beads and gold armlets with animal-head ends are both known from
	# Achaemenid Persia.
	"carnelian_necklace": {"name": "Carnelian necklace", "kind": "rare", "bonus": {"stamina": 10}, "sell": 120,
		"desc": "A string of red carnelian beads with a gold clasp, dragged into the giant rat's nest from some traveller's pack."},
	"ibex_armlet": {"name": "Ibex armlet", "kind": "rare", "bonus": {"hp": 10}, "sell": 250,
		"desc": "A heavy gold armlet whose two ends are ibex heads with swept-back horns. The chief wore it above the elbow."},
	# the stranger's trail (Stage 7b): what he dropped in the ruins (placeholder words)
	"sword_blade": {"name": "Broken blade", "kind": "story",
		"desc": "A straight iron blade, snapped off at the grip and spotted with rust. Datis's garrison sword, or half of it."},
	"sword_hilt": {"name": "Sword hilt", "kind": "story",
		"desc": "A bronze guard and a leather-wrapped grip, gnawed at the edges. The stump of the blade is still in it."},
	"brass_box": {"name": "Strange brass box", "kind": "story",
		"desc": "Dropped in the ruins where the boot prints stop. A small brass case with a glass face; the needle inside always swings back to the north."},
}

# the order the inventory shows its sections in, and their headings
const KINDS := ["tool", "food", "valuable", "rare", "story"]
const KIND_NAMES := {"tool": "Tools", "food": "Supplies", "valuable": "Valuables", "rare": "Rare finds", "story": "Story items"}
const BONUS_NAMES := {"hp": "max HP", "stamina": "max stamina", "focus": "max focus"}

# ---------------------------------------------------------------- icons
# Each icon is a 12x12 pixel grid: "." is empty, "o" the dark outline, the other letters come from the icon's own palette
# (three tones, light from the top-left, like every other drawn thing in the game).
const OUTLINE := "#2a1c10"
const ART := {
	"lasso": {"pal": {"l": "#e8c888", "m": "#c09050", "d": "#8a6030"}, "rows": [
		"...oooooo...",
		".oolllllldo.",
		".olmoooomdo.",
		"olmo....omdo",
		"olo......odo",
		"omo......odo",
		"omo......odo",
		"omdo....odmo",
		".omdoooodmo.",
		".oodddddddo.",
		"...oooooo...",
		"............"]},
	"bread": {"pal": {"l": "#f0c878", "m": "#d8a050", "d": "#a8702e"}, "rows": [
		"............",
		"...oooooo...",
		".oolllmmmoo.",
		"olllmmmmmmdo",
		"ollmmdmmmmdo",
		"olmmmmmmdmdo",
		"ommdmmmmmmdo",
		"ommmmmdmmddo",
		".oddmmmmddo.",
		"..oddddddo..",
		"...oooooo...",
		"............"]},
	"apple": {"pal": {"c": "#6a4a2a", "g": "#6aa83a", "l": "#f08a6a", "m": "#d03a2e", "d": "#8a1e1e"}, "rows": [
		"......oo....",
		".....oc.oo..",
		".....ocoggo.",
		"..oooocoooo.",
		".ollmmmmmmdo",
		"olllmmmmmmdo",
		"ollmmmmmmmdo",
		"olmmmmmmmmdo",
		"ommmmmmmmddo",
		".ommmmmmddo.",
		"..oddooddo..",
		"...oo..oo..."]},
	"coins": {"pal": {"l": "#fff0a0", "m": "#e8c040", "d": "#a87e1c"}, "rows": [
		"............",
		"..oooooooo..",
		".ollllllllo.",
		".ommmmmmmdo.",
		".oooooooooo.",
		".ollllllllo.",
		".ommmmmmmdo.",
		".oooooooooo.",
		".ollllllllo.",
		".ommmmmmmdo.",
		".oddddddddo.",
		"..oooooooo.."]},
	"brass_box": {"pal": {"l": "#ecc66a", "m": "#c8963a", "d": "#8a6420", "g": "#cfe2e0", "r": "#c0392b"}, "rows": [
		"............",
		"....oooo....",
		"....o..o....",
		"...oooooo...",
		"..ollllmmo..",
		".olggggggdo.",
		".olggrgggdo.",
		".omggrgggdo.",
		".omggggggdo.",
		"..ommmmddo..",
		"...oooooo...",
		"............"]},
	"small_potion": {"pal": {"l": "#d8a070", "m": "#b06a3a", "d": "#7a4220", "w": "#e8d8a0"}, "rows": [
		"............",
		"....oooo....",
		"....owwo....",
		"....oooo....",
		"....omlo....",
		"...ollmmo...",
		"..ollmmmdo..",
		"..olmmmmdo..",
		"..ommmmddo..",
		"...oddddo...",
		"....oooo....",
		"............"]},
	"large_potion": {"pal": {"l": "#8ae0d0", "m": "#3aa898", "d": "#1e6a60", "w": "#e8d8a0"}, "rows": [
		"....oooo....",
		"....owwo....",
		"....oooo....",
		"....omlo....",
		"...ollmmo...",
		"..ollmmmmo..",
		".ollmmmmmdo.",
		".olmmmmmmdo.",
		".ommmmmmddo.",
		".ommmmmmddo.",
		"..oddddddo..",
		"...oooooo..."]},
	"small_focus": {"pal": {"l": "#a8b8ff", "m": "#5a68d8", "d": "#2e347a", "w": "#e8d8a0"}, "rows": [
		"............",
		"....oooo....",
		"....owwo....",
		"....oooo....",
		"....omlo....",
		"...ollmmo...",
		"..ollmmmdo..",
		"..olmmmmdo..",
		"..ommmmddo..",
		"...oddddo...",
		"....oooo....",
		"............"]},
	"sword": {"pal": {"l": "#e8eef2", "m": "#a8b4bc", "d": "#6a747c", "g": "#d8a84a", "h": "#7a4a28"}, "rows": [
		"..........oo",
		".........olo",
		"........olmo",
		".......olmo.",
		"......olmo..",
		".....olmo...",
		".o..olmo....",
		".ogolmo.....",
		"..oggo......",
		".ohoggo.....",
		"ohho.oo.....",
		"oo.........."]},
	# the spear (Stage 8e): a leaf head at the top right, the shaft corner to corner, the round gold counterweight at the butt
	"spear": {"pal": {"l": "#e8eef2", "m": "#a8b4bc", "d": "#6a747c", "h": "#9a6a38", "g": "#e0b050", "x": "#a87a2a"}, "rows": [
		"..........oo",
		".........olo",
		"........olmo",
		".......olmo.",
		"......omdo..",
		".....oho....",
		"....oho.....",
		"...oho......",
		"..oho.......",
		".oggo.......",
		".ogxo.......",
		"..oo........"]},
	# the bow (Stage 8e): a curved stave on the right, its string down the left
	"bow": {"pal": {"l": "#d8a060", "m": "#a06a36", "d": "#6a4220", "w": "#e8e0c8"}, "rows": [
		"...oo.......",
		"..owolo.....",
		"..ow.olo....",
		"..ow..olo...",
		"..ow...olo..",
		"..ow...omo..",
		"..ow...omo..",
		"..ow...odo..",
		"..ow..odo...",
		"..ow.odo....",
		"..owodo.....",
		"...oo......."]},
	"sword_blade": {"pal": {"l": "#d8dce0", "m": "#9aa4a8", "d": "#6a5a4a"}, "rows": [
		"..........oo",
		".........olo",
		"........olmo",
		".......olmo.",
		"......olmo..",
		".....oldo...",
		"....olmo....",
		"...odmo.....",
		"...ooo......",
		"............",
		"............",
		"............"]},
	"sword_hilt": {"pal": {"g": "#d8a84a", "m": "#a8b4bc", "h": "#7a4a28", "d": "#4a2c18"}, "rows": [
		"............",
		"............",
		"............",
		"......oo....",
		".....omo....",
		".o..omo.....",
		".ogoomo.....",
		"..oggo......",
		".ohoggo.....",
		"ohdo.oo.....",
		"odo.........",
		"oo.........."]},
	"antidote": {"pal": {"l": "#c8e890", "m": "#7ab84a", "d": "#3e6a22", "w": "#e8d8a0"}, "rows": [
		"............",
		".....oo.....",
		"....owwo....",
		".....oo.....",
		"....olmo....",
		"....olmo....",
		"...ollmdo...",
		"...olmmdo...",
		"...olmmdo...",
		"...ommddo...",
		"....oooo....",
		"............"]},
	"large_focus": {"pal": {"l": "#a8b8ff", "m": "#5a68d8", "d": "#2e347a", "w": "#e8d8a0"}, "rows": [
		"....oooo....",
		"....owwo....",
		"....oooo....",
		"....omlo....",
		"...ollmmo...",
		"..ollmmmmo..",
		".ollmmmmmdo.",
		".olmmmmmmdo.",
		".ommmmmmddo.",
		".ommmmmmddo.",
		"..oddddddo..",
		"...oooooo..."]},
	# a squat amber flask, a linen strip tied round its neck with a red cord
	"revive_potion": {"pal": {"l": "#f0d080", "m": "#c89838", "d": "#8a5e1c", "w": "#e8e0c8", "r": "#c0392b"}, "rows": [
		"............",
		"...oooooo...",
		"...owwwwo...",
		"....oooo....",
		"...orrrro...",
		"..ollmmmmo..",
		".ollmmmmmdo.",
		".olmmmmmmdo.",
		".ommmmmmddo.",
		".ommmmmmddo.",
		"..oddddddo..",
		"...oooooo..."]},
	"carnelian_necklace": {"pal": {"l": "#f07850", "m": "#c83a28", "d": "#8a1e14", "g": "#e8c040"}, "rows": [
		"............",
		"..o......o..",
		".ogo....ogo.",
		".olo....olo.",
		".omo....omo.",
		".olo....olo.",
		".omo....omo.",
		".olo....olo.",
		"..omo..omo..",
		"...olloll...",
		"....oddo....",
		"....oooo...."]},
	"ibex_armlet": {"pal": {"l": "#fff0a0", "m": "#e8c040", "d": "#a87e1c", "h": "#8a6420"}, "rows": [
		"...h....h...",
		"..oho..oho..",
		".ollo..ollo.",
		".olmo..omdo.",
		"olmo....omdo",
		"olo......odo",
		"omo......odo",
		"omo......odo",
		"omdo....odmo",
		".omdoooodmo.",
		"..oddddddo..",
		"...oooooo..."]},
	# not an item: the Unarmed weapon's icon in the Player tab (progress.gd WEAPONS), a fist
	"unarmed": {"pal": {"l": "#e8b88a", "m": "#c88a5a", "d": "#8a5a34"}, "rows": [
		"............",
		"..oooooooo..",
		".ollollollo.",
		".olmolmolmo.",
		".ommommommdo",
		".oooooooommo",
		"olllllllomdo",
		"ommmmmmmmddo",
		".ommmmmmddo.",
		"..ommmmmdo..",
		"..ommmmddo..",
		"..oooooooo.."]},
	# anything without its own art: a plain wrapped bundle
	"unknown": {"pal": {"l": "#d8c8a8", "m": "#b0a080", "d": "#7a6a50"}, "rows": [
		"............",
		"....oooo....",
		"...ollmmo...",
		"..oooooooo..",
		".olllmmmmdo.",
		".ollmmmmmdo.",
		".olmmmmmmdo.",
		".ommmmmmddo.",
		".ommmmmmddo.",
		".oddddddddo.",
		"..oooooooo..",
		"............"]},
}
# The HUD's weapon badge (hud.gd _draw_weapon): bigger 20x20 art for the weapon in hand, in the same format, so it reads like the user's
# reference picture instead of a blown-up 12px icon. A weapon without one here falls back to its ART icon, enlarged.
const BADGE := 20
const BADGE_ART := {
	# a clenched fist, knuckles up, its wrist bound in a red-brown wrap
	"unarmed": {"pal": {"l": "#f0c8a0", "m": "#d89a6a", "d": "#9a6038", "w": "#b0502a", "x": "#6e2e18"}, "rows": [
		"....................",
		"....ooo.ooo.ooo.ooo.",
		"...olllolllolllolllo",
		"...olmmolmmolmmolmmo",
		"...ommdommdommdommdo",
		"...ooooooooooooooooo",
		"..ollllllllllommmmdo",
		"..ommmmmmmmmmommmddo",
		"..oooooooooooommmddo",
		"...ommmmmmmmmmmmddo.",
		"....ommmmmmmmmmmddo.",
		".....oddddddddddddo.",
		"......owwwwwwwwxxo..",
		"......oxxxxxxxxxxo..",
		"......owwwwwwwwxxo..",
		"......owwwwwwwwxxo..",
		"......oxxxxxxxxxxo..",
		"......owwwwwwwwxxo..",
		"......oooooooooooo..",
		"...................."]},
	# the sword, point up and to the right: a bright two-tone blade, a gold cross-guard, a leather grip and a gold pommel
	"sword": {"pal": {"l": "#f4f8fa", "m": "#b8c4cc", "g": "#e0b050", "h": "#7a4a28", "x": "#d8a84a"}, "rows": [
		"..................oo",
		".................olo",
		"................olmo",
		"...............olmo.",
		"..............olmo..",
		".............olmo...",
		"............olmo....",
		"...........olmo.....",
		"..........olmo......",
		".........olmo.......",
		"...oo...olmo........",
		"...ogo.olmo.........",
		"....oggolmo.........",
		".....ogggo..........",
		"....ohhoggo.........",
		"...ohhho.ogo........",
		"..ohhho...oo........",
		".oxhho..............",
		".oxxo...............",
		"..oo................"]},
	# the spear (Stage 8e), point up and to the right: a leaf-shaped head, a gold socket, the shaft, the round gold counterweight
	"spear": {"pal": {"l": "#f4f8fa", "m": "#b8c4cc", "g": "#e0b050", "x": "#a87a2a", "h": "#b07a40", "k": "#6a4220"}, "rows": [
		"..................oo",
		".................olo",
		"................olmo",
		"...............ollmo",
		"..............ollmo.",
		".............olmo...",
		"............ogxo....",
		"...........ohko.....",
		"..........ohko......",
		".........ohko.......",
		"........ohko........",
		".......ohko.........",
		"......ohko..........",
		".....ohko...........",
		"....ohko............",
		"...ohko.............",
		"..oggo..............",
		".oggxo..............",
		".oxxxo..............",
		"..ooo..............."]},
	# the bow (Stage 8e): a curved stave with a dark leather grip, its string down the left, an arrow nocked across
	"bow": {"pal": {"l": "#d8a060", "m": "#a06a36", "d": "#6a4220", "g": "#4a2c18", "w": "#e8e0c8", "a": "#e0d4b0", "b": "#c89a48",
		"r": "#a8372b"}, "rows": [
		"....oooo............",
		"....owolo...........",
		"....ow.olo..........",
		"....ow..olo.........",
		"....ow...olo........",
		"....ow....olo.......",
		"....ow....omo.......",
		"....ow.....omo......",
		"....ow.....ogo......",
		"....ow.....ogo......",
		".rraaaaaaaaaaaaaabb.",
		"....ow.....ogo......",
		"....ow.....omo......",
		"....ow....omo.......",
		"....ow....odo.......",
		"....ow...odo........",
		"....ow..odo.........",
		"....ow.odo..........",
		"....owodo...........",
		"....oooo............"]},
}
const ICON := 12    # icon size in pixels at scale 1
# Things lying on the ground (pickup()): every one pulses with a soft halo and bobs a little, and a glint runs over it every GLINT_EVERY
# s, so it can't be missed (the user's play-test: a dark map hid them). A story item (a quest part) is drawn twice the size with a
# brighter halo, so it stands out from ordinary loot.
const GLINT_EVERY := 1.4
const GLINT_TIME := 0.35
const PULSE_TIME := 1.2       # one swell and fade of the halo, s
const PULSE_ALPHA := 0.22     # the halo's strongest alpha (ordinary loot), and its radius
const PULSE_R := 9.0
const STORY_PULSE_ALPHA := 0.38
const STORY_PULSE_R := 16.0
const BOB := 1.5              # how far a pickup bobs up and down, px

static func info(id: String) -> Dictionary:
	return ITEMS.get(id, {"name": id, "kind": "story", "desc": ""})

# draw item `id`'s icon with its top-left corner at (x, y); s = pixel scale (1 in lists, 3 for the big picture)
static func icon(n, id: String, x: float, y: float, s := 1.0, alpha := 1.0) -> void:
	_pixels(n, ART.get(id, ART["unknown"]), x, y, s, alpha)

# the HUD's weapon badge art for weapon `w`, centred on c; s = scale (the badge swells when the weapon changes)
static func badge(n, w: String, c: Vector2, s := 1.0) -> void:
	if BADGE_ART.has(w):
		_pixels(n, BADGE_ART[w], c.x - BADGE * s / 2.0, c.y - BADGE * s / 2.0, s, 1.0)
	else:
		icon(n, w,c.x - ICON * 1.5 * s / 2.0, c.y - ICON * 1.5 * s / 2.0, 1.5 * s)

# one pixel grid (ART / BADGE_ART format) with its top-left corner at (x, y)
static func _pixels(n, art: Dictionary, x: float, y: float, s: float, alpha: float) -> void:
	var pal: Dictionary = art["pal"]
	var rows: Array = art["rows"]
	for j in range(rows.size()):
		var row: String = rows[j]
		for i in range(row.length()):
			var ch := row[i]
			if ch == ".":
				continue
			var hex: String = OUTLINE if ch == "o" else pal.get(ch, OUTLINE)
			var c := Color(hex)
			c.a = alpha
			n.draw_rect(Rect2(roundf(x) + i * s, roundf(y) + j * s, s, s), c)

# What a bonus adds, in words: "+10 max HP" (rare finds)
static func bonus_text(id: String) -> String:
	var parts := []
	var b: Dictionary = info(id).get("bonus", {})
	for k in b.keys():
		parts.append("+%d %s" % [b[k], BONUS_NAMES.get(k, k)])
	return ", ".join(parts)

# An item lying on the ground (level.gd pickups and drops), its foot at (x, y): a soft shadow, a pulsing halo, the icon bobbing over it,
# and a glint that runs across it, so it reads as something to take (design doc section 11). A story item is twice the size with a
# brighter halo. Animated: its prop redraws often.
static func pickup(n, id: String, x: float, y: float) -> void:
	var story: bool = info(id)["kind"] == "story"
	var s := 2.0 if story else 1.0
	var size := ICON * s
	var t := Time.get_ticks_msec() / 1000.0 + x * 0.013
	var pulse := 0.5 + 0.5 * sin(TAU * t / PULSE_TIME)
	var bob := roundf(BOB * sin(TAU * t / (PULSE_TIME * 1.5)))
	var mid := Vector2(x, y - size / 2.0 - 1.0 + bob)
	var ha: float = (STORY_PULSE_ALPHA if story else PULSE_ALPHA) * (0.45 + 0.55 * pulse)
	var hr: float = (STORY_PULSE_R if story else PULSE_R) * (0.9 + 0.15 * pulse)
	for i in range(4):          # soft edge: stacked faint circles, brightest in the middle
		n.draw_circle(mid, hr * (1.0 - i * 0.22), Color(1.0, 0.95, 0.75, ha * 0.35))
	n.draw_rect(Rect2(roundf(x) - 5 * s, roundf(y) - 1, 10 * s, 2), Color(0, 0, 0, 0.3))
	n.draw_rect(Rect2(roundf(x) - 4 * s, roundf(y), 8 * s, 1), Color(0, 0, 0, 0.2))
	icon(n, id, x - size / 2.0, y - size - 1.0 + bob, s)
	var k := fmod(t, GLINT_EVERY)
	if k < GLINT_TIME:
		var gx := roundf(x - size / 2.0 + (k / GLINT_TIME) * size)
		var gy := roundf(y - size + 1.0 + bob)
		var c := Color(1, 1, 0.9, 0.9)
		n.draw_rect(Rect2(gx, gy - s, s, 3 * s), c)
		n.draw_rect(Rect2(gx - s, gy, 3 * s, s), c)
