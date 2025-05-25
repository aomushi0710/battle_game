extends TextureButton

var monster: Monster
var action: Action
	

func _on_button_up() -> void:
	monster = Global.monster_data[1][2] # テスト用
	
	$name/element.selected(monster)
	$name/name.text = "[b][i]%s[/i][/b]" % monster.name
