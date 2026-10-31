extends RefCounted
# npc_data.gd - every waystation character as plain data. Positions are world pixels (feet).
# type: "talk" (E to talk) or "ambient" (walks / works, may mutter a line in a white bubble)
# sprite: person | camel | lizard | sleeper     look: palette name from sprites.gd     acc: jar | spear | scroll | plate (one, or a list)
# mode: stay | patrol | chase | dash            idle: bob | sway | work | stir | brush | none
# solid: [w, h] collision box so the hero cannot walk through them# chatter lines live in dialogue.gd (CHATTER), keyed by id.
# (Stage 3b: same people as before, moved into the new portrait town - gate in the SOUTH wall.)

const LIST := [
	# ---- talkable ----
	{"id": "arshan", "type": "talk", "look": "keeper", "pos": [362, 452], "face": "right", "idle": "sway", "solid": [8, 4]},
	{"id": "nidu", "type": "talk", "look": "scribe", "pos": [641, 537], "face": "down", "idle": "bob", "solid": [8, 4]},     # just west of the pottery stall, not touching it; his head is level with its roof top
	{"id": "datis", "type": "talk", "look": "datis", "pos": [474, 556], "face": "left", "idle": "sway", "solid": [8, 4]},
	# ---- gate guards (south gate, flanking the road) ----
	{"id": "guard1", "type": "ambient", "look": "guard", "pos": [391, 698], "face": "down", "idle": "sway", "solid": [8, 4]},
	{"id": "guard2", "type": "ambient", "look": "guard", "pos": [457, 698], "face": "down", "idle": "sway", "solid": [8, 4]},
	# ---- east gate guard (stands where the south watch post used to be, facing the outer road) ----
	{"id": "guard4", "type": "ambient", "look": "guard", "pos": [810, 482], "face": "right", "idle": "sway", "solid": [8, 4]},
	# ---- life of the waystation ----
	{"id": "carrier", "type": "ambient", "look": "carrier", "pos": [478, 512], "face": "left", "mode": "patrol", "speed": 24.0, "pause": 2.5, "acc": "jar", "solid": [8, 4],
		"route": [[478, 512], [560, 444]]},
	{"id": "potter", "type": "ambient", "look": "potter", "pos": [238, 514], "face": "right", "idle": "work", "solid": [8, 4]},
	{"id": "camel", "type": "ambient", "sprite": "camel", "pos": [196, 392], "face": "right", "idle": "none", "solid": [28, 6]},
	{"id": "handler", "type": "ambient", "look": "handler", "pos": [236, 396], "face": "left", "idle": "brush", "solid": [8, 4]},
	{"id": "lizard", "type": "ambient", "sprite": "lizard", "pos": [330, 540], "mode": "dash", "speed": 46.0, "pause": 1.4,
		"route": [[330, 540], [385, 556], [350, 576], [312, 572], [385, 520], [318, 562]]},
	{"id": "child", "type": "ambient", "look": "child", "scale": 0.72, "pos": [296, 556], "face": "right", "mode": "chase", "follow": "lizard", "speed": 34.0},
	# asleep under the west end of the cook's long canopy
	{"id": "traveller", "type": "ambient", "sprite": "sleeper", "look": "traveller", "pos": [178, 604], "face": "right", "solid": [26, 6]},
	{"id": "cook", "type": "ambient", "look": "cook", "pos": [284, 606], "face": "left", "idle": "stir", "solid": [8, 4]},
]
