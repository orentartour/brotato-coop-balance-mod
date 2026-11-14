extends "res://ui/menus/run/character_selection.gd"

# CoopBalance - the "Random" character button never picks a character that has an
# effect on one of CF_CONFIG.RANDOM_EXCLUDED_EFFECT_KEYS (enemy_health,
# enemy_damage by default). Technique: displayed_elements[0] (the pool vanilla
# draws from) is temporarily replaced by a filtered copy while the vanilla
# _on_element_pressed runs, then restored. Manual selection is untouched.

const CF_CONFIG = preload("res://mods-unpacked/BrotatoCoop-CoopBalance/config.gd")
const CF_MOD_ID = "BrotatoCoop-CoopBalance"
const CF_MAX_EFFECT_DEPTH = 4

func _on_element_pressed(element: InventoryElement, _inventory_player_index: int) -> void:
	# Enemy-buff filter: co-op only. "Already beaten" filter: solo and co-op.
	var use_effects: bool = CF_CONFIG.ENABLE_RANDOM_FILTER and RunData.is_coop_run
	var use_beaten: bool = CF_CONFIG.RANDOM_EXCLUDE_BEATEN_DIFFICULTY > 0
	if element == null or not element.is_random or not (use_effects or use_beaten):
		._on_element_pressed(element, _inventory_player_index)
		return

	var original: Array = displayed_elements[0]
	# Both filters first; if that leaves nobody, drop the "already beaten"
	# filter; if still nobody, vanilla full list.
	var filtered: Array = _cf_filter(original, use_effects, use_beaten)
	if filtered.empty() and use_beaten:
		ModLoaderLog.info("Random: every allowed character already beat the target difficulty here, ignoring that filter", CF_MOD_ID)
		filtered = _cf_filter(original, use_effects, false)
	if filtered.empty() or filtered.size() == original.size():
		if filtered.empty():
			ModLoaderLog.info("Random filter would leave no available character, using the full list", CF_MOD_ID)
		._on_element_pressed(element, _inventory_player_index)
		return

	displayed_elements[0] = filtered
	._on_element_pressed(element, _inventory_player_index)
	# Restore, unless something rebuilt the list in the meantime.
	if displayed_elements[0] == filtered:
		displayed_elements[0] = original


# Returns the filtered pool, or [] when no available (unlocked, enabled)
# character would remain. Logs what was excluded and why.
func _cf_filter(original: Array, use_effects: bool, use_beaten: bool) -> Array:
	var filtered: = []
	var by_effect: = []
	var by_beaten: = []
	var has_available: = false
	for character in original:
		if use_effects and _cf_is_excluded_character(character):
			by_effect.push_back(character.my_id)
			continue
		if use_beaten and _cf_has_beaten_target(character):
			by_beaten.push_back(character.my_id)
			continue
		filtered.push_back(character)
		if not character.is_locked and _get_item_disabled_update(character) == null:
			has_available = true
	ModLoaderLog.info("Random pool (zone %s): excluded for enemy buffs %s, excluded for danger %s+ already beaten %s" % [
		"random" if ProgressData.settings.zone_is_random else str(RunData.current_zone),
		str(by_effect), CF_CONFIG.RANDOM_EXCLUDE_BEATEN_DIFFICULTY, str(by_beaten)], CF_MOD_ID)
	return filtered if has_available else []


# True when the character already beat RANDOM_EXCLUDE_BEATEN_DIFFICULTY (or
# higher) on the selected map. With the map on "Random", only when it is
# beaten on every map.
func _cf_has_beaten_target(character) -> bool:
	if not "my_id_hash" in character:
		return false
	var target: int = CF_CONFIG.RANDOM_EXCLUDE_BEATEN_DIFFICULTY
	var zone_ids: = []
	if ProgressData.settings.zone_is_random:
		for i in range(_random_zone_index):
			zone_ids.push_back(_zone_selection_button.get_item_id(i))
	else:
		zone_ids.push_back(RunData.current_zone)
	if zone_ids.empty():
		return false
	for zone_id in zone_ids:
		var info = ProgressData.get_character_difficulty_info(character.my_id_hash, zone_id)
		if info == null or info.max_difficulty_beaten.difficulty_value < target:
			return false
	return true


func _cf_is_excluded_character(character) -> bool:
	if character == null or not "effects" in character or typeof(character.effects) != TYPE_ARRAY:
		return false
	if "my_id" in character and CF_CONFIG.RANDOM_EFFECT_FILTER_WHITELIST.has(character.my_id):
		return false
	for effect in character.effects:
		if _cf_effect_matches(effect, CF_MAX_EFFECT_DEPTH):
			return true
	return false


# Checks the stat key of an effect, including the fields used by effect
# subclasses (ConvertStatEffect.to_stat, GainStatForEveryStatEffect.stat_scaled,
# ClassBonusEffect.stat_name, StatGainsModificationEffect.stats_modified) and
# nested EffectWithSubEffects.sub_effects. Effects stored with a custom_key
# (stats_end_of_wave, stats_on_level_up...) keep the stat in "key".
func _cf_effect_matches(effect, depth: int) -> bool:
	if effect == null or depth <= 0 or not effect is Object:
		return false
	var keys: Array = CF_CONFIG.RANDOM_EXCLUDED_EFFECT_KEYS

	for field in ["key", "to_stat", "stat_scaled", "stat_name"]:
		if field in effect:
			var value = effect.get(field)
			if typeof(value) == TYPE_STRING and keys.has(value):
				return true

	if "stats_modified" in effect:
		var stats_modified = effect.get("stats_modified")
		if typeof(stats_modified) == TYPE_ARRAY:
			for stat in stats_modified:
				if typeof(stat) == TYPE_STRING and keys.has(stat):
					return true

	if "sub_effects" in effect:
		var sub_effects = effect.get("sub_effects")
		if typeof(sub_effects) == TYPE_ARRAY:
			for sub_effect in sub_effects:
				if _cf_effect_matches(sub_effect, depth - 1):
					return true

	return false
