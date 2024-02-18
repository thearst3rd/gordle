extends Control


func _ready() -> void:
	if OS.get_name() == "HTML5":
		$C/V/V2/QuitButton.hide()


func _on_DailyButton_pressed() -> void:
	Global.daily_mode = true
	var error := get_tree().change_scene_to_file("res://src/main.tscn")
	assert(not error)


func _on_RandomButton_pressed() -> void:
	Global.daily_mode = false
	var error := get_tree().change_scene_to_file("res://src/main.tscn")
	assert(not error)


func _on_CreditsButton_pressed() -> void:
	$Credits.show()


func _on_QuitButton_pressed() -> void:
	get_tree().get_root().propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)


func _on_CreditsBackButton_pressed() -> void:
	$Credits.hide()
