extends Control


const letter_count := 5
const guess_count := 6

const Letter = preload("res://src/Letter.tscn")

export var color_incorrect: Color = Color()
export var color_misplaced: Color = Color()
export var color_correct: Color = Color()

# An array of arrays of the letter nodes
var letters := []

var target_word: String
var current_guess: int

onready var error_text_color_default = $C/V/V/ErrorText.get("custom_colors/font_color")

func _ready() -> void:
	for _i in range(guess_count):
		var letter_array := []
		for _j in range(letter_count):
			var letter := Letter.instance()
			letter_array.append(letter)
			$C/V/LetterGrid.add_child(letter)
		letters.append(letter_array)

	target_word = Global.generate_word(letter_count)
	current_guess = 0


func _on_GuessButton_pressed() -> void:
	var guess_text_node := find_node("GuessText") as LineEdit
	var guess := guess_text_node.text.to_upper()
	guess_entered(guess)


func _on_GuessText_text_entered(new_text: String) -> void:
	guess_entered(new_text)


func guess_entered(guess: String) -> void:
	if current_guess >= guess_count:
		return
	guess = guess.to_upper()
	if guess.length() != letter_count:
		show_error("Word must be five characters.")
		return
	if not Global.is_valid_word(guess):
		show_error("Not a recognized word.")
		return

	var letters_remaining = []
	for letter in target_word:
		letters_remaining.append(letter)

	hide_error()

	# Mark all greens
	for i in range(letter_count):
		var guess_letter := guess[i]
		var target_letter := target_word[i]

		var letter_instance := letters[current_guess][i] as ColorRect
		letter_instance.get_node("Label").text = guess_letter
		if guess_letter == target_letter:
			letter_instance.color = color_correct
			# Remove that one letter from remaining letters (is there a function for this?)
			for j in range(letters_remaining.size()):
				if letters_remaining[j] == guess_letter:
					letters_remaining.remove(j)
					break

	# Mark all yellows (and grays)
	for i in range(letter_count):
		var letter_instance := letters[current_guess][i] as ColorRect
		if letter_instance.color == color_correct:
			# Ignore things that are already green
			continue
		var guess_letter := guess[i]
		var found := false
		for j in range(letters_remaining.size()):
			if letters_remaining[j] == guess_letter:
				found = true
				letters_remaining.remove(j)
				break
		if found:
			letter_instance.color = color_misplaced
		else:
			letter_instance.color = color_incorrect

	current_guess += 1
	var guess_text_node := find_node("GuessText") as LineEdit
	guess_text_node.text = ""

	var ended := false
	var won := false

	if guess == target_word:
		ended = true
		won = true
	elif current_guess >= guess_count:
		ended = true

	if ended:
		find_node("GuessButton").disabled = true
		find_node("GuessText").editable = false
		if won:
			show_error("Congrats! You won!", Color(0.4, 0.9, 0.6))
		else:
			show_error("Game Over. The word was %s" % target_word, error_text_color_default)


func show_error(text: String, color = null):
	$C/V/V/ErrorText.text = text
	if typeof(color) == TYPE_COLOR:
		$ErrorFadeOut.stop()
		$C/V/V/ErrorText.add_color_override("font_color", color)
	else:
		$ErrorFadeOut.play("ErrorFadeOut")


func hide_error():
	$C/V/V/ErrorText.text = ""
	$ErrorFadeOut.stop()
