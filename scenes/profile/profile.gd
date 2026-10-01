extends Control

# Profile information
@onready var back_button: Button = $BackButton

@onready var full_name_value: Label = $ScrollContainer/CenterContainer/ContentVBox/PersonalInfoPanel/PersonalInfoMargin/PersonalInfoVBox/FullNameValue
@onready var year_section_value: Label = $ScrollContainer/CenterContainer/ContentVBox/PersonalInfoPanel/PersonalInfoMargin/PersonalInfoVBox/YearSectionValue
@onready var lrn_value: Label = $ScrollContainer/CenterContainer/ContentVBox/PersonalInfoPanel/PersonalInfoMargin/PersonalInfoVBox/LRNValue

# Change password
@onready var current_pass_input: LineEdit = $ScrollContainer/CenterContainer/ContentVBox/ChangePassPanel/ChangePassMargin/ChangePassVBox/CurPassRow/CurrentPassInput
@onready var current_eye_button: Button = $ScrollContainer/CenterContainer/ContentVBox/ChangePassPanel/ChangePassMargin/ChangePassVBox/CurPassRow/CurEyeButton

@onready var new_pass_input: LineEdit = $ScrollContainer/CenterContainer/ContentVBox/ChangePassPanel/ChangePassMargin/ChangePassVBox/NewPassRow/NewPassInput
@onready var new_eye_button: Button = $ScrollContainer/CenterContainer/ContentVBox/ChangePassPanel/ChangePassMargin/ChangePassVBox/NewPassRow/NewEyeButton

# Exact confirm password nodes from profile.tscn
@onready var confirm_pass_input: LineEdit = $ScrollContainer/CenterContainer/ContentVBox/ChangePassPanel/ChangePassMargin/ChangePassVBox/ConEyeRow/CPPassInput
@onready var confirm_eye_button: Button = $ScrollContainer/CenterContainer/ContentVBox/ChangePassPanel/ChangePassMargin/ChangePassVBox/ConEyeRow/CPEyeButton

@onready var update_pass_button: Button = $ScrollContainer/CenterContainer/ContentVBox/ChangePassPanel/ChangePassMargin/ChangePassVBox/UpdatePassButton

# Confirmation dialog
@onready var confirmation_dialog: ConfirmationDialog = $PWConfirmationDialog

# Password change API
const CHANGE_PASSWORD_API := "http://192.168.1.41/AutoSim3D/api/student_change_password.php"

var http_request: HTTPRequest
var is_password_request_running: bool = false

# Password visibility states
var current_password_visible: bool = false
var new_password_visible: bool = false
var confirm_password_visible: bool = false

# Current logged-in user ID
var current_user_id: int = 0

# Temporary password values used during confirmation
var pending_current_password: String = ""
var pending_new_password: String = ""

# Notice dialog
var notice_dialog: AcceptDialog


# Initialize the profile screen when the scene is ready.
func _ready() -> void:
	_setup_connections()
	_setup_password_fields()
	_setup_http_request()
	_setup_notice_dialog()
	load_profile()


# Connect all button and dialog signals used by the profile screen.
func _setup_connections() -> void:
	if not back_button.pressed.is_connected(_on_back_button_pressed):
		back_button.pressed.connect(_on_back_button_pressed)

	if not current_eye_button.pressed.is_connected(_on_current_eye_pressed):
		current_eye_button.pressed.connect(_on_current_eye_pressed)

	if not new_eye_button.pressed.is_connected(_on_new_eye_pressed):
		new_eye_button.pressed.connect(_on_new_eye_pressed)

	if not confirm_eye_button.pressed.is_connected(_on_confirm_eye_pressed):
		confirm_eye_button.pressed.connect(_on_confirm_eye_pressed)

	if not update_pass_button.pressed.is_connected(_on_update_pass_pressed):
		update_pass_button.pressed.connect(_on_update_pass_pressed)

	if not confirmation_dialog.confirmed.is_connected(_on_confirmation_yes):
		confirmation_dialog.confirmed.connect(_on_confirmation_yes)

	if not confirmation_dialog.canceled.is_connected(_on_confirmation_no):
		confirmation_dialog.canceled.connect(_on_confirmation_no)

	confirmation_dialog.dialog_text = "Are you sure you want to change your password?"


# Configure all password fields to hide their text by default.
func _setup_password_fields() -> void:
	current_pass_input.secret = true
	new_pass_input.secret = true
	confirm_pass_input.secret = true

	current_password_visible = false
	new_password_visible = false
	confirm_password_visible = false


# Create and configure the HTTPRequest node used for the password API.
func _setup_http_request() -> void:
	http_request = HTTPRequest.new()
	http_request.timeout = 20.0
	add_child(http_request)

	http_request.request_completed.connect(_on_password_request_completed)


# Create the dialog used for displaying profile messages and errors.
func _setup_notice_dialog() -> void:
	notice_dialog = AcceptDialog.new()
	notice_dialog.title = "Profile"
	add_child(notice_dialog)


# Load the logged-in student's profile information from DatabaseManager.
func load_profile() -> void:
	current_user_id = int(DatabaseManager.current_user_id)

	if current_user_id <= 0:
		show_notice("Unable to identify the logged-in student. Please log in again.")
		return

	var student_data: Dictionary = DatabaseManager.get_student(current_user_id)

	if student_data.is_empty():
		show_notice("Student information not found. Please log in again.")
		return

	full_name_value.text = str(student_data.get("fullname", ""))
	year_section_value.text = str(student_data.get("year_section", ""))
	lrn_value.text = str(student_data.get("lrn", ""))


# Toggle visibility of the current password field.
func _on_current_eye_pressed() -> void:
	current_password_visible = not current_password_visible
	current_pass_input.secret = not current_password_visible


# Toggle visibility of the new password field.
func _on_new_eye_pressed() -> void:
	new_password_visible = not new_password_visible
	new_pass_input.secret = not new_password_visible


# Toggle visibility of the confirm password field.
func _on_confirm_eye_pressed() -> void:
	confirm_password_visible = not confirm_password_visible
	confirm_pass_input.secret = not confirm_password_visible


# Validate the password fields before showing the confirmation dialog.
func _on_update_pass_pressed() -> void:
	if is_password_request_running:
		show_notice("Please wait for the current request to finish.")
		return

	var current_password: String = current_pass_input.text.strip_edges()
	var new_password: String = new_pass_input.text
	var confirm_password: String = confirm_pass_input.text

	if current_password.is_empty():
		show_notice("Please enter your current password.")
		current_pass_input.grab_focus()
		return

	if new_password.is_empty():
		show_notice("Please enter your new password.")
		new_pass_input.grab_focus()
		return

	if confirm_password.is_empty():
		show_notice("Please confirm your new password.")
		confirm_pass_input.grab_focus()
		return

	if new_password.length() < 8:
		show_notice("New password must be at least 8 characters.")
		new_pass_input.grab_focus()
		return

	if new_password != confirm_password:
		show_notice("New passwords do not match.")
		confirm_pass_input.grab_focus()
		return

	if current_password == new_password:
		show_notice("New password must be different from your current password.")
		new_pass_input.grab_focus()
		return

	if current_user_id <= 0:
		show_notice("Invalid student session. Please log in again.")
		return

	pending_current_password = current_password
	pending_new_password = new_password

	confirmation_dialog.dialog_text = "Are you sure you want to change your password?"
	confirmation_dialog.popup_centered()


# Handle the confirmation dialog when the user chooses Yes.
func _on_confirmation_yes() -> void:
	if is_password_request_running:
		show_notice("Please wait for the current request to finish.")
		return

	if pending_current_password.is_empty():
		show_notice("Password information is missing.")
		return

	if pending_new_password.is_empty():
		show_notice("New password information is missing.")
		return

	update_pass_button.disabled = true
	is_password_request_running = true

	_send_change_password_request()


# Handle the confirmation dialog when the user chooses Cancel.
func _on_confirmation_no() -> void:
	_clear_pending_passwords()


# Send the current and new password to the PHP API.
func _send_change_password_request() -> void:
	var form_data := {
		"user_id": str(current_user_id),
		"current_password": pending_current_password,
		"new_password": pending_new_password
	}

	var body: String = ""

	for key in form_data:
		if not body.is_empty():
			body += "&"

		body += str(key).uri_encode()
		body += "="
		body += str(form_data[key]).uri_encode()

	var headers := [
		"Content-Type: application/x-www-form-urlencoded"
	]

	var error: Error = http_request.request(
		CHANGE_PASSWORD_API,
		headers,
		HTTPClient.METHOD_POST,
		body
	)

	if error != OK:
		is_password_request_running = false
		update_pass_button.disabled = false
		_clear_pending_passwords()
		show_notice("Unable to connect to the server.")


# Process the response returned by the password change API.
func _on_password_request_completed(
	result: int,
	response_code: int,
	headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	is_password_request_running = false
	update_pass_button.disabled = false

	var response_text: String = body.get_string_from_utf8()

	print("Change password result: ", result)
	print("Change password response code: ", response_code)
	print("Change password response: ", response_text)

	if result != HTTPRequest.RESULT_SUCCESS:
		show_notice("Unable to connect to the server.")
		_clear_pending_passwords()
		return

	if response_code != 200:
		show_notice("Server error. HTTP code: %d" % response_code)
		_clear_pending_passwords()
		return

	if response_text.strip_edges().is_empty():
		show_notice("Server returned an empty response.")
		_clear_pending_passwords()
		return

	var json := JSON.new()
	var parse_result: Error = json.parse(response_text)

	if parse_result != OK:
		show_notice("Invalid response from server.")
		_clear_pending_passwords()
		return

	var response = json.data

	if not response is Dictionary:
		show_notice("Invalid server response.")
		_clear_pending_passwords()
		return

	if response.get("success", false):
		_clear_password_fields()
		show_notice(
			str(response.get("message", "Password changed successfully!"))
		)
	else:
		show_notice(
			str(response.get("message", "Password change failed."))
		)

	_clear_pending_passwords()


# Clear all password input fields and reset their visibility.
func _clear_password_fields() -> void:
	current_pass_input.clear()
	new_pass_input.clear()
	confirm_pass_input.clear()

	_setup_password_fields()


# Clear the temporary password values stored before confirmation.
func _clear_pending_passwords() -> void:
	pending_current_password = ""
	pending_new_password = ""


# Display a message to the user using the profile notice dialog.
func show_notice(message: String) -> void:
	if notice_dialog == null:
		return

	notice_dialog.dialog_text = message
	notice_dialog.popup_centered()


# Return to the HomePage when the Back button is pressed.
func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game_scene/levels/HomePage.tscn")
