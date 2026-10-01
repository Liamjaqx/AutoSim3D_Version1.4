extends Control


@onready var full_name_input = $CenterContainer/SignupPanel/MarginContainer/VBoxContainer/FormColumns/LeftColumn/FullNameInput
@onready var lrn_input = $CenterContainer/SignupPanel/MarginContainer/VBoxContainer/FormColumns/LeftColumn/LRNInput
@onready var year_section_input = $CenterContainer/SignupPanel/MarginContainer/VBoxContainer/FormColumns/LeftColumn/YearSectionInput

@onready var password_input = $CenterContainer/SignupPanel/MarginContainer/VBoxContainer/FormColumns/RightColumn/PasswordRow/PasswordField/PasswordInput
@onready var confirm_password_input = $CenterContainer/SignupPanel/MarginContainer/VBoxContainer/FormColumns/RightColumn/ConfirmPasswordRow/ConfirmPasswordField/ConfirmPasswordInput

@onready var signup_button = $CenterContainer/SignupPanel/MarginContainer/VBoxContainer/SignupButton
@onready var login_button = $CenterContainer/SignupPanel/MarginContainer/VBoxContainer/LoginRow/LoginButton
@onready var message_label = $CenterContainer/SignupPanel/MarginContainer/VBoxContainer/MessageLabel


# Password toggle buttons
@onready var password_toggle_button: Button = $CenterContainer/SignupPanel/MarginContainer/VBoxContainer/FormColumns/RightColumn/PasswordRow/PasswordField/PasswordToggleButton
@onready var confirm_password_toggle_button: Button = $CenterContainer/SignupPanel/MarginContainer/VBoxContainer/FormColumns/RightColumn/ConfirmPasswordRow/ConfirmPasswordField/CPToggleButton


var message_id := 0
var http_request: HTTPRequest

# Password visibility states
var password_visible := false
var confirm_password_visible := false

# Point this to your XAMPP server project directory
const API_URL := "http://192.168.1.41/AutoSim3D/api/student_signup.php"


func _ready():
	signup_button.pressed.connect(_on_signup_button_pressed)
	login_button.pressed.connect(_on_login_button_pressed)

	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_signup_request_completed)

	message_label.text = ""

	# Password show/hide buttons
	password_toggle_button.pressed.connect(_on_password_toggle_pressed)
	confirm_password_toggle_button.pressed.connect(_on_confirm_password_toggle_pressed)

	password_visible = false
	confirm_password_visible = false
	password_input.secret = true
	confirm_password_input.secret = true


func _on_signup_button_pressed():
	var full_name = full_name_input.text.strip_edges()
	var lrn = lrn_input.text.strip_edges()
	var password = password_input.text
	var confirm_password = confirm_password_input.text


	# Full Name validation
	if full_name.is_empty():
		show_message("Please enter your full name.")
		return

	var name_regex = RegEx.new()
	name_regex.compile("^[A-Za-z ]+$")
	if not name_regex.search(full_name):
		show_message("Full name must contain letters only.")
		return


	# LRN validation
	if lrn.is_empty():
		show_message("Please enter your LRN.")
		return
	if not lrn.is_valid_int():
		show_message("LRN must contain numbers only.")
		return


	# Year & Section validation
	if year_section_input.selected < 0:
		show_message("Please select your Year & Section.")
		return
	var year_section = year_section_input.get_item_text(year_section_input.selected)


	# Password validation
	if password.is_empty():
		show_message("Please enter your password.")
		return
	if password.length() < 8:
		show_message("Password must be at least 8 characters.")
		return


	# Confirm Password validation
	if confirm_password.is_empty():
		show_message("Please confirm your password.")
		return
	if password != confirm_password:
		show_message("Passwords do not match.")
		return


	# Disable button and send request to XAMPP
	signup_button.disabled = true
	show_message("Connecting to server...", true)


	# Prepare POST payload mapping to PHP keys
	var form_data = {
		"fullname": full_name,
		"lrn": lrn,
		"year_section": year_section,
		"password": password
	}

	var body = ""
	for key in form_data:
		if body != "":
			body += "&"
		body += str(key).uri_encode() + "=" + str(form_data[key]).uri_encode()

	var headers = ["Content-Type: application/x-www-form-urlencoded"]

	var error = http_request.request(API_URL, headers, HTTPClient.METHOD_POST, body)

	if error != OK:
		signup_button.disabled = false
		show_message("Unable to connect to the server.")


func _on_signup_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	signup_button.disabled = false

	if result != HTTPRequest.RESULT_SUCCESS:
		show_message("Unable to reach the server.")
		return

	if response_code != 200:
		show_message("Server error. Please try again.")
		return

	var response_text = body.get_string_from_utf8()
	var json = JSON.new()
	var parse_result = json.parse(response_text)

	if parse_result != OK:
		show_message("Invalid response format from server.")
		return

	var response = json.data
	if not response is Dictionary:
		show_message("Invalid server response.")
		return

	if response.get("success", false):
		show_message(response.get("message", "Signup successful! Pending approval."), true)

		# Clear form fields
		full_name_input.text = ""
		lrn_input.text = ""
		year_section_input.select(-1)
		password_input.text = ""
		confirm_password_input.text = ""
		
		password_visible = false
		confirm_password_visible = false
		password_input.secret = true
		confirm_password_input.secret = true

		# Redirect to Login after delay
		await get_tree().create_timer(2.0).timeout
		get_tree().change_scene_to_file("res://scenes/Login/Login.tscn")
	else:
		show_message(response.get("message", "Signup failed."))


# Password show/hide toggle
func _on_password_toggle_pressed():
	password_visible = not password_visible
	password_input.secret = not password_visible


func _on_confirm_password_toggle_pressed():
	confirm_password_visible = not confirm_password_visible
	confirm_password_input.secret = not confirm_password_visible


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


func _on_login_button_pressed():
	get_tree().change_scene_to_file("res://scenes/Login/Login.tscn")
