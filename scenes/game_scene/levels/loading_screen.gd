extends Control

@export var progress_bar: ProgressBar
# The path of the heavy scene you want to load in the background:
@export_file("*.tscn") var next_scene_path: String = "res://ToyotaPointer/Scenes/Core Scene/Toyota.tscn"

var progress: Array[float] = []

func _ready() -> void:
	# Start the asynchronous thread request
	ResourceLoader.load_threaded_request(next_scene_path)

func _process(delta: float) -> void:
	var status = ResourceLoader.load_threaded_get_status(next_scene_path, progress)
	
	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			if progress.size() > 0:
				# progress[0] goes from 0.0 to 1.0
				progress_bar.value = progress[0] * 100
				
		ResourceLoader.THREAD_LOAD_LOADED:
			# Fully loaded! Grab the packed scene and switch to it.
			progress_bar.value = 100
			var packed_scene = ResourceLoader.load_threaded_get(next_scene_path)
			get_tree().change_scene_to_packed(packed_scene)
			
		ResourceLoader.THREAD_LOAD_FAILED:
			print("Error: Failed to load scene in background.")
