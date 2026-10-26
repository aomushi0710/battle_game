extends CanvasLayer

const DEFAULT_DURATION: float = 0.5 ## 秒数指定がない場合のアニメーション秒数

var _progress: Array = [] ## ロード率取得用の配列 INFO Godotの仕様上、配列の最初の要素に進捗率が返されるため

@onready var _fade := %Fade as ColorRect ## アニメーションに使用される黒の矩形
@onready var _input_blocker := %InputBlocker as Control ## シーン遷移中のマウス入力を止めるための何も描画されていないUI


func _ready() -> void:
	set_process_input(false)

## シーン遷移中のマウス以外の入力は全てここで無効化されます
func _input(_event: InputEvent) -> void:
	get_viewport().set_input_as_handled()

## 全ての入力を無効化します
func block_input() -> void:
	# ボタンなどのフォーカスを解除
	var viewport: Viewport = get_viewport()
	if viewport.gui_get_focus_owner():
		viewport.gui_release_focus()
	
	set_process_input(true)
	_input_blocker.visible = true

## 全ての入力を有効化します
func unblock_input() -> void:
	set_process_input(false)
	_input_blocker.visible = false

# 以下関数内の処理に生成AIのコードを使用しています
## 遷移先シーンのパスを引数として、マルチスレッドでロードを行いシーンを切り替えます[br]
## フェードアウトとフェードインのアニメーションは[Callable]で指定できます
func change_scene(path: String, fade_out_func: Callable = fade_out_transparent, fade_in_func: Callable = fade_in_transparent) -> void:
	block_input()
	
	var new_packed: PackedScene = await _load_and_fade_out(path, fade_out_func)
	if new_packed:
		var tree: SceneTree = get_tree()
		var old_scene: Node = tree.current_scene
		var new_scene: Node = new_packed.instantiate()
		
		tree.root.add_child(new_scene)
		tree.current_scene = new_scene
		
		if fade_out_func == no_fade_out:
			await tree.process_frame
		
		if is_instance_valid(old_scene):
			tree.root.remove_child(old_scene)
			old_scene.queue_free()
	
	await fade_in_func.call()
	
	unblock_input()

# 以下関数内の処理に生成AIのコードを使用しています
## 遷移先シーンのパスとそのシーンが発行するシグナル名を引数として、現在のシーンの兄弟にサブシーンを追加して切り替えます。[br]
## サブシーンから指定したシグナルが発行されると、元のシーンに戻りサブシーンを破棄します。その時、シグナルの返り値をそのまま返します。[br]
## メインシーンからサブシーン、サブシーンからメインシーンに遷移する時の、フェードアウトとフェードインのアニメーションは[Callable]で指定できます。
func call_sub_scene(
	path: String,
	finish_signal_name: StringName,
	enter_fade_out_func: Callable = fade_out_transparent,
	enter_fade_in_func: Callable = fade_in_transparent,
	exit_fade_out_func: Callable = fade_out_transparent,
	exit_fade_in_func: Callable = fade_in_transparent
) -> Variant:
	block_input()
	
	var sub_packed_scene: PackedScene = await _load_and_fade_out(path, enter_fade_out_func)
	if not sub_packed_scene:
		await enter_fade_in_func.call()
		return null
	
	var main_scene: Node = get_tree().current_scene
	var previous_process_mode: ProcessMode = main_scene.process_mode
	main_scene.process_mode = Node.PROCESS_MODE_DISABLED
	if main_scene is CanvasItem or main_scene is Node3D:
		main_scene.visible = false
	
	# 親の visible が効かない CanvasLayer のうち、現在表示中のものだけを非表示にして記録
	var active_layers: Array[CanvasLayer] = []
	for child: Node in main_scene.find_children("*", "CanvasLayer"):
		var layer: CanvasLayer = child as CanvasLayer
		if layer and layer.visible:
			layer.visible = false
			active_layers.append(layer)
			
	# 現在有効な Camera2D を記録してオフにし、画面の描画位置を原点(0, 0)にリセット
	var viewport: Viewport = get_viewport()
	var prev_cam_2d: Camera2D = viewport.get_camera_2d()
	if prev_cam_2d:
		prev_cam_2d.enabled = false
	viewport.canvas_transform = Transform2D.IDENTITY
	
	var sub_scene: Node = sub_packed_scene.instantiate()
	get_tree().root.add_child(sub_scene)
	get_tree().current_scene = sub_scene
	
	await enter_fade_in_func.call()
	
	unblock_input()
	
	var result: Variant = null ## シグナルの返り値
	if sub_scene.has_signal(finish_signal_name):
		result = await Signal(sub_scene, finish_signal_name)
	else:
		push_error("Signal not found in sub scene: " + String(finish_signal_name))
	
	block_input()
	
	await exit_fade_out_func.call()
	
	get_tree().root.remove_child(sub_scene)
	sub_scene.queue_free()
	
	if main_scene is CanvasItem or main_scene is Node3D:
		main_scene.visible = true
	main_scene.process_mode = previous_process_mode
	
	# 隠していた CanvasLayer だけを表示に戻す
	for layer: CanvasLayer in active_layers:
		layer.visible = true
		
	# 元の Camera2D を再び有効化してフィールドの座標へ戻す
	if prev_cam_2d:
		prev_cam_2d.enabled = true
	
	get_tree().current_scene = main_scene
	
	await exit_fade_in_func.call()
	
	unblock_input()
	
	return result

## アニメーションを再生せずにフェードインします
func no_fade_in() -> void:
	await get_tree().process_frame
	_fade.hide()
	_fade.color.a = 1.0

## アニメーションを再生せずにフェードインします
func no_fade_out() -> void:
	_fade.color.a = 0.0
	_fade.show()

## 画面を覆う黒色の[ColorRect]を縮小させてフェードインします
func fade_in_zoom(duration: float = DEFAULT_DURATION) -> void:
	_fade.color.a = 1.0
	
	_fade.show()
	var tween: Tween = _fade.create_tween()
	tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(_fade, "scale", Vector2.ZERO, duration).from(Vector2.ONE)
	await tween.finished
	_fade.hide()
	
## 画面中央から黒色の[ColorRect]を拡大させてフェードアウトします
func fade_out_zoom(duration: float = DEFAULT_DURATION) -> void:
	_fade.color.a = 1.0
	
	_fade.show()
	var tween: Tween = _fade.create_tween()
	tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(_fade, "scale", Vector2.ONE, duration).from(Vector2.ZERO)
	await tween.finished

## 画面を覆う黒色の[ColorRect]を透明化させてフェードインします
func fade_in_transparent(duration: float = DEFAULT_DURATION) -> void:
	_fade.scale = Vector2.ONE
	
	_fade.show()
	var tween: Tween = _fade.create_tween()
	tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(_fade, "color:a", 0, duration).from(1.0)
	await tween.finished
	_fade.hide()

## 画面を覆う透明の[ColorRect]を非透明化させてフェードアウトします
func fade_out_transparent(duration: float = DEFAULT_DURATION) -> void:
	_fade.scale = Vector2.ONE
	
	_fade.show()
	var tween: Tween = _fade.create_tween()
	tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(_fade, "color:a", 1, duration).from(0.0)
	await tween.finished

# 以下関数内の処理に生成AIのコードを使用しています
## 指定したパスの[PackedScene]をマルチスレッドでロードしながら、フェードアウトアニメーションを再生します[br]
## ロードが完了すると[PackedScene]を返します
func _load_and_fade_out(path: String, fade_out_func: Callable) -> PackedScene:
	var err: Error = ResourceLoader.load_threaded_request(path)
	if err != OK:
		push_error("Failed to request scene load: " + path)
		return
	
	await fade_out_func.call()
	
	var status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(path, _progress) ## スレッドのロード状態
	while status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame
		status = ResourceLoader.load_threaded_get_status(path, _progress)
	
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		return ResourceLoader.load_threaded_get(path) as PackedScene
	
	push_error("Failed to load scene: " + path)
	return null
