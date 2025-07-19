extends "new_battle.gd"

@onready var arrow_mark = $"../arrow_mark"
@onready var pause_text = $"../tutorial_pause_text"
var arrow_tween: Tween
var pause_tween: Tween


func _ready() -> void:
	super()
	tutorial_mode = true
	pause_text.hide()
	arrow_mark.hide()


func tree_paused() -> void:
	pause_text.hide()
	pause_text.modulate.a = 0
	if get_tree().paused == true:
		pause_text.show()
		pause_tween = get_tree().create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
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
	"[font_size=%d][color=%s][b]↓[/b][/color][/font_size]" % [size_, color]
	arrow_mark.show()
	
	arrow_tween = get_tree().create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	arrow_tween.tween_property(arrow_mark, "size:y", size_, 1)
	await arrow_tween.finished
	arrow_tween = null
	arrow_tween = get_tree().create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	arrow_tween.set_loops()
	arrow_tween.tween_property(arrow_mark, "size:y", size_ * 1.5, 0.5)
	arrow_tween.tween_property(arrow_mark, "size:y", size_, 0.5)

## 矢印マークの削除
func arrow_mark_hide() -> void:
	if arrow_tween and arrow_tween.is_running():
		arrow_tween.kill()
	arrow_tween = get_tree().create_tween()
	arrow_tween.tween_property(arrow_mark, "modulate:a", 0, 0.5)
	await arrow_tween.finished
	arrow_mark.hide()
	
## バトル開始カットイン終了後、最初に流れるメッセージ設定
func _on_cutin_ended() -> void:
	player_monster.picked_action = [Global.action_data[1], Global.action_data[4], 
	Global.action_data[46], Global.action_data[1]]
	get_tree().paused = true
	tree_paused()
	arrow_mark_setter(250, "red", 0, Vector2(1279, 459))
	await dialog.text_setter(0, true, [
		"この黒い箱は[b]ダイアログボックス[/b]！\nバトル中はこの枠内にメッセージが表示\nされる。" + 
		"[color=yellow]枠の中をクリックしてみよう！[/color]",
		"右下の矢印が動いている時は\nこのようにクリックで次に進むことが\nできる。", 
		"もしくはEnterキーやスペースキーでも\n大丈夫だ！" + 
		"(他のボタンにフォーカスが\n当たっていると動作しません)", 
		"今回は相手がダミーだが、実戦では\nこちらに攻撃してくるので注意しよう。\n" + 
		"[color=red]それではバトルを始めよう！[/color]"])
	get_tree().paused = false
	tree_paused()
	
	arrow_mark_setter(100, "red", 90, Vector2(790, 700))
	await get_tree().create_timer(1).timeout
	get_tree().paused = true
	tree_paused()
	await dialog.text_setter(0, true, 
		["バトル中は[color=green]緑[/color]の[color=green][b]SPDゲージ[/b][/color]が自動で\n" + 
		"溜まっていく。\nゲージが埋まると行動可能になるぞ！",
		"(このチュートリアルでは相手の\n[color=green][b]SPDゲージ[/b][/color]は溜まりません。)"])
	get_tree().paused = false
	tree_paused()

## プレイヤー行動可能時に流れるメッセージ設定
func _on_player_ready() -> void:
	back_disabled = true
	$button/main/Action.disabled = true
	$button/main/Item.disabled = true
	$button/main/Status.disabled = true
	arrow_mark_setter(100, "red", 90, Vector2(790, 660))
	await dialog.text_setter(0, true, [
		"%s が行動可能になった。\n%s は[color=aqua]MP[/color]が[color=aqua]%d[/color]回復した！" % 
		[player_monster.monster.name, player_monster.monster.name, player_monster.monster.supplyMP] + 
		"\n[color=yellow]%s は指示を待っている...[/color]" % player_monster.monster.name, 
		"[color=aqua]青[/color]の[color=aqua][b]MPゲージ[/b][/color]は、モンスターが行動可能\n" + 
		"になるたびに[color=aqua][b]supplyMP[/b][/color]の値だけ回復！\n" + 
		"バトルは[color=aqua][b]maxMP[/b][/color]の20%から始まるぞ。"])
	
	arrow_mark_setter(150, "red", 0, Vector2(665, 640))
	$button/main/Status.disabled = false
	dialog.text_setter(0, false, [
		"それでは、このモンスターの[b]ステータス[/b]\nを確認してみよう！モンスターは、\n" + 
		"８つのステータスを持っているぞ！",
		"[color=yellow]Player Statusボタンを選び、\n味方モンスターのいずれかをクリック[/color]"])
	await $button.status_paging
	await dialog.text_setter(0, true, [
		"[color=coral][b]HP[/b][/color]: モンスターの体力。ダメージを\n" + 
		"受けると減っていき、０になると\n[color=red]行動不能[/color]になってしまう。",
		"[color=aqua][b]MP[/b][/color]: モンスターの持つ魔力。\n一部の技を使うときに必要になる。\n" + 
		"そして[color=aqua]MP[/color]には[color=yellow]２つのパラメータ[/color]がある。", 
		"[color=aqua][b]supplyMP[/b][/color]:1ターンで回復する[color=aqua]MP[/color]の量。\n" + 
		"[color=aqua][b]maxMP[/b][/color]:[color=aqua]MP[/color]をため込める量の限界。\n" + 
		"バトルは[color=aqua]maxMP[/color]の20%の状態で始まる。", 
		"[color=green][b]SPD[/b][/color]:モンスターの素早さ。\nこの値が大きければ大きいほど、\n" + 
		"[color=green]SPDゲージ[/color]が溜まる速度が上がる。", 
		"[color=red][b]ATK[/b][/color]:モンスターの物理攻撃力。\n" + 
		"[color=light_blue][b]DEF[/b][/color]:モンスターの物理防御力。\n" + 
		"[color=red]物理技[/color]は、このステータスが使われる。", 
		"[color=dodger_blue][b]MAG[/b][/color]:モンスターの魔法攻撃力。\n" + 
		"[color=purple][b]RES[/b][/color]:モンスターの魔法防御力。\n" + 
		"[color=dodger_blue]魔法技[/color]は、このステータスが使われる。", 
		"バトル中はいつでも敵と味方の\nステータスを確認できるので、\n有効活用して戦おう！"])
	back_disabled = false
	$button/戻る.disabled = false
	arrow_mark_setter(150, "red", 0, Vector2(45, 775))
	dialog.text_setter(0, false, [
		"それでは、敵を攻撃してみよう！\n[color=yellow]戻るボタンを2回押してから、\n" + 
		"Actionボタンをクリック！[/color]"])
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
	arrow_mark_hide()
	await dialog.text_setter(0, true, [
		"モンスターは[b]事前に設定された確率[/b]で、\n技の候補を選び出す！" + 
		"（チュートリアル\nでは、選ばれる技は固定です）", 
		"４つの技から１つを選んで攻撃しよう！\nただし、一度候補に選ばれた技は\n" + 
		"[b]攻撃で使うまで残り続ける[/b]ぞ。"])
	arrow_mark_setter(150, "red", 0, Vector2(248, 640))
	$button/action.get_child(0).disabled = false
	dialog.text_setter(0, false, [
		"左のアイコンは技の属性を表している。\n" + 
		"「体当たり」は[img=50]res://image/element/無属性.PNG[/img]無属性だ。\n" + 
		"１番上の「体当たり」を選んでみよう！"])
	
