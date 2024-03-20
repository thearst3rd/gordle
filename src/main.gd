extends Control


const guess_count := 6

const Letter := preload("res://src/letter.tscn")

@export var color_incorrect: Color = Color()
@export var color_misplaced: Color = Color()
@export var color_correct: Color = Color()

# An array of arrays of the letter nodes
var letters := []
var keyboard_buttons := {}
var letter_count := 5

var target_word: String
var current_guess: int
var ended: bool
var won: bool
var input_guess: String

@onready var title: Label = %Title
@onready var subtitle: Label = %Subtitle
@onready var letter_grid: GridContainer = %LetterGrid
@onready var info_text: Label = %InfoText

@onready var keyboard_vbox: VBoxContainer = %KeyboardVBox
@onready var guess_button: Button = %GuessButton
@onready var backspace_button: Button = %ButtonBksp
@onready var share_button: Button = %ShareButton

@onready var info_text_animation: AnimationPlayer = %InfoTextAnimation
@onready var copied_text_animation: AnimationPlayer = %CopiedTextAnimation

@onready var error_text_color_default := info_text.label_settings.font_color


func _ready() -> void:
	if Global.game_mode != Global.GameMode.CUSTOM:
		Global.custom_word = ""
		Global.custom_date_str = ""

	if not Global.custom_word.is_empty():
		target_word = Global.custom_word
		title.text = "Custom " + title.text

		if Global.custom_date_str:
			subtitle.text = Global.custom_date_str
		else:
			subtitle.text = Global.encode_word(target_word)
	else:
		var random_seed = null
		if Global.game_mode == Global.GameMode.DAILY:
			var current_time := Time.get_date_string_from_system(true)
			random_seed = Time.get_unix_time_from_datetime_string(current_time)

			title.text = "Daily " + title.text
			subtitle.text = current_time
		elif Global.game_mode == Global.GameMode.RANDOM:
			title.text = "Random " + title.text

		target_word = Global.generate_word(letter_count, random_seed)

		if Global.game_mode != Global.GameMode.DAILY:
			subtitle.text = Global.encode_word(target_word)

	letter_count = target_word.length()
	letter_grid.columns = letter_count
	for _i in range(guess_count):
		var letter_array := []
		for _j in range(letter_count):
			var letter := Letter.instantiate()
			letter_array.append(letter)
			letter_grid.add_child(letter)
		letters.append(letter_array)

	current_guess = 0
	ended = false
	won = false

	for i in range(0, 26):
		var letter := char("A".unicode_at(0) + i)
		var keyboard_button: Button = keyboard_vbox.find_child("Button" + letter)
		keyboard_buttons[letter] = keyboard_button
		var error := keyboard_button.connect("pressed", Callable(self, "type_letter").bind(letter))
		assert(not error)

	share_button.hide()


func type_letter(letter: String) -> void:
	if ended or input_guess.length() >= letter_count:
		return
	var index := input_guess.length()
	letter = letter[0]
	input_guess += letter
	var letter_instance := letters[current_guess][index] as ColorRect
	letter_instance.get_node("Label").text = letter


func backspace() -> void:
	if ended or input_guess.length() <= 0:
		return
	input_guess = input_guess.substr(0, input_guess.length() - 1)
	var index := input_guess.length()
	var letter_instance := letters[current_guess][index] as ColorRect
	letter_instance.get_node("Label").text = ""


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_pressed():
		var keycode = event.get_keycode()
		if keycode >= KEY_A and keycode <= KEY_Z:
			var letter := OS.get_keycode_string(keycode)
			type_letter(letter)
			get_viewport().set_input_as_handled()
		elif keycode == KEY_BACKSPACE:
			backspace()
			get_viewport().set_input_as_handled()
		elif keycode == KEY_ENTER:
			guess_entered()
			get_viewport().set_input_as_handled()


func _on_GuessButton_pressed() -> void:
	guess_entered()


func guess_entered() -> void:
	if current_guess >= guess_count:
		return
	input_guess = input_guess.to_upper()
	if input_guess.length() != letter_count:
		show_error("Word must be %d characters." % [letter_count])
		return
	if not Global.is_valid_word(input_guess) and input_guess != target_word:
		show_error("Not a recognized word.")
		return

	var letters_remaining = []
	for letter in target_word:
		letters_remaining.append(letter)

	hide_info()

	# Mark all greens
	for i in range(letter_count):
		var guess_letter := input_guess[i]
		var target_letter := target_word[i]

		var letter_instance := letters[current_guess][i] as ColorRect
		letter_instance.get_node("Label").text = guess_letter
		if guess_letter == target_letter:
			letter_instance.color = color_correct
			keyboard_buttons[target_letter].modulate = color_correct
			# Remove that one letter from remaining letters (is there a function for this?)
			for j in range(letters_remaining.size()):
				if letters_remaining[j] == guess_letter:
					letters_remaining.remove_at(j)
					break

	# Mark all yellows (and grays)
	for i in range(letter_count):
		var letter_instance := letters[current_guess][i] as ColorRect
		if letter_instance.color == color_correct:
			# Ignore things that are already green
			continue
		var guess_letter := input_guess[i]
		var found := false
		for j in range(letters_remaining.size()):
			if letters_remaining[j] == guess_letter:
				found = true
				letters_remaining.remove_at(j)
				break
		if found:
			letter_instance.color = color_misplaced
			if keyboard_buttons[guess_letter].modulate != color_correct:
				keyboard_buttons[guess_letter].modulate = color_misplaced
		else:
			letter_instance.color = color_incorrect
			if keyboard_buttons[guess_letter].modulate not in [color_correct, color_misplaced]:
				keyboard_buttons[guess_letter].modulate = color_incorrect

	current_guess += 1

	if input_guess == target_word:
		ended = true
		won = true
	elif current_guess >= guess_count:
		ended = true
		won = false

	input_guess = ""

	if ended:
		guess_button.disabled = true
		for letter in keyboard_buttons:
			keyboard_buttons[letter].disabled = true
		backspace_button.disabled = true
		if won:
			show_info("Congrats! You won!", Color(0.4, 0.9, 0.6))
		else:
			show_info("Game Over. The word was %s" % target_word, error_text_color_default)
		share_button.show()


func show_error(text: String):
	info_text.text = text
	info_text.label_settings.font_color = error_text_color_default
	info_text_animation.stop()
	info_text_animation.play("ErrorMessage")
	info_text.show()


func show_info(text: String, color: Color):
	info_text_animation.stop()
	info_text.text = text
	info_text.label_settings.font_color = color
	info_text.show()


func hide_info():
	info_text_animation.stop()
	info_text.hide()


func _on_MenuButton_pressed() -> void:
	# TODO check if game is in progress and show confirmation popup
	var error := get_tree().change_scene_to_file("res://src/menu.tscn")
	assert(not error)


func _on_ButtonBksp_pressed() -> void:
	backspace()


func _on_share_button_pressed() -> void:
	var text := "%s %s\n" % [title.text, subtitle.text]
	if won:
		text += "%d/%d\n\n" % [current_guess, guess_count]
	elif ended:
		text += "X/%d\n\n" % [guess_count]
	else:
		# Can probably bail early but I might as allow it
		text += "?/%d\n\n" % [guess_count]

	for i in range(current_guess):
		for j in range(letter_count):
			var letter_instance := letters[i][j] as ColorRect
			if letter_instance.color.is_equal_approx(color_correct):
				text += "🟩"
			elif letter_instance.color.is_equal_approx(color_misplaced):
				text += "🟨"
			else:
				text += "⬛"
		text += "\n"

	text += "\nhttps://thearst3rd.com/games/gordle"
	DisplayServer.clipboard_set(text)
	copied_text_animation.stop()
	copied_text_animation.play("Copied")
