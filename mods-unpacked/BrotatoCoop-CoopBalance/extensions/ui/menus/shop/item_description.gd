extends "res://ui/menus/shop/item_description.gd"

# Scrolls a long item description (shop card) without a mouse wheel or a right
# stick, e.g. when playing through a remote screen share that does not forward
# the wheel. Only the description of the item the player has selected scrolls.
#   - mouse: its vertical position on the screen picks the position in the text
#     (top of the screen = start, bottom = end). Works with the hidden co-op
#     cursor; applied only when the mouse moves, so a newly selected card stays
#     at the top until the mouse is moved.
#   - keys (fallback): hold TOOLTIP_SCROLL_UP_KEY / TOOLTIP_SCROLL_DOWN_KEY.
# Vanilla _process (right stick) still runs: Godot 3 calls _process on every
# level of the script chain, so no ._process() super call here.

const CB_CONFIG = preload("res://mods-unpacked/BrotatoCoop-CoopBalance/config.gd")

var _cb_last_mouse_y: = -1.0
var _cb_key_scroll_acc: = 0.0


func _process(delta: float) -> void:
	if not _cb_is_scroll_target():
		_cb_last_mouse_y = -1.0
		_cb_key_scroll_acc = 0.0
		return

	var v_bar: ScrollBar = _scroll_container.get_v_scrollbar()
	var max_scroll: float = v_bar.max_value - v_bar.page
	var viewport: Viewport = get_viewport()
	var mouse_y: float = viewport.get_mouse_position().y

	if max_scroll <= 0.0:
		_cb_last_mouse_y = mouse_y
		return

	if CB_CONFIG.TOOLTIP_MOUSE_SCROLL and _cb_last_mouse_y >= 0.0 and abs(mouse_y - _cb_last_mouse_y) >= 1.0:
		var height: float = viewport.get_visible_rect().size.y
		var margin: float = CB_CONFIG.TOOLTIP_MOUSE_SCROLL_MARGIN * height
		var ratio: float = clamp((mouse_y - margin) / max(1.0, height - 2.0 * margin), 0.0, 1.0)
		_scroll_container.scroll_vertical = int(round(ratio * max_scroll))
	_cb_last_mouse_y = mouse_y

	if CB_CONFIG.TOOLTIP_KEY_SCROLL:
		var direction: = 0.0
		if Input.is_key_pressed(CB_CONFIG.TOOLTIP_SCROLL_UP_KEY):
			direction -= 1.0
		if Input.is_key_pressed(CB_CONFIG.TOOLTIP_SCROLL_DOWN_KEY):
			direction += 1.0
		if direction == 0.0:
			_cb_key_scroll_acc = 0.0
		else:
			# scroll_vertical is an int: accumulate so slow speeds still move.
			_cb_key_scroll_acc += direction * CB_CONFIG.TOOLTIP_KEY_SCROLL_SPEED * delta
			var step: = int(_cb_key_scroll_acc)
			_cb_key_scroll_acc -= step
			_scroll_container.scroll_vertical += step


func _cb_is_scroll_target() -> bool:
	if CB_CONFIG.TOOLTIP_SCROLL_PLAYER >= 0 and _player_index != CB_CONFIG.TOOLTIP_SCROLL_PLAYER:
		return false
	if not is_instance_valid(_scroll_container) or not _scroll_container.visible or not is_visible_in_tree():
		return false

	var focused: Control = null
	if RunData.is_coop_run:
		var focus_emulator = Utils.get_focus_emulator(_player_index)
		if focus_emulator == null:
			return false
		focused = focus_emulator.focused_control
	else:
		focused = get_focus_owner()

	if focused == null or not is_instance_valid(focused):
		return false
	return focused == self or focused.is_a_parent_of(self)
