class_name Spinner_spinning extends Node3D

@export var max_speed = 50;
@export var spin_speed: float = 25 # Radians per second (Y-axis spin)
@export var wobble_strength: float =  - (spin_speed - (max_speed+1)) / (max_speed+1) *  0.1 # Radians of max tilt
@export var wobble_speed: float = 0.2 # How fast it wobbles (Hz)
@onready var static_body_3d: StaticBody3D = $"../../ArenaMesh/StaticBody3D"


var time := 0.0
@export var speed = 14
# The downward acceleration when in the air, in meters per second squared.
@export var fall_acceleration = 75
@export var arena: ArenaScript = null

var is_tipping = false
var tip_axis := Vector3(1, 0, 0)  # or Vector3(0, 0, 1) if you want sideways tip
var tip_speed := 1.5  # radians per second
var current_tip_angle := 0.0
var max_tip_angle := PI  # 180 degrees in radians
var is_scaling_down := false
var scale_timer := 0.0
var scale_duration := 3.0  # seconds to fully shrink and despawn
var target_velocity = Vector3.ZERO

func update_wobble():
	wobble_strength = - (spin_speed - (max_speed+1)) / (max_speed+1) *  0.1 

func tip():
	spin_speed = 0
	is_tipping = true
	current_tip_angle = 0.0

func _process(delta):
	time += delta

	# Base spin
	if not is_tipping:
		rotate_y(spin_speed * delta)

	# Wobble (skip if tipping)
	if not is_tipping:
		var x_angle = sin(time * wobble_speed) * wobble_strength
		var z_angle = cos(time * wobble_speed) * wobble_strength
		rotation.x = x_angle
		rotation.z = z_angle
	else:
		spinner.start_shrink_and_despawn()
		scale_timer = 0.0
	
		rotate_object_local(tip_axis, current_tip_angle)
	
	
	var from = spinner_tip.global_transform.origin 
	var down_dir = -spinner_tip.global_transform.basis.y
	var to = from + down_dir * 0.22

	var space_state = get_world_3d().direct_space_state
	
	var query = PhysicsRayQueryParameters3D.new()
	query.from = from
	query.to = to
	query.exclude = []  # exclude spinner if needed
	query.collision_mask = 2  # adjust mask to your arena's layerr mask if needed
	
	var result = space_state.intersect_ray(query)

	if result:
		if  result.collider == static_body_3d:
			
			var hit_pos = result.position
			var hit_normal = result.normal

			if last_mark_pos != Vector3.ZERO or last_mark_pos.distance_to(hit_pos) > 0:
				spawn_path_mark(hit_pos, hit_normal, last_mark_pos)
				last_mark_pos = hit_pos
	else:
		last_mark_pos = Vector3.ZERO
		


@onready var spinner: CharacterBody3D = $".."

@onready var spinner_tip = $Tip  # Assuming you have a node marking the spinner tip position
@onready var arena_mesh: MeshInstance3D = $"../../ArenaMesh"


var last_mark_pos : Vector3 = Vector3.ZERO
var decal_material : StandardMaterial3D
var old_line_offset: float = 0.0
var target_line_offset: float = 0.0
var interp_t: float = 1.0  # interpolation progress (0..1)

func reset_line_offset():
	# Pick a new target offset between -5 and +5
	old_line_offset = target_line_offset
	target_line_offset = randi() % 11 - 5
	interp_t = 0.0  # reset interpolation progress

func create_path_texture(size: int = 64, delta: float = 0.1) -> ImageTexture:
	# Update interpolation progress
	interp_t = min(interp_t + delta, 1.0)

	# Interpolate current offset between old and target
	var current_line_offset = lerp(old_line_offset, target_line_offset, interp_t)

	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)

	img.fill(Color(0, 0, 0, 0))  # transparent background

	var line_width = 40
	var center_x = int(size / 2 + current_line_offset)

	for x in range(center_x - line_width / 2.0, center_x + line_width / 2.0):
		for y in range(size):
			img.set_pixel(x, y, Color(0, 0, 0, 1))
			
	var tex = ImageTexture.create_from_image(img)
	return tex




func spawn_path_mark(pos: Vector3, normal: Vector3, last_pos: Vector3):
	var sprite = Sprite3D.new()
	var texture = create_path_texture()
	sprite.texture = texture
	
	sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	if last_pos == Vector3.ZERO:
		last_pos = pos
		
	# Calculate vector from last_pos to pos
	var line_vec = pos - last_pos
	var mid_pos = last_pos + line_vec * 0.5

	# Length of the line (distance between points)
	var length = line_vec.length()

	# Build basis:
	# - X axis: direction of line projected on the plane tangent to surface (orthogonal to normal)
	# - Y axis: global up (Vector3.UP)
	# - Z axis: perpendicular to both (normal direction)
	var up = Vector3.UP
	var line_dir = (line_vec - normal * line_vec.dot(normal)).normalized()  # project line_vec onto tangent plane
	var right = line_dir
	var forward = normal.cross(right).normalized()

	sprite.transform.basis = Basis(right, -forward, up)
	
	# Scale sprite:
	# X axis scales along the line length, Y and Z keep fixed thickness

	
	arena_mesh.add_child(sprite)
	sprite.global_transform.origin = mid_pos + normal * 0.001 
	sprite.scale = Vector3(length*3, 0.1, 0.1)
	
	await get_tree().create_timer(20.0).timeout
	sprite.queue_free()
