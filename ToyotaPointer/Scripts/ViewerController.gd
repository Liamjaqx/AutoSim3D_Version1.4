extends Node

@export var engine_root : Node3D
@export var camera : Camera3D
@onready var ray = camera.get_node("RayCast3D")

var selected_mesh: MeshInstance3D = null

var dragging := false

# ---------- Default View ----------
const DEFAULT_ROTATION := Vector3(0, 45, 0)

# ---------- Auto Reset ----------
var idle_time := 0.0
const RESET_DELAY := 0.5      # Wait 2 seconds
const RESET_SPEED := 5.0      # Higher = faster return

func _ready():

	# Initial presentation angle
	engine_root.rotation_degrees = DEFAULT_ROTATION

	# Camera distance
	camera.position = Vector3(0,1.2,6.0)


func _process(delta):

	# Count time when not dragging
	if !dragging:
		idle_time += delta

		# Smoothly return to the default position
		if idle_time >= RESET_DELAY:
			engine_root.rotation_degrees = engine_root.rotation_degrees.lerp(
				DEFAULT_ROTATION,
				delta * RESET_SPEED
			)


func _unhandled_input(event):

	# Left mouse starts rotating
	if event is InputEventMouseButton:

		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
			
			if event.pressed:
				ray.force_raycast_update()
		
		if ray.is_colliding():
			var body = ray.get_collider()
			var mesh = body.get_parent()

			if mesh is MeshInstance3D:
				selected_mesh = mesh
				print(selected_mesh.name)
				

			# Reset timer whenever player interacts
			if dragging:
				idle_time = 0.0

	# Rotate engine
	if event is InputEventMouseMotion and dragging:

		engine_root.rotate_x(deg_to_rad(event.relative.y * 0.4))
		engine_root.rotate_y(deg_to_rad(event.relative.x * 0.4))

		# Keep resetting timer while dragging
		idle_time = 0.0


	# Mouse wheel zoom
	if event is InputEventMouseButton:

		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.position.z -= 0.25
			idle_time = 0.0

		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.position.z += 0.25
			idle_time = 0.0

		camera.position.z = clamp(camera.position.z,2.0,8.0)


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game_scene/levels/ChooseEngine.tscn")
	
