extends CharacterBody3D

@export var max_speed := 30.0
@export var acceleration := 20.0
@export var rotation_speed := 3.0  # radians per second
@export var fall_acceleration := 30.0
@export var jump_velocity := 10.0

@export var player_controlled : bool = false
var friction := 0.05  # smaller = less slowing

# Bounce state
var bounce_timer := 0.0
var bounce_cooldown := 0.8
var just_bounced := false

func _ready():
	velocity = global_transform.basis * Vector3(0, 0, -20)
	#velocity.x = forward_dir.x * 10
	#velocity.z = forward_dir.z * 10

var was_on_ground_last_iter = false;
func _physics_process(delta):
	
	var collision = move_and_collide(velocity * delta)
	var on_floor = is_on_floor()
	if collision:
		velocity = velocity.bounce(collision.get_normal())
		if not on_floor:
			velocity.y *= 0.9
			
	# Handle bounce cooldown
	if bounce_timer > 0.0:
		bounce_timer -= delta
	else:
		just_bounced = false

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

	if not is_on_floor():
		velocity.y -= fall_acceleration * delta
	else:
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity
		else:
			velocity.y = 0
			
	
	was_on_ground_last_iter = on_floor
	# velocity = velocity.bounce(collision.get_normal())
	# look_at(global_position + velocity, up_direction)
