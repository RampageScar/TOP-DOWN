extends RefCounted
# inventory.gd - what the hero carries: item id -> count. What an item is (name, kind, icon) lives in items.gd.
# Recent gains are kept for a few seconds so the HUD can show "+2 Flatbread" toasts.

const Items = preload("res://scripts/items.gd")
const TOAST_TIME := 2.5     # seconds a gain stays in the HUD's toast list

var counts := {}
var gains: Array = []       # [{"id": String, "n": int, "at": msec}], oldest first
var changed_at := -100000

# toast = false: no "+n" toast (the lasso the hero starts with)
func add(id: String, n := 1, toast := true) -> void:
	if n <= 0:
		return
	counts[id] = counts.get(id, 0) + n
	changed_at = Time.get_ticks_msec()
	if toast:
		gains.append({"id": id, "n": n, "at": changed_at})

# take n of an item away; false (and nothing taken) if there are fewer than n
func remove(id: String, n := 1) -> bool:
	if count(id) < n:
		return false
	counts[id] -= n
	if counts[id] <= 0:
		counts.erase(id)
	changed_at = Time.get_ticks_msec()
	return true

func count(id: String) -> int:
	return counts.get(id, 0)

func has(id: String) -> bool:
	return count(id) > 0

# the items carried, in the order the inventory shows them: by kind (items.gd KINDS), then in the order they were first picked up
func ids() -> Array:
	var out := []
	for k in Items.KINDS:
		for id in counts.keys():
			if Items.info(id)["kind"] == k:
				out.append(id)
	return out

# gains still young enough to show as toasts (and forget the old ones)
func recent() -> Array:
	var now := Time.get_ticks_msec()
	while not gains.is_empty() and now - gains[0]["at"] > TOAST_TIME * 1000.0:
		gains.pop_front()
	return gains
