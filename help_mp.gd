extends TextureProgressBar

var dmg_text = preload("res://damage_text.tscn")
var mp = 0

func _on_help_spd_help_mp():
	if $".".value == 999: # 自動初期化
		$".".value = 200
		
	damage_effect(100)
	for i in range(100): # 少しずつゲージを増やす反復処理
		$".".value += 1
		await get_tree().create_timer(0.5 / 100).timeout
		text_update()

func damage_effect(dmg: int) -> void:
	var text = dmg_text.instantiate() # インスタンス生成
	var color = Color(0,0,0,0)
	text.text = "[b][i] %d[/i][/b]" % dmg # ダメージエフェクト文字
	color = Color(Color.AQUA,1.0) # 青色指定
	get_parent().add_child(text) # child指定
	text.position =  Vector2(25 + randi() % 100,randi() % 156) # 端や下側に出現しないように調整
	text.self_modulate = color # 色適用
	text.show()
	
	await get_tree().create_timer(1.0).timeout # 1秒停止
	for i in range(50):
		text.position.y -= 1 #上に移動
		if i > 10: # 少し移動してから
			color.a -= 0.025 # 徐々に透明化
			text.self_modulate = color # 変更点を適用
		await get_tree().create_timer(0.01).timeout
	text.queue_free() # 削除

func text_update():
	mp = int($".".value)
	$mp_text.text = "[color=aqua][b]MP[/b] %3d/999[/color]" % mp
