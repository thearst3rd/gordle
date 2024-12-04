extends Control


var main_licenses := [
	["Godot Engine", Engine.get_license_text()],
]

@onready var quit_button: Button = %QuitButton
@onready var credits: ColorRect = %Credits

@onready var random_buttons = [%Random3, %Random4, %Random6, %Random7, %Random8]

@onready var credits_label: RichTextLabel = %CreditsRichTextLabel


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


var credits_added := false

func _on_CreditsButton_pressed() -> void:
	if not credits_added:
		credits_label.append_text(generate_license_bbcode_text())
		credits_added = true
	credits.show()


func _on_QuitButton_pressed() -> void:
	get_tree().get_root().propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)


func _on_CreditsBackButton_pressed() -> void:
	credits.hide()


func generate_license_bbcode_text() -> String:
	var text := "[center][font_size=36]Licenses[/font_size][/center]"

	for license: Array in main_licenses:
		text += "\n\n[center][font_size=20]" + license[0] + "[/font_size][/center]\n\n"
		text += "[font_size=13]" + license[1].strip_edges() + "[/font_size]"

	text += "\n\n[center][font_size=26]All Third-Party Licenses[/font_size][/center]"

	# These engine license/copyright functions are not incredibly obvious how to usefully extract information from.
	# This is similar to how it's done in the "About Godot" -> "Third-party Licenses" -> "All Components" screen
	for info in Engine.get_copyright_info():
		text += "\n\n[center][font_size=18]" + info.name + "[/font_size][/center]\n[font_size=14]"
		for part: Dictionary in info.parts:
			for copyright: String in part.copyright:
				text += "\n(c) " + copyright
			text += "\nLicense: " + part.license
		text += "[/font_size]"

	var engine_licenses := Engine.get_license_info()
	for license: String in engine_licenses:
		text += "\n\n[center][font_size=18]" + license + "[/font_size][/center]\n\n"
		text += "[font_size=12]" + engine_licenses[license] + "[/font_size]"

	return text
