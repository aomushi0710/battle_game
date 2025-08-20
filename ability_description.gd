extends Panel

@onready var background := $background
@onready var name_label := $name
@onready var range_label := $range
@onready var chance_label := $chance
@onready var power_label := $power

var ability: Ability

func _ready() -> void:
	ability = load("res://ability/ATK_DOWN.tres")
	background.texture = background.texture.duplicate(true)
	var gradient: Gradient = background.texture.gradient
	gradient.colors = [Color.WHITE]
	match ability.test
	
	fit_name_label_size(ability.bbcode_name)
	name_label.text = "[b]%s[/b]" % ability.bbcode_name
	


func fit_name_label_size(text: String) -> void:
	var font: Font = name_label.get_theme_font("bold_font")
	for i: int in range(80, 0, -1): # 最大サイズ80
		var text_size = font.get_string_size(
			Global.strip_bbcode(text), # bbcodeタグを排除
			HORIZONTAL_ALIGNMENT_CENTER, 
			-1, 
			i)
		if text_size.x <= name_label.size.x and text_size.y <= name_label.size.y:
			name_label.add_theme_font_size_override("bold_font_size", i)
			break
