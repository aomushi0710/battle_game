extends "res://src/game/new_battle.gd"

@onready var arrow_mark := %Arrow as RichTextLabel
@onready var pause_text := %PauseText as RichTextLabel

@onready var item_button := %ItemButton as Button
@onready var status_button := %StatusButton as Button
@onready var target_button1 := %Target1 as TextureButton

var arrow_tween: Tween
var pause_tween: Tween


func setup() -> void:
	super()
	pause_text.hide()
	arrow_mark.hide()
	enemy_deck_container.hide()


func _tree_paused() -> void:
	pause_text.hide()
	pause_text.modulate.a = 0.0
	if get_tree().paused:
		pause_text.show()
		pause_tween = pause_text.create_tween()
		pause_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		pause_tween.set_loops()
		pause_tween.tween_property(pause_text, "modulate:a", 1.0, 1.0)
		pause_tween.tween_property(pause_text, "modulate:a", 0.0, 1.0)
	else:
		pause_tween.kill()

## 矢印マークを表示する関数[br]size_:フォントサイズ color:BBcodeで記述される色の文字列
## direction:矢印の方向(rotation) pos:表示位置(position)
func _show_arrow_mark(size_: float, color: String, direction: float, pos: Vector2) -> void:
	if arrow_tween and arrow_tween.is_running():
		await _hide_arrow_mark()
	
	arrow_mark.hide()
	arrow_mark.modulate.a = 1.0
	arrow_mark.position = pos
	arrow_mark.size = Vector2(size_, 0.0)
	arrow_mark.pivot_offset = Vector2(size_ / 2.0, size_ / 2.0)
	arrow_mark.rotation_degrees = direction
	arrow_mark.text = "[font_size=%d][color=%s][b]⬇️[/b][/color][/font_size]" % [size_, color]
	arrow_mark.show()
	
	arrow_tween = arrow_mark.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	arrow_tween.tween_property(arrow_mark, "size:y", size_ * 1.6, 1.0)
	await arrow_tween.finished
	
	arrow_tween = null
	arrow_tween = arrow_mark.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	arrow_tween.set_loops()
	arrow_tween.tween_property(arrow_mark, "size:y", size_ * 1.3, 0.5)
	arrow_tween.tween_property(arrow_mark, "size:y", size_ * 1.6, 0.5)

## 矢印マークの削除
func _hide_arrow_mark() -> void:
	if arrow_tween and arrow_tween.is_running():
		arrow_tween.kill()
	
	arrow_tween = arrow_mark.create_tween()
	arrow_tween.tween_property(arrow_mark, "modulate:a", 0.0, 0.5)
	await arrow_tween.finished
	arrow_mark.hide()
	
## バトル開始カットイン終了後、最初に流れるメッセージ設定
func _on_cutin_ended() -> void:
	get_tree().paused = true
	_tree_paused()
	_show_arrow_mark(250, "red", 0, Vector2(1279, 459))
	await buttons.dialog_tab.text_setter(load("res://resource/battlelog_data/tutorial/tutorial1.tres"))
	get_tree().paused = false
	_tree_paused()
	
	_show_arrow_mark(100, "red", 90, Vector2(790, 700))
	await get_tree().create_timer(1).timeout
	get_tree().paused = true
	_tree_paused()
	await buttons.dialog_tab.text_setter(load("res://resource/battlelog_data/tutorial/tutorial2.tres"))
	get_tree().paused = false
	_tree_paused()
	# チュートリアル用固定アクション
	player_monster.generated_action = [
		player_monster.data.data.action[0], player_monster.data.data.action[0], 
		player_monster.data.data.action[1], player_monster.data.data.action[4]
	]

## プレイヤー行動可能時に流れるメッセージ設定
func _on_player_ready() -> void:
	back_disabled = true
	for button in buttons.main_buttons.get_children() as Array[Button]:
		button.disabled = true
	
	_show_arrow_mark(100, "red", 90, Vector2(790, 660))
	await buttons.dialog_tab.text_setter(BattlelogData.new([
		"%s が行動可能になった。\n%s は[color=aqua]MP[/color]が[color=aqua]%d[/color]回復した！" % 
		[player_monster.data.get_monsterform().name, player_monster.data.get_monsterform().name, player_monster.data.supplyMP] + 
		"\n[color=yellow]%s は指示を待っている...[/color]" % player_monster.data.get_monsterform().name, 
		"[color=aqua]青[/color]の[color=aqua][b]MPゲージ[/b][/color]は、モンスターが行動可能\nになるたびに[color=aqua][b]supplyMP[/b][/color]の値だけ回復！\nバトルは[color=aqua][b]maxMP[/b][/color]の20%から始まるぞ。"
	]))
	
	_show_arrow_mark(150, "red", 0, Vector2(665, 640))
	status_button.disabled = false
	buttons.dialog_tab.text_setter(load("res://resource/battlelog_data/tutorial/tutorial3.tres"))
	await buttons.status_button_showed
	buttons.player_status_button.disabled = false
	
	await buttons.status_paging
	_hide_arrow_mark()
	await buttons.dialog_tab.text_setter(load("res://resource/battlelog_data/tutorial/tutorial4.tres"))
	back_disabled = false

	buttons.back_button.disabled = false
	_show_arrow_mark(150, "red", 0, Vector2(45, 775))
	buttons.dialog_tab.text_setter(load("res://resource/battlelog_data/tutorial/tutorial5.tres"))
	
	await buttons.back
	await buttons.back
	back_disabled = true
	_show_arrow_mark(150, "red", 0, Vector2(248, 640))
	await buttons.main_button_showed
	buttons.main_action_button.disabled = false


func _on_status_button_up() -> void:
	_show_arrow_mark(150, "red", 0, Vector2(248, 640))


func _on_player_status_button_pressed() -> void:
	_show_arrow_mark(150, "red", 0, Vector2(248, 640))


func _on_action_button_up() -> void:
	back_disabled = true
	_hide_arrow_mark()
	await buttons.dialog_tab.text_setter(load("res://resource/battlelog_data/tutorial/tutorial6.tres"))
	
	buttons.action_container.get_child(0).disabled = false
	buttons.dialog_tab.text_setter(load("res://resource/battlelog_data/tutorial/tutorial7.tres"))
	target_button1.disabled = true
	
	await buttons.description_paging
	await buttons.dialog_tab.text_setter(load("res://resource/battlelog_data/tutorial/tutorial8.tres"))
	target_button1.disabled = false
	
	_show_arrow_mark(150, "red", 0, Vector2(248, 640))
	buttons.dialog_tab.text_setter(load("res://resource/battlelog_data/tutorial/tutorial9.tres"))
	await target_button1.button_up
	_hide_arrow_mark()
	await command_ended
	
	get_tree().paused = true
	_tree_paused()
	_show_arrow_mark(150, "red", 180, Vector2(881, 133))
	buttons.dialog_tab.text_setter(load("res://resource/battlelog_data/tutorial/tutorial10.tres"))

func battle_finish(_win: bool) -> void:
	if arrow_tween and arrow_tween.is_running():
		arrow_tween.kill()
	if pause_tween and pause_tween.is_running():
		pause_tween.kill()
	buttons.now_showing = -1
