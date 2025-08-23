extends Panel

@onready var background := $background
@onready var name_label := $name
@onready var target_label := $target
@onready var chance_label := $chance
@onready var power_label := $power

var ability: Ability

func _ready() -> void:
	background.texture = background.texture.duplicate(true)
	var gradient: Gradient = background.texture.gradient
	var power_text: String = ""
	if ability is AbilityEffect: # 状態異常
		pass # 未実装
	
	elif ability is AbilityBuff: # バフ
		gradient.colors = [Color.WHITE, Color.DARK_RED]
		power_label.text = "[color=red]バフ継続ターン数[/color]:%d" % ability.turn
	
	elif ability is AbilityDebuff: # デバフ
		gradient.colors = [Color.WHITE, Color.DARK_BLUE]
		power_label.text = "[color=dodger_blue]デバフ継続ターン数[/color]:%d" % ability.turn
	
	elif ability is AbilityHealing: # ゲージ回復
		match ability.status:
			AbilityHealing.Status.HP:
				gradient.colors = [Color.WHITE, Color.YELLOW_GREEN]
				power_text = "[color=yellow_green]HP回復量[/color]:%s"
			
			AbilityHealing.Status.MP:
				gradient.colors = [Color.WHITE, Color.AQUA]
				power_text = "[color=aqua]MP回復量[/color]:%s"
			
			AbilityHealing.Status.SPD:
				gradient.colors = [Color.WHITE, Color.GREEN]
				power_text = "[color=green]SPD増加量[/color]:%s"
		
		match ability.amount_type:
			AbilityHealing.AmountType.定数:
				power_label.text = power_text % "%d" % ability.amount
			
			AbilityHealing.AmountType.MAG:
				power_label.text = power_text % "MAGの%d%%" % (ability.amount * 100)
	
	else:
		gradient.colors = [Color.BLACK, Color.BLACK]
	
	fit_name_label_size(ability.bbcode_name)
	name_label.text = "[b]%s[/b]" % ability.bbcode_name
	
	match ability.target:
		Ability.Target.連動: # TODO 今後はactionのものと連動して書き換えるようにする
			target_label.text = "[color=yellow]対象[/color]:　 連動 　"
		
		Ability.Target.敵単体:
			target_label.text = "[color=yellow]対象[/color]:　敵単体　"
		
		Ability.Target.敵全体:
			target_label.text = "[color=yellow]対象[/color]:　敵全体　"
		
		Ability.Target.味方単体:
			target_label.text = "[color=yellow]対象[/color]: 味方単体 "
		
		Ability.Target.味方全体:
			target_label.text = "[color=yellow]対象[/color]: 味方全体 "
		
		Ability.Target.自分:
			target_label.text = "[color=yellow]対象[/color]:　 自分 　"
		
		_:
			target_label.text = "[center][color=red][b]ERROR[/b][/color][/center]"
	
	chance_label.text = "[color=green]確率[/color]:%3d%%" % ability.chance


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
