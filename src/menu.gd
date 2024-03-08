extends Control


@onready var quit_button: Button = %QuitButton
@onready var credits: ColorRect = %Credits


func _ready() -> void:
	if OS.has_feature("web"):
		quit_button.hide()


func _on_DailyButton_pressed() -> void:
	Global.game_mode = Global.GameMode.DAILY
	var error := get_tree().change_scene_to_file("res://src/main.tscn")
	assert(not error)


func _on_RandomButton_pressed() -> void:
	Global.game_mode = Global.GameMode.RANDOM
	var error := get_tree().change_scene_to_file("res://src/main.tscn")
	assert(not error)


func _on_custom_button_pressed() -> void:
	var error := get_tree().change_scene_to_file("res://src/custom_setup.tscn")
	assert(not error)


func _on_CreditsButton_pressed() -> void:
	credits.show()


func _on_QuitButton_pressed() -> void:
	get_tree().get_root().propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)


func _on_CreditsBackButton_pressed() -> void:
	credits.hide()
