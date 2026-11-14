extends "res://items/materials/gold.gd"

# Remembers on each dropped material the EntityType it was valued for
# (ENEMY / NEUTRAL / other), as computed by Main.get_gold_value().
# drop() is called by Main.spawn_gold() every time a coin is (re)used from the
# pool, so the meta is always overwritten before the coin can be picked up.

const CF_META_ENTITY_TYPE = "_cf_entity_type"


func drop(pos: Vector2, p_rotation: float, p_push_back_destiation: Vector2) -> void:
	var entity_type = -1
	var tree = Engine.get_main_loop()
	if tree is SceneTree:
		var main = tree.current_scene
		if main != null and "_cf_last_gold_type" in main:
			entity_type = main._cf_last_gold_type
	set_meta(CF_META_ENTITY_TYPE, entity_type)
	.drop(pos, p_rotation, p_push_back_destiation)
