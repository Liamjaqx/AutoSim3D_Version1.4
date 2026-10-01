extends Control

const TOYOTA_QUIZ_SCENE = "res://scenes/quiz/toyota7k_quiz.tscn"

@onready var toyota_button: Button = $CenterContainer/VBoxContainer/HBoxContainer/Toyota


func _ready() -> void:
	toyota_button.pressed.connect(_on_toyota_pressed)


func _on_toyota_pressed() -> void:
	get_tree().change_scene_to_file(TOYOTA_QUIZ_SCENE)
