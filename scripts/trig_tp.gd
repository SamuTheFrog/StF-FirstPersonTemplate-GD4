extends Area3D

@export var teleport_pos = Vector3(0.0, 0.0, 0.0)

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.global_transform.origin = teleport_pos
