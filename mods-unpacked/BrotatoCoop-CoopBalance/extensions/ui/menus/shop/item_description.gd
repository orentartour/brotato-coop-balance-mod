extends "res://ui/menus/shop/item_description.gd"

# Auto-scrolls long item descriptions (shop cards) so the whole text can be
# read without any input: useful when playing through a remote screen share
# that forwards neither the mouse wheel nor the hidden co-op cursor.
# Cycle when the text overflows: pause at the top, scroll down slowly, pause at
# the bottom, scroll back up quickly, repeat. Moving the right stick (vanilla
# scroll) pauses the auto-scroll for a few seconds.
# Vanilla _process (right stick) still runs: Godot 3 calls _process on every
# level of the script chain, so no ._process() super call here.

const CB_CONFIG = preload("res://mods-unpacked/BrotatoCoop-CoopBalance/config.gd")

enum CbPhase {TOP_PAUSE, DOWN, BOTTOM_PAUSE, UP}

var _cb_phase: int = CbPhase.TOP_PAUSE
var _cb_timer: = 0.0
var _cb_pos: = 0.0
var _cb_manual_pause: = 0.0


func set_item(item_data: ItemParentData, player_index: int, item_count: = 1) -> void:
	.set_item(item_data, player_index, item_count)
	_cb_restart()


func _cb_restart() -> void:
	_cb_phase = CbPhase.TOP_PAUSE
	_cb_timer = 0.0
	_cb_pos = 0.0
	_cb_manual_pause = 0.0
	if is_instance_valid(_scroll_container):
		_scroll_container.scroll_vertical = 0


func _process(delta: float) -> void:
	if not CB_CONFIG.TOOLTIP_AUTO_SCROLL:
		return
	if not is_instance_valid(_scroll_container) or not _scroll_container.visible or not is_visible_in_tree():
		return

	var v_bar: ScrollBar = _scroll_container.get_v_scrollbar()
	var max_scroll: float = v_bar.max_value - v_bar.page
	if max_scroll <= 1.0:
		return

	# Right stick in use: let the player scroll by hand, resume later from there.
	if abs(Utils.get_player_rjoy_vector(_player_index).y) > 0.2:
		_cb_manual_pause = CB_CONFIG.TOOLTIP_AUTO_SCROLL_MANUAL_PAUSE
	if _cb_manual_pause > 0.0:
		_cb_manual_pause -= delta
		_cb_pos = float(_scroll_container.scroll_vertical)
		return

	match _cb_phase:
		CbPhase.TOP_PAUSE:
			_cb_pos = 0.0
			_cb_timer += delta
			if _cb_timer >= CB_CONFIG.TOOLTIP_AUTO_SCROLL_TOP_PAUSE:
				_cb_phase = CbPhase.DOWN
		CbPhase.DOWN:
			_cb_pos += CB_CONFIG.TOOLTIP_AUTO_SCROLL_SPEED * delta
			if _cb_pos >= max_scroll:
				_cb_pos = max_scroll
				_cb_phase = CbPhase.BOTTOM_PAUSE
				_cb_timer = 0.0
		CbPhase.BOTTOM_PAUSE:
			_cb_pos = max_scroll
			_cb_timer += delta
			if _cb_timer >= CB_CONFIG.TOOLTIP_AUTO_SCROLL_BOTTOM_PAUSE:
				_cb_phase = CbPhase.UP
		CbPhase.UP:
			_cb_pos -= CB_CONFIG.TOOLTIP_AUTO_SCROLL_RETURN_SPEED * delta
			if _cb_pos <= 0.0:
				_cb_pos = 0.0
				_cb_phase = CbPhase.TOP_PAUSE
				_cb_timer = 0.0

	_scroll_container.scroll_vertical = int(round(_cb_pos))
