extends Control

var tween: Tween
var animation_left: TextureRect
var animation_right: TextureRect

func _on_tree_entered() -> void:
	animation_left = $stage_animation
	animation_right = $stage_animation.duplicate()
	change()
	add_child(animation_right)
	animation()


func animation() -> void:
	tween = get_tree().create_tween()
	tween.set_loops()
	tween.tween_property(animation_right, "position:x", 1152, 30)
	tween.parallel().tween_property(animation_left, "position:x", 0, 30)
	tween.tween_callback(Callable(self, "change"))


func change() -> void:
	animation_left.position.x = -1152
	animation_right.position.x = 0
