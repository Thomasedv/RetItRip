class_name ArenaScript extends Node3D

@onready var mesh_instance = $ArenaMesh
@onready var collision_shape = $ArenaMesh/StaticBody3D/CollisionShape3D

@export var radius: float = 20.0
@export var segments: int = 64
@export var depth: float = -4.0  # Depth of the center curve


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

	var mesh = st.commit()
	mesh_instance.mesh = mesh

	# 💥 Collision setup
	var collision_mesh = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var shape = ConcavePolygonShape3D.new()
	shape.set_faces(collision_mesh)
	collision_shape.shape = shape
	
	
