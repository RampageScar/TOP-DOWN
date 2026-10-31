extends SceneTree
# suite.gd - shared base for the test suites (world.gd, fight.gd). Not run on its own.
# A suite lists its sections in _sections(): [{"name": .., "run": Callable, "pre": Callable (optional)}].
# Every section starts on a FRESH game (main.tscn built again), so sections never depend on each other.
# Each frame: "pre" runs first (for samplers that must see every frame), then, unless `wait` is counting down, "run".
# A section ends by calling done(). Inside a section: f = frames since the section started, step / wait / snap are reset per section.

var main
var f := 0
var step := 0
var wait := 0
var snap := {}
var fails := 0
var passes := 0
var _list: Array = []
var _cur := -1
var _need_new := true

const ACTIONS := ["move_left", "move_right", "move_up", "move_down", "interact", "light", "heavy", "block", "dodge", "lasso"]
# the game autosaves on doors and new objectives: the suites save into this scratch folder (emptied at the end), never the user's saves
const Save = preload("res://scripts/save.gd")
const SAVE_DIR := "user://test_saves/"

func _sections() -> Array:    # suites override this
	return []

func _initialize() -> void:
	Save.dir = SAVE_DIR
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	_list = _sections()
	_next()

func ok(cond: bool, msg: String) -> void:
	print(("PASS  " if cond else "FAIL  ") + msg)
	if cond:
		passes += 1
	else:
		fails += 1

func done() -> void:
	_next()

func _next() -> void:
	_cur += 1
	_need_new = true
	if _cur < _list.size():
		print("\n==== ", _list[_cur]["name"])

# throw away the old game and start a new one (as if the test file had just been launched)
func new_game() -> void:
	for a in ACTIONS:
		if InputMap.has_action(a):     # the actions only exist once main.gd has run once
			Input.action_release(a)
	paused = false
	_free_main()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	main.combat.rng.seed = 7       # the drop rolls (combat.gd DROPS): the same every run
	f = 0
	step = 0
	wait = 0
	snap = {}

# main.gd keeps the maps you left OUT of the tree (frozen), so freeing main alone would leak them: free those first
func _free_main() -> void:
	if main == null:
		return
	for lv in main.levels.values():
		if is_instance_valid(lv) and not lv.is_inside_tree():
			lv.free()
	root.remove_child(main)
	main.free()
	main = null

func _finish() -> void:
	_free_main()
	for fn in DirAccess.get_files_at(SAVE_DIR):
		DirAccess.remove_absolute(SAVE_DIR + fn)
	DirAccess.remove_absolute(SAVE_DIR)
	print("\n---- passed: %d  failures: %d" % [passes, fails])
	print("OK" if fails == 0 else "FAILED")
	quit(1 if fails > 0 else 0)

func _process(_d: float) -> bool:
	if _cur >= _list.size():
		_finish()
		return true
	if _need_new:
		_need_new = false
		new_game()
		return false
	f += 1
	var sec: Dictionary = _list[_cur]
	if sec.has("pre"):
		sec["pre"].call()
	if wait > 0:
		wait -= 1
		return false
	sec["run"].call()
	return false

# ---------------------------------------------------------------- helpers shared by the suites
func press(a: String) -> void:
	Input.action_press(a)

func release(a: String) -> void:
	Input.action_release(a)

# The death screen (Stage 7j) only goes on by loading a save, which reloads the scene; the suites build main.tscn themselves, so a section
# that goes on after a fall puts the hero back on his feet by hand (full bars, the screen closed, the game running again).
func get_up() -> void:
	main.death.open = false
	main.world.talking = false
	main.combat.over_t = -1.0
	main.player.dead = false
	main.player.refill()
	paused = false

func tap_interact() -> void:
	var ev := InputEventAction.new()
	ev.action = "interact"
	ev.pressed = true
	Input.parse_input_event(ev)

# 4 px flood fill with the hero's feet box: which ground cells can be walked to from `start`
func reachable(w, start: Vector2) -> Dictionary:
	var seen := {}
	var q := [start]
	seen[Vector2i(int(start.x / 4), int(start.y / 4))] = true
	while not q.is_empty():
		var p: Vector2 = q.pop_back()
		for d in [Vector2(4, 0), Vector2(-4, 0), Vector2(0, 4), Vector2(0, -4)]:
			var n: Vector2 = p + d
			if n.x < 6 or n.y < 20 or n.x > w.W - 6 or n.y > w.H - 4:
				continue
			var k := Vector2i(int(n.x / 4), int(n.y / 4))
			if seen.has(k) or w.feet_blocked(n):
				continue
			seen[k] = true
			q.append(n)
	return seen

func reach(seen: Dictionary, p: Vector2) -> bool:
	return seen.has(Vector2i(int(p.x / 4), int(p.y / 4)))

# no prop on the straight line a -> b (2 px steps)
func seg_clear(w, a: Vector2, b: Vector2) -> bool:
	var n := int(a.distance_to(b) / 2.0) + 1
	for i in range(n + 1):
		if w.feet_blocked(a.lerp(b, float(i) / n)):
			return false
	return true
