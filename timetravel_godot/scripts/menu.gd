extends CanvasLayer
# menu.gd - the game menu. Each key opens it on its own tab (Stage 7k, the user's keys, KEY_TABS): I Player, J Journal, M Map, Tab
# Squad, Esc System. It pauses the game while open, like a conversation.
# One plain, era-neutral look for every era (the user's call, 2026-10-27): a dark see-through panel, a thin grey border, white text and
# one accent colour. The colours below are shared by every panel of this kind (the tuning panel and the shop use them too, and the
# shop also the panel size and detail_head()); the dialogue box keeps its parchment.
# Tabs: Player (Stage 7a's inventory, which became the Player tab in 7f: a top strip with the hero's level, XP and bars; a list of his
# weapons with their levels, then the items by kind (E eats; since 7i, with a companion here, E opens "Use on: You / Farnaka / Back",
# and the Reviving Potion lists the fallen companions); the details of the selected one on the right); Quests (7b: the main thread's
# steps and the optional objectives); Journal (7b: the logs and clues found, and since 7j the records of the era, which E opens in the
# reader; since 7k also an Enemies part: each kind cut down, with its description and the number slain); Map (7k: blank for now); Squad
# (7c: a card per companion of this era, his details, and a Commands box Follow / Wait / Disband / Give item / Back, where Disband is
# refused while the story still needs him, quest.gd NEEDS, and the orders are locked while he is down; Give item (7i) turns the box
# into a list of the food and potions carried); Combos (8e, before System as the user asked: each weapon the hero has, its named
# strings with their L / H / Q letters and moves, what Q and its finishers do, and its guard and parry, read from combat.gd WEAPON_KIT
# with the live numbers); System (7d: the autosave and four save slots, each with Save here / Load / Back, then New game and Quit
# game; overwriting, loading, starting again and quitting ask for a second E).
# Items are applied to the hero or a companion by main.gd use_item, so both tabs say the same things.
# A map can open a found log straight in the reader (read_log); closing it then closes the menu.
# Keys while open: A/D or left/right switch tabs, W/S select, E uses / reads the selected thing; a tab's key goes to that tab, or closes
# the menu if it is the tab already open; Esc closes. While a choice inside a tab is open (a slot's actions, a companion's commands or
# his Give item list, an item's Use on) A/D move inside it instead, and Tab / Esc back out of it first.

const Items = preload("res://scripts/items.gd")
const Quest = preload("res://scripts/quest.gd")
const Squad = preload("res://scripts/squad.gd")
const Save = preload("res://scripts/save.gd")
const Combat = preload("res://scripts/combat.gd")
const Progress = preload("res://scripts/progress.gd")

# ---- the era-neutral style ----
const BACKDROP := Color(0, 0, 0, 0.45)
const BG := Color(0.07, 0.075, 0.085, 0.93)
const BG_LIGHT := Color(0.14, 0.15, 0.17, 0.95)
const EDGE := Color("#8a8f99")
const EDGE_DARK := Color("#40444c")
const TEXT := Color("#f2f2f2")
const DIM := Color("#9a9ea8")
const ACCENT := Color("#8cc8ff")
# the hero's bars (the HUD and the Player tab)
const HP_COL := Color("#e0392b")
const STAMINA_COL := Color("#9ad04a")
const FOCUS_COL := Color("#5aa8ff")
const XP_COL := Color("#ffe9a0")
const MATE_HP_COL := Color("#5ac85a")     # a companion's HP (the HUD, over his head): green, so it reads apart from the red enemy bars
const POISON_COL := Color("#b46ae0")      # poisoned (Stage 7j, the scorpion's sting): the HUD's HP bar and the word "Poisoned"

const TABS := ["player", "quests", "journal", "map", "squad", "combos", "system"]
const TAB_NAMES := {"player": "Player", "quests": "Quests", "journal": "Journal", "map": "Map", "squad": "Squad", "combos": "Combos",
	"system": "System"}
const TAB_GAP := 16.0       # between two tab names, shrunk when the seven don't fit beside "Esc close" (Stage 8e)
# the key (main.gd action) that opens the menu on each tab (the user's keys, Stage 7k). Open, the same key closes it and another
# tab's key goes to that tab; Esc always closes (after backing out of an open choice).
const KEY_TABS := {"inventory": "player", "journal": "journal", "map": "map", "squad_menu": "squad", "system_menu": "system"}
const SYSTEM := ["auto", "1", "2", "3", "4", "new", "quit"]       # save.gd SLOTS, then New game and Quit game
const SYSTEM_NAMES := {"auto": "Autosave", "1": "Slot 1", "2": "Slot 2", "3": "Slot 3", "4": "Slot 4", "new": "New game", "quit": "Quit game"}
const SLOT_ACTS := {"save": "Save here", "load": "Load", "back": "Back"}
const SYSTEM_ROW_H := 20.0
const KIND_LABELS := {"log": "Log", "clue": "Clue", "record": "Record"}    # a journal entry's kind (dialogue.gd LOGS), in the Journal tab
const ORDERS := ["follow", "wait", "home"]
const ORDER_NAMES := {"follow": "Follow", "wait": "Wait here", "home": "Disband", "give": "Give item", "back": "Back"}
const SQUAD_CMDS := ["follow", "wait", "home", "give", "back"]    # the Commands box: the orders, Give item, then Back
# 10x10 pixel icons for the Commands box and the gear slot, as rows of "#" (drawn in the text colour)
const ICONS := {
	"follow": ["....##....", "....##....", "...###....", "..#.##.#..", ".#..##..#.", "....##....", "...#..#...", "..#....#..", ".#......#.", ".........."],
	"wait": ["...#.#.#..", "...#.#.#.#", ".#.#.#.#.#", ".#.#.#.#.#", ".#######.#", ".#########", "..########", "..#######.", "...#####..", "...#####.."],
	"home": [".#........", ".#######..", ".########.", ".#######..", ".######...", ".#........", ".#........", ".#........", ".#........", "###......."],
	"give": ["...####...", "....##....", "....##....", "...#..#...", "..#....#..", "..######..", "..######..", "..######..", "...####...", ".........."],
	"back": [".........."  , "...#......", "..##......", ".#########", "##########", ".#########", "..##......", "...#......", "..........", ".........."],
	"bow": ["..#.##....", "..#...#...", "..#....#..", "..#....#..", "..#.....#.", "..#.....#.", "..#....#..", "..#....#..", "..#...#...", "..#.##...."],
}
const SAY_TIME := 1.8       # how long a status line stays ("You're not hungry.")

# the panel, and the inventory's list (left) and details (right)
const PX := 40.0
const PY := 22.0
const PW := 400.0
const PH := 226.0
const LIST_X := PX + 8.0
const LIST_W := 166.0
const BODY_TOP := PY + 28.0
const BODY_BOTTOM := PY + PH - 32.0
const DX := PX + 186.0
const DW := PW - 196.0
const ROW_H := 14.0
const HEAD_H := 12.0
const STRIP_H := 24.0       # the Player tab's top strip (level, XP, HP / stamina / focus); its list and details start under it

var main                    # main.gd: world, player, progress, combat, dialogue, inv, travelling
var open := false
var tab := "player"
var sel := 0                # the selected entry of the current tab
var reading := ""           # a journal entry (dialogue.gd LOGS id) open in the reader, "" for none
var _read_from_world := false   # the reader was opened by finding the page in the world: closing it closes the menu
var confirm := ""           # System tab: the action waiting for a second E ("save2", "load auto", "new" ...)
var pick := ""              # System tab: the slot whose actions (Save here / Load / Back) are open, "" for none
var pick_sel := 0           # the selected action of that slot
var squad_pick := ""        # Squad tab: the companion (id) whose commands are open, "" for none
var cmd_sel := 0            # the selected command (SQUAD_CMDS)
var give_open := false      # Squad tab: his Give item list is open in the Commands box
var give_sel := 0
var use_pick := ""          # Player tab: the item whose "Use on" choice is open, "" for none
var use_sel := 0
var _infos := {}            # System tab: slot -> where and when it was saved, "" if empty (read from disk on opening, not every frame)
var say_text := ""
var say_t := 0.0
var ui: Control

func _ready() -> void:
	layer = 7
	process_mode = Node.PROCESS_MODE_ALWAYS
	ui = Control.new()
	ui.size = Vector2(480, 270)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.draw.connect(_draw_ui)
	add_child(ui)

func _process(delta: float) -> void:
	say_t = maxf(0.0, say_t - delta)
	ui.queue_redraw()

# not over a conversation, a sign, a door's fade, a scene, the hero's fall (the death screen) or another panel
func can_open() -> bool:
	return not open and not main.travelling and not main.world.talking and not main.player.dead and main.combat.over_t < 0.0 \
		and not main.dialogue.open and not main.dialogue.sign_open and not get_tree().paused

func open_on(t: String) -> void:
	open = true
	tab = t
	sel = 0
	say_t = 0.0
	reading = ""
	_read_from_world = false
	confirm = ""
	_close_inner(true)
	_read_infos()
	main.world.talking = true
	get_tree().paused = true

func close() -> void:
	open = false
	reading = ""
	main.world.talking = false
	get_tree().paused = false

# a map found a log (the ruins' torn page): show it in the reader straight away
func read_log(id: String) -> void:
	if not open:
		open_on("journal")
		_read_from_world = true
	reading = id

func _say(t: String) -> void:
	say_text = t
	say_t = SAY_TIME

# ---------------------------------------------------------------- input
# the tab a key press asks for (KEY_TABS), "" for none
func _key_tab(event: InputEvent) -> String:
	for a in KEY_TABS.keys():
		if event.is_action_pressed(a):
			return KEY_TABS[a]
	return ""

func _unhandled_input(event: InputEvent) -> void:
	var want := _key_tab(event)
	if not open:
		if want != "" and can_open():
			open_on(want)
			get_viewport().set_input_as_handled()
		return
	var closing := event.is_action_pressed("menu") or want != ""
	if reading != "":
		if closing or event.is_action_pressed("interact"):
			if _read_from_world:
				close()
			else:
				reading = ""
			get_viewport().set_input_as_handled()
		elif event is InputEventKey or event is InputEventAction:
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("menu") and _inner_open():
		_close_inner()                   # Tab / Esc backs out of an open choice first; the next press acts as below
	elif want != "" and want != tab and want != "system":
		tab = want                       # another tab's key: go there
		sel = 0
		_close_inner(true)
	elif closing:
		close()
	elif _inner_open() and (event.is_action_pressed("move_left") or event.is_action_pressed("move_right")):
		_move_sel(-1 if event.is_action_pressed("move_left") else 1)    # A/D move inside the choice, never to another tab
	elif event.is_action_pressed("move_left"):
		_switch_tab(-1)
	elif event.is_action_pressed("move_right"):
		_switch_tab(1)
	elif event.is_action_pressed("move_up"):
		_move_sel(-1)
	elif event.is_action_pressed("move_down"):
		_move_sel(1)
	elif event.is_action_pressed("interact"):
		_use()
	else:
		return
	get_viewport().set_input_as_handled()

func _switch_tab(d: int) -> void:
	var i := (TABS.find(tab) + d + TABS.size()) % TABS.size()
	if TABS[i] != tab:
		tab = TABS[i]
		sel = 0
		_close_inner(true)

# a choice opened inside a tab (a slot's Save here / Load / Back, a companion's commands, an item's Use on): while it is open A/D move
# inside it
func _inner_open() -> bool:
	return (tab == "system" and pick != "") or (tab == "squad" and squad_pick != "") or (tab == "player" and use_pick != "")

# Esc out of an open choice: out of a Give item list back to his commands first, otherwise out of the choice (all: out of everything,
# when the menu opens or the tab changes)
func _close_inner(all := false) -> void:
	confirm = ""
	if give_open and not all:
		give_open = false
		return
	give_open = false
	pick = ""
	squad_pick = ""
	use_pick = ""

func _move_sel(d: int) -> void:
	confirm = ""
	if tab == "system" and pick != "":
		pick_sel = clampi(pick_sel + d, 0, _slot_acts(pick).size() - 1)
		return
	if tab == "player" and use_pick != "":
		use_sel = clampi(use_sel + d, 0, _use_targets(use_pick).size() - 1)
		return
	if tab == "squad" and give_open:
		var list := _members()
		if not list.is_empty():
			give_sel = clampi(give_sel + d, 0, _give_list(list[clampi(sel, 0, list.size() - 1)]).size() - 1)
		return
	if tab == "squad" and squad_pick != "":
		cmd_sel = clampi(cmd_sel + d, 0, SQUAD_CMDS.size() - 1)
		return
	var n := 0
	match tab:
		"player":
			n = _entries().size()
		"journal":
			n = _journal_rows().size()
		"squad":
			n = _members().size()
		"combos":
			n = _combo_weapons().size()
		"system":
			n = SYSTEM.size()
	if n > 0:
		sel = clampi(sel + d, 0, n - 1)

func _use() -> void:
	match tab:
		"player":
			if use_pick != "":
				_use_on()
			else:
				_use_item()
		"journal":
			var j := _journal_rows()
			if not j.is_empty():
				reading = j[clampi(sel, 0, j.size() - 1)]
		"squad":
			_give_order()
		"combos":
			_say("Press 1 in play to change weapon.")
		"system":
			_system(SYSTEM[clampi(sel, 0, SYSTEM.size() - 1)])

# ---------------------------------------------------------------- the Player tab
# what the list shows: the hero's weapons ("w:unarmed", "w:lasso"; one that is an item only while he carries it), then everything
# carried except the coins (their own line at the bottom) and the items that are a weapon (already listed as one)
func _entries() -> Array:
	var out := []
	var weapon_items := []
	for w in Progress.WEAPON_ORDER:
		var item: String = Progress.WEAPONS[w]["item"]
		weapon_items.append(item)
		if item == "" or main.inv.has(item):
			out.append("w:" + w)
	for id in main.inv.ids():
		if id != "coins" and not weapon_items.has(id):
			out.append(id)
	return out

func _use_item() -> void:
	var list := _entries()
	if list.is_empty():
		return
	sel = clampi(sel, 0, list.size() - 1)
	var id: String = list[sel]
	if id.begins_with("w:"):
		_say("Press %s in play." % Progress.WEAPONS[id.substr(2)]["key"])
		return
	var it := Items.info(id)
	match it["kind"]:
		"food":
			# with a companion here, ask who gets it (the Reviving Potion: which fallen companion); alone, the hero uses it at once
			var who := _use_targets(id)
			if it.get("revive", false) and who.size() <= 1:
				_say("No one needs reviving.")
			elif who.size() <= 2 and who[0] == main.player:
				_say(main.use_item(id, main.player))
				sel = clampi(sel, 0, maxi(0, _entries().size() - 1))
			else:
				use_pick = id
				use_sel = 0
		"tool":
			_say("Press %s in play to use it." % it.get("key", "?"))

# who an item can go to in the Use on choice, then "back": the hero and the companions with him; for the Reviving Potion only the
# fallen ones (the hero is never revived)
func _use_targets(id: String) -> Array:
	var out := []
	if Items.info(id).get("revive", false):
		out.append_array(main.fallen_mates())
	else:
		out.append(main.player)
		out.append_array(main.combat.mates())
	out.append("back")
	return out

# E in the Use on choice: use the item on the one chosen (a fallen companion only gets the Reviving Potion)
func _use_on() -> void:
	var who := _use_targets(use_pick)
	var t = who[clampi(use_sel, 0, who.size() - 1)]
	if t is String:
		_close_inner()
		return
	if t != main.player and t.down and not Items.info(use_pick).get("revive", false):
		_say("Revive him first.")
		return
	_say(main.use_item(use_pick, t))
	_close_inner()
	sel = clampi(sel, 0, maxi(0, _entries().size() - 1))

# ---------------------------------------------------------------- drawing
func _draw_ui() -> void:
	if not open:
		return
	var font := ThemeDB.fallback_font
	ui.draw_rect(Rect2(0, 0, 480, 270), BACKDROP)
	ui.draw_rect(Rect2(PX + 2, PY + 2, PW, PH), Color(0, 0, 0, 0.35))
	ui.draw_rect(Rect2(PX, PY, PW, PH), BG)
	ui.draw_rect(Rect2(PX, PY, PW, PH), EDGE, false)
	# the tab bar: the names TAB_GAP apart, or closer if they would run into "Esc close"
	var names_w := 0.0
	for t in TABS:
		names_w += font.get_string_size(TAB_NAMES[t], HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
	var room := PW - 28.0 - font.get_string_size("Esc close", HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	var gap := minf(TAB_GAP, (room - names_w) / (TABS.size() - 1))
	var tx := PX + 10.0
	for t in TABS:
		var label: String = TAB_NAMES[t]
		var w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
		ui.draw_string(font, Vector2(tx, PY + 15), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, TEXT if t == tab else DIM)
		if t == tab:
			ui.draw_rect(Rect2(tx, PY + 18, w, 1), ACCENT)
		tx += w + gap
	ui.draw_string(font, Vector2(PX, PY + 14), "Esc close", HORIZONTAL_ALIGNMENT_RIGHT, PW - 10.0, 8, DIM)
	ui.draw_rect(Rect2(PX + 6, PY + 22, PW - 12, 1), EDGE_DARK)
	var help := "A/D tabs   W/S select   E %s   Esc close" % {"journal": "read", "squad": "commands", "system": "choose"}.get(tab, "use")
	if tab == "quests" or tab == "map":
		help = "A/D tabs   I M Tab Esc jump to a tab"     # nothing to pick here
	elif tab == "combos":
		help = "A/D tabs   W/S weapon   1 in play takes it in hand   Esc close"
	elif _inner_open():
		help = "A/D or W/S choose   E confirm   Esc back"
	if reading != "":
		_draw_reader(font)
		help = "E close"
	else:
		match tab:
			"player":
				_draw_player(font)
			"quests":
				_draw_quests(font)
			"journal":
				_draw_journal(font)
			"map":
				_draw_map(font)
			"squad":
				_draw_squad(font)
			"combos":
				_draw_combos(font)
			"system":
				_draw_system(font)
	# status line (right) and the key help (bottom)
	if say_t > 0.0 and say_text != "" and reading == "":
		ui.draw_string(font, Vector2(PX + 10, PY + PH - 20), say_text, HORIZONTAL_ALIGNMENT_RIGHT, PW - 20.0, 9, ACCENT)
	ui.draw_rect(Rect2(PX + 6, PY + PH - 15, PW - 12, 1), EDGE_DARK)
	ui.draw_string(font, Vector2(PX + 10, PY + PH - 5), help, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, DIM)

# ---------------------------------------------------------------- system: the save slots, new game
func _read_infos() -> void:
	_infos = {}
	for s in Save.SLOTS:
		_infos[s] = Save.info(s)

# what E on a slot can do: the autosave is only loaded (main.gd writes it); an empty slot can't be loaded
func _slot_acts(slot: String) -> Array:
	var out := []
	if slot != "auto":
		out.append("save")
	if _infos.get(slot, "") != "":
		out.append("load")
	out.append("back")
	return out

func _system(row: String) -> void:
	if row == "new":
		if confirm != "new":
			confirm = "new"
			_say("Press E again to start again. Anything not saved is lost.")
			return
		main.new_game()
		return
	if row == "quit":
		if confirm != "quit":
			confirm = "quit"
			_say("Press E again to quit. Anything not saved is lost.")
			return
		get_tree().quit()
		return
	if pick != row:                      # the first E opens the slot's actions
		if _slot_acts(row) == ["back"]:
			_say("There is no autosave yet.")
			return
		pick = row
		pick_sel = 0
		confirm = ""
		return
	var act: String = _slot_acts(row)[pick_sel]
	var key := act + " " + row
	match act:
		"back":
			pick = ""
		"save":
			var why: String = main.save_block()
			if why != "":
				_say(why)
				return
			if _infos.get(row, "") != "" and confirm != key:
				confirm = key
				_say("Press E again to overwrite %s." % SYSTEM_NAMES[row])
				return
			_say(("Saved to %s." % SYSTEM_NAMES[row]) if main.save_game(row) else "The game could not be saved.")
			_read_infos()
			pick = ""
			confirm = ""
		"load":
			if confirm != key:
				confirm = key
				_say("Press E again to load. Anything not saved is lost.")
				return
			main.load_game(row)

func _draw_system(font: Font) -> void:
	sel = clampi(sel, 0, SYSTEM.size() - 1)
	if pick != "" and SYSTEM[sel] != pick:
		pick = ""
	var y := BODY_TOP + 4.0
	for i in range(SYSTEM.size()):
		var row: String = SYSTEM[i]
		if row == "new":
			y += 6.0                     # a gap between the slots and New game
		if i == sel:
			ui.draw_rect(Rect2(LIST_X, y, PW - 16.0, SYSTEM_ROW_H - 2), Color(ACCENT, 0.16))
			ui.draw_rect(Rect2(LIST_X, y, 2, SYSTEM_ROW_H - 2), ACCENT)
		ui.draw_string(font, Vector2(LIST_X + 8, y + 12), SYSTEM_NAMES[row], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, TEXT)
		if row == pick:
			# the slot's actions, the selected one in the accent colour
			var ax := LIST_X + 90.0
			var acts := _slot_acts(row)
			for a in range(acts.size()):
				var label: String = SLOT_ACTS[acts[a]]
				var w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
				if a == pick_sel:
					ui.draw_rect(Rect2(ax - 3, y + 3, w + 6, SYSTEM_ROW_H - 8), Color(ACCENT, 0.22))
				ui.draw_string(font, Vector2(ax, y + 12), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, ACCENT if a == pick_sel else DIM)
				ax += w + 16.0
		elif row != "new" and row != "quit":
			var info: String = _infos.get(row, "")
			ui.draw_string(font, Vector2(LIST_X + 90, y + 12), info if info != "" else "Empty", HORIZONTAL_ALIGNMENT_LEFT, -1, 9,
				TEXT if info != "" else DIM)
		y += SYSTEM_ROW_H
	ui.draw_string(font, Vector2(LIST_X + 8, y + 10), "Autosave: when you rest, go through a door, or get a new objective.",
		HORIZONTAL_ALIGNMENT_LEFT, PW - 30.0, 8, DIM)

# ---------------------------------------------------------------- squad
# Left: a card per companion of this era (W/S). Right: the selected one's details, and his Commands box, which E opens (then W/S or
# A/D choose, E gives the order, Back / Esc closes it).
const CARD_W := 140.0
const CARD_H := 40.0
const SX := PX + 160.0              # the right side's left edge
const SW := PW - 168.0

func _members() -> Array:
	return main.squad.current(main.world.era)

# is he on the hero's map right now?
func _with_hero(m: Dictionary) -> bool:
	return m["node"].get_parent() == main.world.ysort

# "" if the order (or Give item) can be given now, else why not
func _order_block(m: Dictionary, o: String) -> String:
	if o == "give":
		return "" if _with_hero(m) else "only when he is with you"
	if m["node"].down:
		return "revive him first"          # he lies where he fell, whatever he is told
	if m["order"] == o:
		return "now"
	if o == "wait" and (m["order"] != "follow" or not _with_hero(m)):
		return "only when he is with you"
	if o == "home" and main.quest.needed(m["id"]) != "":
		return main.quest.needed(m["id"])
	return ""

func _give_order() -> void:
	var list := _members()
	if list.is_empty():
		return
	var m: Dictionary = list[clampi(sel, 0, list.size() - 1)]
	if squad_pick != m["id"]:            # the first E opens his commands
		squad_pick = m["id"]
		cmd_sel = 0
		return
	if give_open:
		_give_item(m)
		return
	var o: String = SQUAD_CMDS[cmd_sel]
	if o == "back":
		_close_inner()
		return
	var block := _order_block(m, o)
	if block != "":
		if block == "now":
			_say("He is already doing that.")
		elif block == "revive him first" or o == "home":
			_say("Not now: %s." % block)
		else:
			_say("He has to be with you for that.")
		return
	if o == "give":
		give_open = true
		give_sel = 0
		return
	main.squad_order(m["id"], o)
	_close_inner()
	match o:
		"follow":
			_say("He follows you." if _with_hero(m) else "He will catch up with you at the next door.")
		"wait":
			_say("He holds his position.")
		"home":
			_say("He heads back to %s." % Squad.MATES[m["id"]]["home"]["name"])

# what Give item offers him, then "back": the food and potions carried (while he is down, only the Reviving Potion)
func _give_list(m: Dictionary) -> Array:
	var out := []
	for id in main.inv.ids():
		var it := Items.info(id)
		if it["kind"] == "food" and it.get("revive", false) == m["node"].down:
			out.append(id)
	out.append("back")
	return out

# E in his Give item list: hand the selected item over (main.gd use_item says how it went), or go back to his commands
func _give_item(m: Dictionary) -> void:
	var items := _give_list(m)
	var id: String = items[clampi(give_sel, 0, items.size() - 1)]
	if id == "back":
		give_open = false
		return
	_say(main.use_item(id, m["node"]))
	give_sel = clampi(give_sel, 0, _give_list(m).size() - 1)
	if m["node"].down == false and Items.info(id).get("revive", false):
		give_open = false              # he is up again: his list changes from the potion to the food

func _status(m: Dictionary) -> String:
	if m["node"].down:
		return "Fallen"
	match m["order"]:
		"follow":
			return "Following you" if _with_hero(m) else "Catching up with you"
		"wait":
			return "Holding his position"
		"home":
			return "At " + String(Squad.MATES[m["id"]]["home"]["name"])
	return ""

# a stat line of the details (squad.gd MATES "stats"): [label, value], read live (the tuning panel can change them)
func _stat(m: Dictionary, key: String) -> Array:
	var n = m["node"]
	match key:
		"hp":
			return ["HP", "Fallen" if n.down else "%d / %d" % [n.hp, n.max_hp]]
		"focus":
			return ["Focus", "%d / %d" % [n.focus, n.max_focus]]
		"arrow_dmg":
			return ["Arrow damage", str(main.combat.arrow_dmg())]
		"shot_every":
			return ["Shoots every", "%.1f s" % Combat.RIDER["shot_every"]]
	return [key, "?"]

# a 10x10 icon from ICONS
func _icon(id: String, x: float, y: float, c: Color) -> void:
	var rows: Array = ICONS.get(id, [])
	for ry in range(rows.size()):
		var row: String = rows[ry]
		for rx in range(row.length()):
			if row[rx] == "#":
				ui.draw_rect(Rect2(x + rx, y + ry, 1, 1), c)

func _draw_squad(font: Font) -> void:
	var list := _members()
	if list.is_empty():
		ui.draw_string(font, Vector2(LIST_X + 2, BODY_TOP + 14), "No one travels with you yet.", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, DIM)
		ui.draw_string(font, Vector2(LIST_X + 2, BODY_TOP + 28), "Companions stay in their own era.", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, DIM)
		return
	sel = clampi(sel, 0, list.size() - 1)
	if squad_pick != "" and list[sel]["id"] != squad_pick:
		squad_pick = ""
	# left: the cards
	ui.draw_string(font, Vector2(LIST_X + 2, BODY_TOP + 9), "SQUAD", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, DIM)
	var y := BODY_TOP + 14.0
	for i in range(list.size()):
		var mi: Dictionary = list[i]
		var person: String = Squad.MATES[mi["id"]]["person"]
		ui.draw_rect(Rect2(LIST_X, y, CARD_W, CARD_H - 3), BG_LIGHT)
		ui.draw_rect(Rect2(LIST_X, y, CARD_W, CARD_H - 3), ACCENT if i == sel else EDGE_DARK, false)
		main.dialogue.draw_portrait(ui, Rect2(LIST_X + 4, y + 3, 31, 31), person)
		ui.draw_string(font, Vector2(LIST_X + 40, y + 12), main.dialogue.PEOPLE[person]["name"], HORIZONTAL_ALIGNMENT_LEFT, CARD_W - 42, 9, TEXT)
		ui.draw_string(font, Vector2(LIST_X + 40, y + 22), Squad.MATES[mi["id"]]["role"], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, DIM)
		ui.draw_string(font, Vector2(LIST_X + 40, y + 32), _status(mi), HORIZONTAL_ALIGNMENT_LEFT, CARD_W - 42, 8, ACCENT)
		y += CARD_H
	ui.draw_rect(Rect2(SX - 8, BODY_TOP, 1, BODY_BOTTOM - BODY_TOP), EDGE_DARK)
	# right, top: the details of the selected one
	var m: Dictionary = list[sel]
	var mate: Dictionary = Squad.MATES[m["id"]]
	ui.draw_string(font, Vector2(SX, BODY_TOP + 9), "DETAILS", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, DIM)
	var dy := BODY_TOP + 21.0
	for l in [["Role", mate["role"]], ["Status", _status(m)]]:
		ui.draw_string(font, Vector2(SX, dy), l[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, DIM)
		ui.draw_string(font, Vector2(SX + 80, dy), l[1], HORIZONTAL_ALIGNMENT_LEFT, SW - 80, 9, TEXT)
		dy += 11.0
	# his stats, two to a row (HP and focus, then his bow), so the Commands box still fits under them
	var stats: Array = mate.get("stats", [])
	for i in range(stats.size()):
		var s := _stat(m, stats[i])
		var sx := SX + (i % 2) * 118.0
		ui.draw_string(font, Vector2(sx, dy), s[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, DIM)
		var bad: bool = s[1] == "Fallen"
		ui.draw_string(font, Vector2(sx + 60, dy), s[1], HORIZONTAL_ALIGNMENT_LEFT, 56.0, 9, HP_COL if bad else TEXT)
		if i % 2 == 1 or i == stats.size() - 1:
			dy += 11.0
	ui.draw_string(font, Vector2(SX, dy + 2), "Equipment", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, DIM)
	var gx := SX + 80.0
	for g in mate.get("gear", []):
		ui.draw_rect(Rect2(gx - 1, dy - 9, 14, 14), BG_LIGHT)
		ui.draw_rect(Rect2(gx - 1, dy - 9, 14, 14), EDGE_DARK, false)
		_icon(g, gx + 1, dy - 7, TEXT)
		ui.draw_string(font, Vector2(gx + 17, dy + 2), String(g).capitalize(), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, TEXT)
		gx += 70.0
	# right, bottom: the Commands box (or, after Give item, the list of what he can be given)
	var by := dy + 10.0
	ui.draw_string(font, Vector2(SX, by + 8), "GIVE ITEM" if give_open else "COMMANDS", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, DIM)
	if squad_pick == "":
		ui.draw_string(font, Vector2(SX, by + 8), "E to choose", HORIZONTAL_ALIGNMENT_RIGHT, SW - 4, 8, DIM)
	by += 12.0
	var box := Rect2(SX - 3, by, SW, SQUAD_CMDS.size() * ROW_H + 4)
	ui.draw_rect(box, BG_LIGHT)
	ui.draw_rect(box, ACCENT if squad_pick != "" else EDGE_DARK, false)
	if give_open:
		_draw_give_list(font, m, by)
		ui.draw_string(font, Vector2(PX + 10, PY + PH - 20), "Companions stay in their own era.", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, DIM)
		return
	var why := ""
	for c in range(SQUAD_CMDS.size()):
		var o: String = SQUAD_CMDS[c]
		var block := "" if o == "back" else _order_block(m, o)
		var ry := by + 2.0 + c * ROW_H
		var on := squad_pick != "" and c == cmd_sel
		if on:
			ui.draw_rect(Rect2(SX - 1, ry, SW - 4, ROW_H - 1), Color(ACCENT, 0.18))
			if block != "" and block != "now":
				why = block
		var col := DIM if (block != "" or squad_pick == "") else TEXT
		_icon(o, SX + 3, ry + 2, ACCENT if on else col)
		ui.draw_string(font, Vector2(SX + 18, ry + 10), ORDER_NAMES[o], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, col)
		if block == "now":
			ui.draw_string(font, Vector2(SX, ry + 10), "(now)", HORIZONTAL_ALIGNMENT_RIGHT, SW - 10, 8, DIM)
		elif block != "":
			ui.draw_string(font, Vector2(SX, ry + 10), "(locked)", HORIZONTAL_ALIGNMENT_RIGHT, SW - 10, 8, DIM)
	# why the selected command can't be given, under the box (wrapped, so a long reason isn't cut off)
	if why != "":
		ui.draw_multiline_string(font, Vector2(SX, box.end.y + 10), why[0].to_upper() + why.substr(1) + ".",
			HORIZONTAL_ALIGNMENT_LEFT, SW - 4, 8, -1, DIM)
	ui.draw_string(font, Vector2(PX + 10, PY + PH - 20), "Companions stay in their own era.", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, DIM)

# his Give item list inside the Commands box (as many rows as the box has, scrolled to keep the selected one in view): each item with
# its icon and how many are carried, then Back
func _draw_give_list(font: Font, m: Dictionary, by: float) -> void:
	var items := _give_list(m)
	give_sel = clampi(give_sel, 0, items.size() - 1)
	var rows := SQUAD_CMDS.size()
	var off := maxi(0, give_sel - rows + 1)
	for r in range(mini(rows, items.size() - off)):
		var i := r + off
		var id: String = items[i]
		var ry := by + 2.0 + r * ROW_H
		var on := i == give_sel
		if on:
			ui.draw_rect(Rect2(SX - 1, ry, SW - 4, ROW_H - 1), Color(ACCENT, 0.18))
		if id == "back":
			_icon("back", SX + 3, ry + 2, ACCENT if on else TEXT)
			ui.draw_string(font, Vector2(SX + 18, ry + 10), "Back" if items.size() > 1 else "Back  (nothing to give)", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, TEXT)
			continue
		Items.icon(ui, id, SX + 2, ry + 1)
		ui.draw_string(font, Vector2(SX + 18, ry + 10), Items.info(id)["name"], HORIZONTAL_ALIGNMENT_LEFT, SW - 60, 9, TEXT)
		ui.draw_string(font, Vector2(SX, ry + 10), "x%d" % main.inv.count(id), HORIZONTAL_ALIGNMENT_RIGHT, SW - 10, 8, DIM)

# ---------------------------------------------------------------- quests
# the main thread's steps so far (done ones ticked, the current one marked), then the optional objectives, across the whole panel
func _draw_quests(font: Font) -> void:
	var q = main.quest
	var y := BODY_TOP + 9.0
	ui.draw_string(font, Vector2(LIST_X + 2, y), String(Quest.THREAD).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, DIM)
	y += 6.0
	var any := false
	for i in range(mini(q.stage + 1, Quest.STEPS.size())):
		var t: String = Quest.STEPS[i]["text"]
		if t == "":
			continue
		any = true
		y = _step_line(font, LIST_X, y, t, "done" if i < q.stage else "now")
	if not any:
		y = _step_line(font, LIST_X, y, "No objective yet.", "none")
	var side := []
	for id in Quest.SIDE.keys():
		var st: String = q.side_state(id)
		if st != "hidden":
			side.append([q.side_label(id) if st == "open" else Quest.SIDE[id]["text"], st])     # an open one shows how far along
	if not side.is_empty():
		y += 8.0
		ui.draw_string(font, Vector2(LIST_X + 2, y), "OPTIONAL", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, DIM)
		y += 6.0
		for s in side:
			var st: String = s[1]
			y = _step_line(font, LIST_X, y, s[0] + (" (missed)" if st == "missed" else ""), "done" if st == "done" else ("none" if st == "missed" else "now"))

# The Journal tab's entries: the writings found (dialogue.gd LOGS ids, in the order found), then since 7k "foe:<kind>" for every enemy
# kind cut down at least once (in dialogue.gd FOES order). E opens either in the reader.
func _journal_rows() -> Array:
	var out: Array = main.quest.journal.duplicate()
	for k in main.dialogue.FOES.keys():
		if main.combat.kills_by.get(k, 0) > 0:
			out.append("foe:" + k)
	return out

# the journal across the whole panel, in two parts under their own headings: WRITINGS (the logs, clues and records) and ENEMIES (each
# kind with the number slain). The headings are drawn rows that can't be selected.
func _draw_journal(font: Font) -> void:
	var rows := _journal_rows()
	var x := LIST_X
	var w := PW - 16.0
	if rows.is_empty():
		ui.draw_string(font, Vector2(x + 2, BODY_TOP + 9), "JOURNAL", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, DIM)
		ui.draw_string(font, Vector2(x + 2, BODY_TOP + 26), "Nothing written yet.", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, DIM)
		return
	sel = clampi(sel, 0, rows.size() - 1)
	var shown := []          # [heading or entry id, its index in rows (-1 for a heading)]
	for i in range(rows.size()):
		var foe: bool = rows[i].begins_with("foe:")
		if i == 0 and not foe:
			shown.append(["h:WRITINGS", -1])
		if foe and (i == 0 or not rows[i - 1].begins_with("foe:")):
			shown.append(["h:ENEMIES", -1])
		shown.append([rows[i], i])
	var at := 0
	for k in range(shown.size()):
		if shown[k][1] == sel:
			at = k
	var off := maxf(0.0, (at + 1) * ROW_H - (BODY_BOTTOM - BODY_TOP - 2.0))
	for k in range(shown.size()):
		var ry := BODY_TOP + 2.0 + k * ROW_H - off
		if ry < BODY_TOP + 1.0 or ry + ROW_H > BODY_BOTTOM + 1.0:
			continue
		var id: String = shown[k][0]
		if id.begins_with("h:"):
			ui.draw_string(font, Vector2(x + 2, ry + 10), id.substr(2), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, DIM)
			continue
		if shown[k][1] == sel:
			ui.draw_rect(Rect2(x, ry, w, ROW_H - 1), Color(ACCENT, 0.16))
			ui.draw_rect(Rect2(x, ry, 2, ROW_H - 1), ACCENT)
		var title: String
		var right: String
		if id.begins_with("foe:"):
			var kind := id.substr(4)
			title = main.dialogue.FOES[kind]["name"]
			right = "Slain %d" % main.combat.kills_by.get(kind, 0)
		else:
			var e: Dictionary = main.dialogue.LOGS.get(id, {"kind": "clue", "title": id})
			title = e["title"]
			right = KIND_LABELS.get(e["kind"], "Clue")
		ui.draw_string(font, Vector2(x + 6, ry + 10), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, TEXT)
		ui.draw_string(font, Vector2(x, ry + 10), right, HORIZONTAL_ALIGNMENT_RIGHT, w - 6.0, 8, DIM)

# the Map tab (Stage 7k): blank for now. It is where an area's map will show once maps can be had (IMPROVEMENTS.md "Maps for sale").
func _draw_map(font: Font) -> void:
	ui.draw_string(font, Vector2(LIST_X + 2, BODY_TOP + 9), "MAP", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, DIM)
	ui.draw_rect(Rect2(LIST_X, BODY_TOP + 14, PW - 16.0, BODY_BOTTOM - BODY_TOP - 16.0), EDGE_DARK, false)
	ui.draw_string(font, Vector2(LIST_X, (BODY_TOP + BODY_BOTTOM) / 2.0 + 4.0), "You have no map of this land yet.",
		HORIZONTAL_ALIGNMENT_CENTER, PW - 16.0, 9, DIM)

# ---------------------------------------------------------------- combos
# The Combos tab (Stage 8e). Left: the weapons the hero has (combat.gd WEAPON_LIST order; W/S), the one in hand marked. Right, for the
# selected one: every string of its WEAPON_KIT row (its letters in combat.gd LETTER_COL, its name, its moves), the bow's held draw, then
# what Q, a finisher and Space do with it. The numbers are read live from combat.gd (the tuning panel can change them). For now every
# string is there from the start (the user's call); teachers will unlock them later.
const COMBO_LIST_W := 92.0
const COMBO_ROW := 11.0

func _combo_weapons() -> Array:
	return Combat.WEAPON_LIST.filter(func(w): return main.combat.has_weapon(w))

# a move's name as the tab shows it ("long_thrust" -> "long thrust")
func _move_label(m: String) -> String:
	return m.replace("_", " ")

func _draw_combos(font: Font) -> void:
	var c = main.combat
	var list := _combo_weapons()
	sel = clampi(sel, 0, list.size() - 1)
	# left: the weapons
	ui.draw_string(font, Vector2(LIST_X + 2, BODY_TOP + 9), "WEAPONS", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, DIM)
	for i in range(list.size()):
		var lw: String = list[i]
		var ly := BODY_TOP + 14.0 + i * ROW_H
		if i == sel:
			ui.draw_rect(Rect2(LIST_X, ly, COMBO_LIST_W, ROW_H - 1), Color(ACCENT, 0.16))
			ui.draw_rect(Rect2(LIST_X, ly, 2, ROW_H - 1), ACCENT)
		Items.icon(ui, lw, LIST_X + 5, ly + 1)
		ui.draw_string(font, Vector2(LIST_X + 22, ly + 10), Combat.WEAPON_KIT[lw]["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, TEXT)
		if lw == c.weapon:
			ui.draw_rect(Rect2(LIST_X + COMBO_LIST_W - 9, ly + 5, 3, 3), ACCENT)
	var key_y := BODY_TOP + 22.0 + list.size() * ROW_H
	ui.draw_rect(Rect2(LIST_X + 6, key_y - 4, 3, 3), ACCENT)
	ui.draw_string(font, Vector2(LIST_X + 13, key_y), "in hand", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, DIM)
	var x0 := LIST_X + COMBO_LIST_W + 16.0
	var rw := PX + PW - 10.0 - x0
	ui.draw_rect(Rect2(x0 - 8, BODY_TOP, 1, BODY_BOTTOM - BODY_TOP), EDGE_DARK)
	# right: the strings, then Q, the finishers and the guard
	var w: String = list[sel]
	var kit: Dictionary = Combat.WEAPON_KIT[w]
	var y := BODY_TOP + 9.0
	ui.draw_string(font, Vector2(x0, y), "STRINGS", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, DIM)
	var lx := x0 + rw
	for part in [["Q", " finisher"], ["H", " heavy (RMB)  "], ["L", " light (LMB)  "]]:      # the legend, right to left
		var tw := font.get_string_size(part[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		lx -= tw
		ui.draw_string(font, Vector2(lx, y), part[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, DIM)
		lx -= font.get_string_size(part[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		ui.draw_string(font, Vector2(lx, y), part[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Combat.LETTER_COL[part[0]])
	for s in kit["strings"].keys():
		y += COMBO_ROW
		for k in range(s.length()):
			ui.draw_string(font, Vector2(x0 + k * 7, y), s[k], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Combat.LETTER_COL[s[k]])
		var row: Dictionary = kit["strings"][s]
		ui.draw_string(font, Vector2(x0 + 26, y), row["name"], HORIZONTAL_ALIGNMENT_LEFT, 100.0, 9, TEXT)
		var moves: Array = row["moves"].map(func(m): return _move_label(m))
		ui.draw_string(font, Vector2(x0 + 130, y), ", ".join(moves), HORIZONTAL_ALIGNMENT_LEFT, rw - 130.0, 8, DIM)
	if kit.has("hold"):            # the bow: H is held to draw, not a string
		y += COMBO_ROW
		ui.draw_string(font, Vector2(x0, y), "H", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Combat.LETTER_COL["H"])
		ui.draw_string(font, Vector2(x0 + 26, y), "held: draw and aim, let go to shoot (%s)" % _move_label(kit["hold"]),
			HORIZONTAL_ALIGNMENT_LEFT, rw - 26.0, 9, TEXT)
	# Q: the special (or the lasso), and the finishers
	y += COMBO_ROW + 6.0
	ui.draw_string(font, Vector2(x0, y), "Q", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Combat.LETTER_COL["Q"])
	var q_text: String
	if kit.has("special"):
		var sp: String = kit["special"]
		q_text = "%s: %d focus, then %.0f s to recharge" % [kit["moves"][sp]["name"], c.focus_val(sp), c.special_cd_max()]
	else:
		q_text = "Lasso: tap to throw (%d stamina); hold, then let go: the strong lasso (%d focus)" % [c.stamina_cost("lasso"),
			c.focus_val("strong")]
	y = _combo_line(font, x0 + 26, y, rw - 26.0, q_text, TEXT)
	var fin := ""
	for s in kit["strings"].keys():
		if s.ends_with("Q"):
			fin = "A Q after a string's second swing ends it with a finisher: %d focus, %.1f x damage, the same recharge." \
				% [c.focus_val("finisher"), Combat.FINISHER["mul"]]
			break
	if fin != "":
		y = _combo_line(font, x0 + 26, y, rw - 26.0, fin, DIM)
	# Space: the guard, and the parry
	y += 4.0
	var g: Dictionary = c.tune["block"].get(w, {})
	if not g.is_empty():
		ui.draw_string(font, Vector2(x0, y), "Space", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, TEXT)
		var parry := "Press it just before a hit to parry it (+%d focus)." % c.tune["parry"]["focus"]
		if not kit.get("parry", true):
			parry = "The bow can't parry."
		_combo_line(font, x0 + 26, y, rw - 26.0, "Block: %d %% of a hit gets through, %d stamina a hit. %s" % [g["cut"], g["stamina"], parry], TEXT)

# a wrapped line of the Combos tab at (x, y); returns the y of the next one
func _combo_line(font: Font, x: float, y: float, w: float, t: String, col: Color) -> float:
	var h := font.get_multiline_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, w, 8).y
	ui.draw_multiline_string(font, Vector2(x, y), t, HORIZONTAL_ALIGNMENT_LEFT, w, 8, -1, col)
	return y + maxf(h, COMBO_ROW)

# one objective line in the Quests tab (wrapped to the panel): a tick (done), a filled marker (current) or a plain dot; returns the
# y of the next line
func _step_line(font: Font, x: float, y: float, t: String, state: String) -> float:
	var w := PW - 30.0
	var h := font.get_multiline_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, w, 9).y
	var top := y + 2.0
	match state:
		"done":
			for p in [[2, 5], [3, 6], [4, 7], [5, 6], [6, 5], [7, 4], [8, 3]]:     # a pixel tick
				ui.draw_rect(Rect2(x + p[0], top + p[1], 1, 1), ACCENT)
		"now":
			ui.draw_rect(Rect2(x + 3, top + 3, 4, 4), TEXT)
		_:
			ui.draw_rect(Rect2(x + 4, top + 4, 2, 2), DIM)
	ui.draw_multiline_string(font, Vector2(x + 12, top + 8), t, HORIZONTAL_ALIGNMENT_LEFT, w, 9, -1, TEXT if state == "now" else DIM)
	return y + maxf(h, 11.0) + 2.0

# a journal entry, full size: its title, whose words they are (its own "by" line, or one for its kind), and the text. An enemy kind
# ("foe:<kind>") shows its name, the number slain and its description.
func _draw_reader(font: Font) -> void:
	var e: Dictionary
	var by: String
	if reading.begins_with("foe:"):
		var kind := reading.substr(4)
		e = main.dialogue.FOES.get(kind, {"name": kind, "text": ""})
		e = {"title": e["name"], "text": e["text"]}
		by = "Enemy   -   slain: %d" % main.combat.kills_by.get(kind, 0)
	else:
		e = main.dialogue.LOGS.get(reading, {"kind": "clue", "title": reading, "text": ""})
		by = e.get("by", "From the stranger's notebook" if e["kind"] == "log" else KIND_LABELS.get(e["kind"], "Clue"))
	var x := PX + 18.0
	ui.draw_string(font, Vector2(x, BODY_TOP + 14), e["title"], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, TEXT)
	ui.draw_string(font, Vector2(x, BODY_TOP + 28), by, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, ACCENT)
	ui.draw_rect(Rect2(x, BODY_TOP + 33, PW - 36, 1), EDGE_DARK)
	ui.draw_multiline_string(font, Vector2(x, BODY_TOP + 48), e["text"], HORIZONTAL_ALIGNMENT_LEFT, PW - 36.0, 10, -1, TEXT)

func _draw_player(font: Font) -> void:
	_draw_strip(font)
	var top := BODY_TOP + STRIP_H + 4.0
	var list := _entries()
	sel = clampi(sel, 0, maxi(0, list.size() - 1))
	# rows: the weapons under their heading, then a heading per kind and its items; scrolled so the selected one is always in view
	var rows := []
	var last_kind := ""
	for id in list:
		var k: String = "weapon" if id.begins_with("w:") else Items.info(id)["kind"]
		if k != last_kind:
			rows.append({"head": "Weapons" if k == "weapon" else Items.KIND_NAMES[k], "y": 0.0})
			last_kind = k
		rows.append({"id": id, "y": 0.0})
	var yy := 0.0
	var sel_bottom := 0.0
	for r in rows:
		r["y"] = yy
		yy += HEAD_H if r.has("head") else ROW_H
		if r.has("id") and r["id"] == list[sel]:
			sel_bottom = yy
	var off := maxf(0.0, sel_bottom - (BODY_BOTTOM - top))
	for r in rows:
		var y: float = top + r["y"] - off
		if y < top - 1.0 or y + ROW_H > BODY_BOTTOM + 1.0:
			continue
		if r.has("head"):
			ui.draw_string(font, Vector2(LIST_X + 2, y + 9), String(r["head"]).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, DIM)
			continue
		var id: String = r["id"]
		if id == list[sel]:
			ui.draw_rect(Rect2(LIST_X, y, LIST_W, ROW_H - 1), Color(ACCENT, 0.16))
			ui.draw_rect(Rect2(LIST_X, y, 2, ROW_H - 1), ACCENT)
		if id.begins_with("w:"):
			var w := id.substr(2)
			Items.icon(ui, _weapon_icon(w), LIST_X + 5, y + 1)
			ui.draw_string(font, Vector2(LIST_X + 22, y + 10), Progress.WEAPONS[w]["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, TEXT)
			_mini_bar(LIST_X + LIST_W - 64, y + 6, 30, 2, main.progress.wfrac(w), XP_COL)
			ui.draw_string(font, Vector2(LIST_X, y + 10), "Lv %d" % main.progress.wlevel(w), HORIZONTAL_ALIGNMENT_RIGHT, LIST_W - 4.0, 9, DIM)
			continue
		Items.icon(ui, id, LIST_X + 5, y + 1)
		ui.draw_string(font, Vector2(LIST_X + 22, y + 10), Items.info(id)["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, TEXT)
		var n: int = main.inv.count(id)
		if n > 1:
			ui.draw_string(font, Vector2(LIST_X, y + 10), "x%d" % n, HORIZONTAL_ALIGNMENT_RIGHT, LIST_W - 4.0, 9, DIM)
	# coins, bottom left
	var sy := PY + PH - 20
	Items.icon(ui, "coins", LIST_X + 4, sy - 10)
	ui.draw_string(font, Vector2(LIST_X + 22, sy), "Coins  %d" % main.inv.count("coins"), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, TEXT)
	ui.draw_rect(Rect2(PX + 180, top, 1, BODY_BOTTOM - top), EDGE_DARK)
	# the selected weapon or item, right
	if list.is_empty():
		return
	var id: String = list[sel]
	if id.begins_with("w:"):
		_draw_weapon(font, id.substr(2), top)
		return
	var it := Items.info(id)
	detail_head(ui, font, id, it["name"], Items.KIND_NAMES[it["kind"]] + ("   x%d" % main.inv.count(id) if main.inv.count(id) > 1 else ""), top)
	var action := ""
	var y := top + 60.0
	match it["kind"]:
		"food":
			if it.get("revive", false):
				action = "E  revive  (%d %% HP)" % Combat.RIDER["revive"]
			elif it.has("focus"):
				action = "E  %s  (+%d focus)" % [it.get("use", "eat"), it["focus"]]
			else:
				action = "E  %s  (+%d HP)" % [it.get("use", "eat"), it["heal"]]
		"tool":
			action = "Key %s in play" % it.get("key", "?")
		"rare":      # a lasting bonus while carried; Nidu's stall buys it (shop.gd), and the bonus goes with it
			action = "While carried: " + Items.bonus_text(id)
			ui.draw_string(font, Vector2(DX, y), "Sells for %d coins" % it.get("sell", 0), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, DIM)
			y += 12.0
	if action != "":
		ui.draw_string(font, Vector2(DX + 52, top + 40), action, HORIZONTAL_ALIGNMENT_LEFT, DW - 52.0, 9 if it["kind"] != "rare" else 8, ACCENT)
	if use_pick == id:
		_draw_use_on(font, id, y)
		return
	ui.draw_multiline_string(font, Vector2(DX, y), it["desc"], HORIZONTAL_ALIGNMENT_LEFT, DW, 9, int((BODY_BOTTOM - y + 8.0) / 10.0), TEXT)

# the "Use on" choice in place of the description: each one who can get the item, with the bar it fills (HP, or focus for a focus
# potion), then Back. A fallen companion is greyed for anything but the Reviving Potion.
func _draw_use_on(font: Font, id: String, y: float) -> void:
	var it := Items.info(id)
	var who := _use_targets(id)
	use_sel = clampi(use_sel, 0, who.size() - 1)
	ui.draw_string(font, Vector2(DX, y + 2), "USE ON", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, DIM)
	var box := Rect2(DX - 3, y + 6, DW, who.size() * ROW_H + 4)
	ui.draw_rect(box, BG_LIGHT)
	ui.draw_rect(box, ACCENT, false)
	for i in range(who.size()):
		var t = who[i]
		var ry := box.position.y + 2.0 + i * ROW_H
		var on := i == use_sel
		if on:
			ui.draw_rect(Rect2(DX - 1, ry, DW - 4, ROW_H - 1), Color(ACCENT, 0.18))
		if t is String:
			_icon("back", DX + 3, ry + 2, ACCENT if on else TEXT)
			ui.draw_string(font, Vector2(DX + 18, ry + 10), "Back", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, TEXT)
			continue
		var hero: bool = t == main.player
		var greyed: bool = not hero and t.down and not it.get("revive", false)
		var label: String = "You" if hero else main.mate_name(t)
		var bar := ""
		if not hero and t.down:
			bar = "Fallen"
		elif it.has("focus"):
			bar = "Focus %d / %d" % [t.focus, t.max_focus]
		else:
			bar = "HP %d / %d" % [t.hp, t.max_hp]
		ui.draw_string(font, Vector2(DX + 6, ry + 10), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, DIM if greyed else TEXT)
		ui.draw_string(font, Vector2(DX, ry + 10), bar, HORIZONTAL_ALIGNMENT_RIGHT, DW - 10, 8, HP_COL if bar == "Fallen" else DIM)

# the top strip: "Lv 3", the XP bar and its numbers ("MAX" at the cap), then HP, stamina and focus as numbers
func _draw_strip(font: Font) -> void:
	var pr = main.progress
	var p = main.player
	var y := BODY_TOP
	ui.draw_string(font, Vector2(LIST_X + 2, y + 15), "Lv %d" % pr.level, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, TEXT)
	_mini_bar(LIST_X + 40, y + 5, 118, 4, pr.frac(), XP_COL)
	var line: String = "MAX  (a teacher can raise it)" if pr.at_cap() else "%d / %d XP" % [pr.xp, pr.total_for(pr.level + 1)]
	ui.draw_string(font, Vector2(LIST_X + 40, y + 19), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, DIM)
	var x := DX
	for c in [["HP", p.hp, p.max_hp, HP_COL], ["Stamina", p.stamina, p.max_stamina, STAMINA_COL], ["Focus", p.focus, p.max_focus, FOCUS_COL]]:
		ui.draw_string(font, Vector2(x, y + 8), c[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, c[3])
		ui.draw_string(font, Vector2(x, y + 19), "%d / %d" % [c[1], c[2]], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, TEXT)
		x += 68.0
	ui.draw_rect(Rect2(PX + 6, y + STRIP_H, PW - 12, 1), EDGE_DARK)

# a weapon's details: its level and cap, its XP to the next level (or that a teacher is needed), what it adds now and next, its costs
func _draw_weapon(font: Font, w: String, top: float) -> void:
	var pr = main.progress
	var d: Dictionary = Progress.WEAPONS[w]
	var lv: int = pr.wlevel(w)
	detail_head(ui, font, _weapon_icon(w), d["name"], "Weapon   Lv %d / %d" % [lv, pr.wcap[w]], top)
	ui.draw_string(font, Vector2(DX + 52, top + 40), "Key %s in play" % d["key"], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, ACCENT)
	var y := top + 58.0
	if lv >= pr.wtop(w):
		ui.draw_string(font, Vector2(DX, y), "Weapon XP: MAX. A teacher can take you further.", HORIZONTAL_ALIGNMENT_LEFT, DW, 8, XP_COL)
	else:
		ui.draw_string(font, Vector2(DX, y), "Weapon XP  %d / %d" % [pr.wxp[w], pr.wtotal(w, lv + 1)], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, TEXT)
		_mini_bar(DX + 110, y - 5, DW - 112, 3, pr.wfrac(w), XP_COL)
	y += 11.0
	ui.draw_string(font, Vector2(DX, y), "Now: " + (pr.bonus_text(w, lv) if lv > 1 else "no bonus yet"), HORIZONTAL_ALIGNMENT_LEFT, DW, 8, TEXT)
	if lv < pr.wtop(w):
		y += 11.0
		ui.draw_string(font, Vector2(DX, y), "Next: " + pr.bonus_text(w, lv + 1), HORIZONTAL_ALIGNMENT_LEFT, DW, 8, DIM)
	y += 11.0
	var c = main.combat
	var cost := ""
	if w == "lasso":
		cost = "Stamina %d a throw; strong lasso %d focus" % [c.stamina_cost("lasso"), c.focus_val("strong")]
	else:      # (Stage 8e: from the weapon's own moves, combat.gd WEAPON_KIT; the bow's heavy is its draw, a second's worth)
		var light := _first_move(w, "L")
		var heavy := _first_move(w, "H")
		var per_s: String = " a second" if Combat.WEAPON_KIT[w].has("hold") else ""
		cost = "Stamina: %s %d, %s %d%s%s" % [_move_label(light), c.stamina_cost(light), _move_label(heavy), c.stamina_cost(heavy),
			per_s, "   (in hand)" if c.weapon == w else ""]
	ui.draw_string(font, Vector2(DX, y), cost, HORIZONTAL_ALIGNMENT_LEFT, DW, 8, DIM)
	y += 6.0
	ui.draw_multiline_string(font, Vector2(DX, y + 8), d["desc"], HORIZONTAL_ALIGNMENT_LEFT, DW, 8, int((BODY_BOTTOM - y) / 9.0), TEXT)

# the right side's head on canvas n: a big icon in a box, the name, and a line under it (static: the shop draws the same one)
static func detail_head(n, font: Font, icon_id: String, title: String, sub: String, top: float) -> void:
	n.draw_rect(Rect2(DX, top, 44, 44), BG_LIGHT)
	n.draw_rect(Rect2(DX, top, 44, 44), EDGE_DARK, false)
	Items.icon(n, icon_id, DX + 4, top + 4, 3.0)
	n.draw_string(font, Vector2(DX + 52, top + 13), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, TEXT)
	n.draw_string(font, Vector2(DX + 52, top + 26), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, DIM)

# the first move a light ("L") or heavy ("H") press plays with weapon w (the bow's heavy is its held draw)
func _first_move(w: String, key: String) -> String:
	var kit: Dictionary = Combat.WEAPON_KIT[w]
	if key == "H" and kit.has("hold"):
		return kit["hold"]
	for s in kit["strings"].keys():
		if s.begins_with(key):
			return kit["strings"][s]["moves"][0]
	return ""

# the icon a weapon is drawn with: its item's (the lasso), else its own (items.gd ART "unarmed")
func _weapon_icon(w: String) -> String:
	var item: String = Progress.WEAPONS[w]["item"]
	return item if item != "" else w

func _mini_bar(x: float, y: float, w: float, h: float, frac: float, col: Color) -> void:
	ui.draw_rect(Rect2(x - 1, y - 1, w + 2, h + 2), Color(0, 0, 0, 0.8))
	ui.draw_rect(Rect2(x, y, w, h), Color(col.darkened(0.75), 0.9))
	var fw := roundf(w * clampf(frac, 0.0, 1.0))
	if fw > 0.0:
		ui.draw_rect(Rect2(x, y, fw, h), col)
