extends Node


enum GameMode {
	DAILY,
	RANDOM,
	CUSTOM,
}

const MIN_WORD_LENGTH := 3
const MAX_WORD_LENGTH := 8
const DEFAULT_WORD_LENGTH := 5
const GENERABLE_WORDS_FILENAME = "res://words/popular-filtered.txt"
const ALL_WORDS_FILENAME := "res://words/enable1.txt"

# !$'()*+,-.0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz     <- All URL-encodable characters
const LARGE_BASE_CHARS := "!'()*+,-.123456789ABCDEFGHJKLMNPQRSTUVWXYZ_abcdefghijkmnopqrstuvwxyz" # <- Without some similar looking characters
const LARGE_BASE := 68 # Number of characters in above array
const ENCODING_INDICATOR := "$"

var date_regex = RegEx.create_from_string("^[0-9]+-[0-9]+-[0-9]+$")

var game_mode := GameMode.DAILY
var custom_word := ""
var custom_date_str := ""
var custom_word_length := -1

var generable_words: Dictionary
var all_words: Dictionary

var allow_future := false


func _ready() -> void:
	randomize()
	generable_words = parse_words(GENERABLE_WORDS_FILENAME, MIN_WORD_LENGTH, MAX_WORD_LENGTH)
	all_words = parse_words(ALL_WORDS_FILENAME, MIN_WORD_LENGTH, MAX_WORD_LENGTH)

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
	if length < MIN_WORD_LENGTH or length > MAX_WORD_LENGTH:
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
## * A valid encoded word, or
## * A normal alphabetical word, or
## * A valid date in YYYY-MM-DD encoding
##     * Will only allow this date to be in the present or past, unless `allow_future` is set to true
##
## Returns true if successful, and will set `custom_word` and possibly `custom_date_str` values accordingly. Returns
## false if unsuccessful and will erase `custom_word` and `custom_date_str`.
func parse_custom(value: String) -> bool:
	custom_word = ""
	custom_date_str = ""

	var decoded := decode_word(value)
	var decoded_len := decoded.length()
	if decoded_len >= MIN_WORD_LENGTH and decoded_len <= MAX_WORD_LENGTH:
		custom_word = decoded
		return true

	var value_len := value.length()
	if value_len >= MIN_WORD_LENGTH and value_len <= MAX_WORD_LENGTH:
		# ...is there an is_alpha function that I missed?
		var word := value.to_upper()
		var valid := true
		for i in range(value_len):
			var code := word.unicode_at(i)
			if code < 65 or code > 90: # 65 = ascii "A", 90 = ascii "Z"
				valid = false
				break
		if valid:
			custom_word = word
			return true

	if date_regex.search(value):
		var parsed_date := Time.get_datetime_dict_from_datetime_string(value, false)
		parsed_date["hour"] = 0
		parsed_date["minute"] = 0
		parsed_date["second"] = 0
		var new_time := Time.get_unix_time_from_datetime_dict(parsed_date)
		var valid := false
		if new_time != 0 or (parsed_date["year"] == 1970 and parsed_date["month"] == 1 and parsed_date["day"] == 1):
			valid = true
			if not allow_future:
				var current_time := Time.get_unix_time_from_datetime_string(Time.get_date_string_from_system(false))
				if new_time > current_time:
					valid = false
		if valid:
			custom_word = generate_word(DEFAULT_WORD_LENGTH, new_time)
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


## Encodes a word using a very basic "encryption" method. Returns an empty string if invalid word
func encode_word(word: String) -> String:
	word = word.to_upper()

	# Encode word in base 26
	var num := 1 # Start with a single 1 bit
	for i in range(word.length()):
		num *= 26
		var letter_ind := word.unicode_at(i) - 65 # 65 = ascii "A"
		if letter_ind < 0 or letter_ind >= 26:
			return ""
		num += letter_ind

	# Bit count for redundancy
	var count := popcnt(num)
	num = (num << 6) + count

	return ENCODING_INDICATOR + large_encode(num)


## Decodes an encoded word. Returns an empty string if invalid
func decode_word(encoded_word: String) -> String:
	if not encoded_word.begins_with(ENCODING_INDICATOR):
		return ""

	var large_base_str := encoded_word.substr(1)
	var full_num := large_decode(large_base_str)

	# Check the bit count
	var count := full_num & 0x3F # 6 bits
	var num := full_num >> 6
	if popcnt(num) != count:
		return ""

	if num <= 0:
		return ""

	# Decode base 26 word
	var word := ""
	while num > 1:
		var letter_ind := num % 26
		word = char(letter_ind + 65) + word # 65 = ascii "A"
		@warning_ignore("integer_division")
		num = num / 26

	if num != 1:
		return ""

	return word


## Encodes an integer as a large-base string
func large_encode(num: int) -> String:
	if num <= 0: # Negative numbers not supported since they are not needed
		return LARGE_BASE_CHARS[0]
	var lint := ""
	while num > 0:
		lint = LARGE_BASE_CHARS[num % LARGE_BASE] + lint
		@warning_ignore("integer_division")
		num = num / LARGE_BASE
	return lint


## Checks if the given string is a valid large-base integer. (Sorta, it only checks if the character composition is good)
func is_valid_large_base_int(lint: String) -> bool:
	for chr in lint:
		if chr not in LARGE_BASE_CHARS:
			return false
	return true


## Converts the given large-base integer back into a normal int. Returns -1 if invalid
func large_decode(lint: String) -> int:
	var num := 0
	for chr in lint:
		var index := LARGE_BASE_CHARS.find(chr)
		if index < 0:
			return -1
		num = (num * LARGE_BASE) + index
	return num
