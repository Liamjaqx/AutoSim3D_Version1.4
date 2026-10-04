extends HBoxContainer


# Toyota 7K button.
func _on_toyota_pressed() -> void:
	print("Selected mode: ", AppState.selected_mode)

	if AppState.selected_mode == "explore":
		get_tree().change_scene_to_file(
			"res://ToyotaPointer/Scenes/Core Scene/Toyota.tscn"
		)

	elif AppState.selected_mode == "assembly":
		get_tree().change_scene_to_file(
			"TOYOTA_ASSEMBLY_SCENE_PATH"
		)

	elif AppState.selected_mode == "quiz":
		get_tree().change_scene_to_file(
			"res://scenes/quiz/toyota7k_quiz.tscn"
		)


# Isuzu 4JA1 button.
func _on_isuzu_pressed() -> void:
	print("Selected mode: ", AppState.selected_mode)

	if AppState.selected_mode == "explore":
		get_tree().change_scene_to_file(
			"ISUZU_EXPLORE_SCENE_PATH"
		)

	elif AppState.selected_mode == "assembly":
		get_tree().change_scene_to_file(
			"ISUZU_ASSEMBLY_SCENE_PATH"
		)

	elif AppState.selected_mode == "quiz":
		get_tree().change_scene_to_file(
			"res://scenes/quiz/isuzu4ja1_quiz.tscn"
		)


# Back button.
func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(
		"res://scenes/game_scene/levels/HomePage.tscn"
	)
