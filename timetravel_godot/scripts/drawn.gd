extends Node2D
# A node that draws itself by calling draw_fn(self). Used for props and the hero body.
# rebase_y: the node sits at (0, sort_y) for y-sorting but its draw function uses absolute world coordinates.
# interval: for animated nodes, redraw only this often (seconds) instead of every frame (0 = every frame).

var draw_fn: Callable
var animated := false
var rebase_y := false
var interval := 0.0
var _acc := 0.0

func _ready() -> void:
	set_process(animated)

func _process(delta: float) -> void:
	if interval > 0.0:
		_acc += delta
		if _acc < interval:
			return
		_acc = 0.0
	queue_redraw()

func _draw() -> void:
	if rebase_y:
		draw_set_transform(Vector2(0.0, -position.y), 0.0, Vector2.ONE)
	if draw_fn.is_valid():
		draw_fn.call(self)
