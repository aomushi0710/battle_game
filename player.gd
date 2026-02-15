extends CharacterBody2D

@export var speed = 256
@export var canvas_layer: CanvasLayer
@export var world: Node2D
@export var camera: Camera2D

@onready var dialog := $"../../CanvasLayer/dialog"
@onready var interaction_area := $InteractionArea ## プレイヤーの前方にある検知エリア
@onready var terrain := $"../tilemap/terrain"
@onready var tile_size: int = terrain.tile_set.tile_size.x ## タイル1マスの大きさ

var is_moving: bool = false ## 移動中かどうかのフラグ
var object_interactable ## 触れられるオブジェクトの参照
var can_move: bool = true ## プレイヤーが移動可能かどうかのフラグ
var is_dialog_active: bool = false ## ダイアログが開かれているかどうかのフラグ
var dialog_just_closed: bool = false ## ダイアログが閉じられるまで入力を止めるフラグ


func _physics_process(delta):
	if not can_move:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	var direction: Vector2 = Vector2.ZERO ## 方向ベクトル
	var horizontal_input: int = Input.get_axis("left", "right") ## 左右のみ
	if horizontal_input != 0: # 左右入力があった時はそのまま
		direction.x = horizontal_input
	else: # 左右入力がなかった時は上下入力を許可する
		direction.y = Input.get_axis("up", "down")
	velocity = direction * speed
	move_and_slide()
	
	if direction == Vector2.ZERO:
		is_moving = false
	else:
		is_moving = true
	
	# プレイヤーの方向に応じて、検知エリアの向きを変える
	if direction != Vector2.ZERO:
		interaction_area.position = direction * tile_size


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("interact"):
		var areas = interaction_area.get_overlapping_areas()
		if not areas.is_empty():
			var signboard = areas[0]
			
			# 看板の処理
			if signboard is SignBoard:
				# INFO ダイアログを閉じると同時に開く判定になってしまうので、
				# フラグを利用して処理を無理やり止めている
				if dialog_just_closed: # ダイアログが閉じられる時各種フラグを戻す
					dialog_just_closed = false
					is_dialog_active = false
					return
				if is_dialog_active: # 既にダイアログが開かれているなら何もしない
					return
				
				
				
				await dialog.dialog_manager(signboard.dialog_datas)

# アイテムを取得する処理
func pickup():
	if object_interactable.is_pickable:
		object_interactable.queue_free()
		object_interactable = null

## ダイアログが開かれた時、各種フラグを立てる関数
func _on_dialog_dialog_opened() -> void:
	can_move = false
	is_dialog_active = true

## ダイアログが閉じられた時、各種フラグを立てる関数
func _on_dialog_dialog_closed() -> void:
	can_move = true
	dialog_just_closed = true

## ダイアログからバトルが開始した時、バトルと無関係なノードを隠し、カメラ機能もオフにする関数
func _on_dialog_battle_started() -> void:
	canvas_layer.hide()
	world.hide()
	camera.enabled = false

## ダイアログからのバトルが終了した時、バトル前の状態に戻す関数
func _on_dialog_battle_finished() -> void:
	canvas_layer.show()
	world.show()
	camera.enabled = true
