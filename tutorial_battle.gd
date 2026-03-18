extends "new_battle.gd"

@onready var arrow_mark = $"../arrow_mark"
@onready var pause_text = $"../tutorial_pause_text"
var arrow_tween: Tween
var pause_tween: Tween


func setup() -> void:
	super()
	pause_text.hide()
	arrow_mark.hide()


func tree_paused() -> void:
	pause_text.hide()
	pause_text.modulate.a = 0
	if get_tree().paused == true:
		pause_text.show()
		pause_tween = get_tree().create_tween().bind_node(pause_text).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		pause_tween.set_loops()
		pause_tween.tween_property(pause_text, "modulate:a", 1, 1)
		pause_tween.tween_property(pause_text, "modulate:a", 0, 1)
	else:
		pause_tween.kill()

## 矢印マークを表示する関数[br]size_:フォントサイズ color:BBcodeで記述される色の文字列
## direction:矢印の方向(rotation) pos:表示位置(position)
func arrow_mark_setter(size_: int, color: String, direction: float, pos: Vector2) -> void:
	if arrow_tween and arrow_tween.is_running():
		arrow_tween.kill()
		await arrow_mark_hide()
	arrow_mark.hide()
	arrow_mark.modulate.a = 1
	arrow_mark.position = pos
	arrow_mark.size = Vector2(size_, 0)
	arrow_mark.pivot_offset = Vector2(size_ / 2, size_ / 2)
	arrow_mark.rotation_degrees = direction
	arrow_mark.text = \
	"[font_size=%d][color=%s][b]⬇️[/b][/color][/font_size]" % [size_, color]
	arrow_mark.show()
	
	arrow_tween = get_tree().create_tween().bind_node(arrow_mark).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	arrow_tween.tween_property(arrow_mark, "size:y", size_ * 1.6, 1)
	await arrow_tween.finished
	arrow_tween = null
	arrow_tween = get_tree().create_tween().bind_node(arrow_mark).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	arrow_tween.set_loops()
	arrow_tween.tween_property(arrow_mark, "size:y", size_ * 1.3, 0.5)
	arrow_tween.tween_property(arrow_mark, "size:y", size_ * 1.6, 0.5)

## 矢印マークの削除
func arrow_mark_hide() -> void:
	if arrow_tween and arrow_tween.is_running():
		arrow_tween.kill()
	arrow_tween = get_tree().create_tween().bind_node(arrow_mark)
	arrow_tween.tween_property(arrow_mark, "modulate:a", 0, 0.5)
	await arrow_tween.finished
	arrow_mark.hide()
	
## バトル開始カットイン終了後、最初に流れるメッセージ設定
func _on_cutin_ended() -> void:
	get_tree().paused = true
	tree_paused()
	arrow_mark_setter(250, "red", 0, Vector2(1279, 459))
	await dialog.text_setter(load("res://battlelog_data/tutorial/tutorial1.tres"))
	get_tree().paused = false
	tree_paused()
	
	arrow_mark_setter(100, "red", 90, Vector2(790, 700))
	await get_tree().create_timer(1).timeout
	get_tree().paused = true
	tree_paused()
	await dialog.text_setter(load("res://battlelog_data/tutorial/tutorial2.tres"))
	get_tree().paused = false
	tree_paused()
	player_monster.generated_action = [
		player_monster.data.action[0], player_monster.data.action[0], 
		player_monster.data.action[1], player_monster.data.action[2]
	]

## プレイヤー行動可能時に流れるメッセージ設定
func _on_player_ready() -> void:
	back_disabled = true
	$button/main/Action.disabled = true
	$button/main/Item.disabled = true
	$button/main/Status.disabled = true
	arrow_mark_setter(100, "red", 90, Vector2(790, 660))
	await dialog.text_setter(BattlelogData.new([
		"%s が行動可能になった。\n%s は[color=aqua]MP[/color]が[color=aqua]%d[/color]回復した！" % 
		[player_monster.data.get_monsterform().name, player_monster.data.get_monsterform().name, player_monster.data.supplyMP] + 
		"\n[color=yellow]%s は指示を待っている...[/color]" % player_monster.data.get_monsterform().name, 
		"[color=aqua]青[/color]の[color=aqua][b]MPゲージ[/b][/color]は、モンスターが行動可能\n" + 
		"になるたびに[color=aqua][b]supplyMP[/b][/color]の値だけ回復！\n" + 
		"バトルは[color=aqua][b]maxMP[/b][/color]の20%から始まるぞ。"
	]))
	
	arrow_mark_setter(150, "red", 0, Vector2(665, 640))
	$button/main/Status.disabled = false
	dialog.text_setter(load("res://battlelog_data/tutorial/tutorial3.tres"))
	await $button.status_paging
	arrow_mark_hide()
	await dialog.text_setter(load("res://battlelog_data/tutorial/tutorial4.tres"))
	back_disabled = false
	$button/戻る.disabled = false
	arrow_mark_setter(150, "red", 0, Vector2(45, 775))
	dialog.text_setter(load("res://battlelog_data/tutorial/tutorial5.tres"))
	await $button.back
	$button/player.disabled = true
	await $button.back
	$button/main/Item.disabled = true
	$button/main/Status.disabled = true
	back_disabled = true
	arrow_mark_setter(150, "red", 0, Vector2(248, 640))


func _on_status_button_up() -> void:
	arrow_mark_setter(150, "red", 0, Vector2(248, 640))


func _on_button_player_or_enemy_button_pressed() -> void:
	arrow_mark_setter(150, "red", 0, Vector2(248, 640))


func _on_action_button_up() -> void:
	back_disabled = true
	arrow_mark_hide()
	await dialog.text_setter(load("res://battlelog_data/tutorial/tutorial6.tres"))
	$button/action.get_child(0).disabled = false
	dialog.text_setter(load("res://battlelog_data/tutorial/tutorial7.tres"))
	$button/target/target1.disabled = true
	await $button.description_paging
	await dialog.text_setter(load("res://battlelog_data/tutorial/tutorial8.tres"))
	$button/target/target1.disabled = false
	arrow_mark_setter(150, "red", 0, Vector2(248, 640))
	dialog.text_setter(load("res://battlelog_data/tutorial/tutorial9.tres"))
	await $button/target/target1.button_up
	arrow_mark_hide()
	await command_ended
	get_tree().paused = true
	tree_paused()
	arrow_mark_setter(150, "red", 180, Vector2(881, 133))
	dialog.text_setter(load("res://battlelog_data/tutorial/tutorial10.tres"))

func battle_finish(_win: bool) -> void:
	if arrow_tween and arrow_tween.is_running():
		arrow_tween.kill()
	if pause_tween and pause_tween.is_running():
		pause_tween.kill()
	$button.now_showing = -1
