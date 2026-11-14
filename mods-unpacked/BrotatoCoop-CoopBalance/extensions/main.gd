extends "res://main.gd"

# CoopBalance - co-op material malus compensation.
#
# Vanilla (get_gold_value): gold_drops / enemy_gold_drops / neutral_gold_drops
# are averaged over all players, then every picked material is split
# round-robin between players. A Farmer (-50 %) therefore costs their partner
# -25 % too. Here, after the vanilla pickup, each player receives
# delta * (ratio - 1) extra materials/XP, where ratio compares the player's
# "fair" multiplier with the vanilla one (see config.gd for the rule).
#
# Main is re-instanced every wave, so the fractional accumulators below are
# naturally reset at the start of every wave (and run).

const CF_CONFIG = preload("res://mods-unpacked/BrotatoCoop-CoopBalance/config.gd")
const CF_MOD_ID = "BrotatoCoop-CoopBalance"
const CF_META_ENTITY_TYPE = "_cf_entity_type"

# EntityType of the last get_gold_value() call; read by the gold.gd extension
# in drop(). -1 = unknown (no compensation).
var _cf_last_gold_type: int = -1
# Fractional remainder of compensation per player.
var _cf_acc: = [0.0, 0.0, 0.0, 0.0]


# Test overlay (config SHOW_DEBUG_HUD).
const CF_HUD_FONT = preload("res://resources/fonts/actual/base/font_26_outline.tres")
const CF_HUD_REFRESH = 0.5
const CF_HUD_SCALE = 0.5
const CF_HUD_OFFSET_X = 120
var _cf_hud_label: Label = null
var _cf_hud_timer: float = 0.0


# Godot 3 calls _ready() / _process() on every script of the inheritance chain
# by itself (multilevel call): NEVER call ._ready() / ._process() here, or the
# vanilla Main runs twice (double signal connections, broken waves).
func _ready() -> void:
	# Overlay in co-op only (no compensation in solo).
	if CF_CONFIG.SHOW_DEBUG_HUD and RunData.get_player_count() > 1:
		_cf_create_hud()


func _process(delta: float) -> void:
	if _cf_hud_label == null:
		return
	_cf_hud_timer -= delta
	if _cf_hud_timer <= 0.0:
		_cf_hud_timer = CF_HUD_REFRESH
		_cf_update_hud()


func _cf_create_hud() -> void:
	_cf_hud_label = Label.new()
	_cf_hud_label.name = "CoopBalanceOverlay"
	_cf_hud_label.add_font_override("font", CF_HUD_FONT)
	_cf_hud_label.modulate = Color(1.0, 0.85, 0.3)
	_cf_hud_label.align = Label.ALIGN_LEFT
	_cf_hud_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Top of the screen, just right of the wave timer (centered, ~173 px wide)
	# and left of player 2's life bar (top-right, 320 px wide).
	_cf_hud_label.anchor_left = 0.5
	_cf_hud_label.anchor_right = 0.5
	_cf_hud_label.anchor_top = 0.0
	_cf_hud_label.anchor_bottom = 0.0
	_cf_hud_label.grow_horizontal = Control.GROW_DIRECTION_END
	_cf_hud_label.grow_vertical = Control.GROW_DIRECTION_END
	_cf_hud_label.margin_left = CF_HUD_OFFSET_X
	_cf_hud_label.margin_right = CF_HUD_OFFSET_X
	_cf_hud_label.margin_top = 28
	_cf_hud_label.margin_bottom = 28
	_cf_hud_label.rect_scale = Vector2(CF_HUD_SCALE, CF_HUD_SCALE)
	$UI.add_child(_cf_hud_label)


# One line per material source: compensation applied on top of vanilla, per
# player, e.g. "enemies   P1 +0%   P2 +33%".
func _cf_update_hud() -> void:
	var nb_players: int = RunData.get_player_count()
	if nb_players <= 1:
		_cf_hud_label.text = "Coop Balance: solo, no compensation"
		return
	var lines: = ["Coop Balance" + (" (strict)" if CF_CONFIG.STRICT_OWN_MALUS else "")]
	lines.push_back(_cf_hud_line("enemies", EntityType.ENEMY, nb_players))
	lines.push_back(_cf_hud_line("trees", EntityType.NEUTRAL, nb_players))
	_cf_hud_label.text = PoolStringArray(lines).join("\n")


func _cf_hud_line(title: String, entity_type: int, nb_players: int) -> String:
	var ratios: Array = _cf_compute_ratios(entity_type, nb_players)
	var line: = title
	for i in nb_players:
		var pct: int = int(round((ratios[i] - 1.0) * 100.0))
		line += "   P%d %s%d%%" % [i + 1, "+" if pct >= 0 else "", pct]
	return line


func get_gold_value(entity_type: int, args: Entity.DieArgs, base_value: float, unit: Unit = null) -> float:
	_cf_last_gold_type = entity_type
	return .get_gold_value(entity_type, args, base_value, unit)


func on_gold_picked_up(gold: Node, player_index: int) -> void:
	var nb_players: int = RunData.get_player_count()
	# Same early exits as vanilla: already picked up, or not picked by a player
	# (end of wave -> bonus gold, evil mob...). Solo: nothing to do.
	if nb_players <= 1 or player_index < 0 or not is_instance_valid(gold) or gold.already_picked_up:
		.on_gold_picked_up(gold, player_index)
		return

	var ratios: Array = _cf_get_ratios(gold, nb_players)
	if ratios.empty():
		.on_gold_picked_up(gold, player_index)
		return

	var gold_before: = []
	for i in nb_players:
		gold_before.push_back(RunData.get_player_gold(i))

	.on_gold_picked_up(gold, player_index)

	for i in nb_players:
		var delta: int = RunData.get_player_gold(i) - gold_before[i]
		if delta <= 0:
			continue
		_cf_credit(i, delta * (ratios[i] - 1.0))


# Returns one ratio per player, or [] when no compensation applies.
func _cf_get_ratios(gold: Node, nb_players: int) -> Array:
	if not gold.has_meta(CF_META_ENTITY_TYPE):
		return []
	var entity_type: int = int(gold.get_meta(CF_META_ENTITY_TYPE))
	if entity_type < 0:
		return []

	var ratios: Array = _cf_compute_ratios(entity_type, nb_players, CF_CONFIG.DEBUG_LOG)
	for ratio in ratios:
		if abs(ratio - 1.0) > 0.0001:
			return ratios
	return []


# Always returns one ratio per player (1.0 = no compensation) for materials
# coming from an entity of the given EntityType.
func _cf_compute_ratios(entity_type: int, nb_players: int, log_it: bool = false) -> Array:
	var has_extra_key: = false
	var extra_key: int = Keys.empty_hash
	if entity_type == EntityType.ENEMY:
		has_extra_key = true
		extra_key = Keys.enemy_gold_drops_hash
	elif entity_type == EntityType.NEUTRAL:
		has_extra_key = true
		extra_key = Keys.neutral_gold_drops_hash

	var sum_gold_drops: = 0
	var sum_extra: = 0
	var own_effects: = []
	var sum_pos: = 0.0
	var sum_neg: = 0.0
	var has_malus: = false
	for i in nb_players:
		var g: int = int(RunData.get_player_effect(Keys.gold_drops_hash, i))
		var x: int = 0
		if has_extra_key:
			x = int(RunData.get_player_effect(extra_key, i))
		sum_gold_drops += g
		sum_extra += x
		var t: int = g + x
		own_effects.push_back(t)
		if t > 0:
			sum_pos += t
		elif t < 0:
			sum_neg += t
			has_malus = true

	if not has_malus:
		var ones: = []
		for i in nb_players:
			ones.push_back(1.0)
		return ones

	# Vanilla: each key averaged separately with integer division.
	var vanilla_effect: int = int(float(sum_gold_drops) / nb_players) + int(float(sum_extra) / nb_players)
	var vanilla_mult: float = _cf_effect_multiplier(vanilla_effect)
	var mean_pos: float = sum_pos / nb_players
	var mean_neg: float = sum_neg / nb_players

	var ratios: = []
	var any_change: = false
	for i in nb_players:
		var own_neg: float = min(float(own_effects[i]), 0.0)
		var comp: float
		if CF_CONFIG.STRICT_OWN_MALUS:
			comp = mean_pos + own_neg
		else:
			comp = mean_pos + max(mean_neg, own_neg)
		var ratio: float = _cf_effect_multiplier(comp) / vanilla_mult
		if not CF_CONFIG.STRICT_OWN_MALUS:
			# Never take anything away in default mode (integer rounding of
			# the vanilla average could make the ratio slightly < 1).
			ratio = max(ratio, 1.0)
		if abs(ratio - 1.0) > 0.0001:
			any_change = true
		ratios.push_back(ratio)

	if any_change and log_it:
		ModLoaderLog.info("type=%s effects=%s vanilla=%s ratios=%s" % [entity_type, str(own_effects), vanilla_effect, str(ratios)], CF_MOD_ID)

	return ratios


# Value multiplier applied by vanilla get_gold_value() for a given effect,
# including the co-op factor and the MIN_GOLD_CHANCE floor (relative to the
# base value).
func _cf_effect_multiplier(effect: float) -> float:
	var coop_factor: float = CoopService.get_coop_materials_factor()
	return max((1.0 + coop_factor) * (1.0 + effect / 100.0), MIN_GOLD_CHANCE)


func _cf_credit(player_index: int, amount: float) -> void:
	_cf_acc[player_index] += amount
	var whole: int = int(_cf_acc[player_index])
	if whole == 0:
		return
	_cf_acc[player_index] -= whole

	if whole > 0:
		RunData.add_gold(whole, player_index)
		RunData.add_xp(whole, player_index)
	elif CF_CONFIG.STRICT_OWN_MALUS:
		RunData.remove_gold(-whole, player_index)
		_cf_remove_xp(player_index, -whole)


# Strict mode only: mirror of RunData.add_xp() without level-down (a level
# already gained is kept, XP is clamped at 0).
func _cf_remove_xp(player_index: int, value: int) -> void:
	var player_data = RunData.players_data[player_index]
	var xp_removed: float = value * (1 + (Utils.get_stat(Keys.xp_gain_hash, player_index) / 100.0))
	player_data.current_xp = max(0.0, player_data.current_xp - xp_removed)
	RunData.emit_signal("xp_added", player_data.current_xp, RunData.get_next_level_xp_needed(player_index), player_index)
