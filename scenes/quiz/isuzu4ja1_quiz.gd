extends Control

const RESULT_SCENE = "res://scenes/quiz/isuzu4ja1_quizresult.tscn"
const QUESTION_TIME_SECONDS = 30.0
const API_URL = "http://localhost/AutoSim3D/api/quiz/get_quiz_questions.php"
const QUIZ_ID = 2
const IMAGE_BASE_URL = "http://localhost/AutoSim3D/assets/images/quiz/Isuzu4JA1/"

const FIXED_IMAGE_SIZE = Vector2(0, 280)
const FIXED_BUTTON_SIZE = Vector2(0, 70)
const FIXED_QUESTION_TEXT_SIZE = Vector2(0, 90)

@onready var http_request: HTTPRequest = $HTTPRequest

@onready var question_number: Label = %QuestionNumber
@onready var question_text: Label = %QuestionText
@onready var question_image: TextureRect = %QuestionImage

@onready var answer_a: Button = %AnswerA
@onready var answer_b: Button = %AnswerB
@onready var answer_c: Button = %AnswerC
@onready var answer_d: Button = %AnswerD

@onready var next_button: Button = %NextButton
@onready var question_count: Label = %QuestionCount
@onready var quiz_progress: ProgressBar = %QuizProgress
@onready var timer_label: Label = %TimerLabel

var questions: Array = []

var current_question: int = 0
var score: int = 0
var selected_answer: int = -1

var time_left: float = QUESTION_TIME_SECONDS
var quiz_finished: bool = false
var quiz_loaded: bool = false

var answer_buttons: Array[Button] = []


func _ready() -> void:
	answer_buttons = [
		answer_a,
		answer_b,
		answer_c,
		answer_d
	]

	for i in range(answer_buttons.size()):
		var btn = answer_buttons[i]
		btn.pressed.connect(_on_answer_pressed.bind(i))
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.custom_minimum_size = FIXED_BUTTON_SIZE

	question_text.custom_minimum_size = FIXED_QUESTION_TEXT_SIZE
	question_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	question_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	next_button.pressed.connect(_on_next_pressed)
	next_button.disabled = true

	quiz_progress.min_value = 0
	quiz_progress.max_value = 15
	quiz_progress.value = 0

	question_image.custom_minimum_size = FIXED_IMAGE_SIZE
	question_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	question_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	question_image.hide()

	question_number.text = "Loading quiz..."
	question_text.text = "Please wait while questions are loading."
	question_count.text = "0 / 15"

	for btn in answer_buttons:
		btn.disabled = true
		btn.text = ""

	timer_label.text = "Time: 00:30"

	http_request.request_completed.connect(_on_questions_received)

	var quiz_url = API_URL + "?quiz_id=" + str(QUIZ_ID)

	print("QUIZ URL: ", quiz_url)

	var error = http_request.request(quiz_url)

	if error != OK:
		show_load_error("Could not connect to the quiz API.")


func _process(delta: float) -> void:
	if not quiz_loaded or quiz_finished:
		return

	time_left -= delta

	if time_left <= 0:
		time_left = 0
		update_timer_label()
		_on_time_out()
		return

	update_timer_label()


func _on_questions_received(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		show_load_error("Network error while loading questions.")
		return

	if response_code != 200:
		show_load_error("API returned HTTP %d." % response_code)
		return

	var json = JSON.new()
	var parse_error = json.parse(body.get_string_from_utf8())

	if parse_error != OK:
		show_load_error("Invalid JSON response from API.")
		return

	var response = json.data

	if typeof(response) != TYPE_DICTIONARY:
		show_load_error("Unexpected API response format.")
		return

	if not response.has("questions"):
		show_load_error("API response has no questions.")
		return

	var api_questions = response["questions"]

	if typeof(api_questions) != TYPE_ARRAY or api_questions.is_empty():
		show_load_error("No quiz questions found.")
		return

	var loaded_questions: Array = []

	for item in api_questions:
		if typeof(item) != TYPE_DICTIONARY:
			show_load_error("Invalid question data.")
			return

		if not item.has("question") or not item.has("choices") or not item.has("correct_answer"):
			show_load_error("A question is missing required fields.")
			return

		var choices = item["choices"]

		if typeof(choices) != TYPE_ARRAY or choices.size() != 4:
			show_load_error("Each question must have four choices.")
			return

		var correct_letter = str(item["correct_answer"]).strip_edges().to_upper()
		var correct_index = ["A", "B", "C", "D"].find(correct_letter)

		if correct_index == -1:
			show_load_error("Invalid correct answer in API.")
			return

		var image_name = str(item.get("image", "")).strip_edges()

		loaded_questions.append({
			"question": str(item["question"]),
			"choices": choices,
			"correct": correct_index,
			"image": image_name
		})

	questions = loaded_questions
	quiz_progress.max_value = questions.size()

	quiz_loaded = true
	current_question = 0
	score = 0
	quiz_finished = false

	load_question()


func show_load_error(message: String) -> void:
	quiz_loaded = false
	quiz_finished = true

	question_number.text = "Quiz unavailable"
	question_text.text = message + "\n\nPlease check XAMPP and try again."

	question_count.text = "0 / 15"
	next_button.disabled = true

	for btn in answer_buttons:
		btn.disabled = true

	push_warning(message)


func load_question() -> void:
	if current_question >= questions.size():
		finish_quiz()
		return

	selected_answer = -1
	time_left = QUESTION_TIME_SECONDS

	var data = questions[current_question]

	question_number.text = "Question %d" % (current_question + 1)
	question_text.text = data["question"]
	question_count.text = "%d / %d" % [
		current_question + 1,
		questions.size()
	]

	quiz_progress.value = current_question + 1

	load_question_image(str(data.get("image", "")))

	var choice_letters = ["A", "B", "C", "D"]

	for i in range(answer_buttons.size()):
		answer_buttons[i].text = choice_letters[i] + ". " + str(data["choices"][i])
		answer_buttons[i].disabled = false
		answer_buttons[i].modulate = Color.WHITE

	next_button.disabled = true
	next_button.text = "Submit"

	update_timer_label()


func load_question_image(image_name: String) -> void:
	question_image.texture = null
	question_image.hide()

	if image_name.is_empty():
		return

	# API returns a filename, not a res:// path.
	# Download the image from the XAMPP-served folder.
	var image_url = IMAGE_BASE_URL + image_name.uri_encode()

	var image_http = HTTPRequest.new()
	add_child(image_http)

	image_http.request_completed.connect(
		_on_image_received.bind(image_http),
		CONNECT_ONE_SHOT
	)

	var error = image_http.request(image_url)

	if error != OK:
		image_http.queue_free()


func _on_image_received(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray,
	image_http: HTTPRequest
) -> void:
	if is_instance_valid(image_http):
		image_http.queue_free()

	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		return

	var image = Image.new()
	var image_error = image.load_png_from_buffer(body)

	if image_error != OK:
		image_error = image.load_jpg_from_buffer(body)

	if image_error != OK:
		image_error = image.load_webp_from_buffer(body)

	if image_error != OK:
		return

	question_image.texture = ImageTexture.create_from_image(image)
	question_image.show()


func _on_answer_pressed(answer_index: int) -> void:
	if quiz_finished or not quiz_loaded:
		return

	selected_answer = answer_index

	for i in range(answer_buttons.size()):
		if i == selected_answer:
			answer_buttons[i].modulate = Color(0.65, 0.85, 1.0, 1.0)
		else:
			answer_buttons[i].modulate = Color.WHITE

	next_button.disabled = false


func _on_time_out() -> void:
	if not quiz_loaded or quiz_finished:
		return

	if selected_answer != -1:
		var correct_answer: int = questions[current_question]["correct"]

		if selected_answer == correct_answer:
			score += 1

	current_question += 1

	if current_question >= questions.size():
		finish_quiz()
	else:
		load_question()


func _on_next_pressed() -> void:
	if quiz_finished or not quiz_loaded or selected_answer == -1:
		return

	var correct_answer: int = questions[current_question]["correct"]

	if selected_answer == correct_answer:
		score += 1

	current_question += 1

	if current_question >= questions.size():
		finish_quiz()
	else:
		load_question()


func finish_quiz() -> void:
	if quiz_finished:
		return

	quiz_finished = true

	Global.final_score = score
	Global.total_questions = questions.size()

	get_tree().change_scene_to_file(RESULT_SCENE)


func update_timer_label() -> void:
	var minutes: int = int(time_left / 60)
	var seconds: int = int(time_left) % 60

	timer_label.text = "Time: %02d:%02d" % [minutes, seconds]
