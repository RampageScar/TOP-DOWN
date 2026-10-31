extends CanvasLayer
# shop.gd - a trader's stall (Stage 7h): Scribe Nidu's in the town. Talking to the keeper and picking "Show me your goods." opens it
# (dialogue.gd TALK, a "then" of "shop_<keeper>"). Two tabs: Buy (the keeper's goods at each item's items.gd "price", one per E, paid
# in coins) and Sell (the rare finds the hero carries, for their "sell"; a second E confirms, since the find's lasting bonus goes with
# it). Stock never runs out, and nothing sold can be bought back. Pauses the game while open, like the menu, and uses the menu's
# era-neutral style constants and panel size; the keeper's own words come from dialogue.gd SHOP_LINES.
# Since Stage 8e Nidu also sells the spear and the bow (costly on purpose, the user's prices); a weapon is carried once, so a second
# isn't sold. The Buy list scrolls when it is longer than its box.
# Keys: A/D switch Buy / Sell, W/S select, E buys or sells, Tab / Esc leave.

const Items = preload("res://scripts/items.gd")
const Menu = preload("res://scripts/menu.gd")

# every shop in the game, keyed by its keeper (a dialogue.gd PEOPLE id): its name, what it sells (item ids, listed in this order) and
# which kinds of item it buys (items.gd kinds; only an item with a "sell" price is bought)
const SHOPS := {
	"nidu": {"name": "Scribe Nidu's stall", "buys": ["rare"], "sells": ["bread", "apple", "small_potion", "large_potion",
		"small_focus", "large_focus", "antidote", "revive_potion", "spear", "bow"]},      # (the weapons since Stage 8e)
}
const TABS := ["buy", "sell"]
const TAB_NAMES := {"buy": "Buy", "sell": "Sell"}
const SAY_TIME := 1.8       # how long a status line stays ("Not enough coins.")
const KEEPER_H := 32.0      # the keeper's strip under the tab bar (portrait, name, the keeper's last words)

var main                    # main.gd: player, inv, progress, dialogue, world
var open := false
var keeper := ""            # whose shop is open (a SHOPS key)
var tab := "buy"
var sel := 0
var confirm := ""           # Sell: the item waiting for a second E
var line := ""              # what the keeper says in the strip: a greeting, then a word after each sale
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

# does this person keep a shop? (dialogue.gd gives them the coin mark)
func keeps(id: String) -> bool:
	return SHOPS.has(id)

func open_on(who: String) -> void:
	if not SHOPS.has(who):
		return
	open = true
	keeper = who
	tab = "buy"
	sel = 0
	confirm = ""
	say_t = 0.0
	line = _words("hello")
	main.world.talking = true
	get_tree().paused = true

func close() -> void:
	open = false
	main.world.talking = false
	get_tree().paused = false

# one of the keeper's lines (dialogue.gd SHOP_LINES): "hello", "bought", "sold", "short"
func _words(what: String) -> String:
	return main.dialogue.SHOP_LINES.get(keeper, {}).get(what, "")

func _say(t: String) -> void:
	say_text = t
	say_t = SAY_TIME

# what the open tab lists: the keeper's goods (Buy), or what the hero carries that the keeper buys (Sell)
func _entries() -> Array:
	var s: Dictionary = SHOPS[keeper]
	if tab == "buy":
		return s["sells"]
	var out := []
	for id in main.inv.ids():
		var it := Items.info(id)
		if s["buys"].has(it["kind"]) and it.has("sell"):
			out.append(id)
	return out

# ---------------------------------------------------------------- input
func _unhandled_input(event: InputEvent) -> void:
	if not open:
		return
	if event.is_action_pressed("menu"):
		close()
	elif event.is_action_pressed("move_left") or event.is_action_pressed("move_right"):
		var d := -1 if event.is_action_pressed("move_left") else 1
		tab = TABS[(TABS.find(tab) + d + TABS.size()) % TABS.size()]
		sel = 0
		confirm = ""
	elif event.is_action_pressed("move_up") or event.is_action_pressed("move_down"):
		var n := _entries().size()
		if n > 0:
			sel = clampi(sel + (-1 if event.is_action_pressed("move_up") else 1), 0, n - 1)
		confirm = ""
	elif event.is_action_pressed("interact"):
		if tab == "buy":
			buy()
		else:
			sell()
	else:
		return
	get_viewport().set_input_as_handled()

# E on Buy: one of the selected item for its price, if the hero has the coins
func buy() -> void:
	var list := _entries()
	if list.is_empty():
		return
	sel = clampi(sel, 0, list.size() - 1)
	var id: String = list[sel]
	var price := int(Items.info(id).get("price", 0))
	if _owned_tool(id):
		_say("You already have one.")
		return
	if main.inv.count("coins") < price:
		_say("Not enough coins.")
		line = _words("short")
		return
	main.inv.remove("coins", price)
	main.inv.add(id, 1, false)          # (no HUD toast: the status line says it, and a run of buys would pile them up)
	_say("Bought: %s. -%d coins%s" % [Items.info(id)["name"], price, ". Key 1 in play" if _is_tool(id) else ""])
	line = _words("bought")

# a tool (a weapon: the spear, the bow) is carried once; buying it again would only waste the coins
func _is_tool(id: String) -> bool:
	return Items.info(id)["kind"] == "tool"

func _owned_tool(id: String) -> bool:
	return _is_tool(id) and main.inv.has(id)

# E on Sell: the first E asks (the find's bonus goes with it), the second sells it for its "sell" price
func sell() -> void:
	var list := _entries()
	if list.is_empty():
		return
	sel = clampi(sel, 0, list.size() - 1)
	var id: String = list[sel]
	var it := Items.info(id)
	if confirm != id:
		confirm = id
		var bonus := Items.bonus_text(id)
		_say("Press E again to sell it." + ("  You lose its %s." % bonus if bonus != "" else ""))
		return
	confirm = ""
	main.inv.remove(id)
	main.inv.add("coins", int(it["sell"]), false)
	main.progress.apply_max()           # the bonus is gone at once (main.gd would only see it once the game runs again)
	_say("Sold: %s. +%d coins" % [it["name"], int(it["sell"])])
	line = _words("sold")
	sel = clampi(sel, 0, maxi(0, _entries().size() - 1))

# ---------------------------------------------------------------- drawing
func _draw_ui() -> void:
	if not open:
		return
	var font := ThemeDB.fallback_font
	var px := Menu.PX
	var py := Menu.PY
	var pw := Menu.PW
	var ph := Menu.PH
	ui.draw_rect(Rect2(0, 0, 480, 270), Menu.BACKDROP)
	ui.draw_rect(Rect2(px + 2, py + 2, pw, ph), Color(0, 0, 0, 0.35))
	ui.draw_rect(Rect2(px, py, pw, ph), Menu.BG)
	ui.draw_rect(Rect2(px, py, pw, ph), Menu.EDGE, false)
	# the tab bar, and the shop's name on the right
	var tx := px + 10.0
	for t in TABS:
		var label: String = TAB_NAMES[t]
		var w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
		ui.draw_string(font, Vector2(tx, py + 15), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Menu.TEXT if t == tab else Menu.DIM)
		if t == tab:
			ui.draw_rect(Rect2(tx, py + 18, w, 1), Menu.ACCENT)
		tx += w + 16.0
	ui.draw_string(font, Vector2(px, py + 14), SHOPS[keeper]["name"], HORIZONTAL_ALIGNMENT_RIGHT, pw - 10.0, 9, Menu.DIM)
	ui.draw_rect(Rect2(px + 6, py + 22, pw - 12, 1), Menu.EDGE_DARK)
	# the keeper: portrait (half the dialogue box's 56 px), name, last words
	var ky := Menu.BODY_TOP
	main.dialogue.draw_portrait(ui, Rect2(Menu.LIST_X + 2, ky + 2, 28, 28), keeper)
	ui.draw_string(font, Vector2(Menu.LIST_X + 38, ky + 11), main.dialogue.PEOPLE[keeper]["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Menu.DIM)
	ui.draw_string(font, Vector2(Menu.LIST_X + 38, ky + 24), line, HORIZONTAL_ALIGNMENT_LEFT, pw - 58.0, 9, Menu.TEXT)
	ui.draw_rect(Rect2(px + 6, ky + KEEPER_H, pw - 12, 1), Menu.EDGE_DARK)
	var top := ky + KEEPER_H + 4.0
	_draw_list(font, top)
	ui.draw_rect(Rect2(px + 180, top, 1, Menu.BODY_BOTTOM - top), Menu.EDGE_DARK)
	_draw_detail(font, top)
	# coins (bottom left), the status line (right) and the key help (bottom)
	var sy := py + ph - 20
	Items.icon(ui, "coins", Menu.LIST_X + 4, sy - 10)
	ui.draw_string(font, Vector2(Menu.LIST_X + 22, sy), "Coins  %d" % main.inv.count("coins"), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Menu.TEXT)
	if say_t > 0.0 and say_text != "":
		ui.draw_string(font, Vector2(px + 10, sy), say_text, HORIZONTAL_ALIGNMENT_RIGHT, pw - 20.0, 9, Menu.ACCENT)
	ui.draw_rect(Rect2(px + 6, py + ph - 15, pw - 12, 1), Menu.EDGE_DARK)
	ui.draw_string(font, Vector2(px + 10, py + ph - 5), "A/D buy / sell   W/S select   E %s   Tab leave" % tab,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Menu.DIM)

# the left list: a heading, then each entry with its icon, name and price (dimmed when the hero can't pay it)
func _draw_list(font: Font, top: float) -> void:
	var x := Menu.LIST_X
	var w := Menu.LIST_W
	var list := _entries()
	ui.draw_string(font, Vector2(x + 2, top + 9), "GOODS" if tab == "buy" else "RARE FINDS", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Menu.DIM)
	ui.draw_string(font, Vector2(x, top + 9), "PRICE" if tab == "buy" else "PAYS", HORIZONTAL_ALIGNMENT_RIGHT, w - 4.0, 8, Menu.DIM)
	if list.is_empty():
		ui.draw_string(font, Vector2(x + 2, top + 26), "Nothing to sell.", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Menu.DIM)
		ui.draw_multiline_string(font, Vector2(x + 2, top + 40), "This stall buys rare finds, like the keepsake a boss leaves.",
			HORIZONTAL_ALIGNMENT_LEFT, w - 4.0, 8, -1, Menu.DIM)
		return
	sel = clampi(sel, 0, list.size() - 1)
	var coins: int = main.inv.count("coins")
	# as many rows as fit, scrolled so the selected one is always in view (Stage 8e: the weapons made Nidu's list longer than the box)
	var rows := int((Menu.BODY_BOTTOM + 1.0 - top - Menu.HEAD_H) / Menu.ROW_H)
	var off := maxi(0, sel - rows + 1)
	for i in range(off, mini(list.size(), off + rows)):
		var id: String = list[i]
		var it := Items.info(id)
		var y := top + Menu.HEAD_H + (i - off) * Menu.ROW_H
		if i == sel:
			ui.draw_rect(Rect2(x, y, w, Menu.ROW_H - 1), Color(Menu.ACCENT, 0.16))
			ui.draw_rect(Rect2(x, y, 2, Menu.ROW_H - 1), Menu.ACCENT)
		var cost := int(it.get("price", 0)) if tab == "buy" else int(it.get("sell", 0))
		var can := tab == "sell" or (coins >= cost and not _owned_tool(id))
		Items.icon(ui, id, x + 5, y + 1, 1.0, 1.0 if can else 0.5)
		ui.draw_string(font, Vector2(x + 22, y + 10), it["name"], HORIZONTAL_ALIGNMENT_LEFT, w - 60.0, 9, Menu.TEXT if can else Menu.DIM)
		ui.draw_string(font, Vector2(x, y + 10), str(cost), HORIZONTAL_ALIGNMENT_RIGHT, w - 4.0, 9, Menu.XP_COL if can else Menu.DIM)

# the right side: the selected entry's big icon, name, how many the hero has, what E does, and its description
func _draw_detail(font: Font, top: float) -> void:
	var list := _entries()
	if list.is_empty():
		return
	var id: String = list[clampi(sel, 0, list.size() - 1)]
	var it := Items.info(id)
	var have: int = main.inv.count(id)
	var sub: String = Items.KIND_NAMES[it["kind"]] + ("   You have %d" % have if have > 0 else "")
	Menu.detail_head(ui, font, id, it["name"], sub, top)
	var dx := Menu.DX
	var dw := Menu.DW
	var y := top + 58.0
	if tab == "buy" and _owned_tool(id):
		ui.draw_string(font, Vector2(dx + 52, top + 40), "You have one", HORIZONTAL_ALIGNMENT_LEFT, dw - 52.0, 9, Menu.DIM)
	elif tab == "buy":
		ui.draw_string(font, Vector2(dx + 52, top + 40), "E buy for %d coins" % int(it.get("price", 0)), HORIZONTAL_ALIGNMENT_LEFT, dw - 52.0, 9, Menu.ACCENT)
	else:
		ui.draw_string(font, Vector2(dx + 52, top + 40), "E sell for %d coins" % int(it["sell"]), HORIZONTAL_ALIGNMENT_LEFT, dw - 52.0, 9, Menu.ACCENT)
		var bonus := Items.bonus_text(id)
		if bonus != "":
			ui.draw_string(font, Vector2(dx, y), "While carried: " + bonus, HORIZONTAL_ALIGNMENT_LEFT, dw, 8, Menu.TEXT)
			y += 11.0
			ui.draw_string(font, Vector2(dx, y), "Selling it gives that up.", HORIZONTAL_ALIGNMENT_LEFT, dw, 8, Menu.DIM)
			y += 12.0
	ui.draw_multiline_string(font, Vector2(dx, y), it["desc"], HORIZONTAL_ALIGNMENT_LEFT, dw, 9, int((Menu.BODY_BOTTOM - y + 8.0) / 10.0), Menu.TEXT)
