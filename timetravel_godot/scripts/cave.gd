extends "res://scripts/level.gd"
# cave.gd - the band's hideout in the hills (1100 x 1500, portrait). You walk in through the cave mouth in the town's north-east cliff.
# The layout follows the user's reference picture, turned so the route runs south -> north (the hero comes from the south):
#   south       the mouth (daylight falling in) and the entrance hall (a broken cart, scrub, supplies)
#   tunnel      the band's lookouts (bandits), with a side alcove where they sleep
#   middle      the abandoned camp: the king's riders camped here when the band struck (torn tents sprayed with blood, a fire still
#               burning, pools of blood, drag marks and spatter, bloodied tables, arrows in the ground, broken spears, a torn tunic,
#               a dropped shield; no bodies). When you walk in between the tents, rats come at you from four sides: one out of each
#               tent, one up the tunnel behind you and one down the tunnel ahead (CAMP_TRIGGER, CAMP_RATS).
#   the fork    up-left: a winding tunnel to the jail room (a cage of lashed poles holding a captured royal rider, a jailer, four small
#               pens - two of them holding the dead, one a rider's last note that E reads (Stage 7j) - chain frames, a strap
#               bench, the jailer's tools, braziers of coals). E at the
#               cage door opens it; talk to the rider and he joins you (rider.gd) - and the band answers: a spiked barricade shuts
#               the tunnel, two bandits rush up it, two slingers follow and sling from range (WAVE, BARRICADE). When they are all
#               down the barricade lifts, and two more (WAIT) are waiting lower down on the way out.
#               up-right: the band's camp (red tent, a lit fire, stake palisades, four bandits), then a flight of wooden steps north
#   north-east  the boss room, the band's stronghold: the chief's seat in front of his hoard, his war table and its map, tents,
#               palisades, banners and fire bowls round the walls, loot strewn over the open floor (a strongbox and a stack of crates
#               are tall enough to stop his charge), an empty cage, and the riders the band staked along the north wall (dark
#               silhouettes) - the last of them, the riders' captain, still alive. The chief (chief.gd) sleeps on his seat until you
#               walk into the room; then a barricade shuts the steps behind you and three slingers (slinger.gd) burst out of the
#               tents (no saving until it is over, so a fall goes back to a save from before). When he falls the seal lifts; E at
#               the captain cuts him down, he tells
#               what was done here, and the hero goes back to the king (hall.gd "king_return"), with the rider if he was freed; if
#               not, the rider stays behind in the cage. The captain goes with the hero: back in the cave, his stake is empty.
#
#   The floor is ROOMS (ellipses) + TUNNELS (polylines), both wobbled by noise so the walls look like rock, rasterised into a mask of
#   MASK_CELL px squares. terrain.gd paints the ground from the mask (dirt, stone rim, rock faces); every rock cell of the coarser
#   SOLID_CELL grid is solid. Props, torches, rugs, blood (pools, drag marks, spatter) and enemies are data further down.
# Light: a dark ambient colour plus torches, fires, the daylight at the mouth and a small lantern on the hero (helpers in level.gd).

const Props = preload("res://scripts/props.gd")
const CVP = preload("res://scripts/cave_props.gd")
const Rider = preload("res://scripts/rider.gd")
const NPC = preload("res://scripts/npc.gd")
const Terrain = preload("res://scripts/terrain.gd")

const MASK_CELL := 4       # floor mask cell (px)
const SOLID_CELL := 8      # collision cell (px): solid unless all of its mask cells are floor

# walkable rooms: [centre x, centre y, radius x, radius y]
const ROOMS := [
	[360, 1360, 125, 70],     # entrance hall
	[560, 1206, 42, 32],      # side alcove (the lookouts' bedding)
	[380, 1015, 190, 115],    # abandoned camp
	[400, 830, 80, 50],       # the fork
	[230, 262, 165, 108],     # jail room
	[680, 560, 210, 92],      # the band's camp
	[820, 252, 232, 134],     # boss room
]
# walkable tunnels: {"w": width, "pts": [[x, y]...] (a smooth curve through them), "wobble": how much the walls wander (share of w)}
const TUNNELS := [
	{"w": 74.0, "pts": [[360, 1500], [362, 1440], [360, 1400]]},                                              # the mouth
	{"w": 78.0, "pts": [[360, 1310], [384, 1250], [352, 1190], [372, 1120]]},                                 # entrance -> camp (lookouts)
	{"w": 52.0, "pts": [[376, 1218], [450, 1226], [528, 1208]]},                                              # side alcove
	{"w": 92.0, "pts": [[390, 920], [402, 840]]},                                                             # camp -> fork
	{"w": 64.0, "pts": [[372, 806], [306, 744], [256, 664], [284, 584], [236, 500], [212, 428], [222, 352]]},  # fork -> jail (winding)
	{"w": 76.0, "pts": [[438, 816], [516, 760], [576, 702], [612, 640]]},                                     # fork -> the band's camp
	{"w": 56.0, "pts": [[832, 500], [832, 372]], "wobble": 0.0},                                              # the steps up to the boss room
]
const WOBBLE_ROOM := 0.15
const WOBBLE_TUNNEL := 0.15
# worn tracks along the way people walk (painted only): [width, points...]
const PATHS := [
	[40.0, [[360, 1500], [362, 1380], [372, 1300], [384, 1250], [352, 1190], [372, 1120], [386, 1010], [400, 900], [402, 830]]],
	[34.0, [[402, 830], [306, 744], [256, 664], [284, 584], [236, 500], [212, 428], [226, 300]]],
	[38.0, [[402, 830], [516, 760], [612, 640], [700, 566], [832, 500]]],
	[40.0, [[832, 380], [826, 300], [820, 200]]],
]
# the wooden steps from the band's camp up into the boss room (the walkable gap is the last tunnel)
const STAIRS := Rect2(806, 392, 52, 88)
const STEP := {"count": 8, "tread": 6, "riser": 5}      # 8 x (6 + 5) px = the 88 px of STAIRS

# Blood on the ground (terrain.gd; traces, not bodies). Pools: [x, y, radius]
const STAINS := [
	# the camp: under both tent doors, round the fire, by the tables and the bedrolls
	[292, 964, 14], [466, 968, 12], [358, 998, 12], [414, 1036, 11], [262, 1018, 10], [252, 1064, 9], [428, 1084, 9], [538, 1010, 8],
	[258, 974, 7], [318, 1076, 7], [490, 1066, 7], [372, 1106, 6], [302, 1002, 6], [440, 1004, 6], [508, 1044, 5], [330, 1040, 5],
	[298, 1352, 4],                                                                                     # the entrance
	[232, 226, 6], [142, 226, 5], [318, 224, 4], [296, 266, 6], [338, 304, 4], [326, 340, 5], [104, 252, 4], [176, 300, 4],   # the jail
	[898, 178, 6], [930, 174, 6], [964, 192, 5], [820, 204, 4], [776, 262, 3], [870, 330, 3],          # the boss room
]
# blood dragged along the ground: [width at the start, [[x, y]...] (a smooth curve)]
const DRAGS := [
	[18.0, [[292, 964], [318, 992], [342, 1036], [356, 1080], [366, 1120]]],    # the camp: from the left tent past the fire, toward the tunnel
	[14.0, [[404, 1036], [424, 1064], [440, 1090], [452, 1110]]],                # from the fire past the spilled pot
	[11.0, [[262, 1018], [240, 1042], [228, 1068]]],
	[9.0, [[476, 968], [504, 970], [540, 964]]],                                 # east from the right tent
	[12.0, [[232, 226], [250, 262], [268, 300], [284, 332]]],                    # the jail: from the cage door across the room
	[8.0, [[142, 226], [128, 250], [110, 262]]],
	[12.0, [[930, 182], [950, 208], [970, 236], [988, 262]]],                    # the boss room: from the stakes
]
# droplets flung round: [x, y, radius, count]
const SPATTER := [
	[380, 990, 44, 70], [300, 1000, 30, 34], [456, 1000, 30, 34], [380, 1070, 40, 44], [240, 1040, 24, 20], [520, 1030, 24, 20],
	[290, 290, 30, 24], [160, 240, 22, 14],
	[914, 186, 30, 30], [960, 230, 24, 16],
]
# rugs painted on the ground (the boss room's tents and the bedding corner): [x, y, w, h]
const RUGS := [[622, 250, 36, 12], [646, 338, 36, 12], [986, 308, 36, 12], [920, 306, 44, 16]]

# props: [kind, x, y, extra...]  (y = foot). kinds: tent [w, torn, red], fire [lit], table [w, items, bloody], bedroll [colour],
# palisade [w], seat, hoard [w], war [w] (the war table), banner, bowl, gear, pot, stool, cart, agave, rack, barrel, crate, stack,
# sacks, pots, arrows, spear (broken), cloth, brand, captive [variant], pen [w, d, dead (-1 = empty, else the figure's variant)],
# cage [w, d] (empty, door open), frame (chains), bench (straps), mat (straw), strongbox, bag (coin), coins, skull (ibex)
const PROPS := [
	# entrance hall: a broken cart, scrub that grows where the daylight reaches, the lookouts' supplies
	["cart", 270, 1376], ["agave", 300, 1412], ["agave", 426, 1416], ["crate", 446, 1340], ["barrel", 462, 1354], ["sacks", 440, 1386],
	# side alcove: where the lookouts sleep
	["bedroll", 532, 1186, "#6a4a3a"], ["crate", 586, 1214], ["barrel", 576, 1230],
	# the abandoned camp (the riders' camp, raided)
	["tent", 290, 948, 46, true, false], ["tent", 470, 952, 42, true, false],
	["fire", 380, 1028, true],
	["table", 300, 1062, 40, "food", true], ["table", 470, 1050, 36, "food", true],
	["bedroll", 210, 992, "#7a3a2a"], ["bedroll", 512, 992, "#4e5a6e"],
	["gear", 248, 1010], ["pot", 414, 1072],
	["sacks", 540, 1036], ["barrel", 534, 1060], ["crate", 212, 1062],
	["arrows", 330, 976], ["arrows", 440, 1092], ["arrows", 236, 1040], ["cloth", 548, 1012],
	["spear", 354, 984], ["spear", 488, 1024],
	# the jail room (the rider's cage is placed by _jail()): small pens in the corners (two hold the dead), chain frames, a strap
	# bench and the jailer's tools, braziers of coals, the jailer's table (the rider's bow) and stool, his stores
	["pen", 102, 248, 34, 22, 0], ["pen", 360, 244, 34, 22, -1], ["pen", 122, 330, 34, 22, -1], ["pen", 326, 336, 34, 22, 1],
	["frame", 142, 222], ["frame", 318, 220], ["frame", 368, 296],
	["bench", 296, 262], ["table", 300, 292, 30, "irons"],
	["brand", 338, 300], ["brand", 172, 340],
	["table", 132, 284, 34, "bow"], ["stool", 156, 296],
	["rack", 90, 288], ["mat", 150, 312], ["pots", 170, 240], ["barrel", 286, 240], ["crate", 268, 344],
	# the band's camp
	["tent", 620, 514, 50, false, true],
	["fire", 690, 576, true],
	["rack", 760, 508],
	["palisade", 708, 634, 72], ["palisade", 520, 540, 30],
	["stack", 528, 586], ["barrel", 548, 612], ["sacks", 860, 560], ["crate", 852, 592],
	["bedroll", 712, 590, "#5a4a3a"], ["bedroll", 630, 598, "#6a3a2a"],
	# the boss room. North: the chief's seat in front of his hoard, banners and fire bowls either side
	["hoard", 820, 138, 120], ["seat", 820, 150], ["banner", 750, 148], ["banner", 890, 148], ["bowl", 728, 176], ["bowl", 912, 176],
	# north-west: his war table, stools, stores against the wall
	["war", 676, 200, 68], ["stool", 634, 204], ["stool", 718, 206], ["barrel", 624, 186], ["pots", 706, 172], ["banner", 604, 236],
	# north-east: the riders staked along the wall (the captain's own stake, at the east end, is placed by _captain_stake()),
	# an empty cage beyond them
	["captive", 898, 174, 0], ["captive", 930, 170, 1],
	["cage", 1012, 254, 36, 24],
	# west: two tents with their rugs, a banner, stores
	["tent", 640, 248, 44, false, false], ["tent", 664, 336, 44, false, false],
	["barrel", 616, 284], ["crate", 690, 310],
	# east: a tent with its rug, stores; the bedding corner to the south-east
	["tent", 1004, 306, 44, false, false], ["banner", 974, 322],
	["sacks", 934, 318], ["bedroll", 948, 304, "#6a3a2a"],
	# south: palisades round the top of the steps and along the south walls, a fire bowl each side, a spear rack
	["palisade", 752, 374, 44], ["palisade", 868, 374, 44], ["palisade", 708, 352, 40], ["palisade", 914, 352, 34],
	["bowl", 702, 340], ["bowl", 962, 340], ["rack", 726, 316],
	# the open floor: the band's loot strewn about. The strongbox and the crate stack are tall (they stop his charge and the stones);
	# the spilled coins, the stool and the ibex skull are low (the four coin bags are PICKUPS: they can be taken)
	["strongbox", 762, 298], ["stack", 892, 298],
	["coins", 816, 214], ["coins", 748, 278], ["coins", 932, 268], ["coins", 868, 250],
	["skull", 790, 238], ["stool", 878, 224],
]
# things to take (level.gd pickups, Stage 7g): [id, item, n, foot, look]. The raided camp still holds the riders' own supplies; the
# chief's room has the band's four coin bags, drawn as bags (draw_look "bag") until taken. The hoard behind his seat stays scenery.
const PICKUPS := [
	["camp_bread", "bread", 2, Vector2(488, 1076)],
	["camp_apple", "apple", 1, Vector2(318, 1088)],
	["camp_potion", "small_potion", 1, Vector2(232, 1026)],
	["bag_1", "coins", 25, Vector2(738, 254), "bag"], ["bag_2", "coins", 25, Vector2(912, 242), "bag"],
	["bag_3", "coins", 25, Vector2(852, 290), "bag"], ["bag_4", "coins", 25, Vector2(796, 316), "bag"],
]
# torches: [x, y] (foot of the post; the flame and its light sit about 30 px above)
const TORCHES := [
	[282, 1320], [440, 1322], [336, 1226], [590, 1192],
	[238, 944], [524, 944],
	[344, 800],
	[290, 712], [266, 572], [192, 438],
	[178, 198], [282, 198],
	[536, 522], [872, 532],
	[640, 184], [984, 186],
]

# the cage in the jail room: centre of its front foot, width, depth. Stand in front of its door and press E to open it.
const CAGE := {"x": 230.0, "y": 214.0, "w": 72.0, "d": 44.0}
const CAGE_USE := {"id": "cage", "rect": Rect2(210, 214, 40, 24), "prompt": Vector2(256, 228)}
const CAGE_OPEN_TIME := 0.6
# the captured royal rider, sitting in the cage; when the door opens he steps out to RIDER_OUT and waits to be spoken to
const RIDER := {"id": "rider", "type": "ambient", "look": "rider", "pos": [230, 198], "face": "down", "idle": "bob"}
const RIDER_OUT := Vector2(208, 230)
# a rider's last note (Stage 7j): a scrap of leather in the jail's empty east pen. Stand in front of the pen and press E: it opens in the
# reader (dialogue.gd LOGS "jail_note") and goes into the journal, and the hero takes it.
const NOTE := Vector2(358, 236)
const NOTE_USE := {"id": "note", "rect": Rect2(344, 246, 32, 16), "prompt": Vector2(384, 250)}

# The ambush when the rider joins you: a spiked barricade is thrown across the jail tunnel at BARRICADE, and the band comes up the
# tunnel from it, already after you: each entry arrives `delay` s after the rider joins (keep the list in delay order). Two bandits
# rush you at once from different points; then two slingers come up behind them and keep their distance (slinger.gd). The barricade
# stays until every one of them is down (no saving meanwhile: busy()).
const WAVE := [
	{"kind": "bandit", "pos": Vector2(214, 436), "axis": Vector2.RIGHT, "span": 10.0, "delay": 0.0},
	{"kind": "bandit", "pos": Vector2(240, 506), "axis": Vector2.RIGHT, "span": 10.0, "delay": 0.0},
	{"kind": "slinger", "pos": Vector2(268, 596), "delay": 4.0},
	{"kind": "slinger", "pos": Vector2(256, 550), "delay": 4.6},
]
const WAVE_LEASH := 360.0       # they chase you anywhere in the jail room (a normal bandit gives up at 200 px from home)
const BARRICADE := Vector2(270, 624)      # a point low in the jail tunnel; the barricade spans the tunnel's floor on that row
# when the ambush is over: two more of the band waiting lower down, on the hero's way out (awake, an ordinary beat, not yet after him)
const WAIT := [
	{"kind": "bandit", "pos": Vector2(300, 736), "axis": Vector2.RIGHT, "span": 10.0},
	{"kind": "bandit", "pos": Vector2(386, 838), "axis": Vector2.RIGHT, "span": 16.0},
]

# The chief's fight (Stage 6c): when the "boss" group wakes, a barricade shuts the steps (at SEAL, spanning the floor on that row) and
# a slinger bursts out of each tent's doorway (SLINGER_SPOTS) until he falls. Then, after BOSS_EXIT_TIME s, the seal lifts; the hero
# goes back to the king only once he has cut the captain down (CAPTAIN_USE).
const SEAL := Vector2(832, 398)
const SLINGER_SPOTS := [Vector2(640, 256), Vector2(664, 344), Vector2(1004, 314)]
const BOSS_EXIT_TIME := 1.5

# The riders' captain, bound alive to the last stake of the row along the boss room's north wall, under a torch (so he reads as a
# person, not a shadow like the others). Once the seal has lifted, E in front of him cuts him down and he tells what was done here
# (dialogue.gd SCENES "captain"); when the scene closes the hero goes back to the king.
const CAPTAIN := {"id": "captain", "type": "ambient", "look": "captain", "pos": [962, 190], "face": "down", "idle": "bob", "solid": [12, 6]}
const CAPTAIN_USE := {"id": "captain", "rect": Rect2(944, 190, 36, 24), "prompt": Vector2(982, 172)}
const CAPTAIN_DROP := 6.0       # how far he slumps forward when the ropes are cut (px)

# The abandoned camp's rats wait until the hero walks in between the tents (CAMP_TRIGGER, the ground between the tents and the
# fire); then they come at him from four sides, already after him: one out of each tent's doorway, one up the tunnel he came in by
# and one down the tunnel to the fork. "puff" = which way the dust they kick up flies.
const CAMP_TRIGGER := Rect2(320, 950, 120, 66)
const CAMP_RATS := [
	{"kind": "rat", "pos": Vector2(290, 960), "puff": Vector2.DOWN},      # the left tent
	{"kind": "rat", "pos": Vector2(470, 962), "puff": Vector2.DOWN},      # the right tent
	{"kind": "rat", "pos": Vector2(366, 1150), "puff": Vector2.UP},       # up the tunnel from the entrance
	{"kind": "rat", "pos": Vector2(402, 838), "puff": Vector2.DOWN},      # down the tunnel from the fork
]

# Enemy groups. "wake" = a group sleeps until the hero comes within `radius` of `center`.
#  lookouts (no group): 3 bandits in the tunnel and the alcove, awake from the start
#  the band's camp and the jailer (no group): awake bandits pacing their beat
#  boss:  the chief, asleep on his seat until you reach the middle of his room; then he comes for you at once (aggro)
# (the camp's rats, the ambush and the ones waiting after it are not here: cave.gd adds them during play)
const WAKE := {
	"boss": {"center": Vector2(820, 260), "radius": 70.0, "aggro": true},
}

# rest spots (level.gd rests: E rests and autosaves, only while no enemy is after you): the band's fire, the cave's only one and the
# last stop before the steps up to the chief
const RESTS := [
	{"rect": Rect2(660, 552, 60, 50), "prompt": Vector2(716, 568), "name": "the band's fire"},    # a ring all round the fire (690, 576)
]
# place name (hud.gd shows it top-right): the whole cave has one name; its rooms have none (only well-known places are named)
const PLACE_NAME := "The Hill Cave"
const PLACES := []
# quest notes (level.gd notes): walking into the jail, roughly its ROOMS ellipse, shows the optional objective "Free the caged rider"
# (quest.gd SIDE)
const NOTES := [
	[Rect2(65, 154, 330, 216), "saw_cage"],
]
const ENEMIES := [
	{"kind": "bandit", "pos": Vector2(372, 1262), "axis": Vector2.RIGHT, "span": 18.0},
	{"kind": "bandit", "pos": Vector2(358, 1170), "axis": Vector2.RIGHT, "span": 16.0},
	{"kind": "bandit", "pos": Vector2(540, 1212), "axis": Vector2.RIGHT, "span": 14.0},
	{"kind": "bandit", "pos": Vector2(600, 566), "axis": Vector2.DOWN, "span": 18.0},
	{"kind": "bandit", "pos": Vector2(744, 540), "axis": Vector2.RIGHT, "span": 30.0},
	{"kind": "bandit", "pos": Vector2(660, 616), "axis": Vector2.RIGHT, "span": 28.0},
	{"kind": "bandit", "pos": Vector2(806, 584), "axis": Vector2.DOWN, "span": 16.0},
	{"kind": "bandit", "pos": Vector2(230, 290), "axis": Vector2.RIGHT, "span": 40.0},     # the jailer
	{"kind": "chief", "pos": Vector2(820, 176), "group": "boss"},                          # in front of his seat
]

var _gw := 0
var _gh := 0
var _mask := PackedByteArray()      # 1 = floor, per MASK_CELL square
var _tr
var _lantern
var rider                           # rider.gd (made in start_npcs)
var cage_opened := false
var cage_open := 0.0                # the door's swing, 0 shut .. 1 open (drawn by the cage prop)
var _door_rect := Rect2()           # the solid across the cage door (taken away when it opens)
var _bow_table                      # the jail table's prop: redrawn without the bow once the rider takes it
var bow_taken := false
var camp_sprung := false            # the rats have come out of the camp's tents
var wave: Array = []                # the ambush (bandits and slingers spawned so far)
var wave_on := false
var _wave_t := 0.0                  # time since the ambush began
var _wave_next := 0                 # the next WAVE entry to arrive
var _slingers_called := false       # the rider has shouted about the slingers
var _wave_bar := {}                 # the ambush's barricade {"rect", "prop"} (see _barricade_at)
var waiting: Array = []             # the WAIT bandits, once the ambush is over
var chief                           # chief.gd (found among the enemies once they are spawned)
var slingers: Array = []
var boss_on := false                # the chief is awake and his room is sealed
var seal_lifted := false            # the chief has fallen and the steps are open again
var boss_done := false              # the captain has been cut down and the hero has been sent back to the king
var _seal := {}                     # the boss room's barricade
var _boss_down_t := -1.0            # time since the chief fell (-1: he hasn't)
var captain                         # npc.gd (made in start_npcs)
var captain_cut := false
var _captain_stake                  # the captain's stake prop: redrawn with cut ropes once he is down
var _captain_ropes                  # the ropes drawn across him (freed when he is cut down)

func _init() -> void:
	key = "cave"
	place_name = PLACE_NAME
	places = PLACES
	notes = NOTES
	rests = RESTS
	pickup_plan = PICKUPS
	W = 1100
	H = 1500
	spawns = {"entry": {"pos": Vector2(360, 1452), "face": "up"}}
	spawn = spawns["entry"]["pos"]
	# walk back out through the mouth (the bottom edge of the map) -> the town, just below the cave mouth in the cliff
	doors = [{"rect": Rect2(322, 1484, 76, 16), "auto": true, "to": "town", "spawn": "cave"}]
	uses = [CAGE_USE, CAPTAIN_USE, NOTE_USE]
	for k in WAKE.keys():
		groups[k] = {"center": WAKE[k]["center"], "radius": WAKE[k]["radius"], "active": false, "aggro": WAKE[k].get("aggro", false)}

func _ready() -> void:
	_build_mask()
	_paint()
	_make_nodes()
	_rock_solids()
	_add_props()
	_jail()
	_captain_stake_props()
	_add_torches()
	_mouth()
	_make_pickups()
	_make_door_prompts()
	_make_use_prompts()
	_make_rest_prompts()
	_make_debug()
	_add_lighting()

# ---------------------------------------------------------------- the floor mask (ROOMS + TUNNELS)
func _build_mask() -> void:
	_gw = W / MASK_CELL
	_gh = H / MASK_CELL
	_mask.resize(_gw * _gh)
	var nz := FastNoiseLite.new()
	nz.seed = 41
	nz.frequency = 0.024
	for rm in ROOMS:
		var c := Vector2(rm[0], rm[1])
		var rx: float = rm[2]
		var ry: float = rm[3]
		for gy in range(maxi(0, int((c.y - ry * 1.2) / MASK_CELL)), mini(_gh, int((c.y + ry * 1.2) / MASK_CELL) + 1)):
			for gx in range(maxi(0, int((c.x - rx * 1.2) / MASK_CELL)), mini(_gw, int((c.x + rx * 1.2) / MASK_CELL) + 1)):
				var p := Vector2(gx * MASK_CELL + MASK_CELL / 2.0, gy * MASK_CELL + MASK_CELL / 2.0)
				var q := Vector2((p.x - c.x) / rx, (p.y - c.y) / ry)
				if q.length() < 1.0 + WOBBLE_ROOM * nz.get_noise_2d(p.x, p.y):
					_mask[gy * _gw + gx] = 1
	for tn in TUNNELS:
		var pts := []
		for p in tn["pts"]:
			pts.append(Vector2(p[0], p[1]))
		var wob: float = tn.get("wobble", WOBBLE_TUNNEL)
		for q in Terrain.spline(pts, 3.0):
			_stamp(q, tn["w"] / 2.0 * (1.0 + wob * nz.get_noise_2d(q.x * 1.3 + 500.0, q.y * 1.3)))

func _stamp(c: Vector2, r: float) -> void:
	for gy in range(maxi(0, int((c.y - r) / MASK_CELL)), mini(_gh, int((c.y + r) / MASK_CELL) + 1)):
		for gx in range(maxi(0, int((c.x - r) / MASK_CELL)), mini(_gw, int((c.x + r) / MASK_CELL) + 1)):
			if Vector2(gx * MASK_CELL + MASK_CELL / 2.0, gy * MASK_CELL + MASK_CELL / 2.0).distance_to(c) <= r:
				_mask[gy * _gw + gx] = 1

func is_floor(p: Vector2) -> bool:
	var gx := int(p.x / MASK_CELL)
	var gy := int(p.y / MASK_CELL)
	return gx >= 0 and gy >= 0 and gx < _gw and gy < _gh and _mask[gy * _gw + gx] == 1

# ---------------------------------------------------------------- ground painting (done once)
func _paint() -> void:
	_tr = Terrain.new(W, H)
	_tr.rng.seed = 61
	_tr.cave_ground(_mask, _gw, _gh, MASK_CELL)
	for pth in PATHS:
		var pts := []
		for p in pth[1]:
			pts.append(Vector2(p[0], p[1]))
		_tr.cave_path(pts, pth[0])
	_tr.steps(STAIRS.position.x, STAIRS.position.y, STAIRS.size.x, STEP["count"], STEP["tread"], STEP["riser"],
		["#b08458", "#8a6238", "#5a3c22", "#2a1c12"], 0.25)
	for r in RUGS:
		_tr.rug(r[0], r[1], r[2], r[3], "#7a2a20", "#a8463a")
	for s in STAINS:
		_tr.stain(s[0], s[1], s[2])
	for dg in DRAGS:
		var pts := []
		for p in dg[1]:
			pts.append(Vector2(p[0], p[1]))
		_tr.drag(pts, dg[0])
	for sp in SPATTER:
		_tr.spatter(sp[0], sp[1], sp[2], sp[3])
	# daylight on the ground at the mouth: warm sand blown in, brightest at the opening
	for i in range(26):
		var t := float(i) / 25.0
		_tr.patch(360.0 + _tr.rng.randf_range(-28.0, 28.0), 1500.0 - t * 70.0, int(lerpf(20.0, 10.0, t)), Color("#e9c36d"), lerpf(0.7, 0.2, t))
	var spr := Sprite2D.new()
	spr.texture = ImageTexture.create_from_image(_tr.img)
	spr.centered = false
	add_child(spr)

# ---------------------------------------------------------------- collision: rock on the SOLID_CELL grid, merged along each row
func _rock_solids() -> void:
	var k := SOLID_CELL / MASK_CELL
	var sw := int(ceil(float(W) / SOLID_CELL))
	var sh := int(ceil(float(H) / SOLID_CELL))
	for sy in range(sh):
		var sx := 0
		while sx < sw:
			if _rock_cell(sx, sy, k):
				var x0 := sx
				while sx < sw and _rock_cell(sx, sy, k):
					sx += 1
				solid(x0 * SOLID_CELL, sy * SOLID_CELL, (sx - x0) * SOLID_CELL, SOLID_CELL)
			else:
				sx += 1

func _rock_cell(sx: int, sy: int, k: int) -> bool:
	for dy in range(k):
		for dx in range(k):
			var gx := sx * k + dx
			var gy := sy * k + dy
			if gx >= _gw or gy >= _gh or _mask[gy * _gw + gx] == 0:
				return true
	return false

# ---------------------------------------------------------------- props
func _add_props() -> void:
	for p in PROPS:
		var kind: String = p[0]
		var x: float = p[1]
		var y: float = p[2]
		match kind:
			"tent":
				var w: float = p[3]
				var torn: bool = p[4]
				var red: bool = p[5]
				solid(x - w / 2.0, y - 14, w, 14)
				prop(y, func(n): CVP.tent(n, x, y, w, torn, red))
			"fire":
				var lit: bool = p[3]
				solid(x - 14, y - 12, 28, 10, true)          # low: you can be seen across a fire
				prop(y, func(n): CVP.fire_ring(n, x, y, lit), true, 0.1)
			"table":
				var w2: float = p[3]
				var items: String = p[4]
				var bloody: bool = p.size() > 5 and p[5]
				solid(x - w2 / 2.0, y - 10, w2, 10)
				var tbl := prop(y, func(n): CVP.camp_table(n, x, y, w2, "" if items == "bow" and bow_taken else items, bloody))
				if items == "bow":
					_bow_table = tbl
			"bedroll":
				var col := Color(p[3])
				prop(y, func(n): CVP.bedroll(n, x, y, col))                  # flat: walkable, sorted by its top edge
			"palisade":
				var w3: float = p[3]
				solid(x, y - 5, w3, 5)
				prop(y, func(n): CVP.palisade(n, x, y, w3))
			"seat":
				solid(x - 18, y - 18, 36, 18)
				prop(y, func(n): CVP.chief_seat(n, x, y))
			"banner":
				solid(x - 3, y - 3, 6, 4)
				prop(y, func(n): CVP.band_banner(n, x, y, 18.0, 34.0), true, 0.15)
			"bowl":
				solid(x - 8, y - 5, 16, 6)
				prop(y, func(n): CVP.fire_bowl(n, x, y), true, 0.11)
			"gear":
				prop(y - 8, func(n): CVP.dropped_gear(n, x, y))              # flat on the ground
			"pot":
				solid(x - 8, y - 6, 16, 6, true)
				prop(y, func(n): CVP.spilled_pot(n, x, y))
			"stool":
				solid(x - 5, y - 4, 10, 4, true)
				prop(y, func(n): CVP.stool(n, x, y))
			"cart":
				solid(x - 20, y - 12, 40, 12)
				prop(y, func(n): Props.cart(n, x, y))
			"agave":
				solid(x - 4, y - 3, 8, 3, true)
				prop(y, func(n): Props.agave(n, x, y, 0.9, int(x) % 6))
			"rack":
				solid(x - 12, y - 5, 25, 6)
				prop(y, func(n): Props.rack(n, x, y))
			"barrel":
				solid(x - 6, y - 5, 12, 6)
				prop(y, func(n): Props.barrel(n, x, y))
			"crate":
				solid(x - 7, y - 6, 14, 7)
				prop(y, func(n): Props.crate(n, x, y))
			"stack":
				solid(x - 16, y - 6, 32, 7)
				prop(y, func(n): Props.crate_stack(n, x, y))
			"sacks":
				solid(x - 12, y - 6, 24, 7)
				prop(y, func(n): Props.sacks(n, x, y))
			"arrows":
				prop(y, func(n): CVP.arrows_stuck(n, x, y))                  # thin: walkable
			"cloth":
				solid(x - 2, y - 3, 4, 4, true)
				prop(y, func(n): CVP.torn_cloth(n, x, y))
			"spear":
				prop(y - 8, func(n): CVP.broken_spear(n, x, y))               # flat on the ground
			"brand":
				solid(x - 10, y - 6, 21, 7, true)
				prop(y, func(n): CVP.brand_bowl(n, x, y), true, 0.1)
			"captive":
				var v2: int = p[3]
				solid(x - 3, y - 5, 7, 6)
				prop(y, func(n): CVP.stake_captive(n, x, y, v2))
			"pen":
				var pw: float = p[3]
				var pd: float = p[4]
				var dead: int = p[5]
				_cage(x, y, pw, pd, 8.0, 26.0, 0.0, false, CVP.PEN_GAP)
				prop(y - 8, func(n): CVP.pen_inside(n, x, y - 8, dead))
			"cage":
				_cage(x, y, float(p[3]), float(p[4]), CVP.CAGE_DOOR, 30.0, 1.0, false)     # empty, its door hanging open
			"frame":
				solid(x - 14, y - 4, 5, 5)                                     # the two posts (you can walk under the beam)
				solid(x + 9, y - 4, 5, 5)
				prop(y, func(n): CVP.chain_frame(n, x, y))
			"bench":
				solid(x - 20, y - 10, 40, 10, true)
				prop(y, func(n): CVP.strap_bench(n, x, y))
			"mat":
				prop(y, func(n): CVP.straw_mat(n, x, y))                      # flat: walkable, sorted by its top edge
			"pots":
				solid(x - 8, y - 5, 19, 6)
				prop(y, func(n): Props.pots(n, x, y))
			"hoard":
				var hw: float = p[3]
				solid(x - hw / 2.0 + 4, y - 14, hw - 8, 14)                   # tall
				prop(y, func(n): CVP.hoard(n, x, y, hw), true, 0.15)
			"war":
				var ww: float = p[3]
				solid(x - ww / 2.0, y - 14, ww, 14)
				prop(y, func(n): CVP.war_table(n, x, y, ww), true, 0.12)
			"strongbox":
				solid(x - 14, y - 7, 28, 7)                                    # tall: stops a charge and a stone
				prop(y, func(n): CVP.strongbox(n, x, y))
			"coins":
				prop(y - 4, func(n): CVP.coins(n, x, y))                      # flat
			"skull":
				prop(y, func(n): CVP.ibex_skull(n, x, y))                     # small: walkable

# PICKUPS with a look of their own: the coin bags keep the bag drawing they had as loot
func draw_look(look: String, n, x: float, y: float) -> void:
	if look == "bag":
		CVP.coin_bag(n, x, y)

func _add_torches() -> void:
	for t in TORCHES:
		var x: float = t[0]
		var y: float = t[1]
		solid(x - 3, y - 3, 6, 4)
		prop(y, func(n): Props.torch(n, x, y), true, 0.11)

# the rider's cage against the jail room's north wall (its door swings open when you free him), and the note in the east pen (just in
# front of what pen_inside draws there, behind the pen's front poles)
func _jail() -> void:
	_door_rect = _cage(CAGE["x"], CAGE["y"], CAGE["w"], CAGE["d"], CVP.CAGE_DOOR, CVP.CAGE_H, 0.0, true)
	prop(NOTE.y + 0.5, _draw_note, true, 0.5)

func _note_found() -> bool:
	return dialogue != null and dialogue.quest.flags.get("found_note", false)

func _draw_note(n) -> void:
	if not _note_found():
		CVP.leather_note(n, NOTE.x, NOTE.y)

# A cage of lashed poles (cave_props.cage; also the jail's pens and the boss room's empty cage): back poles and straw floor (drawn
# behind whoever is inside), front poles and door (in front), solid on all sides. The door is its own solid unless it already stands
# open, so opening it takes just that away. rider_cage = the rider's cage, whose door swings with `cage_open`. gap = pole spacing.
# Returns the door's rect.
func _cage(x: float, y: float, w: float, d: float, door: float, ch: float, open: float, rider_cage: bool, gap := 7.0) -> Rect2:
	var dl: float = x - door / 2.0 - 2.0
	var dr: float = x + door / 2.0 + 2.0
	solid(x - w / 2.0 - 1, y - d - 4, w + 4, 5)        # back
	solid(x - w / 2.0 - 1, y - d, 4, d)                # left side
	solid(x + w / 2.0 - 1, y - d, 4, d)                # right side
	solid(x - w / 2.0 - 1, y - 4, dl - (x - w / 2.0 - 1), 5)     # front, left of the door
	solid(dr, y - 4, x + w / 2.0 + 3 - dr, 5)                     # front, right of the door
	var door_rect := Rect2(dl, y - 4, dr - dl, 5)
	if open < 0.5:
		solid(door_rect.position.x, door_rect.position.y, door_rect.size.x, door_rect.size.y)
	prop(y - d, func(n): CVP.cage(n, x, y, w, d, "back", 0.0, door, ch, gap))
	prop(y, func(n): CVP.cage(n, x, y, w, d, "front", cage_open if rider_cage else open, door, ch, gap), rider_cage, 0.05)
	return door_rect

# the captain's stake (behind him) and the ropes across him (in front of him); he himself is an NPC, made in start_npcs()
func _captain_stake_props() -> void:
	var x: float = CAPTAIN["pos"][0]
	var y: float = CAPTAIN["pos"][1]
	_captain_stake = prop(y - 4.0, func(n): CVP.bare_stake(n, x, y - 4.0, captain_cut))
	_captain_ropes = prop(y + 1.0, func(n): CVP.captive_ropes(n, x, y))

# daylight falling in at the mouth (drawn additively so it brightens the dark)
func _mouth() -> void:
	var rays := prop(1500, func(n): CVP.daylight(n, 360.0, 1500.0, 74.0, 120.0), true, 0.05)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	rays.material = mat
	rays.z_index = 40

# ---------------------------------------------------------------- people: the caged rider
func start_npcs() -> void:
	if dialogue.squad.has("farnaka"):
		rider = dialogue.squad.node("farnaka")     # (a loaded game) he is already in the squad: no one in the cage
	else:
		rider = Rider.new()
		ysort.add_child(rider)
		npcs.append(rider)
		rider.setup(RIDER, self)
	captain = NPC.new()
	ysort.add_child(captain)
	npcs.append(captain)
	captain.setup(CAPTAIN, self)

# walking in through the mouth counts as finding the band's hideout (quest.gd)
func arrived(_spawn_name: String) -> void:
	dialogue.quest.note("cave_entered")
	if boss_done:
		_captain_gone()

# Once the hero has taken him back to the king, the captain is with the king's healers (dialogue.gd "king_return_*"): coming into the
# cave again (or loading a save) shows his stake empty, its ropes cut. Not done in _go_to_king itself, so he doesn't vanish during the fade.
func _captain_gone() -> void:
	if captain == null:
		return
	npcs.erase(captain)
	captain.queue_free()
	captain = null

# ---------------------------------------------------------------- the rescue: the cage door, the talk, the ambush
# The cage can be opened until the hero goes back to the king (even after the chief has fallen); after that it stays shut.
# The captain can be cut down once the chief has fallen and the seal has lifted. The note can be read any time, once.
func usable(id: String) -> bool:
	match id:
		"cage":
			return not cage_opened and not boss_done
		"captain":
			return seal_lifted and not captain_cut and not boss_done
		"note":
			return not _note_found()
	return false

func use_spot(id: String) -> void:
	if not usable(id):
		return
	if id == "captain":
		_cut_captain_down()
		return
	if id == "note":
		dialogue.quest.note("found_note")
		dialogue.quest.add_journal("jail_note")
		dialogue.menu.read_log("jail_note")
		return
	cage_opened = true
	unsolid(_door_rect)
	rider.free_from_cage(RIDER_OUT)
	dialogue.quest.note("rider_freed")

# the rider's talk has ended (dialogue.gd TALK "rider": "then": "rider_join"): he takes his bow, joins the hero's squad and follows
# you, and the band attacks
func talk_done(what: String) -> void:
	if what != "rider_join" or dialogue.squad.has("farnaka"):
		return
	bow_taken = true
	if _bow_table != null:
		_bow_table.queue_redraw()
	rider.join()
	dialogue.squad.join("farnaka", rider)
	_start_wave()

# the rider is in the squad and here with the hero (following or holding a spot), so he can shout
func _rider_with_us() -> bool:
	return rider != null and is_instance_valid(rider) and rider.world == self and rider.state in ["follow", "wait"]

func _start_wave() -> void:
	_wave_bar = _barricade_at(BARRICADE)
	wave.clear()
	_wave_t = 0.0
	_wave_next = 0
	wave_on = true
	if _rider_with_us():
		rider.shout(dialogue.SHOUTS["rider_wave"], 2.5)
	_update_wave(0.0)

# bring in each WAVE entry when its delay has passed; end the ambush when all have come and all are down
func _update_wave(dt: float) -> void:
	_wave_t += dt
	while _wave_next < WAVE.size() and _wave_t >= WAVE[_wave_next]["delay"]:
		var e: Dictionary = WAVE[_wave_next]
		_wave_next += 1
		var r = combat.spawn_enemy(e, true)
		r.leash = WAVE_LEASH
		r.lose = WAVE_LEASH + 80.0
		wave.append(r)
		if e["kind"] == "slinger" and not _slingers_called:            # once, as the first slinger comes up
			_slingers_called = true
			if _rider_with_us():
				rider.shout(dialogue.SHOUTS["rider_slingers"], 2.5)
	if _wave_next < WAVE.size():
		return
	for r in wave:
		if is_instance_valid(r) and r.alive:
			return
	_end_wave()

func _end_wave() -> void:
	wave_on = false
	_lift(_wave_bar)
	_wave_bar = {}
	for e in WAIT:
		waiting.append(combat.spawn_enemy(e))
	if _rider_with_us():
		rider.shout(dialogue.SHOUTS["rider_clear"], 2.5)

# A spiked barricade across a tunnel (the ambush, the boss room's steps): on the row of `at`, from rock to rock (the run of floor
# around at.x in the floor mask). Returns {"rect": its solid, "prop": its drawing}, for _lift().
func _barricade_at(at: Vector2) -> Dictionary:
	var row := int(at.y / MASK_CELL) * _gw
	var a := int(at.x / MASK_CELL)
	var b := a
	while a > 0 and _mask[row + a - 1] == 1:
		a -= 1
	while b < _gw - 1 and _mask[row + b + 1] == 1:
		b += 1
	var x0 := float(a * MASK_CELL)
	var x1 := float((b + 1) * MASK_CELL)
	var r := Rect2(x0 - 8.0, at.y - 6.0, x1 - x0 + 16.0, 8.0)
	solid(r.position.x, r.position.y, r.size.x, r.size.y)
	var bx := x0 - 2.0
	var bw := x1 - x0 + 4.0
	var p := prop(at.y + 2.0, func(n): CVP.barricade(n, bx, at.y + 2.0, bw))
	combat.spark(Vector2((x0 + x1) / 2.0, at.y - 4.0), Vector2.UP, 12, Color("#c8b89a"))
	return {"rect": r, "prop": p}

func _lift(bar: Dictionary) -> void:
	if bar.is_empty():
		return
	unsolid(bar["rect"])
	combat.spark(bar["rect"].get_center(), Vector2.UP, 12, Color("#c8b89a"))
	bar["prop"].queue_free()

# ---------------------------------------------------------------- the chief's fight and the return to the king
# the chief is awake (his group woke, or he was hit in his sleep): shut the steps, bring in the slingers
func _seal_boss_room() -> void:
	boss_on = true
	groups["boss"]["active"] = true
	_seal = _barricade_at(SEAL)
	slingers.clear()
	for p in SLINGER_SPOTS:
		var s = combat.spawn_enemy({"kind": "slinger", "pos": p}, true)
		combat.spark(s.position + Vector2(0, -2), Vector2.ZERO, 10, Color("#a89878"))     # a puff of dust where he jumps down
		slingers.append(s)
	if _rider_with_us():
		rider.shout(dialogue.SHOUTS["rider_boss"], 2.5)

# BOSS_EXIT_TIME s after the chief fell: lift the seal and let the hero look around; the rider points out the captain
func _lift_seal() -> void:
	seal_lifted = true
	_lift(_seal)
	_seal = {}
	if _rider_with_us():
		rider.shout(dialogue.SHOUTS["rider_captain"], 3.0)

# E at the captain: cut his ropes, he slumps forward, and tells what was done here; then back to the king
func _cut_captain_down() -> void:
	captain_cut = true
	_captain_stake.queue_redraw()
	_captain_ropes.queue_free()
	captain.lines = []
	captain.idle = "none"
	captain.position.y += CAPTAIN_DROP
	combat.spark(captain.position + Vector2(0, -20), Vector2.UP, 6, Color("#c8a868"))       # rope fibres
	dialogue.start_scene(captain, dialogue.SCENES["captain"], _go_to_king)

# note what happened and go back to the king. A freed rider comes too, whatever his squad order (he is called to follow, so the door
# carries him to the hall even from his home spot); one never freed stays behind in the cave.
func _go_to_king() -> void:
	boss_done = true
	var q = dialogue.quest
	var joined: bool = dialogue.squad.has("farnaka")
	q.flags["rider_joined"] = joined
	q.note("chief_down")
	q.note("captain_found")
	if joined:
		dialogue.squad_order.call("farnaka", "follow")
	else:
		rider.stay_behind()
	dialogue.travel.call("hall", "king_return")

func _update_boss(dt: float) -> void:
	if boss_done:
		return
	if chief == null and _boss_down_t < 0.0:      # (once he has fallen and been freed, `chief == null` is true again: don't look)
		for r in rats:
			if r.kind == "chief":
				chief = r
		if chief == null:
			return
	var up: bool = is_instance_valid(chief) and chief.alive
	if not boss_on and _boss_down_t < 0.0 and up and not chief.dormant:
		_seal_boss_room()
	if _boss_down_t < 0.0 and not up:
		boss_on = false
		_boss_down_t = 0.0
		dialogue.quest.note("chief_down")
	if _boss_down_t >= 0.0 and not seal_lifted:
		_boss_down_t += dt
		if _boss_down_t >= BOSS_EXIT_TIME and not player.dead and not talking:
			_lift_seal()

# ---------------------------------------------------------------- light (helpers in level.gd)
func _add_lighting() -> void:
	var cm := CanvasModulate.new()
	cm.color = Color(0.30, 0.27, 0.35)     # the dark of the cave
	add_child(cm)
	for t in TORCHES:
		point_light(Vector2(t[0], t[1] - 30.0), 96.0, Color(1.0, 0.62, 0.26), 1.1, true)
	for p in PROPS:
		match p[0]:
			"fire":
				if p[3]:
					point_light(Vector2(p[1], p[2] - 12.0), 150.0, Color(1.0, 0.55, 0.22), 1.3, true)
			"bowl":
				point_light(Vector2(p[1], p[2] - 26.0), 110.0, Color(1.0, 0.6, 0.25), 1.1, true)
			"brand":
				point_light(Vector2(p[1], p[2] - 12.0), 56.0, Color(1.0, 0.42, 0.18), 0.8, true)     # the coals of the branding irons
			"war":
				point_light(Vector2(p[1] - p[3] / 2.0 + 11.0, p[2] - 26.0), 44.0, Color(1.0, 0.7, 0.35), 0.7, true)   # the oil lamp
	point_light(Vector2(360, 1496), 170.0, Color(1.0, 0.92, 0.75), 1.15)      # daylight at the mouth
	point_light(Vector2(360, 1420), 110.0, Color(1.0, 0.9, 0.72), 0.45)
	_lantern = point_light(Vector2.ZERO, 70.0, Color(1.0, 0.86, 0.62), 0.55)    # the hero's own small light

func _process(dt: float) -> void:
	flicker_lights(0.12)
	if player != null and _lantern != null:
		_lantern.position = player.position + Vector2(0, -10)
	cage_open = move_toward(cage_open, 1.0 if cage_opened else 0.0, dt / CAGE_OPEN_TIME)
	if wave_on and combat != null:
		_update_wave(dt)
	if player != null and combat != null:
		_update_camp()
		_update_boss(dt)

# the hero has walked in between the abandoned camp's tents: the rats come at him from the tents and both tunnels
func _update_camp() -> void:
	if camp_sprung or player.dead or not CAMP_TRIGGER.has_point(player.position):
		return
	camp_sprung = true
	for e in CAMP_RATS:
		combat.spawn_enemy(e, true)
		combat.spark(e["pos"] + Vector2(0, -6), e["puff"], 8, Color("#a89878"))

# ---------------------------------------------------------------- saving (save.gd)
# no saving during the ambush, the chief's fight, or the moments before his room opens
func busy() -> bool:
	return wave_on or boss_on or (_boss_down_t >= 0.0 and not seal_lifted)

func save_state() -> Dictionary:
	var d := super.save_state()
	d["cage_opened"] = cage_opened
	d["bow_taken"] = bow_taken
	d["camp_sprung"] = camp_sprung
	d["wave_done"] = _wave_next >= WAVE.size() and not wave_on
	d["seal_lifted"] = seal_lifted
	d["captain_cut"] = captain_cut
	d["boss_done"] = boss_done
	return d

# The cave as it was saved. The rider is either in the squad (main.gd rebuilds him) or still here: in the cage, out of it waiting to
# be spoken to, or left behind after a lesser return.
func load_state(d: Dictionary) -> void:
	super.load_state(d)
	camp_sprung = d.get("camp_sprung", false)
	bow_taken = d.get("bow_taken", false)
	if bow_taken and _bow_table != null:
		_bow_table.queue_redraw()
	if d.get("wave_done", false):
		_wave_next = WAVE.size()                    # the ambush has been and gone (the ones waiting after it are in "spawned")
	boss_done = d.get("boss_done", false)
	var in_squad: bool = dialogue.squad.has("farnaka")
	if d.get("cage_opened", false):
		cage_opened = true
		cage_open = 1.0
		unsolid(_door_rect)
		if not in_squad:
			rider.position = RIDER_OUT
			rider.free_from_cage(RIDER_OUT)
	if boss_done and not in_squad:
		rider.stay_behind()
	if d.get("seal_lifted", false):
		seal_lifted = true
		_boss_down_t = BOSS_EXIT_TIME
	if d.get("captain_cut", false):
		captain_cut = true
		_captain_stake.queue_redraw()
		_captain_ropes.queue_free()
		captain.lines = []
		captain.idle = "none"
		captain.position.y += CAPTAIN_DROP
	if boss_done:
		_captain_gone()

# ---------------------------------------------------------------- enemies (see ENEMIES / WAKE at the top)
func enemy_plan(_c) -> Array:
	return ENEMIES.duplicate(true)
