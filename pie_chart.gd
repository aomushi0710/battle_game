class_name PieChart
extends Control

signal draw_ended ## _draw関数終了後に発行されます

const elements_font_size: int = 30 ## フォントサイズ
const border_width: float = 2 ## ボーダーの太さ

var actions: Array[Action]
var chances: Array[int]
var color_list: Array[Color] = [Color.BLACK, Color.BLACK, Color.BLACK, Color.BLACK] ## これまでの色の履歴を保持

var border_color: Color ## ボーダーの色
var elements_text_color: Color = Color.WHITE ## フォント色
var font : Font = ThemeDB.fallback_font ## 元のフォント

## グラフの切れ端を描く関数
func draw_slice(center: Vector2, radius: float, angle_from: float, angle_to: float, color: Color) -> void:
	var nb_points: int = round((angle_to-angle_from)/5)
	var outer_arc: Array[Vector2] = []
	var inner_arc: Array[Vector2] = []

	
	inner_arc.push_back(center)
	
	for i in range(nb_points + 1):
		var angle_point: float = deg_to_rad(angle_from + i * (angle_to - angle_from) / nb_points)
		outer_arc.push_back(center + Vector2(cos(angle_point), sin(angle_point)) * radius)
	
	draw_colored_polygon(inner_arc + outer_arc, color)


func _draw() -> void:
	for child in get_children(): # label削除
		child.queue_free()
	
	var sum_chance: int = 0 ## それまでの合計の確率
	for i: int in chances:
		sum_chance += i
	if sum_chance == 100:
		border_color = Color.GOLD
	else:
		border_color = Color.WHITE
	color_list.clear()
	
	var radius: float = size.x / 4.0
	var center: Vector2 = size / 2.0
	var previous_angle: float = 270 ## 円グラフの開始地点が上となるように
	var separation_lines_parameters: Array = []
	for i in len(actions): # 技の数だけ繰り返す
		if chances[i] <= 0: # 0%なら黒を入れてスキップ
			color_list.append(Color.BLACK)
			continue
		
		## 被らないようにcolor_checker関数を通してから、使用する色を取得[br]
		## (複数属性あるものも、とりあえず1つ目の属性のみにする)
		var color: Color =  color_checker(actions[i].element[0].color)
		var current_angle: float = 360.0 * (chances[i] / 100.0) ## その技の角度
		var angle: float = deg_to_rad(current_angle + previous_angle) ## 合計角度
		var mid_angle: float = angle - deg_to_rad(current_angle / 2.0) ## 角度の中心
		var angle_point := Vector2(cos(mid_angle), sin(mid_angle)) * radius
		var text: String = "%s\n[b]%d%%[/b]" % [actions[i].name, chances[i]] ## 技の名前と確率
		## フォントサイズと技名の長さから計算
		var label_size := Vector2(len(actions[i].name) * elements_font_size * 1.1, elements_font_size * 3.2)
		var label_position := center - (label_size / 2) + (angle_point / 1.2) ## labelの位置
		
		var style := StyleBoxFlat.new() ## label背景用styleboxを生成
		style.bg_color = color
		style.bg_color.a = 0.5
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color.BLACK
		style.expand_margin_left = 6
		style.expand_margin_top = 2
		style.expand_margin_right = 6
		style.expand_margin_bottom = 2
		var label := RichTextLabel.new() ## グラフ上に重ねて表示するlabel
		label.bbcode_enabled = true
		label.text = "[font_size=30]%s[/font_size]" % text
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.clip_contents = false
		label.size = label_size
		label.position = label_position
		label.add_theme_stylebox_override("normal", style)
		add_child(label)
		
		draw_slice(center, radius, previous_angle, previous_angle + current_angle, color)
		separation_lines_parameters.append([
			center,
			center + Vector2(cos(angle), sin(angle)) * radius,
			border_color, 
			border_width,
			true
		])
		previous_angle += current_angle
		color_list.append(color)
	
	for params in separation_lines_parameters:
		draw_line.callv(params)
	
	draw_arc(center, radius, 0, TAU, 64, border_color, border_width, true) # 外枠線
	draw_ended.emit()

## 既に使用された色のリストcolor_listと、追加したい色colorを引数とする。[br]
## color_listの中に、colorと重複する色が含まれていた場合に、色をずらして返す関数
func color_checker(color: Color) -> Color:
	for c: Color in color_list:
		if color.is_equal_approx(c): # もし色が一緒なら少し色をずらす
			color.v -= 0.15
			if color.v < 0: # オーバーフロー防止
				color.v += 1
	return color
