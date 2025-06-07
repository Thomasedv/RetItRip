extends Camera3D

@export var smoothing_speed := 99.0  # Higher = faster smoothing

var target_direction: Vector3 = Vector3.FORWARD

#func _process(delta):
	#var moving_obj = get_parent()  # assuming camera is child of moving object
	#if not moving_obj:
		#return
#
	## Get the object's global velocity or movement direction vector
	## Replace this with your actual movement direction vector
	#var velocity = moving_obj.get("velocity") if moving_obj.has_method("get") else Vector3.ZERO
#
	#if velocity.length_squared() > 0.001:
		#target_direction = velocity.normalized()
	#else:
		## Optionally keep current target_direction if object is idle
		#return
#
	## Current forward direction of camera in global space
	#var current_forward = -global_transform.basis.z
#
	## Interpolate between current forward and target direction (slerp for rotation)
	#var new_forward = current_forward.slerp(target_direction, smoothing_speed * delta).normalized()
#
	## Calculate new basis for camera looking toward new_forward, with global up vector
	#var new_basis = Basis().looking_at(new_forward, Vector3.UP)
#
	## Apply the new basis (rotation) while keeping current position
	#global_transform = Transform3D(new_basis, global_transform.origin)
