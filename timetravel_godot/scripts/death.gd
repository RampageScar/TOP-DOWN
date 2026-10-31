extends CanvasLayer
# death.gd - the death screen (Stage 7j, the user's decision 2026-10-28). When the hero falls, hud.gd fades the screen to black; then
# "You fell" and where come up here, and the player picks the save to go on from: the autosave or a filled slot (save.gd SLOTS, in that
# order, so the autosave is first and picked), or a new game, which is all there is when nothing has been saved yet. There is no
# getting up where he fell: a fall costs whatever happened since that save. The screen opens by itself OPEN_AT s after the fall
# (combat.gd over_t), pauses the game and uses the menu's era-neutral style.
# Keys: W/S choose, E resume (main.gd load_game reloads the scene from the slot; New game reloads it fresh).

const Save = preload("res://scripts/save.gd")
const Menu = preload("res://scripts/menu.gd")

const WORDS_AT := 0.6       # s after the fall: the words start to fade in (the screen is black by 0.9 s)
const OPEN_AT := 1.6        # s after the fall: the choices show and take keys, and the game pauses
const ROW_H := 16.0
const ROWS_W := 300.0
const NAMES := {"auto": "Autosave", "1": "Slot 1", "2": "Slot 2", "3": "Slot 3", "4": "Slot 4", "new": "New game"}
const HEAD_SAVES := "The trail isn't lost. Pick it up from:"
const HEAD_NONE := "Nothing is saved yet. Start the trail again:"

var main                    # main.gd: player, combat, world, load_game(), new_game()
var open := false
var rows: Array = []        # what can be picked: the filled save slots, then "new"
var infos := {}             # slot -> where and when it was saved (save.gd info)
var sel := 0
var place := ""             # where the hero fell (level.gd place_at)
var ui: Control

func _ready() -> void:
	layer = 9
	process_mode = Node.PROCESS_MODE_ALWAYS
	ui = Control.new()
	ui.size = Vector2(480, 270)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.draw.connect(_draw_ui)
	add_child(ui)

func _process(_delta: float) -> void:
	if not open and main.player.dead and main.combat.over_t >= OPEN_AT:
		_open()
	ui.queue_redraw()

# list the saves there are (read from disk once, now), pick the first, and stop the game behind the screen
func _open() -> void:
	open = true
	place = main.world.place_at(main.player.position)
	rows = []
	infos = {}
	for s in Save.SLOTS:
		var info := Save.info(s)
		if info != "":
			rows.append(s)
			infos[s] = info
	rows.append("new")
	sel = 0
	main.world.talking = true
	get_tree().paused = true

func _unhandled_input(event: InputEvent) -> void:
	if not open:
		return
	if event.is_action_pressed("move_up"):
		sel = maxi(0, sel - 1)
	elif event.is_action_pressed("move_down"):
		sel = mini(rows.size() - 1, sel + 1)
	elif event.is_action_pressed("interact"):
		resume(rows[sel])
	get_viewport().set_input_as_handled()      # every key stops here while the screen is up

# go on from a row: load that save (main.gd reloads the scene and builds the game from it), or start a new game
func resume(row: String) -> void:
	if row == "new":
		main.new_game()
	else:
		main.load_game(row)

# ---------------------------------------------------------------- drawing
func _draw_ui() -> void:
	var t: float = main.combat.over_t
	if not open and (not main.player.dead or t < WORDS_AT):
		return
	var font := ThemeDB.fallback_font
	var a := 1.0 if open else clampf((t - WORDS_AT) / 0.6, 0.0, 1.0)
	ui.draw_rect(Rect2(0, 0, 480, 270), Color(0, 0, 0, a))
	ui.draw_string(font, Vector2(0, 64), "YOU FELL", HORIZONTAL_ALIGNMENT_CENTER, 480.0, 24, Color(Menu.TEXT, a))
	var where: String = place if open else main.world.place_at(main.player.position)
	if where != "":
		ui.draw_string(font, Vector2(0, 82), "in " + where, HORIZONTAL_ALIGNMENT_CENTER, 480.0, 9, Color(Menu.DIM, a))
	if not open:
		return
	var x := (480.0 - ROWS_W) / 2.0
	var y := 112.0
	ui.draw_string(font, Vector2(x, y), HEAD_SAVES if rows.size() > 1 else HEAD_NONE, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Menu.TEXT)
	y += 8.0
	for i in range(rows.size()):
		var row: String = rows[i]
		if row == "new" and i > 0:
			y += 4.0                         # a small gap between the saves and New game
		if i == sel:
			ui.draw_rect(Rect2(x, y, ROWS_W, ROW_H - 2), Color(Menu.ACCENT, 0.16))
			ui.draw_rect(Rect2(x, y, 2, ROW_H - 2), Menu.ACCENT)
		ui.draw_string(font, Vector2(x + 8, y + 10), NAMES[row], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Menu.TEXT)
		if infos.has(row):
			ui.draw_string(font, Vector2(x + 72, y + 10), infos[row], HORIZONTAL_ALIGNMENT_LEFT, ROWS_W - 76.0, 9, Menu.DIM)
		y += ROW_H
	ui.draw_rect(Rect2(x, 246, ROWS_W, 1), Menu.EDGE_DARK)
	ui.draw_string(font, Vector2(x, 258), "W/S choose   E resume", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Menu.DIM)
