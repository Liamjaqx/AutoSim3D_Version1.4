extends BoxContainer

# Opens Choose Engine for Explore mode.
func _on_explore_button_pressed() -> void:
	AppState.selected_mode = "explore"
	get_tree().change_scene_to_file(
		"res://scenes/game_scene/levels/ChooseEngine.tscn"
	)

# Opens Choose Engine for Assembly and Disassembly mode.
func _on_assembly_pressed() -> void:
	AppState.selected_mode = "assembly"
	get_tree().change_scene_to_file(
		"res://scenes/game_scene/levels/ChooseEngine.tscn"
	)


# Opens Choose Engine for Quiz mode.
func _on_quiz_pressed() -> void:
	AppState.selected_mode = "quiz"
	get_tree().change_scene_to_file(
		"res://scenes/game_scene/levels/ChooseEngine.tscn"
	)


# Opens the student profile.
func _on_profile_pressed() -> void:
	get_tree().change_scene_to_file(
		"res://scenes/profile/profile.tscn"
	)


# Opens the credits screen.
func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file(
		"res://scenes/credits/scrollable_credits.tscn"
	)


# Opens the options menu.
func _on_option_pressed() -> void:
	get_tree().change_scene_to_file(
		"res://addons/maaacks_game_template/examples/scenes/windows/main_menu_options_window.tscn"
	)
