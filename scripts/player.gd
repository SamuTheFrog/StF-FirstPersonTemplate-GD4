extends CharacterBody3D

const WALK_SPEED_BASE = 9.0
const SPRINT_SPEED_AMP = 6.0
const CROUCH_SPEED_AMP = 6.0
const STANDING_HEIGHT = 0.6
const CROUCH_HEIGHT_AMP = 0.9
const DODGE_AMP = 900.0
const DODGE_COOLDOWN = 0.6
const JUMP_AMP = 9.69
const DOUBLEJUMP_AMP = 15.0
const LOOK_SENSITIVITY = .0016
const BOB_FREQ = 2.0
const BOB_AMP = 0.06
const FOV_BASE = 80.0
const FOV_WARP = 0.3

var movement_speed = 6.0
var can_dodge = true
var can_doublejump = true
var can_sprint = true
var hbob = 0.0 # Not entirely sure what this does... but everything breaks without it.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var head = $head
@onready var camera = $head/Camera3D
@onready var fov = "fov"
@onready var collider_standing = $collider_standing
@onready var collider_crouched = $collider_crouched
@onready var overhead_raycast = $overhead_raycast

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(event.relative.x * -LOOK_SENSITIVITY)
		camera.rotate_x(event.relative.y * -LOOK_SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-85), deg_to_rad(90))

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_pressed("move_sprint"):
		if can_sprint:
			movement_speed = lerp(movement_speed, WALK_SPEED_BASE + SPRINT_SPEED_AMP, delta * 6)
		else:
			movement_speed = lerp(movement_speed, WALK_SPEED_BASE, delta * 6)

	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if Input.is_action_just_pressed("move_dodge"):
		if can_dodge:
			velocity.x = lerp(velocity.x, direction.x * DODGE_AMP, delta * 9)
			velocity.z = lerp(velocity.z, direction.z * DODGE_AMP, delta * 9)
			can_dodge = false
			await get_tree().create_timer(DODGE_COOLDOWN).timeout
			can_dodge = true

	if Input.is_action_pressed("move_crouch"):
		movement_speed = lerp(movement_speed, WALK_SPEED_BASE - CROUCH_SPEED_AMP, delta * 3)
		can_dodge = false
		can_sprint = false
		head.position.y = lerp(head.position.y, STANDING_HEIGHT - CROUCH_HEIGHT_AMP, delta * 9)
		collider_standing.disabled = true
		collider_crouched.disabled = false
	else:
		if not overhead_raycast.is_colliding():
			movement_speed = lerp(movement_speed, WALK_SPEED_BASE, delta * 9)
			can_dodge = true
			can_sprint = true
			head.position.y = lerp(head.position.y, STANDING_HEIGHT, delta * 3)
			collider_crouched.disabled = true
			collider_standing.disabled = false

	if is_on_floor():
		if direction:
			velocity.x = lerp(velocity.x, direction.x * movement_speed, delta * 9.0)
			velocity.z = lerp(velocity.z, direction.z * movement_speed, delta * 9.0)
		else:
			velocity.x = lerp(velocity.x, direction.x * movement_speed, delta * 6.0)
			velocity.z = lerp(velocity.z, direction.z * movement_speed, delta * 6.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * movement_speed, delta * 6.0)
		velocity.z = lerp(velocity.z, direction.z * movement_speed, delta * 6.0)

	if Input.is_action_pressed("move_jump") and is_on_floor():
		velocity.y = JUMP_AMP

	if Input.is_action_just_pressed("move_jump") and not is_on_floor():
		if can_doublejump:
			velocity.y = DOUBLEJUMP_AMP
			can_doublejump = false

	if is_on_floor():
		can_doublejump = true

	hbob += delta * velocity.length()  * float(is_on_floor())
	camera.transform.origin = _headbob(hbob)

	var velocity_clamped = clamp(velocity.length(), 0.9, SPRINT_SPEED_AMP * 33)
	var target_fov = FOV_BASE + FOV_WARP * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 9)

	move_and_slide()

func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos
