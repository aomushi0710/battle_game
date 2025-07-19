extends "battle_buttons.gd"

func battle_finished() -> void:
	super()
	Global.deck1 = Global.current_deck.duplicate() # 避難してたデッキを戻す
