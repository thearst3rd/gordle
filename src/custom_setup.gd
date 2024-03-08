extends Control


@onready var future_label: Label = %FutureLabel

@onready var info_text: Label = %InfoText
@onready var info_text_animation: AnimationPlayer = %InfoTextAnimation
@onready var line_edit: LineEdit = %LineEdit



func _ready() -> void:
	if Global.allow_future:
		future_label.hide()
	line_edit.grab_focus()


func _on_back_button_pressed() -> void:
	var error := get_tree().change_scene_to_file("res://src/menu.tscn")
	assert(not error)


func _on_submit_button_pressed() -> void:
	var word := line_edit.text.strip_edges()
	var success := Global.parse_custom(word)
	if success:
		Global.game_mode = Global.GameMode.CUSTOM
		var error := get_tree().change_scene_to_file("res://src/main.tscn")
		assert(not error)
	else:
		show_error("Invalid word, code, or date")


func _on_line_edit_text_submitted(_new_text: String) -> void:
	_on_submit_button_pressed()


func show_error(text: String):
	info_text.text = text
	info_text_animation.stop()
	info_text_animation.play("ErrorMessage")
