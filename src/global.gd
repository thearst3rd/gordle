extends Node


enum GameMode {
	DAILY,
	RANDOM,
	CUSTOM,
}

const MIN_LENGTH := 5
const MAX_LENGTH := 5
const GENERABLE_WORDS_FILENAME = "res://words/popular-filtered.txt"
const ALL_WORDS_FILENAME := "res://words/enable1.txt"

var game_mode := GameMode.DAILY
var custom_word := ""
var custom_date_str := ""

var generable_words: Dictionary
var all_words: Dictionary

var allow_future := false


func _ready() -> void:
	randomize()
	generable_words = parse_words(GENERABLE_WORDS_FILENAME, MIN_LENGTH, MAX_LENGTH)
	all_words = parse_words(ALL_WORDS_FILENAME, MIN_LENGTH, MAX_LENGTH)

	detect_params()


func parse_words(filename: String, min_len: int, max_len: int) -> Dictionary:
	var dict := {}
	for i in range(min_len, max_len + 1):
		dict[i] = []

	var file := FileAccess.open(filename, FileAccess.READ)
	assert(file != null)
	while not file.eof_reached():
		var line := file.get_line()
		var length = line.length()
		if length < min_len || length > max_len:
			continue
		dict[length].append(line.to_upper())
	file.close()

	return dict


func generate_word(length: int, random_seed = null) -> String:
	var random_value: int
	if typeof(random_seed) == TYPE_INT:
		var rng = RandomNumberGenerator.new()
		rng.set_seed(random_seed)
		random_value = rng.randi()
	else:
		random_value = randi()

	var words_list := generable_words[length] as Array

	return words_list[random_value % words_list.size()]


func is_valid_word(word: String) -> bool:
	var length := word.length()
	if length < MIN_LENGTH or length > MAX_LENGTH:
		return false

	var words_list := all_words[length] as Array

	return word.to_upper() in words_list


## Checks for command line/URL parameters and configures the game accordingly
func detect_params() -> void:
	var daily := false
	var custom := ""

	if OS.has_feature("web"):
		var paramsStr = JavaScriptBridge.eval("window.location.search")
		var paramsObj = JavaScriptBridge.create_object("URLSearchParams", paramsStr)
		if paramsObj.has("daily") and paramsObj.get("daily") not in ["false", "0"]:
			daily = true
		if paramsObj.has("custom"):
			custom = paramsObj.get("custom")
		if paramsObj.has("allowfuture") and paramsObj.get("allowfuture") not in ["false", "0"]:
			allow_future = true
	else:
		var args := OS.get_cmdline_user_args()
		if "--daily" in args:
			daily = true
		var custom_index := args.find("--custom")
		if custom_index != -1 and custom_index < (args.size() - 1):
			custom = args[custom_index + 1]
		if "--allowfuture" in args:
			allow_future = true

	print("daily: ", daily)
	print("custom: ", custom)
	print("allowfuture: ", allow_future)

	if daily:
		game_mode = GameMode.DAILY
		get_tree().change_scene_to_file.call_deferred("res://src/main.tscn")
		return

	if custom:
		if parse_custom(custom):
			game_mode = GameMode.CUSTOM
			get_tree().change_scene_to_file.call_deferred("res://src/main.tscn")
			return


## Checks if the given string is:
##
## * A normal five letter word, or
## * A valid encoded word, or
## * A valid date in YYYY-MM-DD encoding
##     * Will only allow this date to be in the present or past, unless `allow_future` is set to true
##
## Returns true if successful, and will set `custom_word` and possibly `custom_date_str` values accordingly. Returns
## false if unsuccessful and will erase `custom_word` and `custom_date_str`.
func parse_custom(value: String) -> bool:
	if value.length() == 5:
		# ...is there an is_alpha function that I missed?
		var word := value.to_upper()
		var valid := true
		for i in range(5):
			var code := word.unicode_at(i)
			if code < 65 or code > 90: # 65 = ascii "A", 90 = ascii "Z"
				valid = false
				break
		if valid:
			custom_word = word
			return true

	if value.is_valid_hex_number():
		var decoded := decode_word(value.hex_to_int())
		if not decoded.is_empty():
			custom_word = decoded
			return true

	var parsed_date := Time.get_datetime_dict_from_datetime_string(value, false)
	if parsed_date.has("year"):
		parsed_date["hour"] = 0
		parsed_date["minute"] = 0
		parsed_date["second"] = 0
		var new_time := Time.get_unix_time_from_datetime_dict(parsed_date)
		var valid := true
		if not allow_future:
			var current_time := Time.get_unix_time_from_datetime_string(Time.get_date_string_from_system(true))
			if new_time > current_time:
				valid = false
		if valid:
			custom_word = generate_word(5, new_time)
			custom_date_str = Time.get_date_string_from_unix_time(new_time)
			return true

	return false


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().quit()


## Returns the number of 1 bits in an integer
func popcnt(num: int) -> int:
	# Is this already implemented somewhere?
	var count := 0
	for i in range(64):
		if num & (1 << i):
			count += 1
	return count


## Encodes a word using a very basic "encryption" method. Returns -1 if invalid word
func encode_word(word: String) -> int:
	if word.length() != 5:
		return -1
	word = word.to_upper()

	# Encode word in base 26
	var num := 0
	for i in range(word.length()):
		var letter_ind := word[i].unicode_at(0) - 65 # 65 = ascii "A"
		if letter_ind < 0 or letter_ind >= 26:
			return -1
		num += letter_ind * (26 ** i)
	# Add an offset so that "aaaaa" isn't just zeroes
	num += 123456

	# Shuffle bits around
	# uvwxyz -> vuxwzy -> zyvuxw
	num = ((num & 0xf0f0f0) >> 4) | ((num & 0x0f0f0f) << 4)
	num = ((num & 0xffff00) >> 8) | ((num & 0x0000ff) << 16)
	# Count bits and add as checksum
	var bits := popcnt(num)
	num = num | (bits << 24)

	return num


## Decodes an encoded word. Returns an empty string if invalid
func decode_word(encoded_word: int) -> String:
	var bits := encoded_word >> 24
	var num := encoded_word & 0xffffff

	# Verify bit count
	if popcnt(num) != bits:
		return ""

	# Unshuffle bits
	num = ((num << 8) & 0xffff00) | ((num >> 16) & 0x0000ff)
	num = ((num << 4) & 0xf0f0f0) | ((num >> 4) & 0x0f0f0f)

	num -= 123456

	if num < 0 or num >= (26 ** 5): # (26 ** 5) - 1 = "ZZZZZ"
		# Someone is trying to be sneaky! Or more likely I just messed up.
		return ""

	# Decode base 26 word
	var word := ""
	for i in range(5):
		var letter_ind := num % 26
		word += char(letter_ind + 65) # 65 = ascii "A"
		@warning_ignore("integer_division")
		num = num / 26

	return word
