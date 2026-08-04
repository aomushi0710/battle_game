extends Control

@export var stage_texture: TextureRect
@export var stage_animation_texture: TextureRect
@export var dialog: TabContainer

var stage: Stage
var tween: Tween
var animation_left: TextureRect
var animation_right: TextureRect


func setup(p_stage: Stage) -> void:
	stage = p_stage
	stage_texture.texture = stage.texture
	stage_animation_texture.texture = stage.animation_texture
	dialog.stage_flavor_text = stage.flavor_text
	dialog.stage_flavor_text_weight = stage.flavor_text_weight
	
	animation_left = stage_animation_texture
	animation_right = stage_animation_texture.duplicate()
	await get_tree().process_frame
	add_child(animation_right)
	animation()


func animation() -> void:
	animation_left.position.x = -1920
	animation_right.position.x = 0
	tween = get_tree().create_tween().bind_node(self)
	tween.finished.connect(func(): animation())
	tween.tween_property(animation_right, "position:x", 1920, 30)
	tween.parallel().tween_property(animation_left, "position:x", 0, 30)
