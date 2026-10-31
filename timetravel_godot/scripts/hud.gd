extends Control
# hud.gd - the screen over the game. Top left, stacked (the user's layout, 2026-10-27): the objective box (and any open optional
# objective), then the hero's bars (HP with its number, stamina, focus; Stage 7e), then his level with a thin XP bar (7f), and a
# line per companion with him (7i: HP and focus, or FALLEN). Top right: the name of the place the hero walks into, for a few seconds. Bottom left: round
# Q (the lasso, or since 8e the weapon's special) and Shift buttons with their cooldowns. Bottom centre, in a boss fight: the boss's name, level and health. Bottom right: a round badge with
# the weapon in hand (a fist, the sword, the spear or the bow; a small round "1" notched into its lower-right, in the same gold), and above it toasts ("+2 Bread", "Journal: ...",
# "+40 XP", "Level 3: ..."). The round buttons are gold-ringed like the user's reference picture (2026-10-28). Also the hint
# line, the hurt flash, the fade to black when the hero falls (death.gd then shows the death screen over it), and the sprite gallery
# overlay (G). While the hero (or a companion) is poisoned (Stage 7j) his HP bar turns purple and says so.
# The boxes use the menu's era-neutral colours.

const Sprites = preload("res://scripts/sprites.gd")
const Items = preload("res://scripts/items.gd")
const Menu = preload("res://scripts/menu.gd")
const Squad = preload("res://scripts/squad.gd")
const Progress = preload("res://scripts/progress.gd")

const PLACE_HOLD := 0.3       # the hero must stay in a new place this long before its name shows (no flicker on a border)
const PLACE_SHOW := 3.2       # how long a place name stays up (fade in 0.4 s, out over the last 0.8 s)
const PLACE_REPEAT := 20.0    # the same name is not shown again within this many seconds
# the hero's bars: all three BAR_W px whatever their maximum (the user's rule: the bars stay the same size, only the value differs)
const BAR_W := 90.0
const HP_COL := Menu.HP_COL
const STAMINA_COL := Menu.STAMINA_COL
const FOCUS_COL := Menu.FOCUS_COL
const XP_COL := Menu.XP_COL
const XP_W := 60.0            # the thin XP bar beside "Lv N"
const BOSS_W := 240.0         # the boss bar at the bottom of the screen
# the round buttons (weapon badge, its key, Q and Shift): a dark disc in a gold ring, lit from the top-left
const RING := Color("#c89838")
const RING_LIT := Color("#f0d080")
const RING_DIM := Color("#6a5030")
const DISC := Color(0.16, 0.10, 0.06, 0.92)
const WEAPON_AT := Vector2(458, 238)   # the weapon badge's centre, and its radius
const WEAPON_R := 15.0
const KEY_R := 8.0            # the "1" chip notched into the badge's lower-right, and the thin dark gap that cuts the badge's ring round it
const KEY_GAP := 0.5
const POP_TIME := 0.15        # the badge swells for this long when the weapon changes
# the keys, along the bottom for the first seconds (Stage 8e: the attacks on the mouse, Space blocks, Q is the weapon's special)
const HINT := "WASD move  LMB/RMB attack  Space block  Shift dodge  Q special  1 weapon  E talk  I M Tab Esc menu"

var player
var world
var quest
var dialogue
var combat
var inv
var progress
var hint_time := 10.0
var gallery := false
var _place := ""              # the place the hero is in (once it has held PLACE_HOLD s)
var _cand := ""               # the place under the hero's feet right now
var _cand_t := 0.0
var _banner := ""             # the place name on show, and for how long it has been up (< 0: none)
var _banner_t := -1.0
var _shown_at := {}           # place name -> ticks when it was last shown
var _notice := ""             # a short message in the middle of the screen ("You rest at the well. Game saved."), and its time left
var _notice_t := 0.0
const NOTICE_TIME := 2.4
var _weapon_shown := ""       # the weapon the badge showed last frame, and how long ago it changed (the pop)
var _pop_t := POP_TIME
var _bold: FontVariation      # the round buttons' bold key letters (made on first use, _label)

# show a short message in the middle of the screen for a couple of seconds
func notice(text: String) -> void:
	_notice = text
	_notice_t = NOTICE_TIME

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # keep redrawing while a dialogue pauses the game
	size = Vector2(480, 270)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	hint_time -= delta
	_notice_t = maxf(0.0, _notice_t - delta)
	_pop_t += delta
	if combat != null and combat.weapon != _weapon_shown:
		if _weapon_shown != "":
			_pop_t = 0.0
		_weapon_shown = combat.weapon
	_update_place(delta)
	queue_redraw()

# which named place the hero is in; when it changes (and holds), show its name
func _update_place(delta: float) -> void:
	if _banner_t >= 0.0:
		_banner_t += delta
		if _banner_t > PLACE_SHOW:
			_banner_t = -1.0
	if world == null or player == null:
		return
	var here: String = world.place_at(player.position)
	if here != _cand:
		_cand = here
		_cand_t = 0.0
	else:
		_cand_t += delta
	if _cand_t >= PLACE_HOLD and _cand != _place:
		_place = _cand
		var now := Time.get_ticks_msec()
		if _place != "" and now - _shown_at.get(_place, -1000000) > PLACE_REPEAT * 1000.0:
			_shown_at[_place] = now
			_banner = _place
			_banner_t = 0.0

func _txt(s: String, x: float, y: float, col: Color, width: float = -1.0, align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	var font := ThemeDB.fallback_font
	draw_string_outline(font, Vector2(x, y), s, align, width, 8, 3, Color.BLACK)
	draw_string(font, Vector2(x, y), s, align, width, 8, col)

func _draw() -> void:
	var y := _draw_bars(_draw_tracker())
	_txt("Lv %d" % progress.level, 4, y + 8, XP_COL)
	_bar(30, y + 4, XP_W, 2, progress.frac(), XP_COL, false)
	if progress.at_cap():
		_txt("MAX", 34 + XP_W, y + 8, XP_COL)
	_draw_mates(y + 14)       # (the foes slain moved to the journal's Enemies list in 7k)
	_draw_place()
	_draw_skills()
	_draw_weapon()
	_draw_boss()
	_draw_toasts()
	_draw_notice()
	_draw_overlays()
	if hint_time > 0.0 and not dialogue.open:
		_txt(HINT, 0, 262, Color.WHITE, 480.0, HORIZONTAL_ALIGNMENT_CENTER)
	if gallery:
		_draw_gallery()

# the objective box, top left; flashes for a couple of seconds when the objective changes. An open optional objective gets a line
# of its own under the main one. Returns the y where the hearts go (just under the box, or the top if there is no objective).
func _draw_tracker() -> float:
	var txt: String = quest.text()
	var side: Array = quest.side_open()
	if txt == "" and side.is_empty():
		return 4.0
	var font := ThemeDB.fallback_font
	var w := font.get_string_size("NEW OBJECTIVE", HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	w = maxf(w, font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x)
	for s in side:
		w = maxf(w, font.get_string_size("Optional: " + s, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x)
	w += 14.0
	var h := (22.0 if txt != "" else 12.0) + 10.0 * side.size()
	var fresh: bool = Time.get_ticks_msec() - quest.changed_at < 2500
	var glow := fresh and int(Time.get_ticks_msec() / 250.0) % 2 == 0
	draw_rect(Rect2(4, 4, w, h), Color(Menu.BG, 0.82))
	draw_rect(Rect2(4, 4, w, h), Menu.ACCENT if glow else Menu.EDGE_DARK.lightened(0.2), false)
	_txt("OBJECTIVE" if not fresh else "NEW OBJECTIVE", 11, 14, Menu.ACCENT if fresh else Menu.DIM)
	var ty := 14.0
	if txt != "":
		ty = 23.0
		_txt(txt, 11, ty, Menu.TEXT)
	for s in side:
		ty += 10.0
		_txt("Optional: " + s, 11, ty, Menu.DIM)
	return 4.0 + h + 4.0

# The hero's bars, from y down: HP (a heart, the bar and "72 / 100"), stamina, and focus (with a notch at what Q costs now: the weapon's
# special, or the strong lasso).
# A bar flashes when a move was refused for want of it. Returns the y under the last bar.
func _draw_bars(y: float) -> float:
	var poisoned: bool = player.poison > 0
	var hp_col := Menu.POISON_COL if poisoned else HP_COL
	Sprites.heart(self, 4, y, hp_col)
	var x := 14.0
	var w := BAR_W
	_bar(x, y, w, 6, float(player.hp) / player.max_hp, hp_col, false)
	var nums := "%d / %d" % [player.hp, player.max_hp]
	_txt(nums, x + w + 4, y + 7, Menu.TEXT)
	if poisoned:
		_txt("Poisoned", x + w + 10 + ThemeDB.fallback_font.get_string_size(nums, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x, y + 7, Menu.POISON_COL)
	var tired: bool = combat.tired_t > 0.0 and int(combat.tired_t * 10.0) % 2 == 0
	_bar(x, y + 8, w, 3, float(player.stamina) / player.max_stamina, STAMINA_COL, tired)
	var low: bool = combat.focus_flash > 0.0 and int(combat.focus_flash * 10.0) % 2 == 0
	_bar(x, y + 13, w, 3, float(player.focus) / player.max_focus, FOCUS_COL, low)
	var notch: float = x + w * float(combat.q_cost()) / player.max_focus
	if notch < x + w:
		draw_rect(Rect2(roundf(notch), y + 12, 1, 5), Color(1, 1, 1, 0.7))
	return y + 18.0

# the companions with the hero (Stage 7i), one line each under the XP line: his name with thin HP and focus bars, or "FALLEN" blinking
# red while he is down (E beside him with a Reviving Potion, or the menu)
func _draw_mates(y: float) -> void:
	for n in combat.mates():
		var m: Dictionary = combat.squad.find(n)
		var who: String = dialogue.PEOPLE[Squad.MATES[m["id"]]["person"]]["name"]
		if n.down:
			var on := int(Time.get_ticks_msec() / 400.0) % 2 == 0
			_txt(who + "  FALLEN", 4, y + 6, HP_COL if on else Menu.DIM)
		else:
			_txt(who, 4, y + 6, Menu.TEXT)
			_bar(50, y, 50, 3, float(n.hp) / n.max_hp, Menu.POISON_COL if n.poison > 0 else Menu.MATE_HP_COL, false)
			_bar(50, y + 5, 50, 2, float(n.focus) / n.max_focus, FOCUS_COL, false)
			if n.poison > 0:
				_txt("poisoned", 104, y + 6, Menu.POISON_COL)
		y += 12.0

# one bar: a dark frame, the fill (a lighter strip along its top), white while it flashes
func _bar(x: float, y: float, w: float, h: float, frac: float, col: Color, flash: bool) -> void:
	draw_rect(Rect2(x - 1, y - 1, w + 2, h + 2), Color(0, 0, 0, 0.8))
	draw_rect(Rect2(x, y, w, h), Color(col.darkened(0.75), 0.9))
	var fw := roundf(w * clampf(frac, 0.0, 1.0))
	if fw > 0.0:
		draw_rect(Rect2(x, y, fw, h), Color.WHITE if flash else col)
		draw_rect(Rect2(x, y, fw, 1), Color.WHITE if flash else col.lightened(0.35))
	elif flash:
		draw_rect(Rect2(x, y, w, h), Color(1, 1, 1, 0.5))

# a boss fight (combat.boss(): the giant or the chief, after the hero): its name and a wide health bar, bottom centre. The notch marks
# half health (the giant's summon, the chief's rage). Bosses hide their own small bar meanwhile.
func _draw_boss() -> void:
	var b = combat.boss()
	if b == null or dialogue.open:
		return
	var x := (480.0 - BOSS_W) / 2.0
	var y := 258.0
	_txt("%s   Lv %d" % [dialogue.BOSSES.get(b.kind, b.kind), b.level], 0, y - 4, Menu.TEXT, 480.0, HORIZONTAL_ALIGNMENT_CENTER)
	_bar(x, y, BOSS_W, 5, float(b.hp) / b.max_hp, HP_COL, b.flash > 0.0)
	draw_rect(Rect2(x + BOSS_W / 2.0, y, 1, 5), Color(0, 0, 0, 0.6))

func _draw_notice() -> void:
	if _notice_t <= 0.0:
		return
	var a := clampf(_notice_t / 0.4, 0.0, 1.0)
	var font := ThemeDB.fallback_font
	var w := font.get_string_size(_notice, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x + 20.0
	var x := (480.0 - w) / 2.0
	draw_rect(Rect2(x, 96, w, 18), Color(Menu.BG, Menu.BG.a * a))
	draw_rect(Rect2(x, 96, w, 18), Color(Menu.ACCENT, a), false)
	draw_string(font, Vector2(x + 10, 109), _notice, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(Menu.TEXT, a))

# the place the hero has just walked into, top right: fades in, stays, fades out
func _draw_place() -> void:
	if _banner_t < 0.0 or dialogue.open:
		return
	var a := clampf(_banner_t / 0.4, 0.0, 1.0) * clampf((PLACE_SHOW - _banner_t) / 0.8, 0.0, 1.0)
	var font := ThemeDB.fallback_font
	var w := font.get_string_size(_banner, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	draw_string_outline(font, Vector2(0, 20), _banner, HORIZONTAL_ALIGNMENT_RIGHT, 474.0, 12, 4, Color(0, 0, 0, a))
	draw_string(font, Vector2(0, 20), _banner, HORIZONTAL_ALIGNMENT_RIGHT, 474.0, 12, Color(Menu.TEXT, a))
	draw_rect(Rect2(474.0 - w, 24, w, 1), Color(Menu.ACCENT, a * 0.9))

func _draw_gallery() -> void:
	draw_rect(Rect2(20, 20, 440, 230), Color(0.04, 0.03, 0.02, 0.9))
	_txt("SPRITE GALLERY  (G to close)", 0, 34, Color("#ffe9a0"), 480.0, HORIZONTAL_ALIGNMENT_CENTER)
	var f := int(Time.get_ticks_msec() / 125.0)
	var dirs := ["down", "up", "right", "left"]
	for i in range(4):
		var x := 70.0 + i * 60.0
		Sprites.person(self, x, 100.0, dirs[i], f, true, {})
		_txt("hero " + dirs[i], x - 30, 120, Color.WHITE, 60.0, HORIZONTAL_ALIGNMENT_CENTER)
		Sprites.person(self, x, 160.0, dirs[i], 0, false, {})
		_txt("idle", x - 30, 180, Color("#aaaaaa"), 60.0, HORIZONTAL_ALIGNMENT_CENTER)
	var names := ["keeper", "scribe", "guard", "villager"]
	for i in range(4):
		var x := 70.0 + i * 60.0
		Sprites.person(self, x, 232.0, "down", f, true, Sprites.PALETTES[names[i]])
		_txt(names[i], x - 30, 242, Color.WHITE, 60.0, HORIZONTAL_ALIGNMENT_CENTER)
	Sprites.rat(self, 340, 100, 1, f / 2.0, 1.0)
	Sprites.rat(self, 400, 100, -1, f / 2.0, 1.0)
	_txt("rat / flipped", 300, 118, Color.WHITE, 140.0, HORIZONTAL_ALIGNMENT_CENTER)
	Sprites.scorpion(self, 370, 148, 1, f / 2.0, minf(2.0, fmod(Time.get_ticks_msec() / 700.0, 2.6)))
	_txt("scorpion (sting)", 300, 162, Color.WHITE, 140.0, HORIZONTAL_ALIGNMENT_CENTER)
	Sprites.rat(self, 370, 190, 1, f / 2.0, 2.0)
	_txt("big rat (x2)", 300, 204, Color.WHITE, 140.0, HORIZONTAL_ALIGNMENT_CENTER)

# bottom right: "+2 Bread" for each recent gain, "Journal: ..." for a new journal entry, and the hero's progress ("+40 XP", "Level 3:
# ...", "Unarmed Lv 2: ..."), newest at the bottom, each fading out over its last half second
func _draw_toasts() -> void:
	var list := []
	for g in inv.recent():
		list.append({"icon": g["id"], "text": "+%d %s" % [g["n"], Items.info(g["id"])["name"]], "at": g["at"], "life": inv.TOAST_TIME})
	for g in progress.recent():
		list.append({"icon": "", "text": g["text"], "at": g["at"], "life": progress.NEWS_TIME})
	if quest.journal.size() > 0 and Time.get_ticks_msec() - quest.journal_at < quest.JOURNAL_TOAST * 1000.0:
		var title: String = dialogue.LOGS.get(quest.journal[-1], {}).get("title", "")
		list.append({"icon": "", "text": "Journal: " + title, "at": quest.journal_at, "life": quest.JOURNAL_TOAST})
	list.sort_custom(func(p, q): return p["at"] < q["at"])
	var font := ThemeDB.fallback_font
	var y := 202.0             # above the weapon badge
	for i in range(list.size() - 1, -1, -1):
		var g: Dictionary = list[i]
		var age: float = (Time.get_ticks_msec() - g["at"]) / 1000.0
		var a := clampf((g["life"] - age) / 0.5, 0.0, 1.0)
		var s: String = g["text"]
		var pad := 26.0 if g["icon"] != "" else 12.0
		var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x + pad
		var x := 476.0 - w
		draw_rect(Rect2(x, y, w, 16), Color(Menu.BG, Menu.BG.a * a))
		draw_rect(Rect2(x, y, w, 16), Color(Menu.ACCENT if g["icon"] == "" else Menu.EDGE, a), false)
		if g["icon"] != "":
			Items.icon(self, g["icon"], x + 3, y + 2, 1.0, a)
		draw_string(font, Vector2(x + pad - 7.0, y + 12), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(Menu.TEXT, a))
		y -= 19.0
		if y < 120.0:
			break

# bottom-right: a round badge with only the weapon in hand (a fist, the sword, the spear or the bow: items.gd BADGE_ART), like the
# user's reference picture. It swells for a moment when the weapon changes. Notched into its lower-right (the user's mock-up), a small
# round "1": the key that switches. It always shows, so the key is known before a weapon is had, in the badge's own gold (the user's
# note: one style).
func _draw_weapon() -> void:
	var w: String = combat.weapon
	var k := clampf(_pop_t / POP_TIME, 0.0, 1.0)
	var s := 1.0 + 0.15 * sin(k * PI)
	_disc(WEAPON_AT, WEAPON_R * s, RING)
	Items.badge(self, w, WEAPON_AT, s)
	var c := WEAPON_AT + Vector2.from_angle(PI / 4.0) * (WEAPON_R + 1.0)
	draw_circle(c, KEY_R + 1.0 + KEY_GAP, Color(0, 0, 0, 0.85))     # the cut in the badge's ring
	_key(c, KEY_R, Progress.WEAPONS["sword"]["key"], 9, true)

# bottom-left: Q and dodge (Shift), round like the weapon badge, the cooldown sweeping round the inside. With a weapon that has a
# special (Stage 8e) Q fills with whichever is further behind, the focus toward the special's cost or its cooldown, and lights when
# both are ready; with the fists it is the lasso's cooldown (the strong lasso's shows on its charge ring)
func _draw_skills() -> void:
	var sp: String = combat.WEAPON_KIT[combat.weapon].get("special", "")
	var q: float = combat.lasso_ready_frac()
	if sp != "":
		var by_focus := clampf(float(player.focus) / maxi(1, combat.focus_val(sp)), 0.0, 1.0)
		var by_time := 1.0 - clampf(combat.special_cd / maxf(0.01, combat.special_cd_max()), 0.0, 1.0)
		q = minf(by_focus, by_time)
	_skill(Vector2(17, 251), "Q", 8, q)
	_skill(Vector2(44, 251), "Shift", 7, combat.dodge_ready_frac())

func _skill(c: Vector2, label: String, size: int, frac: float) -> void:
	var ready := frac >= 1.0
	_disc(c, 12.0, RING if ready else RING_DIM)
	if not ready:
		var pts := PackedVector2Array([c])
		for i in range(25):
			pts.append(c + Vector2.from_angle(-PI / 2.0 + TAU * frac * i / 24.0) * 9.0)
		if frac > 0.04:            # a sliver too thin to triangulate is left out
			draw_colored_polygon(pts, Color(0.55, 0.35, 0.15, 0.9))
	_label(c, 24.0, label, size, Color.WHITE if ready else Color("#aaaaaa"))

# a small round key label (the weapon badge's "1"); lit = the key does something now
func _key(c: Vector2, r: float, label: String, size: int, lit: bool) -> void:
	_disc(c, r, RING if lit else RING_DIM)
	_label(c, r * 2.0, label, size, Menu.TEXT if lit else Color("#aaaaaa"))

# a round button's key letter: bold (the user's note: thin letters got lost in the small circles), a thin black edge, centred on c
func _label(c: Vector2, w: float, label: String, size: int, col: Color) -> void:
	if _bold == null:
		_bold = FontVariation.new()
		_bold.base_font = ThemeDB.fallback_font
		_bold.variation_embolden = 0.9
	var at := Vector2(c.x - w / 2.0, roundf(c.y + (_bold.get_ascent(size) - _bold.get_descent(size)) / 2.0))
	draw_string_outline(_bold, at, label, HORIZONTAL_ALIGNMENT_CENTER, w, size, 2, Color.BLACK)
	draw_string(_bold, at, label, HORIZONTAL_ALIGNMENT_CENTER, w, size, col)

# a round button's body: a dark outline, the gold ring with a lighter arc toward the top-left (the light), and the dark disc inside
func _disc(c: Vector2, r: float, ring: Color) -> void:
	draw_circle(c, r + 1.0, Color(0, 0, 0, 0.85))
	draw_circle(c, r, ring)
	draw_arc(c, r - 0.8, PI * 0.95, PI * 1.6, 12, ring.lerp(RING_LIT, 0.7) if ring == RING else ring.lightened(0.25), 1.2)
	draw_circle(c, r - 2.2, Color(0, 0, 0, 0.9))
	draw_circle(c, r - 2.8, DISC)

# red flash when hurt; when the hero falls, a fade to black (the death screen's words and choices are drawn over it by death.gd)
func _draw_overlays() -> void:
	if combat.hurt_flash > 0.0:
		draw_rect(Rect2(0, 0, 480, 270), Color(0.8, 0.1, 0.1, 0.35 * combat.hurt_flash / 0.3))
	if combat.over_t >= 0.0:
		draw_rect(Rect2(0, 0, 480, 270), Color(0, 0, 0, clampf(combat.over_t / 0.9, 0.0, 1.0)))
