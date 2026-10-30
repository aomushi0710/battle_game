extends "res://src/game/new_battle.gd"

const SCORE_PENALTY_PER_PLAYER_TURN: int = 20 ## 味方モンスターが1ターン行動するごとに減少するスコア[br]ただし、無限にスコアを稼がれないために、モンスターが1ターンで回復するMPを全て消費して[member SCORE_BONUS_PER_USED_MP]を利用してペナルティを相殺しきれない値に調節する必要があります
const SCORE_PENALTY_PER_ALLY_DEATH: int = 1000
const SCORE_BONUS_PER_USED_MP: int = 1 ## 味方モンスターが使用したMPごとに増加するスコア[br]ただし、無限にスコアを稼がれないために、モンスターが1ターンで回復するMPを全て消費して[member SCORE_PENALTY_PER_PLAYER_TURN]のペナルティを相殺しきれない値に調節する必要があります
const SCORE_BONUS_EVOLUTION: int = 100

const SCORE_BONUS_PER_HP_PERCENT: int = 10
const SCORE_BONUS_PER_UNUSED_ITEM: int = 1000

var _tween_score: Tween
var _tween_score_log: Tween

var score: int:
	set(value):
		score = value
		
		if _tween_score and _tween_score.is_running():
			_tween_score.kill()
		
		_tween_score = create_tween()
		_tween_score.tween_property(self, ^"_displayed_score", score, 0.5)

var _displayed_score: int = 0: ## 現在[member _score_label]に表示されているスコア
	set(value):
		_displayed_score = value
		_score_label.text = "SCORE: %06d" % _displayed_score
		

@onready var _score_label := %Score as RichTextLabel
@onready var _score_log_label := %ScoreLog as RichTextLabel


func _ready() -> void:
	super()
	score = Global.enemy_deck.base_score


func monster_setup() -> void:
	super()
	for monster in player_deck:
		monster.mp_used.connect(_on_battle_monster_mp_used)
		monster.evolved.connect(_on_battle_monster_evolved)
		monster.died.connect(_on_battle_monster_died)


func turn_end(monster: BattleMonster) -> void:
	super(monster)
	
	if monster.is_player:
		score -= SCORE_PENALTY_PER_PLAYER_TURN
		_score_log_animation("ターン経過", -SCORE_PENALTY_PER_PLAYER_TURN)


func battle_finish(is_victory: bool) -> void:
	super(is_victory)
	if is_victory:
		var tween: Tween = _score_label.create_tween()
		tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)
		tween.tween_property(_score_label, ^"position:y", Global.viewport_height/2 - _score_label.size.y/2, 0.5)
		await tween.finished
		
		for monster in player_deck:
			var bonus_score := int(float(monster.data.HP) / monster.data.maxHP * 100 * SCORE_BONUS_PER_HP_PERCENT)
			score += bonus_score
			await _score_log_animation(monster.data.get_monsterform().name + "の残りHP", bonus_score, 1.0)
		
		for button in buttons.item_buttons.get_children() as Array[ItemButton]:
			if not button.is_used:
				score += SCORE_BONUS_PER_UNUSED_ITEM
				await _score_log_animation(button.item.name + "未使用", SCORE_BONUS_PER_UNUSED_ITEM, 1.0)
		
		tween = _score_label.create_tween().set_parallel()
		tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)
		tween.tween_property(_score_label, ^"scale", Vector2(2.0, 2.0), 0.5)
		tween.tween_property(_score_label, ^"modulate:b", 0.0, 0.5)
		
	else:
		_score_log_animation("敗北", -score)
		score = 0

## スコア増減の内約を一定時間だけ表示し、消失させるアニメーションを再生します[br][param interval]を指定すると、内約の表示時間を変更できます
func _score_log_animation(text: String, amount: int, interval: float = 3.0) -> void:
	if _tween_score_log and _tween_score_log.is_running():
		_tween_score_log.kill()
	
	if amount > 0:
		_score_log_label.text = "%s:[color=red]%+7d[/color]" % [text, amount]
	else:
		_score_log_label.text = "%s:[color=dodger_blue]%+7d[/color]" % [text, amount]
	
	_score_log_label.position.y = _score_label.position.y + 50.0
	_score_log_label.modulate.a = 1.0
	_score_log_label.show()
	
	_tween_score_log = _score_log_label.create_tween()
	_tween_score_log.tween_interval(interval)
	_tween_score_log.tween_property(_score_log_label, ^"position:y", _score_label.position.y, 0.5)
	_tween_score_log.set_parallel().tween_property(_score_log_label, ^"modulate:a", 0.0, 0.5)
	await _tween_score_log.finished


func _on_battle_monster_evolved() -> void:
	score += SCORE_BONUS_EVOLUTION
	_score_log_animation("進化", SCORE_BONUS_EVOLUTION)


func _on_battle_monster_died() -> void:
	score -= SCORE_PENALTY_PER_ALLY_DEATH
	_score_log_animation("気絶", -SCORE_PENALTY_PER_ALLY_DEATH)


func _on_battle_monster_mp_used(amount: int) -> void:
	score += SCORE_BONUS_PER_USED_MP * amount
	_score_log_animation("MP消費", SCORE_BONUS_PER_USED_MP * amount)
