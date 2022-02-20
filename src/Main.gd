extends CenterContainer


const letter_count := 5
const guess_count := 6

const Letter = preload("res://src/Letter.tscn")

export var color_incorrect: Color = Color()
export var color_misplaced: Color = Color()
export var color_correct: Color = Color()

# An array of arrays of the letter nodes
var letters := []

func _ready() -> void:
	for _i in range(guess_count):
		var letter_array := []
		for _j in range(letter_count):
			var letter := Letter.instance()
			letter_array.append(letter)
			$V/LetterGrid.add_child(letter)
		letters.append(letter_array)
