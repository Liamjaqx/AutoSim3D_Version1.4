extends Node


var db: SQLite = null
var current_user_id: int = 0

const DATABASE_PATH := "user://autosim3d.db"


func _ready():
	print("DatabaseManager is running.")
	initialize_database()


func initialize_database():
	db = SQLite.new()
	db.path = DATABASE_PATH

	print("Opening SQLite database...")

	if not db.open_db():
		push_error("Failed to open SQLite database: " + str(db.error_message))
		db = null
		return

	print("SQLite database opened successfully.")
	print("Database path: " + DATABASE_PATH)

	create_students_table()


func create_students_table():
	if db == null:
		push_error("SQLite database is not open.")
		return

	var query := """
	CREATE TABLE IF NOT EXISTS students (
		user_id INTEGER PRIMARY KEY,
		fullname TEXT NOT NULL,
		lrn TEXT NOT NULL UNIQUE,
		year_section TEXT NOT NULL,
		role TEXT NOT NULL,
		status TEXT NOT NULL
	);
	"""

	print("Creating students table...")

	if not db.query(query):
		push_error("Failed to create students table: " + str(db.error_message))
		return

	print("Students table is ready.")


func save_student(
	user_id: int,
	fullname: String,
	lrn: String,
	year_section: String,
	role: String,
	status: String
) -> bool:

	if db == null:
		push_error("SQLite database is not open.")
		return false

	var query := """
	INSERT OR REPLACE INTO students
	(user_id, fullname, lrn, year_section, role, status)
	VALUES (?, ?, ?, ?, ?, ?);
	"""

	var success := db.query_with_bindings(
		query,
		[
			user_id,
			fullname,
			lrn,
			year_section,
			role,
			status
		]
	)

	if not success:
		push_error("Failed to save student: " + str(db.error_message))
		return false

	print("Student saved to SQLite.")
	return true


func get_student(user_id: int) -> Dictionary:

	if db == null:
		push_error("SQLite database is not open.")
		return {}

	var query := """
	SELECT user_id, fullname, lrn, year_section, role, status
	FROM students
	WHERE user_id = ?;
	"""

	var success := db.query_with_bindings(
		query,
		[user_id]
	)

	if not success:
		push_error("Failed to get student: " + str(db.error_message))
		return {}

	if db.query_result.is_empty():
		return {}

	return db.query_result[0]


func delete_student(user_id: int) -> bool:

	if db == null:
		push_error("SQLite database is not open.")
		return false

	var query := """
	DELETE FROM students
	WHERE user_id = ?;
	"""

	var success := db.query_with_bindings(
		query,
		[user_id]
	)

	if not success:
		push_error("Failed to delete student: " + str(db.error_message))
		return false

	print("Student deleted from SQLite.")
	return true


func clear_students() -> bool:

	if db == null:
		push_error("SQLite database is not open.")
		return false

	var query := "DELETE FROM students;"

	var success := db.query(query)

	if not success:
		push_error("Failed to clear students table: " + str(db.error_message))
		return false

	print("Students table cleared.")
	return true


func _exit_tree():
	if db != null:
		db.close_db()
		db = null
