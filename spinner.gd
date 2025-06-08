class_name Ripper extends CharacterBody3D
const PARTICLE_SPAWNER = preload("res://particle_spawner.tscn")

@export var max_speed := 30.0
@export var acceleration := 20.0
@export var rotation_speed := 3.0  # radians per second
@export var fall_acceleration := 30.0
@export var jump_velocity := 10.0

@export var target_path: NodePath
@export var turn_speed := 3.0

@export var player_controlled : bool = false
@onready var body: Spinner_spinning = $Body

var friction := 0.05  # smaller = less slowing

var health = 100;
var max_health = 100



var shrink_duration := 1.0
var elapsed := 0.0
var shrinking := false

func adjust_spinning():
	body.spin_speed = max(health * 0.6, 0)
	body.update_wobble()
	
	if health < 1:
		body.tip()
		
	
func start_shrink_and_despawn():
	shrinking = true
	for child in get_children():
		if child is Camera3D:
			var cam = child as Camera3D
			cam.reparent(get_parent_node_3d())
	await get_tree().create_timer(shrink_duration).timeout
	queue_free()  # Remove the object

	
func _ready():
	velocity = global_transform.basis * Vector3(0, 0, -10)
	#velocity.x = forward_dir.x * 10
	#velocity.z = forward_dir.z * 10


var was_on_ground_last_iter = false;
func _physics_process(delta):
	if shrinking:
		scale = scale * (0.95)
	if health > 0:
		health += (1 + int(player_controlled) * 2) * delta
		health = clamp(health, -1, 100)
		
	adjust_spinning()
	if velocity.length() < 4:
		health -= clamp(5 - velocity.length(), 1, 6) *delta
		
	var input_forward := 0.0
	var input_turn := 0.0
	if player_controlled:
		if Input.is_action_pressed("move_up"):
			input_forward += 1
		if Input.is_action_pressed("move_down"):
			input_forward -= 1
		if Input.is_action_pressed("move_left"):
			input_turn += 1
		if Input.is_action_pressed("move_right"):
			input_turn -= 1
	else:
		if %Spinner:
			var target = get_node(%Spinner.get_path())
			var to_target = (target.global_transform.origin - global_transform.origin)
			to_target.y = 0  # Ignore vertical difference

			if to_target.length() == 0:
				return

			# Desired facing direction
			var target_direction = to_target.normalized()
			var current_direction = -transform.basis.z.normalized()

		# Smoothly rotate toward the target
			var angle_diff = current_direction.angle_to(target_direction)
			var cross = current_direction.cross(target_direction).y
			rotation.y += sign(cross) * min(angle_diff, turn_speed * delta)

			# Move forward in facing direction
			var forward = -transform.basis.z.normalized()
			var accel = forward * 1 * acceleration * delta
			velocity.x += accel.x
			velocity.z += accel.z
	

	input_forward = clamp(input_forward, -1, 1)
	input_turn = clamp(input_turn, -1, 1)

	# Rotate based on turn input
	if input_turn != 0:
		rotation.y += input_turn * rotation_speed * delta

	# Movement direction from current facing
	var forward = -transform.basis.z.normalized()

	# Apply acceleration based on direction, do not directly set velocity
	if input_forward != 0:
		var accel = forward * input_forward * acceleration * delta
		velocity.x += accel.x
		velocity.z += accel.z

	if not is_on_floor():
		velocity.y -= fall_acceleration * delta
	else:
		if Input.is_action_just_pressed("jump") and player_controlled:
			velocity.y = jump_velocity
		else:
			velocity.y = 0
	
	# Move and get collisions
	var on_floor = is_on_floor()
	move_and_slide()
	#var collision = move_and_collide(velocity * delta, false, 0.001, false, 5)
	for i in get_slide_collision_count():
		var coll = get_slide_collision(i)
		var normal = coll.get_normal()
		var angle = normal.angle_to(Vector3.UP) # or whatever up you are using
		if angle < floor_max_angle:
			# it is a floorddddddddsssssssssssssssssssssssssssssssssdd
			if not was_on_floor and on_floor:
				spawn_hit_effect(coll.get_position())
		
		elif angle > (PI - floor_max_angle):
			# it is a ceiling
			pass
		else:
			var collider = coll.get_collider()
			velocity = velocity.bounce(coll.get_normal()) * 0.9
			spawn_hit_effect(coll.get_position())
			health -= 2
			if collider and collider is CharacterBody3D and collider.has_method("apply_momentum"):
				health -= 5
				# Transfer a fraction of velocity to the other spinner
				var transferred = velocity * 0.1  # adjust strength as needed
				collider.apply_momentum(transferred)
	was_on_floor = on_floor

var was_on_floor = true
func apply_momentum(momentum: Vector3):
	velocity += momentum
	# velocity = velocity.bounce(collision.get_normal())
	# look_at(global_position + velocity, up_direction)
@onready var static_body_3d: StaticBody3D = $"../ArenaMesh/StaticBody3D"
@onready var gpu_particles_3d: GPUParticles3D = $GPUParticles3D

func spawn_hit_effect(position: Vector3):
	var effect_instance = PARTICLE_SPAWNER.instantiate()

	get_tree().current_scene.add_child(effect_instance)
	effect_instance.global_position = position
	effect_instance.get_child(0).emitting = true
	# Optional: queue_free after duration
	await get_tree().create_timer(2.0).timeout
	if effect_instance:  # In case it was already freed
		effect_instance.queue_free()
