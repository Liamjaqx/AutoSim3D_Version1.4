extends Control

const MAIN_MENU_SCENE = "res://scenes/menus/main_menu/main_menu.tscn"
const SAVE_SCORE_API = "http://localhost/AutoSim3D/api/quiz/save_quiz_score.php"
const QUIZ_ID = 2

@onready var score_label: Label = %ScoreLabel
@onready var percentage_label: Label = %PercentageLabel
@onready var perform_label: Label = %PerformLabel
@onready var home_button: Button = %HomeButton
@onready var save_score_request: HTTPRequest = $SaveScoreRequest

var score_saved: bool = false


func _ready() -> void:
	home_button.pressed.connect(_on_home_button_pressed)
	save_score_request.request_completed.connect(_on_score_saved)

	display_results()
	save_quiz_score()


func display_results() -> void:
	var score: int = Global.final_score
	var total: int = Global.total_questions
	var percentage: float = 0.0

	if total > 0:
		percentage = (float(score) / float(total)) * 100.0

	score_label.text = "%d / %d" % [score, total]
	percentage_label.text = "%.1f%%" % percentage

	if percentage >= 90.0:
		perform_label.text = "Excellent!"
	elif percentage >= 80.0:
		perform_label.text = "Very Good!"
	elif percentage >= 75.0:
		perform_label.text = "Passed!"
	else:
		perform_label.text = "Needs Improvement"


func save_quiz_score() -> void:
	var student_id: int = Global.student_id
	var score: int = Global.final_score
	var total: int = Global.total_questions

	if student_id <= 0:
		push_warning("Score not saved: Invalid student ID.")
		return

	if total <= 0 or score < 0 or score > total:
		push_warning("Score not saved: Invalid score data.")
		return

	var data = {
		"student_id": student_id,
		"quiz_id": QUIZ_ID,
		"score": score,
		"total_items": total
	}

	var json_body = JSON.stringify(data)

	var headers = [
		"Content-Type: application/json"
	]

	var error = save_score_request.request(
		SAVE_SCORE_API,
		headers,
		HTTPClient.METHOD_POST,
		json_body
	)

	if error != OK:
		push_warning("Could not send score-saving request.")


func _on_score_saved(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		push_warning("Score saving failed. HTTP: %d" % response_code)
		return

	var json = JSON.new()
	var parse_result = json.parse(body.get_string_from_utf8())

	if parse_result != OK or not json.data is Dictionary:
		push_warning("Invalid response from score API.")
		return

	var response: Dictionary = json.data

	if response.get("success", false):
		score_saved = true
		print("Quiz score saved successfully. Score ID: ", response.get("score_id"))
	else:
		push_warning(str(response.get("message", "Score saving failed.")))


func _on_home_button_pressed() -> void:
	get_tree().change_scene_to_file(
		"res://scenes/game_scene/levels/HomePage.tscn"
	)
