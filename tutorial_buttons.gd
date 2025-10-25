extends "battle_buttons.gd"

func battle_finished() -> void:
	super()
	Global.player_deck = Global.current_deck.duplicate() # 避難してたデッキを戻す
