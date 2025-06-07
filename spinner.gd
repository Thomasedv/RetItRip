extends CharacterBody3D

@export var max_speed := 30.0
@export var acceleration := 2.0
@export var rotation_speed := 3.0  # radians per second
@export var fall_acceleration := 30.0
@export var jump_velocity := 10.0

@export var player_controlled : bool = false
var friction := 0.05  # smaller = less slowing

# Bounce state
var bounce_timer := 0.0
var bounce_cooldown := 0.8
var just_bounced := false

func _ready() -> void:
	var forward_dir = -transform.basis.z.normalized()
	velocity.x = forward_dir.x * 10
	velocity.z = forward_dir.z * 10

func _physics_process(delta):
	# Handle bounce cooldown
	if bounce_timer > 0.0:
		bounce_timer -= delta
	else:
		just_bounced = false

	# Input
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
		input_forward += 1
		
	
	input_forward = clamp(input_forward, -1, 1)
	input_turn = clamp(input_turn, -1, 1)


	var forward_dir = -transform.basis.z.normalized()  # fallback if standing still
	rotation.y += input_turn * rotation_speed * delta


	var target_speed = input_forward * max_speed
	var current_speed = Vector2(velocity.x, velocity.z).length()

	if input_forward > 0.01:
		current_speed = lerp(current_speed, target_speed, acceleration * delta)
	elif input_forward < 0:
		current_speed = lerp(current_speed, 0.0, friction * 10 * delta)
	else:
		current_speed = lerp(current_speed, 0.0, friction * delta)

	# Apply forward velocity (ignore sideways movement)
	velocity.x = forward_dir.x * current_speed
	velocity.z = forward_dir.z * current_speed

	# Gravity
	if not is_on_floor():
		velocity.y -= fall_acceleration * delta
	else:
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity
		else:
			velocity.y = 0

	move_and_slide()
