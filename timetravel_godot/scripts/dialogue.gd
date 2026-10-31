extends CanvasLayer
# dialogue.gd - all spoken text (data at the top), the parchment dialogue box, portraits and quest marks.
# Opening a conversation pauses the whole game (hero, NPCs, animals); this node keeps running so E can advance.
#
# Edit the words in the tables below (PEOPLE, TALK, SCENES, LOGS, BOSSES, FOES, SHOP_LINES, SHOUTS, CHATTER); no other code needs to change.

const Sprites = preload("res://scripts/sprites.gd")

const CPS := 45.0                 # typewriter speed, characters per second
const TALK_RANGE := 26.0

# ---- who can be talked to (portrait is a placeholder silhouette; drop assets/portraits/<id>.png to replace it) ----
const PEOPLE := {
	"arshan": {"name": "Keeper Arshan", "look": "keeper"},
	"nidu": {"name": "Scribe Nidu", "look": "scribe"},
	"datis": {"name": "Veteran Datis", "look": "datis"},
	"king": {"name": "King Rostam", "look": "king"},
	"utana": {"name": "Scholar Utana", "look": "scholar"},
	"rider": {"name": "Rider Farnaka", "look": "rider"},           # also the first member of the hero's squad (squad.gd "farnaka")
	"captain": {"name": "Captain Vahauka", "look": "captain"},     # the riders' captain, staked in the cave's boss room (an Old Persian name)
}

# ---- conversations (1-3 short lines). A key is the minimum quest stage; the highest one that fits is used. ----
# "note" is a quest event noted when the conversation ends (quest.gd note: it moves the objective on); "set_stage" sets the stage
# outright (older form). A line may also be {"t": "text", "choices": [{"label": "..", "lines": [..], "then": ".."}, ..]} (max 3).
# "then" names something the map does when the conversation ends (level.talk_done), e.g. the cave's rider joining you; a choice can
# have its own. "squad_follow" / "squad_wait" / "squad_home" are squad orders for the person spoken to (main.gd squad_order);
# a "squad_home" (Disband) choice is left out while the story still needs him (quest.gd NEEDS). "shop_<keeper>" opens that keeper's
# stall (shop.gd SHOPS) once the box closes.
# "give" = {item id: count} handed to the hero when the conversation ends (items.gd); "take" (7l) = items taken from him then (before
# the give). "first" = a version of the conversation used only the first time it is had (it may have its own "give"); after that the
# ordinary lines.
# "flags" (7l) = [[quest flag, conversation], ...], the furthest along first: from stage "flags_from" on, the first row whose flag is
# set is used instead of the stage table (a side quest's conversations: Datis's sword). A person whose conversation would note an
# event not yet noted wears the "?".
const TALK := {
	"arshan": {
		0: {"lines": [
			"Welcome to the waystation, traveller.",
			"Shade, water and a bed for anyone on the road.",
			"Rest your feet, but mind the desert after dark.",
		],
		# the first time, he sends the hero off with something to eat (placeholder line)
		"first": {"lines": [
			"Welcome to the waystation, traveller.",
			"Shade, water and a bed for anyone on the road.",
			"You look half-starved. Here: bread and an apple, for the road.",
		], "give": {"bread": 2, "apple": 1}}},
	},
	# Nidu keeps the stall by the training yard (Stage 7h, shop.gd). Placeholder lines: road stations of this period handed out rations
	# to travellers, and a scribe wrote down every one, so a scribe selling supplies and writing it down fits.
	"nidu": {
		0: {"lines": [
			{"t": "Bread, apples, a healer's flasks. What do you need?", "choices": [
				{"label": "Show me your goods.", "then": "shop_nidu"},
				{"label": "Nothing for now.", "lines": ["Safe road, then."]},
			]},
		],
		"first": {"lines": [
			"Hm? Forgive me, I am counting water skins.",
			"Every traveller on this road ends up in my ledger. I sell supplies for the road, too.",
			{"t": "Bread, apples, a healer's flasks. What do you need?", "choices": [
				{"label": "Show me your goods.", "then": "shop_nidu"},
				{"label": "Nothing for now.", "lines": ["Safe road, then."]},
			]},
		]}},
	},
	"king": {
		0: {"lines": [
			"The road east is dangerous. Go carefully.",
			"I will not forget what you do for my men.",
		]},
	},
	# placeholder lines: they only build on what the king already says (his riders are missing); no clues or quest yet
	"utana": {
		0: {"lines": [
			"A visitor who wants records, not wine? Sit, if you can find a stool.",
			"Clay tablets for the treasury, leather scrolls for letters. Every grain and every man is written down.",
			"If the king's lost riders passed a toll house, their names are somewhere on these shelves.",
		]},
	},
	"datis": {
		0: {"lines": [
			"Easy there, stranger. You've come a long way.",
			"I can't answer your questions, but King Rostam might.",
			"Go and find the king. Follow the road to his mansion.",
		], "note": "met_datis"},
		1: {"lines": [
			"Still here? Go and find King Rostam.",
			"He'll want to meet a stranger like you.",
		]},
		# Stage 7l, his sword side quest (the user's: the parts in the storeroom, then ten of the band; placeholder words). Once the hero
		# has met the king he asks; the "flags" rows below then take over, the furthest along first.
		2: {"lines": [
			"You've seen the king, then. Good. Now, a favour from an old soldier.",
			"The garrison's sword broke the day the rats took the storeroom. I dropped it in there and ran, and I'm not proud of it.",
			"Bring me the blade and the hilt, and I'll put it back together for you. You fight well with your fists, but a blade is better.",
		], "note": "sword_asked"},
		"flags_from": 2,
		"flags": [
			["bounty_paid", {"lines": [
				"The road's quieter for what you did. Keep that blade oiled.",
				"When you want to learn more than swinging it, come and find me.",
			]}],
			["bounty_met", {"lines": [
				"Ten of the band? They'll think twice before they come down to the road again.",
				"Here: the bounty the garrison owes. You've earned every coin of it.",
			], "give": {"coins": 80}, "note": "bounty_paid"}],
			["sword_given", {"lines": [
				"The band still owes this road. Cut down ten of their men and come back to me.",
			]}],
			["sword_parts", {"lines": [
				"That's it! The blade, and the hilt with its stump still in it.",
				"Give me a moment... a new pin, fresh leather on the grip... there.",
				"It's yours. Press 1 to draw it, and 1 again to put it away.",
				"Now earn it. The hill band robs everyone on this road. Cut down ten of their men and come back; the garrison pays a bounty.",
			], "take": {"sword_blade": 1, "sword_hilt": 1}, "give": {"sword": 1}, "note": "sword_given"}],
			["sword_asked", {"lines": [
				"The blade and the hilt are both somewhere in the storeroom. Mind the rats, and the big one most of all.",
			]}],
		],
	},
	# the cave: the captured royal rider, once the cage is open (placeholder lines). When it ends he takes his bow and joins you.
	"rider": {
		0: {"lines": [
			"You're not one of them... You opened the door.",
			"I am Farnaka, a rider of the king. They fell on our camp in the night. They dragged the rest of us deeper in.",
			"That bow on the table is mine. Let me fight beside you. I owe them for my brothers.",
			"Go first. I'll shoot past your shoulder.",
		], "then": "rider_join"},
	},
	# the rider as a squad mate (npc.talk_id; placeholder lines): holding a spot (order Wait), and at his home spot by the throne
	# (order Disband). While he follows, E never lands on him.
	"rider_wait": {
		0: {"lines": [
			{"t": "I'm keeping watch. What now?", "choices": [
				{"label": "Come with me.", "lines": ["Lead on. I'll shoot past your shoulder."], "then": "squad_follow"},
				{"label": "Go back to the hall.", "lines": ["I'll wait for you by the king."], "then": "squad_home"},
				{"label": "Keep watch here.", "lines": ["Nothing gets past me."]},
			]},
		]},
	},
	"rider_home": {
		0: {"lines": [
			{"t": "If you go back into those hills, I go with you.", "choices": [
				{"label": "Come with me.", "lines": ["Then let's go."], "then": "squad_follow"},
				{"label": "Stay here for now.", "lines": ["I'll be here, by the king."]},
			]},
		]},
	},
}

# ---- scripted scenes (hall.gd): a line may name its speaker with "who" (a PEOPLE id); otherwise the scene's own person speaks ----
const SCENES := {
	# the first meeting at the throne (placeholder; the real script comes later in the project)
	"king_intro": [
		"Come closer, stranger. The throne does not bite.",
		"My guards ride out, and they do not come home. Some are dead. Some are simply lost.",
		"A hostile band hides in the hills. I cannot spare more men to find them.",
		"Help me with my troops, and I will help you in return.",
	],
	# back from the cave with the freed rider. Neither version assumes the hero met the king before.
	"king_return_rider": [
		"Farnaka! I had counted you among the dead.",
		{"t": "My king. The band fell on our camp in the night. Only the captain and I came out alive.", "who": "rider"},
		{"t": "This stranger opened my cage, and we broke them together. Their chief is dead.", "who": "rider"},
		"Then the hills are quiet again. Vahauka is with the healers; I have heard what was done in that cave.",
		"Stranger, I owe you two lives. Ask, and the house of Rostam will answer.",
		"Take these coins for now. The road east is long.",       # hall.gd gives the coins when the scene ends
		# the scientist's trail (decided 2026-10-27; placeholder words): the rider saw a stranger heading for the ancient ruins
		{"t": "My king, one thing more. The evening before the raid, a man passed our camp on the road. Not a trader, not one of the band.", "who": "rider"},
		{"t": "Strange clothes, a pack on his back, boots like nothing I have seen. He went north, toward the old ruins above the town.", "who": "rider"},
		"Another stranger on my roads. Go and look at those ruins, and tell me what you find.",
	],
	# back from the cave without the rider (the lesser return: he is still in the cage), with the captain
	"king_return_alone": [
		"You come down from the hills with their dust on you, stranger. Is it true? Their chief is dead?",
		"Then the road east can breathe again.",
		"You brought Vahauka back to me. He is with the healers. He told me what was done to the others.",
		# the scientist's trail, without the rider: the captain's account reaches the king (placeholder words)
		"He told me one thing more. The evening before the raid, a stranger passed their camp, going north toward the old ruins above the town.",
		"Strange clothes, he said, and stranger boots. Go and look at those ruins, and tell me what you find.",
		"You have done this kingdom a service. Take these coins for your trouble.",
	],
	# the cave: the riders' captain, cut down from his stake after the chief falls (cave.gd). When it ends the hero goes back to the king.
	# He tells it plainly; the room behind him shows the rest.
	"captain": [
		"...You cut the rope. Then he is dead? Their chief?",
		"I am Vahauka. I led the king's riders. They came on our camp in the dark, from the tunnel and from the rocks above.",
		"We held by the fire until the arrows ran out. The ones who ran for the mouth were cut down before they reached the light.",
		"He brought the rest of us here and staked us along the wall, one each night, so the others would watch. I was to be the last.",
		"Get me out of this place. The king must hear it from me.",
	],
}

# ---- the journal (menu.gd Journal tab): the scientist's logs, the clues the hero finds and the records of the era. quest.gd keeps which
# ones were found. ----
# kind "log" = the scientist's own words; "clue" = what the hero noticed; "record" (Stage 7j) = something written by people of this time
# (a tablet, a note). "by" (optional) is the reader's line under the title: whose words they are, and on what. Keep each short and
# specific (design doc section 4). Placeholder words (Stage 7b, 7j): the user will rewrite them.
const LOGS := {
	"boot_prints": {"kind": "clue", "title": "Boot prints in the ruins",
		"text": "Prints of a heavy boot with a ridged sole, nothing like a sandal or a soft riding boot. They leave the road by the east gate, climb past the town wall and wander between the pillars, stopping often."},
	"brass_box": {"kind": "clue", "title": "A strange brass box",
		"text": "Dropped where the boot prints stop. A small brass case with a glass face; the needle inside always swings back to the north. Nobody on this road makes such a thing."},
	"page_1": {"kind": "log", "title": "A torn page",
		"text": "Day 3. The waystation is exactly where the tablets put it. Nobody asks where I come from; this road is full of strangers.\nThe ruins above the town are older than the road. The mark on the north pillar matches my rubbing. If I read it right, it points to the coast."},
	# Stage 7j: the second page lies by the scorpions' den in the west of the ruins. Herodotus (3.94) does say the Indians paid the
	# largest tribute, 360 talents of gold dust; he means the Indus satrapy, and the scientist reads it as "India" (a log may be biased).
	"page_2": {"kind": "log", "title": "A second torn page",
		"text": "Day 4. Herodotus says India paid the largest tribute in the whole empire: 360 talents of gold dust a year. Every historian I know shrugs at that line.\nThe scribes here count barley down to the last jar, so where are the counts from the east? I came to read them for myself.\nSomething stung me under the stones last night. My hand is swollen. No time for it."},
	# Stage 7j: the hall's library. Cyrus took Media, Lydia and Babylon (about 550-539 BCE); Darius fixed the satrapies' tribute and ran
	# the King's Road with its stations, relays of horses and rations issued on a sealed document (Herodotus; the Persepolis tablets);
	# Hindush (the Indus land) paid in gold dust. Naming Darius sets the slice in his reign or later.
	"tablet_road": {"kind": "record", "title": "The King's Road", "by": "A clay tablet on Utana's desk, read out by him",
		"text": "Cyrus, king of Anshan, took Media, then Lydia, then Babylon: the lands of many tongues became one house.\nDarius fixed what each satrapy owes, and bound them all with the King's Road: a station every day's journey, fresh horses for the king's riders, rations for anyone who carries a sealed order.\nThe road runs east as far as Hindush, the land of the great river. Its tribute comes as gold dust."},
	# Stage 7j: the cave's jail. A rider who could write (Aramaic, the empire's working script) left it in an empty pen before his turn
	# on the stake; it agrees with the captain's account (dialogue.gd SCENES "captain").
	"jail_note": {"kind": "record", "title": "A note in the jail", "by": "Charcoal on a scrap of leather, in Aramaic, dropped in a pen",
		"text": "We held the fire until our arrows ran out. Then the chief came down off the rocks with his axe. The men who stood in his way did not get up, and the ones who ran were cut down before the mouth.\nHe brought the rest of us here. Each night he takes one up the steps, and we listen.\nArshaka tonight. Me tomorrow, I think. Tell the king we held.\nBagadata, rider of the king"},
}

# ---- the bosses' names on the boss bar at the bottom of the screen (hud.gd; enemy kind -> name; placeholder words) ----
const BOSSES := {
	"giant": "The Giant Rat",
	"chief": "Chief of the Band",
}

# ---- the journal's Enemies list (menu.gd Journal tab, Stage 7k): a kind shows once the hero has cut one down, with this name, a short
# description and the number slain (combat.gd kills_by). In the order listed here. Placeholder words: the user will rewrite them. ----
const FOES := {
	"rat": {"name": "Rat", "text": "Grain thieves that nest along the road and in the storerooms. One bite is little, but they come in twos and threes; a hurt one runs off to its nest."},
	"giant": {"name": "The Giant Rat", "text": "A rat the size of a calf, fat on the town's grain. Its hide shrugs off blows while it attacks. It leaps and lands with its whole weight, and calls its brood when hurt."},
	"bandit": {"name": "Bandit", "text": "Road robbers of the hill band. Too heavy to drag with a rope, but a strong lasso binds their arms. They never run."},
	"slinger": {"name": "Slinger", "text": "The chief's stone-throwers. They keep their distance and whirl the sling before each throw; close in and they back away. Light enough to pull."},
	"chief": {"name": "Chief of the Band", "text": "A big man with a long axe who took the king's riders. He charges in a straight line, sweeps the axe up close, and grows fierce when wounded. Lead his charge into something solid."},
	"scorpion": {"name": "Scorpion", "text": "Desert scorpions guarding a den in the ruins. Slow and short-sighted, but the sting is slow to come and poisons the blood. An antidote or a rest cures it."},
}

# ---- what a shopkeeper says in the shop's keeper strip (shop.gd; keyed by the keeper; placeholder words) ----
# "hello" when it opens, "bought" after a purchase, "sold" after the hero sells something, "short" when the coins don't reach
const SHOP_LINES := {
	"nidu": {
		"hello": "Coins on the board, and I write it in the ledger.",
		"bought": "Written down. Safe road.",
		"sold": "A fine piece. Your coins, counted twice.",
		"short": "That is more than you carry, friend.",
	},
}

# ---- short lines shouted in a floating bubble during play (npc.shout) ----
const SHOUTS := {
	"rider_wave": "They heard us! Here they come!",
	"rider_slingers": "Slingers in the tunnel! Keep moving!",
	"rider_clear": "Careful. More of them may be waiting below.",
	"rider_boss": "The chief himself! Watch his axe!",
	"rider_captain": "There, on the stake! The captain is alive!",
	"king_call": "Come forward.",                 # the king, when you reach the foot of his steps
	"king_return": "Let them through!",           # the king, when you come back from the cave
}

# ---- idle mutterings in the white oval (2-3 lines each, repeated in order) ----
const CHATTER := {
	"guard1": ["Move along, friend.", "Quiet day on the road.", "Mind the desert heat."],
	"guard2": ["Welcome, traveller.", "Keep to the road.", "Water's at the well."],
	"guard4": ["Halt... ah, carry on.", "The castle lies east.", "Rats nest by the river."],
	"carrier": ["Fresh water!", "Heavy jar today...", "Mind your feet!"],
	"potter": ["Good clay is rare here.", "Round and round...", "Pots for sale!"],
	"handler": ["Easy, old girl.", "She bites. Mostly.", "Best camel on the road."],
	"child": ["Come back, lizard!", "Almost got him!", "Hehe!"],
	"traveller": ["Zzz...", "Five more minutes...", "Zzz... water..."],
	"cook": ["Stew's nearly ready.", "Needs more salt.", "Hungry, traveller?"],
	# castle courtyard
	"cguard1": ["All quiet within the walls.", "Keep to the paving, friend.", "The king's eyes are everywhere."],
	"cguard2": ["Another lap, another lap...", "Off-duty men sleep in those tents.", "Mind the statue's shadow."],
	"cguard3": ["Welcome to the king's court.", "State your business.", "The river runs quiet today."],
	# great hall
	"servant": ["More bread for the long table.", "The king eats late tonight.", "Mind the jug, it's full."],
	# the cave: the captured rider while he is still in the cage (placeholder)
	"rider": ["Water... is someone there?", "They took my bow.", "The others... I saw them fall."],
	# the riders' captain, bound to his stake in the boss room
	"captain": ["...", "Water...", "Cut me down..."],
}

# ---- state ----
var world
var player
var quest
var inv                       # inventory.gd (a conversation's "give" goes in here)
var menu                      # menu.gd (maps open a found log in its reader: dialogue.menu.read_log(id))
var squad                     # squad.gd (maps ask who is in the squad: dialogue.squad.has(id))
var shop                      # shop.gd (a choice's "shop_<keeper>" then opens it; a keeper wears the coin mark)
var squad_order: Callable     # main.gd squad_order(who, order): a choice's "squad_..." then
var travel: Callable          # main.gd: go through a door (level key, spawn name)
var rest: Callable            # main.gd: E at a rest spot (a well, a fire): rest and save
var revive: Callable          # main.gd revive_by_hand(node): E beside a fallen companion uses a Reviving Potion on him
var open := false
var sign_open := false
var sign_lines: Array = []   # [direction, destination, arrow] rows of the sign being read
var npc
var lines: Array = []
var idx := 0
var shown := 0.0
var choosing := false
var sel := 0
var set_stage_after := -1
var then_after := ""             # the conversation's "then" (level.talk_done) for when it ends
var give_after := {}             # the conversation's "give" for when it ends
var take_after := {}             # the conversation's "take" (items taken from the hero) for when it ends
var note_after := ""             # the conversation's "note" (a quest event) for when it ends
var _first_key := ""             # quest flag noted when a conversation's "first" version ends ("talked_<id>_<stage>")
var on_close := Callable()       # run once when the current conversation ends (used by the king scene)
var ui: Control

func _ready() -> void:
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS
	ui = Control.new()
	ui.size = Vector2(480, 270)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.draw.connect(_draw_ui)
	add_child(ui)

# ---------- data helpers used by the world and NPCs ----------
func chatter_for(id: String) -> Array:
	return CHATTER.get(id, [])

# "quest" = white oval with ?, "shop" = white oval with a coin (a shopkeeper), "chat" = white oval with ..., "" = nothing
func mark_for(id: String) -> String:
	if not PEOPLE.has(id):
		return ""
	if quest != null and TALK.has(id):
		var note: String = _pick(id)[0].get("note", "")
		if note != "" and not quest.flags.get(note, false):
			return "quest"            # this talk would move a quest on: Datis at the start, and when his sword quest has news
	if id == "rider" and not (squad != null and squad.has("farnaka")):     # just out of the cage, before he joins you
		return "quest"
	if shop != null and shop.keeps(id):
		return "shop"
	# (the rider as a squad mate, waiting or at home, is an ordinary "chat")
	return "chat"

# which conversation person `id` has now, and the flag that marks its "first" version as had: [conversation, key]. A "flags" row
# whose flag is set wins (from stage "flags_from" on); otherwise the highest stage key at or below the quest's stage.
func _pick(id: String) -> Array:
	var t: Dictionary = TALK[id]
	if quest.stage >= t.get("flags_from", 0):
		for row in t.get("flags", []):
			if quest.flags.get(row[0], false):
				return [row[1], "talked_%s_%s" % [id, row[0]]]
	var best := -1
	for k in t.keys():
		if k is int and k <= quest.stage and k > best:
			best = k
	return [t[best], "talked_%s_%d" % [id, best]]

func _conversation(id: String) -> Dictionary:
	var picked := _pick(id)
	var conv: Dictionary = picked[0]
	var key: String = picked[1]
	_first_key = ""
	if conv.has("first") and not quest.flags.get(key, false):
		_first_key = key
		return conv["first"]
	return conv

# ---------- input ----------
func _unhandled_input(event: InputEvent) -> void:
	if sign_open:
		if event.is_action_pressed("interact") or event.is_action_pressed("ui_cancel"):
			sign_open = false
			world.talking = false
			get_viewport().set_input_as_handled()
		return
	if open:
		if choosing and event.is_action_pressed("move_up"):
			sel = maxi(0, sel - 1)
		elif choosing and event.is_action_pressed("move_down"):
			sel = mini(lines[idx]["choices"].size() - 1, sel + 1)
		elif event.is_action_pressed("interact"):
			_advance()
		else:
			return
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact") and not world.talking and not player.dead:     # (fallen: the death screen takes the keys)
		var fallen = _nearest_fallen()
		var n = _nearest_talkable()
		if fallen != null and revive.is_valid():
			revive.call(fallen)
			get_viewport().set_input_as_handled()
		elif n != null:
			_start(n)
			get_viewport().set_input_as_handled()
		elif not world.near_sign().is_empty():
			sign_lines = world.near_sign()["lines"]
			sign_open = true
			world.talking = true
			get_viewport().set_input_as_handled()
		elif not world.near_rest().is_empty() and rest.is_valid():
			rest.call(world.near_rest())
			get_viewport().set_input_as_handled()
		elif not world.near_use().is_empty():
			world.use_spot(world.near_use()["id"])
			get_viewport().set_input_as_handled()
		elif not world.near_door().is_empty() and travel.is_valid():
			var door: Dictionary = world.near_door()
			travel.call(door["to"], door["spawn"])
			get_viewport().set_input_as_handled()

func _nearest_talkable():
	var best = null
	var bd := TALK_RANGE
	for n in world.npcs:
		if not n.talk:
			continue
		var d: float = player.position.distance_to(n.position)
		if d < bd:
			bd = d
			best = n
	return best

# a fallen companion (rider.gd down) within reach of E: E revives him rather than talking to anyone (Stage 7i)
func _nearest_fallen():
	for n in world.npcs:
		if n.get("down") == true and player.position.distance_to(n.position) < TALK_RANGE:
			return n
	return null

# ---------- flow ----------
func _start(n) -> void:
	var conv := _conversation(n.talk_id if n.talk_id != "" else n.id)
	npc = n
	lines = _drop_locked_orders(conv["lines"].duplicate(), n)
	set_stage_after = conv.get("set_stage", -1)
	then_after = conv.get("then", "")
	give_after = conv.get("give", {})
	take_after = conv.get("take", {})
	note_after = conv.get("note", "")
	idx = 0
	_begin_line()
	var to: Vector2 = player.position - n.position
	n.dir = ("right" if to.x > 0.0 else "left") if absf(to.x) > absf(to.y) else ("down" if to.y > 0.0 else "up")
	open = true
	world.talking = true
	get_tree().paused = true

# a squad mate the story still needs (quest.gd NEEDS) can't be disbanded: his "squad_home" choices are left out
func _drop_locked_orders(ls: Array, n) -> Array:
	var m: Dictionary = squad.find(n) if squad != null else {}
	if m.is_empty() or quest.needed(m["id"]) == "":
		return ls
	for i in range(ls.size()):
		if ls[i] is Dictionary and ls[i].has("choices"):
			var line: Dictionary = ls[i].duplicate()
			line["choices"] = ls[i]["choices"].filter(func(c): return c.get("then", "") != "squad_home")
			ls[i] = line
	return ls

# a one-off scripted conversation (the king scene): `ls` are the lines, `done` runs after the box closes
func start_scene(n, ls: Array, done: Callable) -> void:
	npc = n
	lines = ls.duplicate()
	set_stage_after = -1
	then_after = ""
	give_after = {}
	take_after = {}
	note_after = ""
	_first_key = ""
	on_close = done
	idx = 0
	_begin_line()
	n.dir = "down"
	open = true
	world.talking = true
	get_tree().paused = true

func _line_text() -> String:
	var l = lines[idx]
	return l if l is String else l["t"]

# who says the current line: its "who" (a PEOPLE id), or the person the conversation is with
func _speaker() -> String:
	var l = lines[idx]
	return l["who"] if l is Dictionary and l.has("who") else npc.id

func _begin_line() -> void:
	shown = 0.0
	choosing = false
	sel = 0

func _has_choices() -> bool:
	return lines[idx] is Dictionary and lines[idx].has("choices")

func _advance() -> void:
	if not open:
		return
	var total := _line_text().length()
	if shown < total:
		shown = total
		return
	if _has_choices():
		if not choosing:
			choosing = true
			return
		var pick: Dictionary = lines[idx]["choices"][sel]
		lines = lines.slice(0, idx + 1) + pick.get("lines", [])
		lines[idx] = _line_text()    # the question line is done; drop its choices
		if pick.has("then"):
			then_after = pick["then"]
	idx += 1
	if idx >= lines.size():
		_close()
	else:
		_begin_line()

func _close() -> void:
	open = false
	world.talking = false
	var spoken_to = npc
	npc = null
	if set_stage_after >= 0:
		quest.set_stage(set_stage_after)
	if _first_key != "":
		quest.flags[_first_key] = true
		_first_key = ""
	for id in take_after:
		inv.remove(id, take_after[id])
	take_after = {}
	for id in give_after:
		inv.add(id, give_after[id])
	give_after = {}
	quest.note(note_after)          # after the items change hands, so a side quest's line reads right at once
	note_after = ""
	get_tree().paused = false
	if on_close.is_valid():
		var cb := on_close
		on_close = Callable()
		cb.call()
	if then_after != "":
		var what := then_after
		then_after = ""
		if what.begins_with("squad_"):
			if squad_order.is_valid():
				squad_order.call(spoken_to, what.trim_prefix("squad_"))
		elif what.begins_with("shop_"):
			if shop != null:
				shop.open_on(what.trim_prefix("shop_"))
		else:
			world.talk_done(what)

func _process(delta: float) -> void:
	if open:
		shown = minf(shown + CPS * delta, float(_line_text().length()))
	ui.queue_redraw()

# ---------- drawing ----------
const PARCH := Color("#e8d6a8")
const PARCH_D := Color("#c9ad74")
const INK := Color("#3a2614")
const FRAME := Color("#4a3018")

func _draw_ui() -> void:
	if sign_open:
		var font := ThemeDB.fallback_font
		ui.draw_rect(Rect2(0, 0, 480, 270), Color(0, 0, 0, 0.28))
		var bx := 68.0; var by := 84.0; var bw := 344.0; var bh := 102.0
		ui.draw_rect(Rect2(bx + 3, by + 3, bw, bh), Color(0, 0, 0, 0.4))
		ui.draw_rect(Rect2(bx, by, bw, bh), FRAME)
		ui.draw_rect(Rect2(bx + 3, by + 3, bw - 6, bh - 6), PARCH)
		ui.draw_string(font, Vector2(bx + 18, by + 25), "WOODEN SIGNPOST", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#8a5a32"))
		for i in range(sign_lines.size()):
			_draw_sign_row(font, bx + 22.0, by + 49.0 + i * 21.0, sign_lines[i])
		ui.draw_string(font, Vector2(bx + 18, by + 91), "Press E to close", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("#6a5030"))
		return
	if not open:
		return
	var font := ThemeDB.fallback_font
	ui.draw_rect(Rect2(0, 0, 480, 270), Color(0, 0, 0, 0.28))    # dim the paused world
	var bx := 10.0; var by := 190.0; var bw := 460.0; var bh := 72.0
	ui.draw_rect(Rect2(bx + 2, by + 2, bw, bh), Color(0, 0, 0, 0.35))
	ui.draw_rect(Rect2(bx, by, bw, bh), FRAME)
	ui.draw_rect(Rect2(bx + 2, by + 2, bw - 4, bh - 4), PARCH)
	ui.draw_rect(Rect2(bx + 4, by + 4, bw - 8, bh - 8), PARCH_D, false)
	# portrait
	_draw_portrait(Rect2(bx + 8, by + 8, 56, 56))
	# name plate
	var nm: String = PEOPLE[_speaker()]["name"]
	var nw := font.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x + 14.0
	ui.draw_rect(Rect2(bx + 72, by - 8, nw, 15), FRAME)
	ui.draw_rect(Rect2(bx + 74, by - 6, nw - 4, 11), Color("#7a5530"))
	ui.draw_string(font, Vector2(bx + 79, by + 3), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("#f4ead0"))
	# text
	var txt := _line_text()
	var shown_txt := txt.substr(0, int(shown))
	ui.draw_multiline_string(font, Vector2(bx + 74, by + 22), shown_txt, HORIZONTAL_ALIGNMENT_LEFT, bw - 90.0, 10, 3, INK)
	# choices
	if choosing:
		var ch: Array = lines[idx]["choices"]
		for i in range(ch.size()):
			var cy := by + 38.0 + i * 13.0
			if i == sel:
				ui.draw_rect(Rect2(bx + 72, cy - 9, bw - 90.0, 12), Color(0.29, 0.19, 0.09, 0.22))
				ui.draw_colored_polygon(PackedVector2Array([Vector2(bx + 76, cy - 7), Vector2(bx + 76, cy), Vector2(bx + 81, cy - 3.5)]), INK)
			ui.draw_string(font, Vector2(bx + 86, cy), ch[i]["label"], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, INK)
	elif int(shown) >= txt.length() and fmod(Time.get_ticks_msec() / 1000.0, 0.9) < 0.55:
		var ax := bx + bw - 18.0; var ay := by + bh - 16.0
		ui.draw_colored_polygon(PackedVector2Array([Vector2(ax, ay), Vector2(ax + 8, ay), Vector2(ax + 4, ay + 5)]), INK)

# one row of a signpost: DIRECTION  [arrow]  DESTINATION (the arrow is drawn, so it never depends on the font)
func _draw_sign_row(font: Font, x: float, y: float, row: Array) -> void:
	ui.draw_string(font, Vector2(x, y), row[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, INK)
	var ax := x + 62.0
	var ay := y - 4.0
	if row[2] == "up":
		ui.draw_colored_polygon(PackedVector2Array([Vector2(ax, ay - 5), Vector2(ax + 5, ay + 1), Vector2(ax - 5, ay + 1)]), INK)
		ui.draw_rect(Rect2(ax - 1, ay + 1, 3, 5), INK)
	else:
		ui.draw_colored_polygon(PackedVector2Array([Vector2(ax + 5, ay), Vector2(ax - 1, ay - 5), Vector2(ax - 1, ay + 5)]), INK)
		ui.draw_rect(Rect2(ax - 6, ay - 1, 5, 3), INK)
	ui.draw_string(font, Vector2(x + 80.0, y), row[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, INK)

func _draw_portrait(r: Rect2) -> void:
	draw_portrait(ui, r, _speaker())

# a person's portrait (PEOPLE id) in rect r on canvas n: assets/portraits/<id>.png if it exists, else a placeholder silhouette.
# Also used by the menu's Squad tab and the shop's keeper strip. The silhouette is drawn in a 56 px square and scaled to r (it used
# to keep its 56 px sizes, so in a smaller box its head spilled below the frame).
func draw_portrait(n, r: Rect2, id: String) -> void:
	n.draw_rect(Rect2(r.position - Vector2(2, 2), r.size + Vector2(4, 4)), FRAME)
	var path := "res://assets/portraits/%s.png" % id
	if ResourceLoader.exists(path):
		n.draw_texture_rect(load(path), r, false)
		return
	# placeholder silhouette: dusk backdrop, dark bust, a splash of the character's own colour
	var pal: Dictionary = Sprites.PALETTES.get(PEOPLE[id]["look"], {})
	var accent := Color(pal.get("jac", "#7a4a26"))
	var sil := Color("#2a1c10")
	n.draw_set_transform(r.position, 0.0, r.size / 56.0)
	n.draw_rect(Rect2(0, 0, 56, 56), Color("#b89a5a"))
	n.draw_rect(Rect2(0, 56 * 0.55, 56, 56 * 0.45), Color("#a8884a"))
	var sh := PackedVector2Array()
	for p in Sprites._ellipse(Vector2(28, 62), 56 * 0.95, 34.0):
		sh.append(Vector2(clampf(p.x, 0.0, 56.0), minf(p.y, 56.0)))
	n.draw_colored_polygon(sh, sil)                                                             # shoulders
	n.draw_rect(Rect2(24, 31, 8, 8), sil)                                                      # neck
	n.draw_colored_polygon(Sprites._ellipse(Vector2(28, 24), 22.0, 25.0), sil)                 # head
	n.draw_rect(Rect2(17, 46, 22, 3), accent)                                                  # collar colour
	if pal.get("hat", "") != "":
		n.draw_rect(Rect2(16, 9, 24, 6), Color(pal["hat"]))
	n.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
