extends Control


@onready var lrn_input = $CenterContainer/LoginPanel/MarginContainer/VBoxContainer/LRNInput

@onready var password_input = $CenterContainer/LoginPanel/MarginContainer/VBoxContainer/PasswordRow/PasswordField/PasswordInput

@onready var password_toggle_button: Button = $CenterContainer/LoginPanel/MarginContainer/VBoxContainer/PasswordRow/PasswordField/PasswordToggleButton

@onready var login_button = $CenterContainer/LoginPanel/MarginContainer/VBoxContainer/LoginButton
@onready var signup_button = $CenterContainer/LoginPanel/MarginContainer/VBoxContainer/SignupRow/SignupButton

@onready var message_label = $CenterContainer/LoginPanel/MarginContainer/VBoxContainer/MessageLabel


var message_id := 0
var http_request: HTTPRequest

var password_visible := false


const API_URL := "http://192.168.1.41/AutoSim3D/api/student_login.php"


func _ready():
	login_button.pressed.connect(_on_login_button_pressed)
	signup_button.pressed.connect(_on_signup_button_pressed)

	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_login_request_completed)

	message_label.text = ""

	password_toggle_button.pressed.connect(_on_password_toggle_pressed)

	password_visible = false
	password_input.secret = true


func _on_login_button_pressed():
	var lrn = lrn_input.text.strip_edges()
	var password = password_input.text


	if lrn.is_empty():
		show_message("Please enter your LRN.")
		return

	if not lrn.is_valid_int():
		show_message("LRN must contain numbers only.")
		return


	if password.is_empty():
		show_message("Please enter your password.")
		return


	login_button.disabled = true

	show_message("Logging in...", true)


	var form_data = {
		"lrn": lrn,
		"password": password
	}


	var body = ""

	for key in form_data:
		if body != "":
			body += "&"

		body += str(key).uri_encode()
		body += "="
		body += str(form_data[key]).uri_encode()


	var headers = [
		"Content-Type: application/x-www-form-urlencoded"
	]


	var error = http_request.request(
		API_URL,
		headers,
		HTTPClient.METHOD_POST,
		body
	)


	if error != OK:
		login_button.disabled = false
		show_message("Unable to connect to the server.")


func _on_login_request_completed(
	result: int,
	response_code: int,
	headers: PackedStringArray,
	body: PackedByteArray
):

	login_button.disabled = false


	if result != HTTPRequest.RESULT_SUCCESS:
		show_message("Unable to connect to the server.")
		return


	if response_code != 200:
		show_message("Server error. Please try again.")
		return


	var response_text = body.get_string_from_utf8()


	var json = JSON.new()
	var parse_result = json.parse(response_text)


	if parse_result != OK:
		show_message("Invalid response from server.")
		return


	var response = json.data


	if not response is Dictionary:
		show_message("Invalid server response.")
		return


	if response.get("success", false):

		show_message(
			response.get(
				"message",
				"Login successful!"
			),
			true
		)


		var user_data = response.get("user", {})


		var user_id = int(user_data.get("user_id", 0))
		var fullname = str(user_data.get("fullname", ""))
		var student_lrn = str(user_data.get("lrn", ""))
		var year_section = str(user_data.get("year_section", ""))
		var role = str(user_data.get("role", ""))
		var status = str(user_data.get("status", ""))


		print("Student ID: ", user_id)
		print("Student Name: ", fullname)
		print("LRN: ", student_lrn)
		print("Year & Section: ", year_section)
		print("Role: ", role)
		print("Status: ", status)


		var saved = DatabaseManager.save_student(
			user_id,
			fullname,
			student_lrn,
			year_section,
			role,
			status
		)


		if saved:
			print("Student information saved to SQLite successfully.")
			DatabaseManager.current_user_id = user_id
			Global.student_id = user_id
			get_tree().change_scene_to_file("res://scenes/menus/main_menu/main_menu_with_animations.tscn")
			
		else:
			print("Failed to save student information to SQLite.")


	else:

		show_message(
			response.get(
				"message",
				"Login failed."
			)
		)


func _on_password_toggle_pressed():
	password_visible = not password_visible
	password_input.secret = not password_visible


func show_message(message: String, success: bool = false):

	message_id += 1
	var current_message_id = message_id

	message_label.text = message


	if success:
		message_label.modulate = Color(0.3, 1.0, 0.4)
	else:
		message_label.modulate = Color(1.0, 0.35, 0.35)


	await get_tree().create_timer(3.0).timeout


	if current_message_id == message_id:
		message_label.text = ""


func _on_signup_button_pressed():
	get_tree().change_scene_to_file("res://scenes/Signup/Signup.tscn")
