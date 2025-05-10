extends TextureProgressBar

var spd_percent = 0

signal help_mp
signal help_command

func _process(delta):
	if $".".value < 1000:
		$".".value += 300 * delta
		spd_percent = int($".".value / 10)
		call("text_update")
	elif $".".value == 1000:
		set_process(false)
		for button in $"../help_command".get_children():
			button.disabled = false
		help_mp.emit()
		help_command.emit()

func text_update():
	$spd_text.text = "[color=green][b]SPD[/b]   %3d%%[/color]" % spd_percent 

func _on_help_command_help_spd():
	$".".value = 0
	set_process(true)
