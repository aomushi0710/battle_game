extends Control

var tween: Tween
var animation_left: TextureRect
var animation_right: TextureRect

func _on_tree_entered() -> void:
	animation_left = $stage_animation
	animation_right = $stage_animation.duplicate()
	await get_tree().process_frame
	add_child(animation_right)
	animation()


func animation() -> void:
	animation_left.position.x = -1152
	animation_right.position.x = 0
	tween = get_tree().create_tween()
	tween.finished.connect(func(): animation())
	tween.tween_property(animation_right, "position:x", 1152, 30)
	tween.parallel().tween_property(animation_left, "position:x", 0, 30)


func battle_finished() -> void: # バトル終了
	if tween and tween.is_running():
		tween.kill()
