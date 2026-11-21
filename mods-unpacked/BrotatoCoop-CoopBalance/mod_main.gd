extends Node

const MOD_ID = "BrotatoCoop-CoopBalance"
const MOD_DIR = "res://mods-unpacked/BrotatoCoop-CoopBalance/"
const CF_CONFIG = preload("res://mods-unpacked/BrotatoCoop-CoopBalance/config.gd")


func _init() -> void:
	if CF_CONFIG.ENABLE_GOLD_COMPENSATION:
		# Tags every dropped material with the entity type it came from.
		ModLoaderMod.install_script_extension(MOD_DIR + "extensions/items/materials/gold.gd")
		ModLoaderMod.install_script_extension(MOD_DIR + "extensions/main.gd")
	if CF_CONFIG.ENABLE_RANDOM_FILTER or CF_CONFIG.RANDOM_EXCLUDE_BEATEN_DIFFICULTY > 0:
		ModLoaderMod.install_script_extension(MOD_DIR + "extensions/ui/menus/run/character_selection.gd")
	if CF_CONFIG.TOOLTIP_MOUSE_SCROLL or CF_CONFIG.TOOLTIP_KEY_SCROLL:
		# Scroll long shop item descriptions with the mouse position or keys.
		ModLoaderMod.install_script_extension(MOD_DIR + "extensions/ui/menus/shop/item_description.gd")
	ModLoaderLog.info("CoopBalance loaded (gold compensation: %s, strict own malus: %s, random filter: %s %s)" % [
		CF_CONFIG.ENABLE_GOLD_COMPENSATION,
		CF_CONFIG.STRICT_OWN_MALUS,
		CF_CONFIG.ENABLE_RANDOM_FILTER,
		str(CF_CONFIG.RANDOM_EXCLUDED_EFFECT_KEYS)
	], MOD_ID)
