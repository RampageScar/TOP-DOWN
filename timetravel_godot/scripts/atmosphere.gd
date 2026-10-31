extends Node2D
# atmosphere.gd - the "mood" layer: warm torch glows, river sparkle, and (in a screen layer) a soft vignette and drifting dust.
# Everything here is drawn, nothing is simulated, so it costs almost nothing.

const Drawn = preload("res://scripts/drawn.gd")

var lights: Array = []        # [x, y, radius, kind]  kind 0 = torch, 1 = fire, 2 = cave mouth
var water_marks: Array = []   # [x, y, len, speed, phase]
var shore: Array = []
var glow_node
var water_node
var screen_layer

func setup(world_node, light_list: Array, shore_pts: Array, y0: float, y1: float, map_w: float) -> void:
	lights = light_list
	shore = shore_pts
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in range(150):
		var y := rng.randf_range(y0 + 4, y1 - 4)
		var sx := _shore_x(y)
		if sx > map_w:
			continue
		var x := sx + 10.0 + rng.randf() * (map_w - sx - 10.0)
		water_marks.append([x, y, rng.randi_range(5, 14), rng.randf_range(0.6, 1.6), rng.randf() * TAU])
	# water sparkle sits just above the ground image
	water_node = Drawn.new()
	water_node.animated = true
	water_node.interval = 0.09
	water_node.draw_fn = _draw_water
	world_node.add_child(water_node)
	world_node.move_child(water_node, 1)
	# glows are added on top of everything in the world
	glow_node = Drawn.new()
	glow_node.animated = true
	glow_node.interval = 0.07
	glow_node.z_index = 45
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow_node.material = mat
	glow_node.draw_fn = _draw_glow
	world_node.add_child(glow_node)
	_build_screen_layer(world_node)

func _shore_x(y: float) -> float:
	for i in range(shore.size() - 1):
		var a: Vector2 = shore[i]; var b: Vector2 = shore[i + 1]
		if y >= a.y and y <= b.y:
			return lerpf(a.x, b.x, (y - a.y) / maxf(b.y - a.y, 0.001))
	return 99999.0

func _draw_water(n) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for m in water_marks:
		var wob: float = sin(t * m[3] + m[4]) * 4.0
		var a: float = 0.25 + 0.35 * (0.5 + 0.5 * sin(t * m[3] * 1.7 + m[4]))
		var x: float = roundf(m[0] + wob)
		if x < _shore_x(m[1]) + 5.0:
			continue
		n.draw_rect(Rect2(x, roundf(m[1]), m[2], 1), Color(0.92, 0.98, 1.0, a))
		n.draw_rect(Rect2(x + 2, roundf(m[1]) + 1, m[2] * 0.5, 1), Color(0.75, 0.9, 1.0, a * 0.6))
	# foam wobble along the shore
	for y in range(460, 765, 5):
		var sx := _shore_x(y)
		if sx > 1195.0:
			continue
		var w := 2.0 + 1.5 * sin(t * 1.6 + y * 0.31)
		n.draw_rect(Rect2(roundf(sx + 1), y, roundf(w) + 1, 1), Color(1, 1, 1, 0.65))

func _draw_glow(n) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for l in lights:
		var fl := 0.82 + 0.18 * sin(t * 11.0 + l[0] * 0.13) * sin(t * 7.3 + l[1] * 0.07)
		var r: float = l[2] * fl
		var base := Color(1.0, 0.62, 0.22)
		if l[3] == 2:
			base = Color(0.9, 0.5, 0.2)
		var p := Vector2(l[0], l[1])
		for i in range(6):
			var k := 1.0 - i / 6.0
			n.draw_circle(p, r * k, Color(base.r, base.g, base.b, 0.012 + 0.006 * i))
		n.draw_circle(p, r * 0.16, Color(1.0, 0.85, 0.5, 0.07))

# ---- screen-space layer: vignette + dust ----
var dust: Array = []
var dust_node

func _build_screen_layer(world_node) -> void:
	screen_layer = CanvasLayer.new()
	screen_layer.layer = 1
	world_node.add_child(screen_layer)
	# vignette image, dithered so it keeps the pixel look
	var vi := Image.create(480, 270, false, Image.FORMAT_RGBA8)
	var bayer := [[0.0, 0.5, 0.125, 0.625], [0.75, 0.25, 0.875, 0.375], [0.1875, 0.6875, 0.0625, 0.5625], [0.9375, 0.4375, 0.8125, 0.3125]]
	for y in range(270):
		for x in range(480):
			var dx := (x - 240.0) / 240.0
			var dy := (y - 135.0) / 135.0
			var d := sqrt(dx * dx * 0.8 + dy * dy * 0.8)
			var v := clampf((d - 0.62) / 0.75, 0.0, 1.0)
			var lvl := floorf(v * 4.0 + bayer[y % 4][x % 4]) / 4.0
			if lvl > 0.0:
				vi.set_pixel(x, y, Color(0.12, 0.05, 0.02, minf(lvl * 0.5, 0.42)))
	var tr := TextureRect.new()
	tr.texture = ImageTexture.create_from_image(vi)
	tr.size = Vector2(480, 270)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_layer.add_child(tr)
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	for i in range(34):
		dust.append([rng.randf() * 480.0, rng.randf() * 270.0, rng.randf_range(7.0, 18.0), rng.randf_range(-2.0, 3.0), rng.randf() * TAU])
	dust_node = Drawn.new()
	dust_node.animated = true
	dust_node.draw_fn = _draw_dust
	screen_layer.add_child(dust_node)

func _draw_dust(n) -> void:
	var dt := get_process_delta_time()
	var t := Time.get_ticks_msec() / 1000.0
	for d in dust:
		d[0] += d[2] * dt
		d[1] += d[3] * dt + sin(t * 0.8 + d[4]) * 0.15
		if d[0] > 484.0:
			d[0] = -4.0
			d[1] = randf() * 270.0
		if d[1] < -4.0: d[1] = 272.0
		if d[1] > 274.0: d[1] = -2.0
		n.draw_rect(Rect2(roundf(d[0]), roundf(d[1]), 2, 1), Color(1.0, 0.93, 0.7, 0.28))
