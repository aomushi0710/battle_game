extends Control

var tween: Tween
var animation_left: TextureRect
var animation_right: TextureRect

func _on_tree_entered() -> void:
	match Global.battle_stage: # ステージ背景の決定
		Global.Stage.PLAIN: # 草原ステージ
			$stage.texture = preload("res://image/stage/草原.PNG")
			$stage_animation.texture = preload("res://image/stage/青空.PNG")
			$"../battle/button/dialogtab".stage_flavor_text = [
				["草が風に揺れている..."], 
				["あの山は遠くにあるように見えるが、\n実際は近くにあるように感じられる。"], 
				["この辺りは天候が安定している。\n戦いに邪魔が入ることはないだろう。"]]
	
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
