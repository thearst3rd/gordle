extends Node


const MIN_LENGTH := 5
const MAX_LENGTH := 5
const GENERABLE_WORDS_FILENAME = "res://words/popular-filtered.txt"
const ALL_WORDS_FILENAME := "res://words/enable1.txt"


var generable_words: Dictionary
var all_words: Dictionary


func _ready() -> void:
	randomize()
	generable_words = parse_words(GENERABLE_WORDS_FILENAME, MIN_LENGTH, MAX_LENGTH)
	all_words = parse_words(ALL_WORDS_FILENAME, MIN_LENGTH, MAX_LENGTH)


func parse_words(filename: String, min_len: int, max_len: int) -> Dictionary:
	var dict := {}
	for i in range(min_len, max_len + 1):
		dict[i] = []

	var file := File.new()
	var error := file.open(filename, File.READ)
	assert(not error)
	while not file.eof_reached():
		var line := file.get_line()
		var length = line.length()
		if length < min_len || length > max_len:
			continue
		dict[length].append(line.to_upper())
	file.close()

	for key in dict.keys():
		print(key, ": ", dict[key].size())


	return dict


func generate_word(length: int, random_seed = null) -> String:
	if typeof(random_seed) == TYPE_INT:
		seed(random_seed)

	var words_list := generable_words[length] as Array

	return words_list[randi() % words_list.size()]


func is_valid_word(word: String) -> bool:
	var length := word.length()
	if length < MIN_LENGTH or length > MAX_LENGTH:
		return false

	var words_list := all_words[length] as Array

	return word.to_upper() in words_list
