extends Control


@onready var quit_button: Button = %QuitButton
@onready var credits: ColorRect = %Credits

@onready var random_buttons = [%Random3, %Random4, %Random6, %Random7, %Random8]


func _ready() -> void:
	if OS.has_feature("web"):
		quit_button.hide()

	for button in random_buttons:
		button.pressed.connect(start_random_game.bind(int(button.text[0])))


func start_random_game(length := -1) -> void:
	Global.game_mode = Global.GameMode.RANDOM
	Global.custom_word_length = length
	var error := get_tree().change_scene_to_file("res://src/main.tscn")
	assert(not error)


func _on_DailyButton_pressed() -> void:
	Global.game_mode = Global.GameMode.DAILY
	Global.custom_word_length = -1
	var error := get_tree().change_scene_to_file("res://src/main.tscn")
	assert(not error)


func _on_RandomButton_pressed() -> void:
	start_random_game()


func _on_custom_button_pressed() -> void:
	var error := get_tree().change_scene_to_file("res://src/custom_setup.tscn")
	assert(not error)


func _on_CreditsButton_pressed() -> void:
	credits.show()


func _on_QuitButton_pressed() -> void:
	get_tree().get_root().propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)


func _on_CreditsBackButton_pressed() -> void:
	credits.hide()
