class_name ArenaScript extends Node3D

@onready var mesh_instance = $ArenaMesh
@onready var collision_shape = $ArenaMesh/StaticBody3D/CollisionShape3D

@export var radius: float = 50.0
@export var segments: int = 64
@export var depth: float = -8.0  # Depth of the center curve

func check_if_game_over():
	var cs: Array[CharacterBody3D] = []
	var cam = null
	for child in get_children():
		if child is CharacterBody3D:
			cs.append(child)
		if child is Camera3D:
			cam = child
			
	var child_count = len(cs)
	
	if child_count == 1:
		if cs[0] == %Spinner:
			for child in %Spinner.get_children():
				if child is Camera3D:
					cam = child
			var label = Label.new()
			label.text = "Win!"
			label.set_size(Vector2.ONE*5)
			var ls = LabelSettings.new()
			ls.font_size = 72
			label.label_settings = ls
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.set_position(cam.get_window().size/2)
			cam.add_child(label)
	if %Spinner not in cs:
		var label = Label.new()
		label.text = "RIP!"
		label.set_size(Vector2.ONE*5)
		var ls = LabelSettings.new()
		ls.font_size = 72
		label.label_settings = ls
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.set_position(cam.get_window().size/2)
		cam.add_child(label)
	if child_count == 0:
		var label = Label.new()
		label.text = "RIP!"
		label.set_size(Vector2.ONE*5)
		var ls = LabelSettings.new()
		ls.font_size = 72
		label.label_settings = ls
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.set_position(cam.get_window().size/2)
		cam.add_child(label)

func _ready():
	var st = SurfaceTool.new()
	
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for i in range(segments):
		var angle1 = TAU * i / segments
		var angle2 = TAU * (i + 1) / segments

		var x1 = radius * cos(angle1)
		var z1 = radius * sin(angle1)
		var y1 = -depth * ((x1 * x1 + z1 * z1) / (radius * radius))

		var x2 = radius * cos(angle2)
		var z2 = radius * sin(angle2)
		var y2 = -depth * ((x2 * x2 + z2 * z2) / (radius * radius))

		var center = Vector3(0, -depth * 0.1, 0)

		st.add_vertex(center)
		st.add_vertex(Vector3(x1, y1, z1))
		st.add_vertex(Vector3(x2, y2, z2))

	# Wall height (how tall the walls will be)
	var wall_height := 3.0

	# Begin appending more geometry to the same SurfaceTool
	for i in range(segments):
		var angle1 = TAU * i / segments
		var angle2 = TAU * (i + 1) / segments

		var x1 = radius * cos(angle1)
		var z1 = radius * sin(angle1)
		var y1 = -depth * ((x1 * x1 + z1 * z1) / (radius * radius))

		var x2 = radius * cos(angle2)
		var z2 = radius * sin(angle2)
		var y2 = -depth * ((x2 * x2 + z2 * z2) / (radius * radius))

		var bottom1 = Vector3(x1, y1, z1)
		var bottom2 = Vector3(x2, y2, z2)

		var top1 = bottom1 + Vector3.UP * wall_height
		var top2 = bottom2 + Vector3.UP * wall_height

		# First triangle of wall quad
		st.add_vertex(bottom1)
		st.add_vertex(top1)
		st.add_vertex(top2)

		# Second triangle of wall quad
		st.add_vertex(bottom1)
		st.add_vertex(top2)
		st.add_vertex(bottom2)

	st.generate_normals()  # ✨ Auto-computes normals for smooth lighting

	var mesh = st.commit()
	mesh_instance.mesh = mesh

	# 💥 Collision setup
	var collision_mesh = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var shape = ConcavePolygonShape3D.new()
	shape.set_faces(collision_mesh)
	collision_shape.shape = shape
	
func _process(delta: float) -> void:
	check_if_game_over()
