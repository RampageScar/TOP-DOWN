extends Node
# arena_combat.gd - the combat test arena's own COPY of scripts/combat.gd, taken at Stage 7l (the user's decision, Stage 8a: weapons,
# combos and the feel are tried here without touching the story game). Change it freely; the story game never loads it. What works is
# ported back to scripts/combat.gd by hand, as its own step agreed with the user. It keeps combat.gd's API, so rat.gd, chief.gd,
# slinger.gd and the tuning panel (tuning.gd) work with it unchanged.
# What the arena changed (keep this list current: it is the porting checklist):
#  - ARENA_WEAPONS / WEAPON_LIST: every weapon's moves and strings in one place; _moves(), move_name(), switch_weapon() (key 1 cycles)
#    and equip() read it, so a new weapon is one row (its tune keys come from it by themselves) plus its drawing (arena_player.gd)
#  - Stage 8b: light (Mouse 1) and heavy (Mouse 2) attacks played as named strings (`chain`, _next_chain(), _try_swing(key)) in place
#    of the one combo (COMBO / SWORD_COMBO and last_n are gone); per-move effects "dash" and "stun"; a string's own "pause" in place
#    of COMBO_END_PAUSE; its name floats up when its last swing lands
#  - Stage 8b: attacks go the hero's 8-way aim (facing() = arena_player.gd facing_vec()), not his 4-way `dir`
#  - Stage 8b: the enemy tables (RAT, BANDIT, GIANT, CHIEF, SLINGER, SCORPION) are `var` copies of the _RAT ... consts, so the arena's
#    tuning panel (arena_tuning.gd) can change an enemy's hit damage live; reset_foe() puts a value back
#  - Stage 8c: the spear (SPEAR_MOVES; a move's "side" widens or narrows its box) and the bow (BOW_MOVES, BOW: "shot" moves fire in
#    _fire(); the weapon's "hold" move is H held to draw, _start_draw() / _update_draw() / _loose(); the hero's arrows are shots with
#    "hero", "kb" and "stagger", logged and feeding focus in _update_shots(), and they rock the dummy)
#  - Stage 8c: the block (Space; BLOCK, each weapon's "block", tune["block"], guard()): judged first in hurt_player() (_in_front(),
#    _blocked(), the guard breaking); _check_fall(); a sting caught on the guard doesn't poison (poison_body); _draw_guard()
#  - 8c play-test: every string named ("plain" marks the basic one), its letters and name shown when its last move starts (text() has a
#    width); the volley earned (`earn`, `focus`, `fallback`; string_id, landed, _arrow_landed()); PIERCE / PIERCE_COL (_piercing(),
#    _pierce_shot, _draw_pierce_warnings()); stamina refills at BLOCK.regen behind the guard; the bow blocks too (the weakest guard)
#  - Stage 8d: Q is the weapon's special (a weapon row's "special"; _try_special(), focus only): the sword's flurry ("hits" thrusts
#    with _seg, "burn": BURN, burning, _burn(), _update_burns(), _draw_burns()), the spear's whirl ("radius": _in_area()), the bow's
#    piercer (a shot with "pierce": it goes through foes, "hit"); a special's hits don't feed focus; a move outside the strings ends
#    with its own "after" pause. The fists keep the lasso, and the strong lasso pulls heavy foes too (_pull_heavy(), not bind()).
#  - Stage 8d: the parry (PARRY, tune["parry"], parry_t from a fresh Space press, _parried() first among the guard's cases in
#    hurt_player(); a weapon's "parry": false); _log_hit() takes a colour
#  - 8d play-test: specials and the strong lasso cost 15 focus and share a cooldown (SPECIAL, tune["special"], special_cd,
#    special_cd_max()); the strong lasso's hold-to-charge reads q_charge() (LASSO's own "charge" is gone); q_cost() for the ring
#  - Stage 8f: finishers: strings ending in Q with a "fin" (FINISHER, tune["focus"]["finisher"], _q_fits(), _try_finisher(), a
#    buffered "Q"); a move's row is _cur (its own row changed by "fin", set in _start_swing(m, over)); "mul", "burn_ticks";
#    _throw_lasso()'s reach_mul
#  - 8f follow-up: walking while the bow is drawn (arena_player.gd DRAW_WALK) and the bow's dotted aim reticle, shown whenever the bow
#    is in hand (RETICLE, _draw_reticle())
#  - the cheats (god, endless_stamina, endless_focus, no_q_cooldown) and getting up after a fall (GET_UP) instead of the death screen
#  - no kill XP, weapon XP, drops, quest or saved dead: the hero's levels are what the arena panel sets
#  - the readouts: every hit that lands (on an enemy or the dummy) goes into `hits` (damage numbers, DPS), and the fx layer draws the
#    combo timeline under the hero and the swing's hit box (`view`)
#  - clear_field()
# Ported to the story game at Stage 8e (the user's choice, 2026-10-29): everything above but the arena-only lines (the cheats, GET_UP,
# no XP / drops, the readouts, the live enemy tables, clear_field). Two differences the game made: its sword flurry makes foes bleed
# (combat.gd BLEED) where this one burns, and its weapon table is named WEAPON_KIT (aliased below for hud.gd). The arena's player and
# HUD now take the game's player.gd and hud.gd as they are. A change made here from now on is new, and goes on this list again.
#
# (combat.gd's own header follows.)
# combat.gd - player attacks, dodge, lasso (and the strong lasso), the stamina and focus they spend, the weapon XP they earn, enemy
# spawning and respawning, enemy levels and kill XP, damage, poison, arrows and stones in flight, effects, the hero's fall.
# ALL tuning numbers are the constants below. Rats, bandits, the giant and the scorpions live in rat.gd (RAT, BANDIT, GIANT,
# SCORPION); the cave's chief and his slingers have their own scripts built on it (chief.gd: CHIEF, slinger.gd: SLINGER). Enemy HP,
# hit damage and XP are read through `tune` (see below), which the dev tuning panel (tuning.gd, T) can change while you play.
# When the hero falls, over_t counts up and death.gd opens the death screen from it (Stage 7j): there is no getting up on the map.

const Rat = preload("res://scripts/rat.gd")
const Chief = preload("res://scripts/chief.gd")
const Slinger = preload("res://scripts/slinger.gd")
const Drawn = preload("res://scripts/drawn.gd")

# ---------------- tuning ----------------
# Scale (Stage 7e): the hero has 100 HP (player.gd BASE_HP); an ordinary hit on him costs 20 and a big boss move 40. Enemy HP and the
# hero's damage are 10x the old numbers, so every fight takes the same number of hits as before.
# A weapon's moves (Stage 8b). One row a move: dur = seconds; the hit lands between hit_from..hit_to (share of dur); stamina = what
# the swing costs; reach = how far in front it lands (else REACH_FRONT); pose = its drawing (arena_player.gd); lv = which progress.gd
# bonus the weapon's level adds to its damage (progress only knows punch / kick / slash / thrust; "" for a weapon it doesn't know);
# side = how far to either side of the aim it lands (else REACH_SIDE). Effects: dash = px/s of forward shove on top of SWING_STEP;
# stun = a light foe it staggers is stunned instead (rat.gd "stun", as after the lasso's pull).
# A bow's move (Stage 8c) shoots instead of swinging: "shot" = true, the arrow leaves at hit_from, at "speed" px/s with "kb" push;
# "arrows" = how many, fanned "spread" rad apart; "stagger" = whether it interrupts the foe it hits (a quick arrow doesn't).
# A move's name is its tune key (damage and stamina), so it must be unique across weapons and not "arrow" (the rider's).
# punch / kick and slash / thrust are the story game's combos (combat.gd COMBO, SWORD_COMBO); the others are the arena's first guesses.
const FIST_MOVES := {
	"punch": {"dur": 0.22, "dmg": 10, "kb": 70.0, "hit_from": 0.25, "hit_to": 0.7, "shake": 1.0, "stamina": 10, "pose": "punch", "lv": "punch"},
	"kick": {"dur": 0.34, "dmg": 20, "kb": 130.0, "hit_from": 0.3, "hit_to": 0.7, "shake": 2.5, "stamina": 20, "pose": "kick", "lv": "kick"},
	"shoulder": {"dur": 0.36, "dmg": 10, "kb": 230.0, "hit_from": 0.2, "hit_to": 0.75, "shake": 2.0, "stamina": 20, "reach": 24.0,
		"pose": "shoulder", "lv": "punch", "dash": 120.0},
	"knee": {"dur": 0.30, "dmg": 15, "kb": 50.0, "hit_from": 0.3, "hit_to": 0.7, "shake": 1.5, "stamina": 15, "reach": 22.0,
		"pose": "knee", "lv": "kick"},
	"hammer": {"dur": 0.48, "dmg": 35, "kb": 110.0, "hit_from": 0.5, "hit_to": 0.8, "shake": 3.5, "stamina": 25, "pose": "hammer", "lv": "kick"},
}
const SWORD_MOVES := {
	"slash": {"dur": 0.28, "dmg": 20, "kb": 80.0, "hit_from": 0.3, "hit_to": 0.7, "shake": 1.5, "stamina": 15, "reach": 38.0,
		"pose": "slash", "lv": "slash"},
	"thrust": {"dur": 0.40, "dmg": 35, "kb": 150.0, "hit_from": 0.35, "hit_to": 0.7, "shake": 3.0, "stamina": 25, "reach": 42.0,
		"pose": "thrust", "lv": "thrust"},
	"rise": {"dur": 0.32, "dmg": 20, "kb": 50.0, "hit_from": 0.3, "hit_to": 0.7, "shake": 2.0, "stamina": 18, "reach": 36.0,
		"pose": "rise", "lv": "slash", "stun": true},
	"overhead": {"dur": 0.46, "dmg": 35, "kb": 120.0, "hit_from": 0.45, "hit_to": 0.75, "shake": 3.0, "stamina": 25, "reach": 40.0,
		"pose": "overhead", "lv": "thrust"},
	# the sword's special (Q, Stage 8d; the user's idea: a flame sword like fencing): `hits` fast thrusts, each stepping `step` px/s
	# along the aim, the blade alight; every foe a thrust lands on burns (BURN). See IMPROVEMENTS on the flame and historical care.
	"flurry": {"dur": 0.72, "dmg": 10, "kb": 40.0, "hit_from": 0.3, "hit_to": 0.7, "shake": 1.5, "stamina": 0, "reach": 42.0, "side": 10.0,
		"pose": "flurry", "lv": "", "special": true, "name": "Flaming flurry", "focus": 15, "hits": 4, "step": 60.0, "burn": true,
		"after": 0.35},
}
# The spear (Stage 8c; Achaemenid spearmen fit Era 1): the longest reach and a narrow line, between the fists and the sword in damage.
# jab / long_thrust are its plain string; sweep is a wide swing that clears the front; drive / lunge are its heavy thrusts.
const SPEAR_MOVES := {
	"jab": {"dur": 0.24, "dmg": 15, "kb": 60.0, "hit_from": 0.3, "hit_to": 0.7, "shake": 1.0, "stamina": 12, "reach": 46.0, "side": 8.0,
		"pose": "jab", "lv": ""},
	"long_thrust": {"dur": 0.38, "dmg": 30, "kb": 140.0, "hit_from": 0.35, "hit_to": 0.7, "shake": 2.5, "stamina": 22, "reach": 56.0,
		"side": 8.0, "pose": "long_thrust", "lv": ""},
	"sweep": {"dur": 0.40, "dmg": 20, "kb": 170.0, "hit_from": 0.35, "hit_to": 0.75, "shake": 2.0, "stamina": 20, "reach": 34.0,
		"side": 26.0, "pose": "sweep", "lv": ""},
	"drive": {"dur": 0.40, "dmg": 25, "kb": 100.0, "hit_from": 0.4, "hit_to": 0.7, "shake": 2.0, "stamina": 20, "reach": 52.0, "side": 8.0,
		"pose": "drive", "lv": ""},
	"lunge": {"dur": 0.46, "dmg": 35, "kb": 160.0, "hit_from": 0.35, "hit_to": 0.75, "shake": 3.0, "stamina": 28, "reach": 60.0,
		"side": 9.0, "pose": "lunge", "lv": "", "dash": 140.0},
	# the spear's special (Q, Stage 8d): the shaft swung right round him; it hits every foe within `radius` px, pushing each outward
	"whirl": {"dur": 0.50, "dmg": 30, "kb": 180.0, "hit_from": 0.25, "hit_to": 0.8, "shake": 3.0, "stamina": 0, "radius": 42.0,
		"pose": "whirl", "lv": "", "special": true, "name": "Whirlwind", "focus": 15, "after": 0.35},
}
# The bow (Stage 8c, the user's rules): unlimited arrows. L is a quick, weak arrow (three make a volley); H is held to draw and aim
# (BOW), and the arrow ("aimed") flies when it is let go. "aimed": dmg is a full draw's, stamina is what each second of drawing costs.
const BOW_MOVES := {
	"quick": {"dur": 0.26, "dmg": 10, "kb": 30.0, "hit_from": 0.45, "hit_to": 0.45, "shake": 0.5, "stamina": 8, "pose": "quick", "lv": "",
		"shot": true, "speed": 320.0, "stagger": false},
	# the volley is earned (the user's play-test: it was easy to spam): it flies only if `earn` earlier arrows of its string have hit
	# something (a foe or the dummy) by the time it leaves, and it costs `focus` (read through tune: focus_val("volley")). Otherwise the
	# third shot is a plain `fallback` arrow (its stamina is spent all the same).
	"volley": {"dur": 0.34, "dmg": 10, "kb": 30.0, "hit_from": 0.5, "hit_to": 0.5, "shake": 1.0, "stamina": 18, "pose": "quick", "lv": "",
		"shot": true, "speed": 320.0, "stagger": false, "arrows": 3, "spread": 0.18, "earn": 2, "focus": 10, "fallback": "quick"},
	"aimed": {"dur": 0.20, "dmg": 40, "kb": 90.0, "hit_from": 0.1, "hit_to": 0.1, "shake": 1.5, "stamina": 20, "pose": "loose", "lv": "",
		"shot": true, "speed": 480.0, "stagger": true},
	# the bow's special (Q, Stage 8d): a heavy arrow nocked and loosed at once; it goes through every foe in its line ("pierce"), hitting
	# each once, and staggers them
	"piercer": {"dur": 0.36, "dmg": 50, "kb": 120.0, "hit_from": 0.6, "hit_to": 0.6, "shake": 2.5, "stamina": 0, "pose": "piercer", "lv": "",
		"shot": true, "speed": 520.0, "stagger": true, "pierce": true, "special": true, "name": "Piercing arrow", "focus": 15,
		"after": 0.3},
}
# Specials (Stage 8d, the user's rule): Q is the weapon's own move. With the fists it stays the lasso; every other weapon has a
# "special" move (a row with "special": true, its "name" and its "focus" cost, read through tune: focus_val(move)). A tap of Q starts
# it, then the cooldown (SPECIAL) runs before the next. It costs focus, never stamina, can't be started mid-swing, and its own hits don't feed focus (or a special could pay for the next). "after" = the
# pause once it ends.
# Burning (the sword's flurry): `ticks` x `dmg` HP, one every `every` s, on the foe a burning thrust landed on (a new burn starts the
# count again). It can finish a foe off. Shown as flames on the foe and orange numbers.
const BURN := {"dmg": 4, "every": 0.5, "ticks": 6}
# Parry (Stage 8d, the user's rule: a perfect block, every weapon but the bow): Space pressed no more than tune["parry"]["window"] ms
# before a hit from the front lands. No damage; the hero gains tune["parry"]["focus"]; the attacker (if the hit came from its body)
# staggers, `kb` px/s back, unless it is a boss (armoured); `inv` s of safety. Piercing attacks can't be parried either. The window
# shows as a gold guard arc.
const PARRY := {"window": 150, "focus": 8, "kb": 140.0, "inv": 0.3}
# Drawing the bow (H held): `full` s to a full draw; an arrow let go earlier does `min` of the full damage and flies at `min_speed`,
# rising with the draw to the full damage and the move's own speed. Stamina drains while drawing; at 0 the arrow goes at once.
const BOW := {"full": 0.8, "min": 0.35, "min_speed": 300.0, "loose_pause": 0.15}
# The bow's aim reticle (the user's play-test, 8f follow-up: a short dotted line, not a long one; one dot fewer after the next look):
# `dots` 2x2 px dots `gap` px apart, the first `from` px out from the hand along the aim. It shows whenever the bow is in hand: faint
# for the quick (L) arrows, brighter while H draws, white once the draw is full.
const RETICLE := {"dots": 4, "gap": 6.0, "from": 10.0}
# The block (Stage 8c, Space held; every weapon: the bow too since the user's 8c play-test, the weakest guard). Only a hit from the
# front counts: within `arc` rad either
# side of the aim. A blocked hit lets the weapon's "cut" % of its damage through and costs its "stamina" (ARENA_WEAPONS "block"); after
# it the hero is safe for `inv` s and pushed back `kb` x as far as by a real hit. A hit on the guard with no stamina left breaks it: full
# damage, and no block, swing or lasso for `broken` s. He walks slowly behind it (arena_player.gd GUARD_WALK). The cut and stamina are
# read through tune ("block"), so the tuning panel can change them. Behind the guard stamina refills at `regen` x the usual rate (the
# user's play-test: it used to stop).
const BLOCK := {"arc": 1.2, "inv": 0.25, "kb": 0.4, "broken": 0.6, "regen": 0.5}
# Attacks that go through the block (the user's play-test, 8c): the giant's slam, the chief's charge, a slinger's stone. They are told
# apart in hurt_player() without touching rat.gd / chief.gd (_piercing()), and the arena draws their warnings again in PIERCE_COL
# over the game's red ones (_draw_pierce_warnings()), so the player knows to dodge, not block.
const PIERCE := {"slam": true, "charge": true, "stone": true}
const PIERCE_COL := Color("#b46cff")
# The arena's weapons: id -> its name, its moves and its strings. A string is the letters of the presses that make it (L = light,
# Mouse 1; H = heavy, Mouse 2) -> the moves they play, its name (it floats up over the hero with the letters when the last move starts,
# so every string can be told apart while testing), "plain" on the weapon's basic one, and "pause", the recovery after it. Strings that start alike share those swings (LLL and LLH play the same two punches first), so the
# moves at the same place must match. A press that fits no string starts a new one (_next_chain), so a weapon needs a string starting
# with L and one starting with H, unless H is its "hold" move (the bow: H is held to draw, not a string). "block" = its guard ("cut" %
# let through, "stamina" a blocked hit), {} for none; "parry": false = its guard can't parry (the bow). "special" = its Q move (Stage
# 8d; none: Q is the lasso). A new weapon is a new row and its drawing (arena_player.gd); its tune keys come from its moves.
const ARENA_WEAPONS := {
	"unarmed": {"name": "Fists", "moves": FIST_MOVES, "block": {"cut": 50, "stamina": 15}, "strings": {
		"LLL": {"name": "Punch, punch, kick", "plain": true, "moves": ["punch", "punch", "kick"], "pause": 0.25},
		"LLH": {"name": "Shoulder charge", "moves": ["punch", "punch", "shoulder"], "pause": 0.3},
		"HHH": {"name": "Hammer fist", "moves": ["knee", "knee", "hammer"], "pause": 0.5},
		# finishers (Stage 8f): the fists' Q is the strong lasso, thrown at once (no hold); "reach" x its range
		"LLQ": {"name": "Lasso yank", "moves": ["punch", "punch", "lasso"], "pause": 0.3, "fin": {}},
		"HHQ": {"name": "Bull catch", "moves": ["knee", "knee", "lasso"], "pause": 0.3, "fin": {"reach": 1.3}},
	}},
	"sword": {"name": "Sword", "moves": SWORD_MOVES, "block": {"cut": 30, "stamina": 12}, "special": "flurry", "strings": {
		"LLL": {"name": "Slash, slash, thrust", "plain": true, "moves": ["slash", "slash", "thrust"], "pause": 0.25},
		"LHL": {"name": "Rising cut", "moves": ["slash", "rise", "slash"], "pause": 0.3},
		"HHH": {"name": "Three overheads", "moves": ["overhead", "overhead", "overhead"], "pause": 0.6},
		"LLQ": {"name": "Blazing flurry", "moves": ["slash", "slash", "flurry"], "pause": 0.4, "fin": {}},
		"LHQ": {"name": "Rising blaze", "moves": ["slash", "rise", "flurry"], "pause": 0.4, "fin": {"stun": true}},
		"HHQ": {"name": "Inferno", "moves": ["overhead", "overhead", "flurry"], "pause": 0.5, "fin": {"hits": 5, "dur": 0.9, "burn_ticks": 10}},
	}},
	"spear": {"name": "Spear", "moves": SPEAR_MOVES, "block": {"cut": 35, "stamina": 12}, "special": "whirl", "strings": {
		"LLL": {"name": "Jab, jab, thrust", "plain": true, "moves": ["jab", "jab", "long_thrust"], "pause": 0.3},
		"LLH": {"name": "Sweeping arc", "moves": ["jab", "jab", "sweep"], "pause": 0.35},
		"HHH": {"name": "Charging lunge", "moves": ["drive", "drive", "lunge"], "pause": 0.55},
		"LLQ": {"name": "Wide whirl", "moves": ["jab", "jab", "whirl"], "pause": 0.4, "fin": {"radius": 54.0}},
		"HHQ": {"name": "Vaulting whirl", "moves": ["drive", "drive", "whirl"], "pause": 0.45, "fin": {"dash": 160.0}},
	}},
	"bow": {"name": "Bow", "moves": BOW_MOVES, "block": {"cut": 55, "stamina": 15}, "parry": false, "hold": "aimed", "special": "piercer",
		"strings": {
		"LLL": {"name": "Volley", "plain": true, "moves": ["quick", "quick", "volley"], "pause": 0.5},
		"LLQ": {"name": "Piercing volley", "moves": ["quick", "quick", "piercer"], "pause": 0.5, "fin": {"arrows": 3, "spread": 0.12}},
	}},
}
# the game's name for the same table (scripts/combat.gd since Stage 8e): hud.gd, which the arena's HUD extends, reads it by that name
const WEAPON_KIT := ARENA_WEAPONS
const WEAPON_LIST := ["unarmed", "sword", "spear", "bow"]     # the order key 1 cycles through and the arena panel lists
const GET_UP := 1.2            # seconds after a fall before the hero gets up at full (the arena has no death screen)
const DPS_WINDOW := 5.0        # the HUD's "DPS (5 s)": the damage landed in the last this many seconds, per second
const CHAIN_WINDOW := 0.35     # seconds after a swing in which the next press continues the string
const REACH_FRONT := 30.0       # how far in front of the hero a hit can land
const REACH_SIDE := 15.0
const SWING_STEP := 55.0        # little forward shove on each swing
const DODGE := {"dur": 0.24, "speed": 170.0, "cooldown": 0.7, "invuln": 0.28, "stamina": 25}
# The lasso (Q with the fists). A tap of Q throws it (stamina). Holding Q for the charge (SPECIAL) readies the STRONG lasso, thrown when
# Q is let go: it costs `focus` (no stamina), reaches `strong_range` x as far, and stuns a light foe for twice as long. In the arena (Stage 8d,
# the user's rule: the fists' special) it PULLS a heavy one (a bandit) too, where the game binds him for `bind` s (the design doc:
# heavy enemies resist the lasso; see IMPROVEMENTS before porting). Bosses shrug both off.
const LASSO := {"range": 120.0, "width": 9.0, "widen": 0.12, "tip_speed": 650.0, "cool_hit": 2.0, "cool_miss": 1.0, "stamina": 20,
	"focus": 15, "strong_range": 1.5, "bind": 1.5}
# Q's timers (the user's 8d play-test: specials cost less, 15 focus now, but need time to recharge): a special goes on a tap, then
# no Q special for `cooldown` ms (special_cd). The strong lasso (the fists' special) still charges: Q held `charge` ms (a ring closes
# round the hero, and glows when it is ready, the focus is there and the cooldown is over), thrown when let go; it shares the
# cooldown. Let go early, or while cooling: the ordinary throw. Read through tune (q_charge(), special_cd_max()), so the tuning panel
# can change them.
const SPECIAL := {"charge": 600, "cooldown": 5000}
# Finishers (Stage 8f, the user's choice: the special as a combo's named finisher). A string ending in Q (LLQ, LHQ, HHQ ...) is
# played by pressing Q in the chain window after its first swings (or during the last, buffered): the weapon's special goes as the
# finisher, its row changed by the string's "fin" (more thrusts, a wider whirl, three piercing arrows, a longer reach for the lasso
# ...), with `mul` x its damage, for tune["focus"]["finisher"] focus (cheaper than a plain special), and it needs and restarts the
# special's cooldown (the user's choice). With the fists the finisher is the strong lasso at once, no hold. A Q string lists the
# moves before it like any other string, so the strings starting alike stay in step; put Q strings after the others.
const FINISHER := {"focus": 10, "mul": 1.5}
# Stamina (player.gd BASE_STAMINA): every swing, dodge and throw spends some. A move can start while any is left (it spends down to 0,
# forgiving for a beginner); at 0 the press does nothing and the bar flashes. It refills at `regen` per second, starting `delay` s after
# the last spend. Slow on purpose (the user, 2026-10-28: about 8 s from empty to full), so a long string of moves costs a real pause.
const STAMINA := {"regen": 15, "delay": 1.2}
# Focus (player.gd BASE_FOCUS): spent only on special moves (the strong lasso now; a firearm's shot or a weapon's special later, each
# with its own "focus" cost). It never refills by itself (the user, 2026-10-28): it fills by `per_hit` for every hit that lands on an
# enemy, and by `combo` more when the kick that ends a full punch-punch-kick lands, so fighting well is what charges a special move.
const FOCUS := {"per_hit": 3, "combo": 6}
const BOSSES := ["giant", "chief"]  # get the boss bar at the bottom of the screen (hud.gd); never pulled or bound by the lasso
const HERO_INVULN := 1.0        # seconds of invulnerability after being hurt
# the training dummy (world.hittables): a hit tips it away from the hero and it rocks back and forth, settling within `time` s.
# lean = max tilt (px sideways per px of height), freq / damp = how fast it rocks and settles, shake = share of the swing's own camera
# shake. No damage, no XP.
const DUMMY := {"lean": 0.32, "freq": 15.0, "damp": 4.0, "time": 1.2, "shake": 0.5}
const XP_RAT := 10
const XP_BANDIT := 25
const XP_GIANT := 100
const XP_CHIEF := 150
const XP_SLINGER := 15
const XP_SCORPION := 15
# Enemy levels (Stage 7f): a foe below the hero's level gives less XP (progress.gd kill_xp), so fighting the same weak foes again can't
# level him quickly. A map's enemy_plan() row can set its own "level" (later eras). A level changes only XP for now.
const FOE_LEVEL := {"rat": 1, "bandit": 2, "slinger": 2, "scorpion": 2, "giant": 3, "chief": 4}
# Weapon XP (progress.gd WEAPONS): a punch / a kick that lands on an enemy (not the dummy), a lasso catch, a strong-lasso catch or bind
const WEAPON_XP := {"punch": 1, "kick": 2, "slash": 1, "thrust": 2, "catch": 3, "strong": 5}
# Respawning (the user's rule, 2026-10-28): every ordinary planned enemy that has died comes back at home when the hero walks back into
# its map or rests there (respawn()). Bosses (BOSSES) never do, nor do enemies a map added during play (the ambush, the summons). One
# whose home is within RESPAWN_CLEAR px of the hero waits for the next time, so nothing appears on top of him.
const RESPAWN_CLEAR := 160.0
# Drops (Stage 7g, the user's decisions): what an enemy leaves where it falls (level.gd drop; walk over it to take it). Rows of
# [chance in %, item, min, max]; each row rolls on its own. A boss always leaves its rare find (its rows are 100), and since bosses never
# respawn it comes once; an ordinary foe rolls again each time it comes back. The chances are read through `tune` (drop_chance()).
const DROPS := {
	"rat": [[10, "bread", 1, 1]],
	"bandit": [[45, "coins", 5, 12], [15, "bread", 1, 1], [8, "small_potion", 1, 1]],
	"slinger": [[35, "coins", 3, 8], [10, "small_potion", 1, 1]],
	"giant": [[100, "carnelian_necklace", 1, 1], [100, "small_potion", 1, 1]],
	"chief": [[100, "ibex_armlet", 1, 1], [100, "large_potion", 1, 1], [100, "coins", 50, 50]],
}
# how many rats live at each nest (index = position in NEST_SPOTS in world_waystation.gd). 6 rats on the east side,
# between the road, the river and the cave. The 3 bandits stand on the road south of the town (BANDIT_SPOTS = world.bandit_spots).
const NEST_RATS := {0: 2, 1: 1, 2: 1, 3: 1, 4: 1}
# Bandits use the same brain as rats (rat.gd) with these numbers: they pace back and forth on a short beat,
# spot you from further away, take 6 punches, never flee, and are too heavy to lasso (the strong lasso binds them in place instead).
const _BANDIT := {
	"hp": 60, "flee_hp": 0,
	"patrol_speed": 20.0, "chase_speed": 54.0, "flee_speed": 60.0, "return_speed": 40.0, "roam": 30.0,
	"vision": 120.0, "cone": 1.05, "prox": 38.0, "leash": 200.0, "lose": 250.0,
	"wind_range": 30.0, "wind_time": 0.7, "wind_lock": 0.2, "lunge_speed": 130.0, "lunge_time": 0.22,
	"hit_dist": 17.0, "dmg": 20, "recover_time": 0.9, "cool": 1.1, "stagger": 0.3, "stun_time": 1.0,
	"pull_speed": 280.0, "pull_stop": 16.0, "pull_max": 0.8, "flee_safe": 150.0, "flee_wake": 90.0,
	"progress_time": 2.0, "progress_gain": 6.0, "lost_time": 3.0, "side_time": 1.0,     # getting stuck: see RAT
}
# The giant rat boss (storeroom): reuses the rat brain. HP = twice a bandit's. Armoured while it attacks (hits hurt but never interrupt).
# At half health it summons small rats, once. dmg = HP taken by its lunge.
const _GIANT := {
	"hp": 120, "flee_hp": 0, "sc": 2.4, "kb_mul": 0.25,
	"patrol_speed": 14.0, "chase_speed": 46.0, "flee_speed": 60.0, "return_speed": 40.0, "roam": 30.0,
	"vision": 130.0, "cone": 1.0, "prox": 40.0, "leash": 230.0, "lose": 280.0,
	"wind_range": 54.0, "wind_time": 0.8, "wind_lock": 0.25, "lunge_speed": 170.0, "lunge_time": 0.3,
	"hit_dist": 30.0, "dmg": 40, "recover_time": 1.1, "cool": 1.4, "stagger": 0.2, "stun_time": 1.0,
	"pull_speed": 280.0, "pull_stop": 16.0, "pull_max": 0.8, "flee_safe": 150.0, "flee_wake": 90.0,
	# half-health summon: 5-6 small rats in total, 2-4 from each side (the map says where: storeroom = the two southern pens)
	"summon_frac": 0.5, "summon_time": 1.1, "summon_total_min": 5, "summon_total_max": 6, "summon_side_min": 2, "summon_side_max": 4,
	# jump + ground slam: it crouches (red circle shows where it will land; the circle follows you, then freezes for the last
	# slam_lock seconds so you can run out of it), leaps (cannot be hurt in the air), and lands. You are hurt ONLY if you are
	# inside slam_radius of the landing spot at the moment it lands (a dodge roll's invulnerability also saves you).
	"slam_start_cd": 2.0, "slam_cd": 4.5, "slam_cd_hurt": 3.0, "slam_min": 62.0, "slam_max": 150.0,
	"slam_wind": 0.9, "slam_lock": 0.3, "slam_air": 0.5, "slam_height": 46.0, "slam_radius": 42.0, "slam_dmg": 40, "slam_recover": 1.3,
}
# The band's chief, the cave's boss (chief.gd): a big bandit with a long-handled axe. Asleep on his seat until you walk into the room.
# Armoured while he winds up, charges, sweeps or roars (hits hurt but never interrupt him); too heavy to lasso. Like every enemy he heals
# back to full once he has walked home, and can then enrage again.
#  charge: from charge_min..charge_max px, every charge_cd s. A red line on the ground follows you for charge_wind s and freezes for the
#          last charge_lock s; then he rushes charge_len px along it at charge_speed. Touching you: charge_dmg HP (a dodge passes
#          through him). Running into something tall (rock, a tent, the strongbox in his room) dazes him for daze_time s.
#  sweep:  inside sweep_range he swings the axe instead: a red arc of sweep_arc degrees and sweep_radius px, locked when the wind-up
#          starts; after sweep_wind s it hurts (sweep_dmg) only if you are inside it.
#  enrage: once, at enrage_frac of his health he roars for enrage_time s; afterwards his speeds are x enrage_mul and his wind-ups and
#          recovery / enrage_mul.
const _CHIEF := {
	"hp": 200, "flee_hp": 0, "sc": 1.3, "kb_mul": 0.3,
	"patrol_speed": 16.0, "chase_speed": 48.0, "return_speed": 44.0, "roam": 12.0,
	"vision": 200.0, "cone": 1.4, "prox": 60.0, "leash": 300.0, "lose": 360.0,
	"recover_time": 0.9, "cool": 0.6, "stagger": 0.25, "side_time": 1.0,
	"charge_min": 70.0, "charge_max": 200.0, "charge_wind": 0.8, "charge_lock": 0.25, "charge_speed": 230.0, "charge_len": 190.0,
	"charge_dmg": 40, "charge_hit": 16.0, "charge_cd": 3.5, "charge_start_cd": 1.0, "daze_time": 1.2,
	"sweep_range": 40.0, "sweep_wind": 0.6, "sweep_arc": 120.0, "sweep_radius": 44.0, "sweep_dmg": 20, "sweep_time": 0.2,
	"enrage_frac": 0.5, "enrage_mul": 1.3, "enrage_time": 0.8,
}
# The chief's slingers (slinger.gd): they come in at the edges of the boss room when he wakes, never before. A slinger backs off when
# you are nearer than `near` px and closes in when you are further than `keep_max`; when its sling is ready (`cool`) and it can see you
# within throw_range, it spins the sling for spin_time s (a thin aim line shows) and throws a stone. Light: the lasso pulls it.
const _SLINGER := {
	"hp": 20, "flee_hp": 0,
	"patrol_speed": 18.0, "chase_speed": 50.0, "back_speed": 46.0, "return_speed": 40.0, "roam": 20.0,
	"vision": 220.0, "cone": 1.5, "prox": 60.0, "leash": 320.0, "lose": 380.0,
	"near": 70.0, "keep_max": 130.0, "throw_range": 200.0, "spin_time": 0.7, "throw_cd": 1.6, "first_min": 0.6, "first_max": 1.6,
	"stone_speed": 180.0, "dmg": 20,
	"recover_time": 0.4, "cool": 1.6, "stagger": 0.3, "stun_time": 1.0, "side_time": 1.0,
	"pull_speed": 280.0, "pull_stop": 16.0, "pull_max": 0.8, "flee_safe": 150.0, "flee_wake": 90.0,
}
# The scorpions of the ruins (Stage 7j, rat.gd kind "scorpion"; the den is world_waystation.gd DEN): desert wildlife guarding their
# den (type A). Slow, short-sighted (a narrow cone, but they feel you come close), they stay near the den and never flee. They teach one
# thing, the poison: the sting has a long wind-up (the tail arches over the back while a red line shows) and a short reach, and one
# that lands does `dmg` and poisons (POISON). Light: the lasso pulls them. No drops.
const _SCORPION := {
	"hp": 40, "flee_hp": 0, "kb_mul": 0.6, "poison": true,
	"patrol_speed": 12.0, "chase_speed": 44.0, "flee_speed": 50.0, "return_speed": 34.0, "roam": 24.0,
	"vision": 80.0, "cone": 0.8, "prox": 34.0, "leash": 130.0, "lose": 170.0,
	"wind_range": 30.0, "wind_time": 0.8, "wind_lock": 0.2, "lunge_speed": 120.0, "lunge_time": 0.16,
	"hit_dist": 14.0, "dmg": 10, "recover_time": 0.9, "cool": 1.2, "stagger": 0.25, "stun_time": 1.0,
	"pull_speed": 280.0, "pull_stop": 16.0, "pull_max": 0.8, "flee_safe": 150.0, "flee_wake": 90.0,
	"progress_time": 2.0, "progress_gain": 6.0, "lost_time": 3.0, "side_time": 1.0,     # getting stuck: see RAT
}
# Poison (Stage 7j): a sting from an enemy whose table has "poison" (the scorpion) poisons whoever it lands on, the hero or a companion:
# `dmg` HP every `every` s, `ticks` times (with the sting's own 10, a sting costs 30 in all). A new sting starts the count again rather
# than adding to it. It never takes the last HP (a poison alone can't kill), and a rest cures it. The count lives on the body
# (`poison`, `poison_t`: player.gd, rider.gd); it is not saved.
const POISON := {"dmg": 4, "every": 1.0, "ticks": 5}
# The rider freed from the cave's cage (rider.gd): out of a fight he walks the hero's own trail `follow_gap` px behind (at `speed`, or
# `catch_speed` when he has fallen behind), and jumps back to the hero when more than `snap_dist` away. In a fight (fighting()) he moves
# on his own: he keeps `keep_min` px from the nearest enemy, comes back toward the hero when he has no shot, and never strays more than
# `leash` px from him (stuck for `stuck_snap` s: he joins the hero at once). Every `shot_every` s, if an enemy is within `range`, in sight
# and in the fight (rat.gd in_fight: never a sleeping, unaware or merely suspicious one), he steps `step_out` px to the side, draws for
# `draw_time` s and shoots.
# An arrow does `dmg` and a small knock-back (`kb`) but never staggers: one every 0.5 s would pin an enemy in place.
# Since 7i he can be hurt (`hp`; `invuln` s after each hit, so two biting rats don't empty his bar at once). At 0 HP he falls and stays
# down until a Reviving Potion (back up with `revive` % of his HP) or a rest. Each arrow that lands adds `focus_per_hit` to his focus
# (`focus` at most); with a full bar his next shot is a volley of `volley` arrows fanned `volley_spread` rad apart, which empties it.
const RIDER := {
	"shot_every": 0.5, "range": 170.0, "draw_time": 0.16, "step_out": 9.0,
	"arrow_speed": 300.0, "dmg": 10, "kb": 40.0,
	"follow_gap": 22.0, "speed": 74.0, "catch_speed": 140.0, "snap_dist": 220.0,
	"keep_min": 60.0, "leash": 120.0, "stuck_snap": 1.0,
	"hp": 80, "invuln": 0.6, "revive": 10,
	"focus": 50, "focus_per_hit": 5, "volley": 3, "volley_spread": 0.2,
}
# Who an enemy goes after (the user's rule, 2026-10-28): once in the fight (rat.gd in_fight), whoever is nearest of the hero and the
# companions standing with him, checked every `recheck` s while it chases (never in the middle of an attack). The hero counts as `tie` px
# nearer than he is, so he wins a close call. Enemies still only notice the hero, so a companion never starts a fight.
const FOE := {"recheck": 0.4, "tie": 24.0}
# The alarm (the user's rule, 2026-10-28): when an enemy joins the fight (it spotted the hero, or he struck it first), every other enemy
# of the same SIDE within `radius` px that can see it (no wall between) stops patrolling and joins the fight too. Only those it calls
# join; they don't call others in turn, so one alarm never sweeps a whole map. The one exception: the members of its enemy_plan() group
# (a nest, a camp) all join, however far (the user's play-test). Sleeping enemies (a group not yet woken) and bosses keep their own
# wake-ups.
const ALARM := {"radius": 150.0}
# Staying in a fight (the user's play-test, Stage 7l): an enemy is "engaged" while its foe is within `near` px or it was hit in the
# last `hit_time` s (rat.gd engaged). Engaged, its leash and getting stuck don't send it home (before, a bandit knocked a little past
# its leash, or caught on a tent in the cave, walked off mid-fight); stuck for `stuck_max` s it still gives up, and `hard` x its leash
# from home ends any chase, so a fight can't be dragged across the map.
const ENGAGE := {"near": 80.0, "hit_time": 3.0, "hard": 1.75, "stuck_max": 4.0}
const SIDE := {"rat": "rats", "giant": "rats", "bandit": "band", "slinger": "band", "chief": "band", "scorpion": "scorpions"}
# flying things (arrows, and the slingers' stones in 6c): how far one may fly, and how close to a body counts as a hit
const SHOT_LIFE := 1.0
const SHOT_HIT := {"rat": 7.0, "bandit": 8.0, "giant": 18.0, "chief": 11.0, "slinger": 8.0, "scorpion": 8.0, "hero": 8.0}
const _RAT := {
	"hp": 30, "flee_hp": 10, "calm_time": 4.0,     # calm_time: hiding hurt, s with the hero away before it walks home to heal
	"patrol_speed": 16.0, "chase_speed": 50.0, "flee_speed": 60.0, "return_speed": 40.0, "roam": 40.0,
	"vision": 100.0, "cone": 0.9, "prox": 28.0, "leash": 170.0, "lose": 210.0,
	"wind_range": 36.0, "wind_time": 0.55, "wind_lock": 0.15, "lunge_speed": 150.0, "lunge_time": 0.24,
	"hit_dist": 12.0, "dmg": 20, "recover_time": 0.8, "cool": 0.9, "stagger": 0.25, "stun_time": 1.0,
	"pull_speed": 280.0, "pull_stop": 16.0, "pull_max": 0.8, "flee_safe": 150.0, "flee_wake": 90.0,
	# getting stuck (there is no pathfinding): a chasing rat that has not moved progress_gain px toward the hero in progress_time s
	# (a wall or rock in the way) gives up, walks home and ignores the hero for lost_time s. A rat that is only being outrun keeps
	# chasing. side_time = how long it keeps going round an obstacle on the side it picked. The giant leaves all four out.
	"progress_time": 2.0, "progress_gain": 6.0, "lost_time": 3.0, "side_time": 1.0,
}

# The live values the tuning panel (arena_tuning.gd, T) edits: each move's damage and stamina, the rider's arrow damage, HP and XP
# per enemy kind, the dodge and lasso stamina (and the refill), the focus gains and the strong lasso's cost, and the drop chances. They
# start as the constants above, so without the panel nothing differs. Read them through enemy_hp(), hit_dmg(), arrow_dmg(), xp_for(),
# stamina_cost(), focus_val() and drop_chance(), never the constants, so a change on the panel shows up in the fight at once.
var tune := default_tune()

# The enemy tables rat.gd, chief.gd and slinger.gd read (R = combat.RAT, ...). In the game they are constants; here they are copies
# the arena's tuning panel can change (a constant dictionary can't be written), and the enemies already standing hold the same
# dictionary, so a new hit damage counts from their next attack. reset_foe() puts a value back from the constant.
var RAT := _RAT.duplicate()
var BANDIT := _BANDIT.duplicate()
var GIANT := _GIANT.duplicate()
var CHIEF := _CHIEF.duplicate()
var SLINGER := _SLINGER.duplicate()
var SCORPION := _SCORPION.duplicate()

# an enemy kind's table (the live copy, or with base = true the constant it started as)
func foe_table(kind: String, base := false) -> Dictionary:
	match kind:
		"bandit": return _BANDIT if base else BANDIT
		"giant": return _GIANT if base else GIANT
		"chief": return _CHIEF if base else CHIEF
		"slinger": return _SLINGER if base else SLINGER
		"scorpion": return _SCORPION if base else SCORPION
	return _RAT if base else RAT

func reset_foe(kind: String, key: String) -> void:
	foe_table(kind)[key] = foe_table(kind, true)[key]

var world            # the map the hero is on right now (swapped by main.gd on a map change)
var player
var progress         # progress.gd: XP, the weapon levels and their bonuses (set by main.gd)
var squad            # squad.gd: the companions, who can be hurt and fight beside the hero (set by main.gd)
var inv              # inventory.gd: whether the hero has the sword (set by main.gd)
var quest            # quest.gd: kills count toward a side quest's goal (count_kill; set by main.gd)
var weapon := "unarmed"   # what the attacks swing: an ARENA_WEAPONS id
var rats: Array = []   # that map's enemies (same array as world.rats)
var kills := 0
var kills_by := {}     # kind -> how many the hero's side has cut down (the journal's Enemies list; saved)
var rng := RandomNumberGenerator.new()    # the drop rolls (the test suites seed it, so a run is repeatable)
var fx_node

# swing state
var swing_n := -1          # the swing on now: its place in the string (0, 1, 2), or -1
var swing_t := 0.0
var move := ""             # the move on now (or the last one swung): a key of the weapon's moves
var chain := ""            # the letters of the string so far, the swing on now included ("LL"); "" between strings
var chain_t := 0.0
var atk_pause := 0.0
var pause_max := 0.25      # the pause after the last string (its "pause"), for the timeline
var buffered := ""         # "L" / "H": pressed during a swing, played when it ends
var named := false         # the finished string's name has floated up (once a string)
var fired := false         # a bow move's arrow has gone (once a swing)
var string_id := 0         # counts the strings started; the hero's arrows carry it ("sid"), so the volley knows which ones were its own
var landed := 0            # the arrows of the string on now that have hit something (the volley's "earn")
var _pierce_shot := false  # the hit being judged now is a stone (PIERCE), set round hurt_body() in _update_shots()
# specials and the parry (Stage 8d)
var _seg := -1             # a multi-hit move's thrust on now (the flurry: each one hits afresh)
var burning := {}          # foe -> {"ticks": left, "t": s to the next} (BURN)
var parry_t := 0.0         # s left in which a hit on the guard is parried (from a fresh Space press)
var special_cd := 0.0      # s before the next Q special or strong lasso (SPECIAL.cooldown)
var _cur := {}             # the row of the move on now, with a finisher's changes (Stage 8f; _row())
# the bow (Stage 8c)
var draw_t := -1.0         # seconds H has been held drawing the bow (< 0: not drawing)
var draw_k := 0.0          # how far the last arrow let go was drawn, 0..1 (its damage and speed)
var _drain_frac := 0.0     # the part of a point of stamina drawn off so far
# the block (Stage 8c)
var blocking := false      # the guard is up (Space held, and nothing else going on)
var guard_broken := 0.0    # s left with the guard broken (no block, swing or lasso)
var block_flash := 0.0     # the guard lights up: it just took a hit
var _blocked_frame := -1   # the physics frame of the last blocked hit (a sting caught on the guard doesn't poison)
var hit_set: Array = []
var hit_props: Array = []   # hittables (the dummy) already hit by the current swing
# dodge / lasso state
var dodge_t := 0.0
var dodge_cd := 0.0
var lasso_phase := 0            # 0 idle, 1 rope flying out, 2 pulling a rat, 3 rope coming back
var lasso_len := 0.0
var lasso_reach := 0.0
var lasso_target
var lasso_cd := 0.0
var lasso_cd_max := 1.0
var lasso_charge := -1.0        # how long Q has been held: the strong lasso, or a special charging (Stage 8d) (< 0: not holding)
var lasso_strong := false       # the rope out now is the strong lasso
# stamina / focus
var stamina_t := 0.0            # seconds since stamina was last spent (it refills after STAMINA.delay)
var tired_t := 0.0              # the stamina bar flashes: a move was refused for want of stamina
var focus_flash := 0.0          # the focus bar flashes: not enough focus for the strong lasso
var _st_frac := 0.0             # the part of a point of stamina refilled so far
# effects
var sparks: Array = []
var texts: Array = []
# flying arrows and stones: {"p": Vector2, "v": Vector2, "dmg": int, "side": "ally" (hits enemies) | "enemy" (hits the hero), "kind": "arrow" | "stone", "life": s}
var shots: Array = []
# the hero's fall
var over_t := -1.0              # seconds since he fell (< 0: he hasn't); in the arena he gets up after GET_UP
var hurt_flash := 0.0
# the arena: cheats (the panel's Hero tab) and what the readouts show (its Show tab)
var god := false                # can't die: HP never goes under 1 (hits still land and show)
var endless_stamina := false
var endless_focus := false
var no_q_cooldown := false      # Q never waits: no special / finisher / strong-lasso cooldown, and the lasso's own throw cooldown is skipped
var view := {"numbers": true, "readout": true, "timeline": true, "boxes": false}
# every hit that lands: {"t": s (game clock), "dmg": int, "move": String, "on": kind or "dummy"}; trimmed to the last minute
var hits: Array = []
var total_dmg := 0              # since the last reset (reset_readout)
var total_hits := 0
var first_t := -1.0             # game clock of the first hit since the last reset
var clock := 0.0                # seconds of play (stops while a panel pauses the game)

func setup() -> void:
	rng.randomize()
	attach(world)

static func default_tune() -> Dictionary:
	var drops := {}
	for k in DROPS.keys():
		drops[k] = DROPS[k].map(func(row): return row[0])
	var t := {
		"drops": drops,
		"arrow": RIDER["dmg"],
		"hp": {"rat": _RAT["hp"], "bandit": _BANDIT["hp"], "slinger": _SLINGER["hp"], "scorpion": _SCORPION["hp"], "giant": _GIANT["hp"],
			"chief": _CHIEF["hp"]},
		"xp": {"rat": XP_RAT, "bandit": XP_BANDIT, "slinger": XP_SLINGER, "scorpion": XP_SCORPION, "giant": XP_GIANT, "chief": XP_CHIEF},
		"stamina": {"dodge": DODGE["stamina"], "lasso": LASSO["stamina"], "regen": STAMINA["regen"]},
		"focus": {"per_hit": FOCUS["per_hit"], "combo": FOCUS["combo"], "strong": LASSO["focus"], "finisher": FINISHER["focus"]},
		"parry": {"window": PARRY["window"], "focus": PARRY["focus"]},
		"special": {"charge": SPECIAL["charge"], "cooldown": SPECIAL["cooldown"]},
	}
	# every move of every weapon: its damage under its own name, its stamina under "stamina"; each weapon's block under "block"
	t["block"] = {}
	for id in ARENA_WEAPONS:
		var w: Dictionary = ARENA_WEAPONS[id]
		for m in w["moves"]:
			t[m] = w["moves"][m]["dmg"]
			t["stamina"][m] = w["moves"][m]["stamina"]
			if w["moves"][m].has("focus"):          # a special's cost, or the volley's
				t["focus"][m] = w["moves"][m]["focus"]
		if not w["block"].is_empty():
			t["block"][id] = w["block"].duplicate()
	return t

# what a move costs: a move's name, "dodge", "lasso"; "regen" is the refill per second
func stamina_cost(what: String) -> int:
	return tune["stamina"][what]

# "per_hit" (focus gained per hit that lands), "combo" (more when a full combo's kick lands), "strong" (the strong lasso's cost)
func focus_val(what: String) -> int:
	return tune["focus"][what]

func enemy_hp(kind: String) -> int:
	return tune["hp"].get(kind, tune["hp"]["rat"])

# the moves of the weapon in hand (ARENA_WEAPONS), and the row of the move on now (its own row, changed by a finisher's "fin": _cur)
func _moves() -> Dictionary:
	return ARENA_WEAPONS[weapon]["moves"]

func _row() -> Dictionary:
	return _cur if not _cur.is_empty() else _moves()[move]

# what the swing on now is called: its tune key, stamina cost and weapon-XP key
func move_name() -> String:
	return move

# damage of move m: the panel's value plus what the weapon's level adds to its "lv" key (a weapon progress.gd doesn't know adds nothing)
func hit_dmg(m: String) -> int:
	var lv_bonus := 0
	var lv: String = _moves()[m]["lv"]
	if lv != "" and progress != null and progress.WEAPONS.has(weapon):      # (a special has none: "lv" "")
		lv_bonus = int(progress.bonus(weapon, lv))
	return tune[m] + lv_bonus

# ---- strings (Stage 8b)
# the first of the weapon's strings that starts with the letters c ("" if none does)
func _string_for(c: String) -> String:
	for s in ARENA_WEAPONS[weapon]["strings"].keys():
		if s.begins_with(c):
			return s
	return ""

# the chain a press of key ("L" / "H") makes: the string so far plus key if a string starts that way, else a new one from key alone
func _next_chain(key: String) -> String:
	for c in [chain + key, key]:
		if _string_for(c) != "":
			return c
	return ""

# the move the chain c plays last (its place in the strings that start with c)
func _move_of(c: String) -> String:
	return ARENA_WEAPONS[weapon]["strings"][_string_for(c)]["moves"][c.length() - 1]

# the swing on now ends its string: no longer string starts with the chain so far
func _is_last() -> bool:
	for s in ARENA_WEAPONS[weapon]["strings"].keys():
		if s.length() > chain.length() and s.begins_with(chain):
			return false
	return true

# the string the chain so far is part of: {"name", "moves", "pause"}
func _string() -> Dictionary:
	return ARENA_WEAPONS[weapon]["strings"][_string_for(chain)]

# Key 1: the next weapon in WEAPON_LIST (only between swings). Returns what the HUD may say (its name).
func switch_weapon() -> String:
	var i := WEAPON_LIST.find(weapon)
	return equip(WEAPON_LIST[(i + 1) % WEAPON_LIST.size()])

# take weapon w in hand (key 1, the arena panel's Weapons tab); "" if it can't be done now
func equip(w: String) -> String:
	if swing_n >= 0 or draw_t >= 0.0 or lasso_phase != 0 or lasso_charge >= 0.0 or player.dodging or not ARENA_WEAPONS.has(w):
		return ""
	weapon = w
	chain = ""
	chain_t = 0.0
	return ARENA_WEAPONS[w]["name"]

# the weapon in hand's guard from tune ({"cut", "stamina"}), {} for a weapon that can't block (none now; a row's "block": {})
func guard() -> Dictionary:
	return tune["block"].get(weapon, {})

# the lasso's reach and its cooldowns ("cool_hit" / "cool_miss"), with what the Lasso weapon level adds
func lasso_range() -> float:
	return LASSO["range"] + (progress.bonus("lasso", "range") if progress != null else 0.0)

func lasso_cool(which: String) -> float:
	return maxf(0.2, LASSO[which] - (progress.bonus("lasso", "cool") if progress != null else 0.0))

# (the arena: no weapon XP, so a weapon stays at the level the arena panel set)
func _weapon_xp(_w: String, _n: int) -> void:
	pass

func arrow_dmg() -> int:
	return tune["arrow"]

func xp_for(kind: String) -> int:
	return tune["xp"].get(kind, tune["xp"]["rat"])

# the chance (%) of DROPS[kind] row i
func drop_chance(kind: String, i: int) -> int:
	return tune["drops"][kind][i]

# roll each of a fallen enemy's DROPS rows; what comes up lies where it fell
func _roll_drops(r) -> void:
	var rows: Array = DROPS.get(r.kind, [])
	for i in range(rows.size()):
		if rng.randi_range(1, 100) <= drop_chance(r.kind, i):
			r.world.drop(rows[i][1], rng.randi_range(rows[i][2], rows[i][3]), r.position)

# Make `lvl` the map the fight happens on: its enemy list, its spark layer. The first time a map is attached its enemies are spawned.
# (Other maps keep their own enemies, frozen, while they are out of the scene tree.)
func attach(lvl) -> void:
	world = lvl
	lvl.combat = self
	rats = lvl.rats
	shots.clear()
	if lvl.fx_node == null:
		lvl.fx_node = Drawn.new()
		lvl.fx_node.z_index = 50
		lvl.fx_node.animated = true
		lvl.add_child(lvl.fx_node)
	fx_node = lvl.fx_node
	fx_node.draw_fn = _draw_fx
	sparks.clear()
	texts.clear()
	if not lvl.populated:
		lvl.populated = true
		var plan: Array = lvl.enemy_plan(self)
		for i in range(plan.size()):
			if lvl.dead_plan.has(i):        # killed before the game was saved
				continue
			_spawn_planned(i, plan[i])

# enemy_plan() row i of the current map
func _spawn_planned(i: int, e: Dictionary) -> Node:
	var r = _spawn_rat(e["pos"], e.get("kind", "rat"), e.get("axis", Vector2.RIGHT), e.get("span", 30.0), e.get("group", ""), e.get("munch", Vector2.ZERO))
	r.plan_i = i
	r.level = e.get("level", r.level)
	return r

# The hero walked back into this map (main.gd _switch_level) or rested here (main.gd rest): the ordinary planned enemies that died come
# back at home (see RESPAWN_CLEAR). A group with nobody left alive goes back to sleep first, so its foes wake as they did the first time.
func respawn(lvl) -> void:
	if lvl != world or lvl.dead_plan.is_empty():
		return
	var plan: Array = lvl.enemy_plan(self)
	var back := []
	for i in lvl.dead_plan:
		var e: Dictionary = plan[i]
		if e.get("kind", "rat") in BOSSES or player.position.distance_to(e["pos"]) <= RESPAWN_CLEAR:
			continue
		back.append(i)
	if back.is_empty():
		return
	for g in lvl.groups.keys():
		var left := false
		for r in lvl.rats:
			if r.alive and r.group == g:
				left = true
		if not left:
			lvl.groups[g]["active"] = false
	for i in back:
		lvl.dead_plan.erase(i)
		_spawn_planned(i, plan[i])

# stop whatever the hero is doing (before a map change)
func cancel_all() -> void:
	_cancel_swing()
	_cancel_draw()
	_cancel_charge()
	lasso_phase = 0
	lasso_target = null
	player.lock = false
	player.dodging = false
	dodge_t = 0.0

# kind: "rat" | "bandit" | "giant" | "scorpion" | "chief" | "slinger". A rat with a group name sleeps until level.update_groups() wakes
# the group. The chief and the slingers have their own scripts (built on rat.gd); everything else is rat.gd.
func _spawn_rat(home: Vector2, kind := "rat", axis := Vector2.RIGHT, span := 30.0, group := "", munch := Vector2.ZERO) -> Node:
	var h := home
	if world.feet_blocked(h):    # nudge to the nearest free spot
		var found := false
		for r in range(6, 50, 6):
			for k in range(8):
				var c: Vector2 = home + Vector2.RIGHT.rotated(TAU * k / 8.0) * r
				if not world.feet_blocked(c):
					h = c
					found = true
					break
			if found:
				break
	var rat: Node2D = (Chief if kind == "chief" else (Slinger if kind == "slinger" else Rat)).new()
	world.ysort.add_child(rat)
	rat.level = FOE_LEVEL.get(kind, 1)
	rat.group = group
	rat.dormant = group != "" and world.groups.has(group) and not world.groups[group]["active"]
	rat.setup(self, world, player, h, kind, axis, span)
	if munch != Vector2.ZERO and rat.dormant:
		rat.munching = true       # asleep at a sack, eating
		rat.munch_at = munch
		rat.flip = 1 if munch.x >= h.x else -1
	rats.append(rat)
	return rat

# an enemy a map adds during play (the cave's ambush): e is an enemy_plan() entry. aggro = it charges the hero at once.
func spawn_enemy(e: Dictionary, aggro := false) -> Node:
	var r = _spawn_rat(e["pos"], e.get("kind", "rat"), e.get("axis", Vector2.RIGHT), e.get("span", 30.0), e.get("group", ""))
	r.level = e.get("level", r.level)
	spark(r.position + Vector2(0, -4), Vector2.UP, 8, Color("#c8b89a"))
	if aggro:
		r.wake(true)
	return r

# the giant calls for help: 5-6 small rats in total, 2-4 from the left side and the rest from the right (awake, already chasing).
# The map gives the spawn points (storeroom: inside the two southern pens); without any, they appear in a ring around the giant.
func summon_helpers(boss) -> void:
	var total := randi_range(GIANT["summon_total_min"], GIANT["summon_total_max"])
	var lo: int = maxi(GIANT["summon_side_min"], total - GIANT["summon_side_max"])
	var hi: int = mini(GIANT["summon_side_max"], total - GIANT["summon_side_min"])
	var left := randi_range(lo, hi)
	var right := total - left
	var pts: Dictionary = world.summon_points()
	var got := [0, 0]
	if pts.is_empty():
		got[0] = _summon_at(boss, _ring(boss), total)
	else:
		got[0] = _summon_at(boss, pts.get("left", []), left)
		got[1] = _summon_at(boss, pts.get("right", []), right)
	boss.summon_split = got

func _ring(boss) -> Array:
	var out := []
	var a0 := randf() * TAU
	for k in range(24):
		out.append(boss.position + Vector2.RIGHT.rotated(a0 + TAU * k / 7.0) * (30.0 + 6.0 * (k / 7)))
	return out

func _summon_at(boss, pts: Array, count: int) -> int:
	var order := pts.duplicate()
	order.shuffle()
	var made := 0
	for p in order:
		if made >= count:
			break
		if world.feet_blocked(p):
			continue
		var crowded := false
		for o in rats:
			if o.alive and o.position.distance_to(p) < 12.0:
				crowded = true
		if crowded:
			continue
		var r = _spawn_rat(p, "rat")
		r.dormant = false
		r.leash = 420.0           # they come from far away (the pens): do not let the leash call them home at once
		r.lose = 420.0
		r._enter("chase")
		spark(p + Vector2(0, -4), Vector2.UP, 8, Color("#c8b89a"))
		made += 1
	return made

# the boss the hero is fighting right now (the giant, the chief): alive and after him, or null. hud.gd draws its bar.
func boss():
	for r in rats:
		if r.kind in BOSSES and r.after_hero():
			return r
	return null

func rats_alive() -> int:
	var n := 0
	for r in rats:
		if r.alive:
			n += 1
	return n

# is a fight on? (an enemy on this map has spotted the hero, or he struck first: rat.gd in_fight). Companions move on their own while it is.
func fighting() -> bool:
	for r in rats:
		if r.in_fight():
			return true
	return false

# `src` has just joined the fight: its side within ALARM.radius, in sight of it, joins too (rat.gd join_fight), and so does every awake
# member of its plan group however far (a nest fights as one: the user's play-test, where the storeroom's side room's far rats sat out)
func alarm(src) -> void:
	var side: String = SIDE.get(src.kind, src.kind)
	for r in rats:
		if r == src or not r.alive or r.dormant or r.in_fight() or r.kind in BOSSES or SIDE.get(r.kind, r.kind) != side:
			continue
		var kin: bool = src.group != "" and r.group == src.group
		if kin or (r.position.distance_to(src.position) <= ALARM["radius"] and world.los(src.position, r.position)):
			r.join_fight()

# ---------------------------------------------------------------- the squad in the fight
# the companions with the hero on this map (following or waiting), standing or fallen
func mates() -> Array:
	var out := []
	if squad == null or world == null:
		return out
	for m in squad.current(world.era):
		if m["order"] != "home" and is_instance_valid(m["node"]) and m["node"].get_parent() == world.ysort:
			out.append(m["node"])
	return out

# who an enemy can go after: the hero (unless he has fallen) and the companions standing with him
func targets() -> Array:
	var out := [] if player.dead else [player]
	for m in mates():
		if m.can_be_hurt():
			out.append(m)
	return out

# hurt the hero or a companion; true if it landed (not while invulnerable)
func hurt_body(b, dmg: int, from_pos: Vector2) -> bool:
	if b == player:
		return hurt_player(dmg, from_pos)
	return b.hurt(dmg, from_pos)

# ---------------------------------------------------------------- helpers
# where attacks go: the hero's 8-way aim (arena_player.gd), not the 4 ways his body faces
func facing() -> Vector2:
	return player.facing_vec()

func hand() -> Vector2:
	return player.position + Vector2(0, -11) + facing() * 5.0

# ---------------------------------------------------------------- main loop
func _physics_process(dt: float) -> void:
	if player == null:
		return
	hurt_flash = maxf(0.0, hurt_flash - dt)
	player.weapon = weapon          # (the hero only draws it: the sword in hand, or at his hip)
	player.has_sword = inv != null and inv.has("sword")
	clock += dt
	if player.dead:
		over_t += dt          # (the arena: he gets up after GET_UP, _get_up)
		if over_t >= GET_UP:
			_get_up()
		return
	if not world.talking:
		world.update_groups()
	if endless_stamina:
		player.stamina = player.max_stamina
	if endless_focus:
		player.focus = player.max_focus
	if no_q_cooldown:
		special_cd = 0.0
		lasso_cd = 0.0
	_refill(dt)
	_update_poison(dt)
	var can_act: bool = not world.talking
	var key := ""           # light (Mouse 1) or heavy (Mouse 2) pressed this frame
	if can_act and Input.is_action_just_pressed("light"):
		key = "L"
	elif can_act and Input.is_action_just_pressed("heavy"):
		key = "H"

	# --- dodge
	dodge_cd = maxf(0.0, dodge_cd - dt)
	if dodge_t > 0.0:
		dodge_t -= dt
		player.dodge_p = 1.0 - maxf(dodge_t, 0.0) / DODGE["dur"]
		if dodge_t <= 0.0:
			player.dodging = false
	elif can_act and Input.is_action_just_pressed("dodge") and dodge_cd <= 0.0 and lasso_phase == 0:
		if _spend(stamina_cost("dodge")):
			_cancel_charge()              # a dodge drops a strong lasso being gathered (and a drawn bow, _start_dodge)
			_start_dodge()

	# --- the block (Space held): only between moves (not while drawing the bow), not while the guard is broken
	guard_broken = maxf(0.0, guard_broken - dt)
	block_flash = maxf(0.0, block_flash - dt)
	blocking = can_act and Input.is_action_pressed("block") and not guard().is_empty() and guard_broken <= 0.0 \
		and swing_n < 0 and draw_t < 0.0 and not player.dodging and lasso_phase == 0 and lasso_charge < 0.0
	player.blocking = blocking
	# the parry window opens on a fresh press of Space (Stage 8d), with a weapon whose guard can parry
	parry_t = maxf(0.0, parry_t - dt) if blocking else 0.0       # (it closes with the guard)
	if blocking and Input.is_action_just_pressed("block") and ARENA_WEAPONS[weapon].get("parry", true):
		parry_t = tune["parry"]["window"] / 1000.0
	_update_burns(dt)

	# --- light and heavy attacks: each press goes on with one of the weapon's strings (_next_chain); the bow's H draws (_update_draw)
	if swing_n >= 0:
		_update_swing(dt)
	else:
		atk_pause = maxf(0.0, atk_pause - dt)
		if chain_t > 0.0:
			chain_t -= dt
			if chain_t <= 0.0:
				chain = ""
	if draw_t >= 0.0:
		_update_draw(dt, can_act)
	elif key != "" and not player.dodging and not blocking and guard_broken <= 0.0 and lasso_phase == 0 and lasso_charge < 0.0:
		if swing_n >= 0:
			if swing_t / _row()["dur"] > 0.3:
				buffered = key
		elif atk_pause <= 0.0:
			_try_swing(key)

	# --- Q: the weapon's special (Stage 8d), on a tap, then SPECIAL.cooldown before the next (special_cd); with the fists the lasso: a
	# tap of Q throws it, holding Q for the charge readies the strong lasso (it shares the cooldown), thrown when Q is let go
	# A Q that ends the string so far (Stage 8f) is a finisher instead: at once in the chain window, or buffered during the swing.
	lasso_cd = maxf(0.0, lasso_cd - dt)
	special_cd = maxf(0.0, special_cd - dt)
	var q_pressed: bool = can_act and Input.is_action_just_pressed("lasso")
	if q_pressed and _q_fits() and (swing_n >= 0 or chain_t > 0.0) and not player.dodging and draw_t < 0.0 and lasso_phase == 0 \
			and lasso_charge < 0.0:
		if swing_n >= 0:
			if swing_t / _row()["dur"] > 0.3:
				buffered = "Q"
		else:
			_try_finisher()
	elif ARENA_WEAPONS[weapon].has("special"):
		if can_act and Input.is_action_just_pressed("lasso") and swing_n < 0 and atk_pause <= 0.0 and draw_t < 0.0 \
				and not player.dodging and not blocking and guard_broken <= 0.0 and lasso_phase == 0:
			_try_special()
	elif lasso_charge >= 0.0:
		if not can_act or player.dodging:
			_cancel_charge()
		elif Input.is_action_pressed("lasso"):
			lasso_charge += dt
		else:
			_release_lasso()
	elif can_act and Input.is_action_just_pressed("lasso") and lasso_cd <= 0.0 and lasso_phase == 0 \
			and not player.dodging and swing_n < 0 and draw_t < 0.0 and not blocking and guard_broken <= 0.0:
		lasso_charge = 0.0
		player.aiming = true          # gathering the rope: he can turn to aim, but not walk
	_update_lasso(dt)

# ---------------------------------------------------------------- stamina and focus
# Spend stamina on a move: false (and the bar flashes) if there is none left. Any stamina at all is enough to start a move; it spends
# down to 0 (forgiving for a beginner).
func _spend(cost: int) -> bool:
	if player.stamina <= 0:
		tired_t = 0.6
		return false
	player.stamina = maxi(0, player.stamina - cost)
	stamina_t = 0.0
	return true

# stamina refills STAMINA.delay s after the last spend (the fraction is carried so a low rate still adds up at 60 frames a second),
# at BLOCK.regen x the rate behind the guard. Focus doesn't refill here: only hits feed it (_gain_focus).
func _refill(dt: float) -> void:
	tired_t = maxf(0.0, tired_t - dt)
	focus_flash = maxf(0.0, focus_flash - dt)
	stamina_t += dt
	if stamina_t >= STAMINA["delay"] and player.stamina < player.max_stamina:
		_st_frac += stamina_cost("regen") * dt * (BLOCK["regen"] if blocking else 1.0)
		var add := int(_st_frac)
		_st_frac -= add
		player.stamina = mini(player.max_stamina, player.stamina + add)

# a hit that lands on an enemy feeds the focus bar; the kick that ends a full combo adds FOCUS.combo (once per kick, however many it hits)
func _gain_focus(finisher := false) -> void:
	var add := focus_val("per_hit") + (focus_val("combo") if finisher else 0)
	player.focus = mini(player.max_focus, player.focus + add)

# 0..1: how far the strong lasso has been charged (only while Q is held)
func lasso_charge_frac() -> float:
	return clampf(lasso_charge / q_charge(), 0.0, 1.0) if lasso_charge >= 0.0 else 0.0

# seconds Q must be held before the strong lasso is ready (tune["special"]["charge"], in ms, on the tuning panel)
func q_charge() -> float:
	return tune["special"]["charge"] / 1000.0

# seconds after a special (or a strong lasso) before the next can go (tune["special"]["cooldown"], in ms)
func special_cd_max() -> float:
	return tune["special"]["cooldown"] / 1000.0

# the focus the Q move charging now will cost: the weapon's special, or the strong lasso
func q_cost() -> int:
	return focus_val(ARENA_WEAPONS[weapon]["special"]) if ARENA_WEAPONS[weapon].has("special") else focus_val("strong")

# ---------------------------------------------------------------- dodge
func _start_dodge() -> void:
	var v := Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_up", "move_down"))
	var d := v.normalized() if v != Vector2.ZERO else -facing()
	_cancel_swing()
	_cancel_draw()
	player.dodge_dir = d
	player.dodge_speed = DODGE["speed"]
	player.dodging = true
	player.dodge_p = 0.0
	player.inv_t = maxf(player.inv_t, DODGE["invuln"])
	dodge_t = DODGE["dur"]
	dodge_cd = DODGE["cooldown"] + DODGE["dur"]

# ---------------------------------------------------------------- light and heavy strings (Stage 8b)
# a press of key ("L" / "H"): the move it makes (_next_chain), if there is stamina for it (each move has its own cost)
func _try_swing(key: String) -> void:
	if key == "Q":                  # a buffered finisher (Stage 8f)
		_try_finisher()
		return
	if key == "H" and ARENA_WEAPONS[weapon].has("hold"):
		_start_draw()
		return
	var c := _next_chain(key)
	if c == "":
		return
	var m := _move_of(c)
	if _spend(stamina_cost(m)):
		chain = c
		_start_swing(m)

# start move m (its place in the string is the chain's length; a held move, the bow's aimed arrow, has no chain and counts as first).
# over: a finisher's changes to the move's row (Stage 8f), kept in _cur for the length of the move.
func _start_swing(m: String, over := {}) -> void:
	move = m
	_cur = _moves()[m].duplicate()
	_cur.merge(over, true)
	swing_n = maxi(chain.length() - 1, 0)
	swing_t = 0.0
	buffered = ""
	fired = false
	_seg = -1
	if _row().get("special", false) and chain == "":        # (a finisher is named by its string instead)
		text(player.position + Vector2(0, -36), _row()["name"], Color("#ffb060"), 0.9, 120.0)
	if swing_n == 0:
		named = false
		string_id += 1
		landed = 0
	hit_set.clear()
	hit_props.clear()
	player.swing_n = swing_n
	player.pose = _row()["pose"]
	player.pose_hits = _row().get("hits", 1)
	player.swing_p = 0.0
	if not _row().get("shot", false):         # an archer stands to shoot
		player.impulse = facing() * (SWING_STEP + _row().get("dash", 0.0))
		if chain != "" and _is_last():
			_name_string()                     # (a bow's last shot is named when it leaves: _fire)

func _cancel_swing() -> void:
	swing_n = -1
	player.swing_n = -1
	buffered = ""
	chain_t = 0.0
	chain = ""

func _update_swing(dt: float) -> void:
	var cfg := _row()
	swing_t += dt
	var p: float = swing_t / cfg["dur"]
	player.swing_p = minf(p, 1.0)
	if cfg.get("shot", false):
		if p >= cfg["hit_from"] and not fired:
			fired = true
			_fire(cfg)
	elif cfg.has("hits"):                     # several thrusts in one move (the flurry): each steps forward and hits afresh
		var n: int = cfg["hits"]
		var seg := mini(int(p * n), n - 1)
		if seg != _seg:
			_seg = seg
			hit_set.clear()
			hit_props.clear()
			player.impulse = facing() * cfg.get("step", SWING_STEP)
		var q := p * n - seg
		if q >= cfg["hit_from"] and q <= cfg["hit_to"]:
			_resolve_hits(cfg)
	elif p >= cfg["hit_from"] and p <= cfg["hit_to"]:
		_resolve_hits(cfg)
	if p >= 1.0:
		swing_n = -1
		player.swing_n = -1
		if chain == "":                       # a move outside the strings (the aimed arrow, a special): its own short pause
			atk_pause = cfg.get("after", BOW["loose_pause"])
			pause_max = atk_pause
		elif _is_last():
			atk_pause = _string()["pause"]
			pause_max = atk_pause
			chain = ""
			chain_t = 0.0
			buffered = ""
		else:
			chain_t = CHAIN_WINDOW
			if buffered != "":
				var b := buffered
				buffered = ""
				_try_swing(b)

# ---------------------------------------------------------------- finishers (Stage 8f)
# does a Q now end the string so far as a finisher? (a Q string of the weapon is the chain so far plus Q)
func _q_fits() -> bool:
	return chain != "" and ARENA_WEAPONS[weapon]["strings"].has(chain + "Q")

# Q in the chain window (or buffered from the swing before): the weapon's special as the string's finisher, its row changed by the
# string's "fin" and its damage by FINISHER.mul, for the finisher's focus and the special's cooldown. With the fists: the strong lasso,
# thrown at once (its reach x "fin" "reach").
func _try_finisher() -> void:
	if not _q_fits():
		return
	if special_cd > 0.0:
		text(player.position + Vector2(0, -36), "Ready in %.1f s" % special_cd, Color("#8cc8ff"), 0.8, 100.0)
		return
	var cost := focus_val("finisher")
	if player.focus < cost:
		focus_flash = 0.6
		text(player.position + Vector2(0, -36), "Needs %d focus" % cost, Color("#8cc8ff"), 0.8, 100.0)
		return
	var row: Dictionary = ARENA_WEAPONS[weapon]["strings"][chain + "Q"]
	var fin: Dictionary = row["fin"].duplicate()
	player.focus -= cost
	special_cd = special_cd_max()
	chain += "Q"
	chain_t = 0.0
	if ARENA_WEAPONS[weapon].has("special"):
		fin["mul"] = FINISHER["mul"]
		_start_swing(ARENA_WEAPONS[weapon]["special"], fin)
	else:
		_name_string()
		chain = ""
		_throw_lasso(true, fin.get("reach", 1.0))

# ---------------------------------------------------------------- specials (Stage 8d)
# Q tapped with a weapon that has a special: it starts if its cooldown has run out and there is the focus for it (spent at once,
# and the cooldown starts); otherwise the hero says why (and the focus bar flashes for want of focus)
func _try_special() -> void:
	var m: String = ARENA_WEAPONS[weapon]["special"]
	if special_cd > 0.0:
		text(player.position + Vector2(0, -36), "Ready in %.1f s" % special_cd, Color("#8cc8ff"), 0.8, 100.0)
		return
	if player.focus < focus_val(m):
		focus_flash = 0.6
		text(player.position + Vector2(0, -36), "Needs %d focus" % focus_val(m), Color("#8cc8ff"), 0.8, 100.0)
		return
	player.focus -= focus_val(m)
	special_cd = special_cd_max()
	chain = ""
	chain_t = 0.0
	_start_swing(m)

# a burning thrust landed on r: it burns for `ticks` ticks from now (BURN.ticks, or a finisher's "burn_ticks"; a new burn starts the
# count again)
func _burn(r, ticks := -1) -> void:
	burning[r] = {"ticks": ticks if ticks > 0 else BURN["ticks"], "t": BURN["every"]}

# each tick takes BURN.dmg from a burning foe (logged as "burn", an orange number); it can finish one off
func _update_burns(dt: float) -> void:
	for r in burning.keys():
		if not is_instance_valid(r) or not r.alive:
			burning.erase(r)
			continue
		var b: Dictionary = burning[r]
		b["t"] -= dt
		if b["t"] > 0.0:
			continue
		b["t"] += BURN["every"]
		b["ticks"] -= 1
		_log_hit(BURN["dmg"], r.kind, body_point(r), "burn", Color("#ff9a3a"))
		r.hit(BURN["dmg"], Vector2.ZERO, 0.0, false)
		if b["ticks"] <= 0:
			burning.erase(r)

# ---------------------------------------------------------------- the bow (Stage 8c)
# H with the bow: start drawing (any stamina at all is enough, as for a swing). He walks slowly while drawing (arena_player.gd
# DRAW_WALK), walking turns the aim, and a dotted reticle shows it (RETICLE).
func _start_draw() -> void:
	if player.stamina <= 0:
		tired_t = 0.6
		return
	chain = ""
	chain_t = 0.0
	draw_t = 0.0
	_drain_frac = 0.0
	player.aiming = true
	player.bow_draw = 0.0

# while drawing: stamina drains (the held move's "stamina" a second); H let go, or no stamina left, looses the arrow
func _update_draw(dt: float, can_act: bool) -> void:
	if not can_act or player.dodging:
		_cancel_draw()
		return
	draw_t += dt
	player.bow_draw = draw_frac()
	stamina_t = 0.0
	_drain_frac += stamina_cost(ARENA_WEAPONS[weapon]["hold"]) * dt
	var take := int(_drain_frac)
	_drain_frac -= take
	player.stamina = maxi(0, player.stamina - take)
	if not Input.is_action_pressed("heavy") or player.stamina <= 0:
		_loose()

# 0..1: how far the bow is drawn now
func draw_frac() -> float:
	return clampf(draw_t / BOW["full"], 0.0, 1.0) if draw_t >= 0.0 else 0.0

func _loose() -> void:
	draw_k = draw_frac()
	_cancel_draw()
	_start_swing(ARENA_WEAPONS[weapon]["hold"])

func _cancel_draw() -> void:
	if draw_t < 0.0:
		return
	draw_t = -1.0
	player.aiming = false
	player.bow_draw = -1.0

# a bow move's arrows leave the hand along the aim (a volley fanned out). The held arrow's damage and speed follow how far it was
# drawn, and only one drawn at least half way staggers. A move that must be earned (the volley) falls back to a plain arrow when the
# string's earlier arrows didn't hit enough or the focus is short, and says why.
func _fire(cfg: Dictionary) -> void:
	var mv := move
	if cfg.has("earn"):
		var why := ""
		if landed < cfg["earn"]:
			why = "No volley: %d of %d hit" % [landed, cfg["earn"]]
		elif player.focus < focus_val(move):
			why = "No volley: focus"
			focus_flash = 0.6
		if why != "":
			text(player.position + Vector2(0, -36), why, Color("#d8d0b8"), 0.9, 120.0)
			mv = cfg["fallback"]
			cfg = _moves()[mv]
		else:
			player.focus -= focus_val(move)
			_name_string()
	elif chain != "" and _is_last():
		_name_string()
	var dmg := roundi(hit_dmg(mv) * cfg.get("mul", 1.0))      # (a finisher hits harder: FINISHER.mul)
	var speed: float = cfg["speed"]
	var stagger: bool = cfg["stagger"]
	if mv == ARENA_WEAPONS[weapon].get("hold", ""):
		dmg = roundi(lerpf(dmg * BOW["min"], dmg, draw_k))
		speed = lerpf(BOW["min_speed"], speed, draw_k)
		stagger = stagger and draw_k >= 0.5
	var n: int = cfg.get("arrows", 1)
	var from := hand()
	for i in range(n):
		shoot(from, from + facing() * 100.0, "ally", "arrow", dmg, speed, null, (i - (n - 1) / 2.0) * cfg.get("spread", 0.0))
		# the hero's own arrow: it logs its hits and feeds focus (_update_shots), with its own push and stagger, and its string's id
		shots[-1]["hero"] = mv
		shots[-1]["kb"] = cfg["kb"]
		shots[-1]["stagger"] = stagger
		shots[-1]["sid"] = string_id
		# the bow's special (Stage 8d): it goes through foes, hitting each once ("hit"), and its hits don't feed focus
		if cfg.get("special", false):
			shots[-1]["special"] = true
			shots[-1]["pierce"] = cfg.get("pierce", false)
			shots[-1]["hit"] = []
	player.shake(cfg["shake"], 0.08)

# the last move of a string has started (or the bow's last arrow has left): its letters and name float up over the hero, once
func _name_string() -> void:
	if named or not _is_last():
		return
	named = true
	text(player.position + Vector2(0, -36), "%s  %s" % [chain, _string()["name"]], Color("#ffe9a0"), 0.9, 140.0)

# is something at rel (from the hero's feet) inside the move's hit area? A box in front along the aim, or with "radius" (the spear's
# whirl) a circle all round him
func _in_area(cfg: Dictionary, rel: Vector2) -> bool:
	if cfg.has("radius"):
		return rel.length() < cfg["radius"]
	var f := facing()
	var along := rel.dot(f)
	return along > -4.0 and along < cfg.get("reach", REACH_FRONT) and absf(rel.dot(f.orthogonal())) < cfg.get("side", REACH_SIDE)

func _resolve_hits(cfg: Dictionary) -> void:
	var f := facing()
	var special: bool = cfg.get("special", false)
	for r in rats:
		if not r.alive or hit_set.has(r):
			continue
		var rel: Vector2 = r.position - player.position
		if _in_area(cfg, rel):
			hit_set.append(r)
			var d := roundi(hit_dmg(move) * cfg.get("mul", 1.0))      # (a finisher hits harder: FINISHER.mul)
			var push: Vector2 = rel.normalized() if cfg.has("radius") and rel.length() > 0.5 else f    # a whirl pushes outward
			_log_hit(d, r.kind, body_point(r))      # (before hit(): a killing blow's number goes up from where it stood)
			r.hit(d, push, cfg["kb"])
			# the rising cut: a light foe it staggered is stunned instead (rat.gd's own stun, as after the lasso's pull)
			if cfg.get("stun", false) and r.alive and not r.heavy and not (r.kind in BOSSES) and r.state == "stagger":
				r._enter("stun")
			if cfg.get("burn", false) and r.alive:
				_burn(r, cfg.get("burn_ticks", BURN["ticks"]))
			if not special:     # (a special's own hits don't pay for the next one)
				_gain_focus(_is_last() and hit_set.size() == 1)     # the last swing of a string is only ever reached through all of it
			_weapon_xp(weapon, WEAPON_XP.get(move, 0))
			player.shake(cfg["shake"], 0.12)
	for i in range(world.hittables.size()):
		var h: Dictionary = world.hittables[i]
		if hit_props.has(i):
			continue
		var rel: Vector2 = h["pos"] - player.position
		if _in_area(cfg, rel):
			hit_props.append(i)
			_log_hit(roundi(hit_dmg(move) * cfg.get("mul", 1.0)), "dummy", h["pos"] + Vector2(0, -26))     # the dummy takes none, but its DPS is the weapon's own
			h["t"] = 0.0
			h["dir"] = 1.0 if f.x >= 0.0 else -1.0      # tips away from the hero
			spark(h["pos"] + Vector2(0, -20), f, 5, Color("#e8dcc0"))
			player.shake(cfg["shake"] * DUMMY["shake"], 0.1)

# ---------------------------------------------------------------- lasso
# Q let go: the strong lasso if Q was held long enough and there is the focus for it (without the focus: the ordinary throw, and the
# focus bar flashes); the ordinary throw costs stamina.
func _release_lasso() -> void:
	var strong: bool = lasso_charge >= q_charge()
	lasso_charge = -1.0
	player.aiming = false
	if strong and special_cd > 0.0:          # (Stage 8d: the strong lasso shares the specials' cooldown)
		strong = false
		text(player.position + Vector2(0, -36), "Strong lasso in %.1f s" % special_cd, Color("#8cc8ff"), 0.8, 120.0)
	if strong and player.focus < focus_val("strong"):
		strong = false
		focus_flash = 0.6
	if strong:
		player.focus -= focus_val("strong")
		special_cd = special_cd_max()
	elif not _spend(stamina_cost("lasso")):
		return
	_throw_lasso(strong)

func _cancel_charge() -> void:
	lasso_charge = -1.0
	player.aiming = false

# the strong lasso on a heavy foe (Stage 8d, the user's rule for the fists' special): pulled to the hero and stunned for longer, as a
# light one is by the strong lasso. rat.gd's pull() refuses heavy foes, so the arena does what it does itself (rat.gd unchanged);
# the bandits' and slingers' tables have the pull numbers. Bosses still shrug it off. False for anything that isn't a heavy non-boss.
func _pull_heavy(r) -> bool:
	if not r.heavy or not r.alive or r.kind in BOSSES:
		return false
	r.wake()
	r.stun_extra = r.R["stun_time"]
	r._enter("pulled")
	return true

# reach_mul: a finisher's longer throw (Stage 8f, the fists' HHQ)
func _throw_lasso(strong := false, reach_mul := 1.0) -> void:
	var f := facing()
	var best = null
	var best_along := 9999.0
	var reach: float = lasso_range() * (LASSO["strong_range"] if strong else 1.0) * reach_mul
	lasso_strong = strong
	for r in rats:
		if not r.alive:
			continue
		var rel: Vector2 = r.position - player.position
		var along := rel.dot(f)
		if along < 6.0 or along > reach:
			continue
		if absf(rel.dot(f.orthogonal())) > LASSO["width"] + along * LASSO["widen"]:
			continue
		if not world.los(player.position, r.position):
			continue
		if along < best_along:
			best_along = along
			best = r
	lasso_target = best
	lasso_reach = (best.position + Vector2(0, -4) - hand()).length() if best != null else reach
	lasso_len = 0.0
	lasso_phase = 1
	player.lock = true
	player.swing_n = -1
	lasso_cd_max = lasso_cool("cool_miss")
	lasso_cd = lasso_cd_max

func _update_lasso(dt: float) -> void:
	if lasso_phase == 0:
		return
	match lasso_phase:
		1:
			lasso_len += LASSO["tip_speed"] * dt
			if lasso_len >= lasso_reach:
				lasso_len = lasso_reach
				if lasso_target != null and is_instance_valid(lasso_target) and lasso_target.alive:
					if lasso_strong and _pull_heavy(lasso_target):     # the arena (8d): a heavy foe is pulled too
						lasso_phase = 2
						lasso_cd_max = lasso_cool("cool_hit")
						lasso_cd = lasso_cd_max
						spark(body_point(lasso_target), Vector2.ZERO, 6, Color("#f0d28a"))
						text(lasso_target.position + Vector2(0, -40), "Pulled!", Color("#ffe9a0"), 1.0)
						_weapon_xp("lasso", WEAPON_XP["strong"])
					elif lasso_target.pull(lasso_strong):
						lasso_phase = 2
						lasso_cd_max = lasso_cool("cool_hit")
						lasso_cd = lasso_cd_max
						spark(lasso_target.position + Vector2(0, -4), Vector2.ZERO, 4, Color("#d9b46a"))
						_weapon_xp("lasso", WEAPON_XP["strong" if lasso_strong else "catch"])
					else:
						text(lasso_target.position + Vector2(0, -20), "Too heavy!", Color("#ffe9a0"), 1.0)
						lasso_phase = 3
				else:
					lasso_phase = 3
		2:
			if lasso_target == null or not is_instance_valid(lasso_target) or not lasso_target.alive \
					or lasso_target.state != "pulled":
				if lasso_target != null and is_instance_valid(lasso_target):
					lasso_len = (lasso_target.position + Vector2(0, -4) - hand()).length()
				lasso_phase = 3
		3:
			lasso_len -= LASSO["tip_speed"] * 1.4 * dt
			if lasso_len <= 0.0:
				lasso_phase = 0
				lasso_target = null
				player.lock = false

func lasso_tip() -> Vector2:
	if lasso_phase == 2 and lasso_target != null and is_instance_valid(lasso_target):
		return lasso_target.position + Vector2(0, -4)
	var h := hand()
	if lasso_target != null and is_instance_valid(lasso_target) and lasso_phase == 1:
		return h + (lasso_target.position + Vector2(0, -4) - h).normalized() * lasso_len
	return h + facing() * lasso_len

func lasso_ready_frac() -> float:
	return 1.0 if lasso_cd <= 0.0 else 1.0 - lasso_cd / lasso_cd_max

func dodge_ready_frac() -> float:
	return 1.0 if dodge_cd <= 0.0 else 1.0 - dodge_cd / (DODGE["cooldown"] + DODGE["dur"])

# ---------------------------------------------------------------- damage
func hurt_player(dmg: int, from_pos: Vector2) -> bool:
	if player.inv_t > 0.0 or player.dead:
		return false
	if blocking and _in_front(from_pos) and _piercing(from_pos):
		text(player.position + Vector2(0, -32), "Pierced!", PIERCE_COL.lightened(0.3), 0.9)
	elif blocking and _in_front(from_pos) and parry_t > 0.0:
		return _parried(from_pos)
	elif blocking and _in_front(from_pos):
		if player.stamina > 0:
			return _blocked(dmg, from_pos)
		# no stamina behind the guard: it breaks, and the hit comes through in full
		blocking = false
		player.blocking = false
		guard_broken = BLOCK["broken"]
		text(player.position + Vector2(0, -32), "Guard broken!", Color("#ff8a6a"), 0.9)
	player.hp = maxi(1 if god else 0, player.hp - dmg)
	player.inv_t = HERO_INVULN
	player.hurt_t = 0.35
	player.impulse = (player.position - from_pos).normalized() * 130.0
	hurt_flash = 0.3
	player.shake(3.0, 0.22)
	spark(player.position + Vector2(0, -10), (player.position - from_pos).normalized(), 8, Color("#e03a3a"))
	_cancel_swing()
	_cancel_draw()
	_cancel_charge()
	if lasso_phase == 1 or lasso_phase == 2:
		lasso_phase = 3
	_check_fall()
	return true

func _check_fall() -> void:
	if player.hp <= 0:
		player.dead = true
		player.lock = false
		player.dodging = false
		dodge_t = 0.0
		over_t = 0.0
		lasso_phase = 0

# ---------------------------------------------------------------- the block (Stage 8c)
# is from_pos within BLOCK.arc of the aim? (a hit from the side or behind gets round the guard)
func _in_front(from_pos: Vector2) -> bool:
	var to: Vector2 = from_pos - player.position
	return to.length() < 1.0 or absf(facing().angle_to(to)) <= BLOCK["arc"]

# Does the hit being judged now go through the block (PIERCE)? A stone says so itself (_pierce_shot). The giant's slam and the chief's
# charge come from the attacker's own position while it is in that state ("slam" / "charge"), which is how rat.gd's _land() and
# chief.gd's charge call hurt_player(); so they are found that way and neither script needs a change.
func _piercing(from_pos: Vector2) -> bool:
	if _pierce_shot:
		return true
	for r in rats:
		if not r.alive or r.position.distance_to(from_pos) > 1.0:
			continue
		if (r.kind == "giant" and r.state == "slam" and PIERCE["slam"]) or (r.kind == "chief" and r.state == "charge" and PIERCE["charge"]):
			return true
	return false

# a parry (Stage 8d): the hit is turned aside, no damage and no stamina; focus for the hero; the attacker, if the hit came from its
# body (a lunge, a sweep), staggers back unless it is a boss. Counts as landed (true), like a block.
func _parried(from_pos: Vector2) -> bool:
	parry_t = 0.0
	player.inv_t = PARRY["inv"]
	player.focus = mini(player.max_focus, player.focus + tune["parry"]["focus"])
	_blocked_frame = Engine.get_physics_frames()
	block_flash = 0.25
	player.shake(2.0, 0.12)
	var away: Vector2 = (from_pos - player.position).normalized()
	spark(player.position + Vector2(0, -10) + away * 10.0, away, 10, Color("#ffe08a"))
	text(player.position + Vector2(0, -32), "Parry!", Color("#ffe08a"), 0.9)
	for r in rats:
		if r.alive and r.position.distance_to(from_pos) <= 1.0 and not (r.kind in BOSSES):
			r.hit(0, away, PARRY["kb"])        # 0 damage, but it interrupts: a stagger
			break
	return true

# a hit caught on the guard: the weapon's cut of the damage comes through, the guard costs its stamina (spending down to 0, like a
# move), a short push and a moment's safety. It counts as landed (true): a stone stops on it, and the giant's slam counts as a hit.
func _blocked(dmg: int, from_pos: Vector2) -> bool:
	var g := guard()
	var through := roundi(dmg * g["cut"] / 100.0)
	player.hp = maxi(1 if god else 0, player.hp - through)
	player.stamina = maxi(0, player.stamina - g["stamina"])
	stamina_t = 0.0
	player.inv_t = BLOCK["inv"]
	var away: Vector2 = (player.position - from_pos).normalized()
	player.impulse = away * 130.0 * BLOCK["kb"]
	player.shake(1.5, 0.12)
	block_flash = 0.2
	_blocked_frame = Engine.get_physics_frames()
	spark(player.position + Vector2(0, -10) - away * 8.0, -away, 6, Color("#d8e8ff"))
	if view["numbers"] and through > 0:
		text(player.position + Vector2(0, -28), "-%d" % through, Color("#d8e8ff"), 0.7)
	_check_fall()
	return true

# (the arena: only the count; no XP, drops, quest or saved dead)
func rat_killed(r) -> void:
	kills += 1
	kills_by[r.kind] = kills_by.get(r.kind, 0) + 1
	spark(r.position + Vector2(0, -5), Vector2.UP, 10, Color("#fff2c0"))
	player.shake(2.0, 0.15)

# ---------------------------------------------------------------- the arena
# a fall: up again at full after GET_UP, cured, safe for a moment; the enemies stay as they are
func _get_up() -> void:
	player.dead = false
	player.refill()
	player.poison = 0
	player.inv_t = HERO_INVULN * 1.5
	over_t = -1.0
	text(player.position + Vector2(0, -32), "Up again", Color("#8cc8ff"), 1.0)

# every enemy on the field gone at once (key C, the panel's Spawn tab)
func clear_field() -> void:
	_cancel_charge()
	lasso_phase = 0
	lasso_target = null
	player.lock = false
	shots.clear()
	burning.clear()
	for r in rats.duplicate():
		r.queue_free()
	rats.clear()

# a hit that landed: the readouts (DPS, totals) and, when shown, its number floating up from `at`
func _log_hit(dmg: int, on: String, at: Vector2, mv := "", col := Color.TRANSPARENT) -> void:
	hits.append({"t": clock, "dmg": dmg, "move": mv if mv != "" else move, "on": on})
	while not hits.is_empty() and clock - hits[0]["t"] > 60.0:
		hits.pop_front()
	if first_t < 0.0:
		first_t = clock
	total_dmg += dmg
	total_hits += 1
	if view["numbers"]:
		if col == Color.TRANSPARENT:
			col = Color("#ffffff") if on != "dummy" else Color("#d8d0b8")
		text(at + Vector2(randf_range(-4.0, 4.0), -6.0), str(dmg), col, 0.7)

# damage landed per second over the last DPS_WINDOW s
func dps_recent() -> float:
	var sum := 0
	for h in hits:
		if clock - h["t"] <= DPS_WINDOW:
			sum += h["dmg"]
	return sum / DPS_WINDOW

# damage per second since the first hit after the last reset (0 until a second has passed)
func dps_total() -> float:
	if first_t < 0.0 or clock - first_t < 1.0:
		return 0.0
	return total_dmg / (clock - first_t)

func reset_readout() -> void:
	hits.clear()
	total_dmg = 0
	total_hits = 0
	first_t = -1.0

# the colour of a string letter on the timeline: light pale gold, heavy orange
const LETTER_COL := {"L": Color("#ffe9a0"), "H": Color("#ff9a4a"), "Q": Color("#c88cff")}

# under the hero (view.timeline): the swing on now (its length, the hit window in it, how far it has got), then the chain window
# running down after it (the next press continues the string), the pause after a string's last swing, and a dot in the pressed key's
# colour while the next swing is buffered. Under the bar, one pip a place in the weapon's longest string: the letters pressed so far.
func _draw_timeline(n) -> void:
	var w := 34.0
	var p: Vector2 = (player.position + Vector2(-w / 2.0, 6.0)).round()
	n.draw_rect(Rect2(p.x - 1, p.y - 1, w + 2, 5), Color(0, 0, 0, 0.6))
	if draw_t >= 0.0:            # the bow being drawn: how far, white once full
		var k := draw_frac()
		n.draw_rect(Rect2(p.x, p.y, roundf(w * k), 3), Color("#ffffff") if k >= 1.0 else LETTER_COL["H"])
	elif swing_n >= 0:
		var cfg := _row()
		n.draw_rect(Rect2(p.x + w * cfg["hit_from"], p.y, w * (cfg["hit_to"] - cfg["hit_from"]), 3), Color(0.9, 0.3, 0.25, 0.7))
		n.draw_rect(Rect2(p.x, p.y + 1, roundf(w * clampf(swing_t / cfg["dur"], 0.0, 1.0)), 1), Color("#ffffff"))
		if buffered != "":
			n.draw_rect(Rect2(p.x + w + 3, p.y, 3, 3), LETTER_COL[buffered])
	elif chain_t > 0.0:
		n.draw_rect(Rect2(p.x, p.y, roundf(w * chain_t / CHAIN_WINDOW), 3), Color("#8cc8ff"))
	elif atk_pause > 0.0:
		n.draw_rect(Rect2(p.x, p.y, roundf(w * atk_pause / pause_max), 3), Color(0.6, 0.6, 0.6, 0.8))
	var size := 0
	for s in ARENA_WEAPONS[weapon]["strings"].keys():
		size = maxi(size, s.length())
	for i in range(size):
		n.draw_rect(Rect2(p.x + i * 5, p.y + 5, 3, 2), LETTER_COL[chain[i]] if i < chain.length() else Color(0.3, 0.3, 0.3, 0.8))

# the bow in hand: a short dotted line from the hand along the aim (RETICLE). Faint for the quick arrows, brighter while drawing,
# white once the draw is full.
func _draw_reticle(n) -> void:
	var f := facing()
	var from := hand()
	var col := Color(1.0, 0.92, 0.75, 0.35)
	if draw_t >= 0.0:
		col = Color("#ffffff") if draw_frac() >= 1.0 else Color(1.0, 0.92, 0.75, 0.7)
	for i in range(RETICLE["dots"]):
		var p: Vector2 = (from + f * (RETICLE["from"] + RETICLE["gap"] * i)).round()
		n.draw_rect(Rect2(p.x - 1, p.y - 1, 2, 2), col)

# the swing's hit box (view.boxes): where an enemy's feet must be for the swing on now to land (red while its hit window is open).
# Between swings: the box of the move a light press would start. A bow's move has no box: a faint line shows where it aims.
func _draw_hitbox(n) -> void:
	var cfg: Dictionary = _row() if swing_n >= 0 else _moves()[_move_of(_next_chain("L"))]
	var f := facing()
	if cfg.get("shot", false):
		var from := hand()
		n.draw_line(from + f * 10.0, from + f * 70.0, Color(1, 1, 1, 0.35), 1.0)
		return
	if cfg.has("radius"):            # the whirl: a circle all round him
		var on: bool = swing_n >= 0 and swing_t / cfg["dur"] >= cfg["hit_from"] and swing_t / cfg["dur"] <= cfg["hit_to"]
		n.draw_arc(player.position, cfg["radius"], 0.0, TAU, 32, Color(1, 0.3, 0.25, 0.9) if on else Color(1, 1, 1, 0.35), 1.0)
		return
	var reach: float = cfg.get("reach", REACH_FRONT)
	var s := f.orthogonal() * float(cfg.get("side", REACH_SIDE))
	var a: Vector2 = player.position - f * 4.0
	var b: Vector2 = player.position + f * reach
	var pts := PackedVector2Array([a + s, b + s, b - s, a - s, a + s])
	var live: bool = swing_n >= 0 and swing_t / cfg["dur"] >= cfg["hit_from"] and swing_t / cfg["dur"] <= cfg["hit_to"]
	n.draw_polyline(pts, Color(1, 0.3, 0.25, 0.9) if live else Color(1, 1, 1, 0.35), 1.0)

# flames licking up from every burning foe (BURN)
func _draw_burns(n) -> void:
	var ms := Time.get_ticks_msec()
	for r in burning.keys():
		if not is_instance_valid(r) or not r.alive:
			continue
		var at: Vector2 = body_point(r)
		for i in range(3):
			var ph := float((ms / 70 + i * 5) % 12) / 12.0       # each flame rises and fades in turn
			var p := at + Vector2((i - 1) * 4.0, 4.0 - 10.0 * ph)
			n.draw_rect(Rect2(roundf(p.x) - 1, roundf(p.y) - 1, 3, 3), Color(1.0, 0.55 + 0.4 * (1.0 - ph), 0.15, 0.9 * (1.0 - ph)))

# the guard in front of the hero: a pale arc over the part of the circle it covers (BLOCK.arc either side of the aim), bright for a
# moment when it takes a hit; gold while a parry would land (parry_t); a red, broken arc while the guard is broken
func _draw_guard(n) -> void:
	var c: Vector2 = player.position + Vector2(0, -9)
	var a := facing().angle()
	if guard_broken > 0.0:
		var k := guard_broken / BLOCK["broken"]
		for s in [-1.0, 1.0]:
			n.draw_arc(c, 15.0, a + s * 0.25, a + s * BLOCK["arc"], 6, Color(1, 0.4, 0.3, 0.7 * k), 1.5)
	elif blocking and parry_t > 0.0:
		n.draw_arc(c, 15.0, a - BLOCK["arc"], a + BLOCK["arc"], 14, Color("#ffe08a"), 2.5)
	elif blocking:
		var lit := block_flash > 0.0
		n.draw_arc(c, 15.0, a - BLOCK["arc"], a + BLOCK["arc"], 14, Color(0.85, 0.92, 1.0, 0.9 if lit else 0.45), 2.5 if lit else 1.5)

# The warnings of the attacks that pierce the block (PIERCE), drawn again over the game's red ones in PIERCE_COL: a ring round the
# giant's landing spot, the chief's charge line, a slinger's aim line. (rat.gd, chief.gd and slinger.gd draw theirs in red; the arena
# adds its colour on top rather than changing them.)
func _draw_pierce_warnings(n) -> void:
	var pulse := 0.6 + 0.4 * sin(Time.get_ticks_msec() / 90.0)
	for r in rats:
		if not r.alive:
			continue
		if r.kind == "giant" and PIERCE["slam"] and (r.state == "jump_wind" or r.state == "jump"):
			var at: Vector2 = r.slam_target if r.state == "jump_wind" else r.jump_to
			var rad: float = r.R["slam_radius"]
			n.draw_arc(at, rad + 2.0, 0.0, TAU, 36, Color(PIERCE_COL, pulse), 2.0)
			n.draw_arc(at, rad - 3.0, 0.0, TAU, 36, Color(PIERCE_COL, 0.5 * pulse), 1.0)
		elif r.kind == "chief" and PIERCE["charge"] and r.state == "charge_wind":
			var from: Vector2 = r.position + Vector2(0, -2)
			var to: Vector2 = r._charge_end() + Vector2(0, -2)
			var side: Vector2 = (to - from).normalized().orthogonal() * 7.0
			n.draw_line(from + side, to + side, Color(PIERCE_COL, pulse), 1.0)
			n.draw_line(from - side, to - side, Color(PIERCE_COL, pulse), 1.0)
		elif r.kind == "slinger" and PIERCE["stone"] and r.state == "spin" and r.foe != null:
			var hand_at: Vector2 = r._hand()
			var aim_to: Vector2 = r.foe.position + Vector2(0, -10)
			var len := minf(hand_at.distance_to(aim_to), 120.0)
			n.draw_line(hand_at, hand_at + (aim_to - hand_at).normalized() * len, Color(PIERCE_COL, 0.4 + 0.4 * pulse), 1.0)

# ---------------------------------------------------------------- poison (the scorpion's sting)
# a sting that landed on b (the hero or a companion): poisoned for POISON.ticks ticks from now (a new sting starts the count again)
func poison_body(b) -> void:
	if b == player and _blocked_frame == Engine.get_physics_frames():
		return          # (the arena's block: the sting was caught on the guard)
	b.poison = POISON["ticks"]
	b.poison_t = POISON["every"]
	text(b.position + Vector2(0, -32), "Poisoned!", Color("#d8a8ff"), 1.0)

# each tick takes POISON.dmg HP from the hero or a companion with him, never the last one; a companion who falls is cured
func _update_poison(dt: float) -> void:
	for b in [player] + mates():
		if b.poison <= 0:
			continue
		if b.get("down") == true:
			b.poison = 0
			continue
		b.poison_t -= dt
		if b.poison_t > 0.0:
			continue
		b.poison_t += POISON["every"]
		b.poison -= 1
		var lost := mini(POISON["dmg"], b.hp - 1)
		if lost > 0:
			b.hp -= lost
			text(b.position + Vector2(0, -26), "-%d" % lost, Color("#d8a8ff"), 0.8)

# ---------------------------------------------------------------- effects
func spark(pos: Vector2, dirv: Vector2, n: int, col: Color) -> void:
	for i in range(n):
		var v := (dirv if dirv != Vector2.ZERO else Vector2.RIGHT.rotated(randf() * TAU)).rotated(randf_range(-0.9, 0.9)) \
			* randf_range(40.0, 110.0)
		sparks.append({"p": pos, "v": v, "life": randf_range(0.18, 0.38), "col": col})

# a word floating up from pos; w = the width it is centred in (a combo's name needs more than a number)
func text(pos: Vector2, s: String, col: Color, life: float, w := 60.0) -> void:
	texts.append({"p": pos, "s": s, "life": life, "max": life, "col": col, "w": w})

# ---------------------------------------------------------------- arrows and stones
# fire from `from` toward `at`. side "ally" hits enemies (the rider's arrows), "enemy" hits the hero or a companion (slingers' stones,
# 6c). by = who shot it (a companion: an arrow of his that lands feeds his focus, rider.gd arrow_landed). spread = radians off the line.
func shoot(from: Vector2, at: Vector2, side: String, kind: String, dmg: int, speed: float, by = null, spread := 0.0) -> void:
	var d := at - from
	if d.length() < 1.0:
		return
	shots.append({"p": from, "v": d.normalized().rotated(spread) * speed, "dmg": dmg, "side": side, "kind": kind, "life": SHOT_LIFE,
		"by": by})

# where a body is hit (and aimed at): the middle of the drawn figure, not its feet
func body_point(r) -> Vector2:
	match r.kind:
		"bandit", "slinger": return r.position + Vector2(0, -14)
		"chief": return r.position + Vector2(0, -18)
		"giant": return r.position + Vector2(0, -12)
	return r.position + Vector2(0, -4)

# one of the hero's arrows hit something: if it belongs to the string on now, it counts toward the volley (BOW_MOVES "earn")
func _arrow_landed(s: Dictionary) -> void:
	if s.get("sid", -1) == string_id:
		landed += 1

func _update_shots(dt: float) -> void:
	for s in shots:
		var steps := int(ceil(s["v"].length() * dt / 4.0))      # 4 px steps, so nothing flies through a thin wall or a rat
		for i in range(steps):
			s["p"] += s["v"] * dt / steps
			if world.sight_blocked(s["p"]):
				spark(s["p"], -s["v"].normalized(), 3, Color("#c8b89a"))
				s["life"] = 0.0
				break
			if s["side"] == "ally":
				var pierce: bool = s.get("pierce", false)      # the bow's special goes on through, hitting each thing once ("hit")
				for r in rats:
					if r.alive and body_point(r).distance_to(s["p"]) < SHOT_HIT.get(r.kind, 8.0):
						if pierce:
							if s["hit"].has(r):
								continue
							s["hit"].append(r)
						if s.has("hero"):      # the hero's own arrow (Stage 8c): logged and feeding focus like a swing
							_log_hit(s["dmg"], r.kind, body_point(r), s["hero"])
							if not s.get("special", false):
								_gain_focus()
							_arrow_landed(s)
						r.hit(s["dmg"], s["v"].normalized(), s.get("kb", RIDER["kb"]), s.get("stagger", false))
						if not pierce:
							s["life"] = 0.0
						if s["by"] != null and is_instance_valid(s["by"]):
							s["by"].arrow_landed()
						break
				if s["life"] > 0.0 and s.has("hero"):      # the hero's arrows rock the dummy too, so the bow's DPS can be measured
					for h in world.hittables:
						if (h["pos"] + Vector2(0, -14)).distance_to(s["p"]) < 9.0 and not (pierce and s["hit"].has(h)):
							_log_hit(s["dmg"], "dummy", h["pos"] + Vector2(0, -26), s["hero"])
							_arrow_landed(s)
							h["t"] = 0.0
							h["dir"] = 1.0 if s["v"].x >= 0.0 else -1.0
							spark(s["p"], -s["v"].normalized(), 4, Color("#e8dcc0"))
							if pierce:
								s["hit"].append(h)
							else:
								s["life"] = 0.0
							break
			else:
				for b in targets():      # the hero, or a companion standing in the way
					if (b.position + Vector2(0, -10)).distance_to(s["p"]) < SHOT_HIT["hero"]:
						_pierce_shot = s["kind"] == "stone" and PIERCE["stone"]      # (the arena's block: a stone goes through it)
						var landed_on: bool = hurt_body(b, s["dmg"], s["p"] - s["v"].normalized() * 10.0)
						_pierce_shot = false
						if landed_on:
							s["life"] = 0.0      # while invulnerable (a dodge, or just hurt) it flies past
						break
			if s["life"] <= 0.0:
				break
		s["life"] -= dt
	shots = shots.filter(func(s): return s["life"] > 0.0)

func _process(dt: float) -> void:
	for s in sparks:
		s["p"] += s["v"] * dt
		s["v"] = s["v"] * (1.0 - 5.0 * dt)
		s["life"] -= dt
	sparks = sparks.filter(func(s): return s["life"] > 0.0)
	for t in texts:
		t["p"] += Vector2(0, -14.0 * dt)
		t["life"] -= dt
	texts = texts.filter(func(t): return t["life"] > 0.0)
	if world != null and not shots.is_empty():
		_update_shots(dt)
	if world != null:
		for h in world.hittables:      # the dummy rocks after a hit and settles
			h["t"] += dt
			var k: float = h["t"]
			h["lean"] = h["dir"] * DUMMY["lean"] * exp(-k * DUMMY["damp"]) * sin(k * DUMMY["freq"]) if k < DUMMY["time"] else 0.0

func _draw_fx(n) -> void:
	if lasso_phase != 0:
		var h := hand()
		var tip := lasso_tip()
		var mid := h.lerp(tip, 0.5) + Vector2(0, 2.0 * sin(Time.get_ticks_msec() / 60.0))
		n.draw_polyline(PackedVector2Array([h, mid, tip]), Color("#f0d28a") if lasso_strong else Color("#d9b46a"), 2.0 if lasso_strong else 1.5)
		n.draw_arc(tip, 4.5 if lasso_strong else 3.5, 0.0, TAU, 10, Color("#fff0b0") if lasso_strong else Color("#f0d28a"), 1.3)
	if lasso_charge >= 0.0:     # charging Q (the strong lasso, or a special): a ring closes round the hero, and glows once it is ready
		var k := lasso_charge_frac()
		var c: Vector2 = player.position + Vector2(0, -8)
		var ready: bool = k >= 1.0 and player.focus >= q_cost() and special_cd <= 0.0
		n.draw_arc(c, 14.0, -PI / 2.0, -PI / 2.0 + TAU * k, 20, Color("#8cc8ff") if ready else Color(0.85, 0.75, 0.5, 0.8), 1.5)
		if ready:
			n.draw_arc(c, 16.0 + sin(Time.get_ticks_msec() / 80.0), 0.0, TAU, 20, Color(0.55, 0.78, 1.0, 0.5), 1.0)
	for r in rats:      # warnings on the ground: the chief's charge line and sweep arc, a slinger's aim
		if r.alive and r.has_method("draw_telegraph"):
			r.draw_telegraph(n)
	_draw_pierce_warnings(n)
	_draw_burns(n)
	if not player.dead:
		_draw_guard(n)
		if weapon == "bow":
			_draw_reticle(n)
		if view["boxes"]:
			_draw_hitbox(n)
		if view["timeline"]:
			_draw_timeline(n)
	for s in shots:
		var p: Vector2 = s["p"].round()
		if s.get("special", false):     # the piercing arrow: longer, heavier, with a pale trail
			var d2: Vector2 = s["v"].normalized()
			n.draw_line(p - d2 * 22.0, p - d2 * 11.0, Color(1, 0.95, 0.8, 0.45), 1.0)
			n.draw_line(p - d2 * 11.0, p, Color("#2a2a30"), 3.0)
			n.draw_line(p - d2 * 11.0, p, Color("#e0d4b0"), 1.5)
			n.draw_rect(Rect2(p.x - 2, p.y - 2, 4, 4), Color("#e0e6ea"))
			n.draw_line(p - d2 * 11.0, p - d2 * 8.0, Color("#a8372b"), 3.0)
		elif s["kind"] == "arrow":     # shaft, bronze head, red fletching
			var d: Vector2 = s["v"].normalized()
			n.draw_line(p - d * 7.0, p, Color("#e0d4b0"), 1.0)
			n.draw_rect(Rect2(p.x - 1, p.y - 1, 2, 2), Color("#c89a48"))
			n.draw_line(p - d * 7.0, p - d * 5.0, Color("#a8372b"), 2.0)
		else:                        # a stone: it pierces the block, so it glows in PIERCE_COL round its edge
			if PIERCE["stone"]:
				n.draw_rect(Rect2(p.x - 2, p.y - 2, 5, 5), Color(PIERCE_COL, 0.7))
			n.draw_rect(Rect2(p.x - 1, p.y - 1, 3, 3), Color("#3a2517"))
			n.draw_rect(Rect2(p.x - 1, p.y - 1, 2, 2), Color("#9a8a74"))
	for s in sparks:
		var a: float = clampf(s["life"] / 0.3, 0.0, 1.0)
		var c: Color = s["col"]
		n.draw_rect(Rect2(roundf(s["p"].x), roundf(s["p"].y), 2, 2), Color(c.r, c.g, c.b, a))
	var font := ThemeDB.fallback_font
	for t in texts:
		var a: float = clampf(t["life"] / (t["max"] * 0.5), 0.0, 1.0)
		var w: float = t["w"]
		var p := Vector2(roundf(t["p"].x - w / 2.0), roundf(t["p"].y))
		n.draw_string_outline(font, p, t["s"], HORIZONTAL_ALIGNMENT_CENTER, w, 8, 3, Color(0, 0, 0, a))
		var c: Color = t["col"]
		n.draw_string(font, p, t["s"], HORIZONTAL_ALIGNMENT_CENTER, w, 8, Color(c.r, c.g, c.b, a))
