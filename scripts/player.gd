extends CharacterBody3D

const WALK_SPEED = 9.0 # Obvious
const SPRINT_SPEED = 15.0 # You
const JUMP_VELOCITY = 9.69 # Fucking
const LOOK_SENSITIVITY = .0016 # Idiot
const BOB_FREQ = 2.0 # Head-bob frequency
const BOB_AMP = 0.06 # Head-bob amplitude
const FOV_BASE = 80.0 # Field of View base
const FOV_WARP = 0.3 # Field of view motion warping strength
const DODGE_AMP = 900.0 # Dodge amplitude
const DODGE_COOLDOWN = 0.6 # Dodge cooldown
const AFTERJUMP_AMP = 15.0 # Afterjump amplitude

var movement_speed = 6.0 # Temporary value for adjusting movement speeds on the go
var canDodge = true # Temporary value to prevent Afterjump spam
var canAfterjump = true # Temporary value to prevent Temporal Jump spam
var hbob = 0.0 # Not entirely sure what this does... something to do with head bobbin'... BUT AS TODD HOWARD SAYS
# # # # # # # # # # # # # # IT # # # # # # # # # # JUST # # # # # # # # # # WORKS # # # # # # # # # # # # # # # # 
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") # Gravity, this adds it, dumbass.

@onready var head = $head # Creates reference to head
@onready var camera = $head/Camera3D # Creates reference to camera
@onready var fov = "fov" # Makes FOV a publicably editable value



func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) # Track mouse movement + Lock in window

func _unhandled_input(event):
# Makes player look around lol
	if event is InputEventMouseMotion:
		head.rotate_y(event.relative.x * -LOOK_SENSITIVITY)
		camera.rotate_x(event.relative.y * -LOOK_SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-85), deg_to_rad(90))

# This applies gravity when necessary
func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

# FAST AS FUCK BOIIIIIIIIII
	if Input.is_action_pressed("move_sprint"):
		movement_speed = SPRINT_SPEED
	else:
		movement_speed = WALK_SPEED

# MOVEMENT STUFF
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

# So with this, we can dodge things now. That's cool.
	if Input.is_action_just_pressed("move_dodge"):
		if canDodge:
			velocity.x = lerp(velocity.x, direction.x * DODGE_AMP, delta * 6)
			velocity.z = lerp(velocity.z, direction.z * DODGE_AMP, delta * 6)
			canDodge = false
			await get_tree().create_timer(DODGE_COOLDOWN).timeout
			canDodge = true

# If they on the floor, they can run, lol.
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


# Bunny hops FTW
	if Input.is_action_pressed("move_jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

# I always liked double jumps in games... Metroid did it best.
	if Input.is_action_just_pressed("move_jump") and not is_on_floor():
		if canAfterjump:
			velocity.y = AFTERJUMP_AMP
			canAfterjump = false
# Prevents infinite Afterjump
	if is_on_floor():
		canAfterjump = true

# Makes head go bobbin'.
	hbob += delta * velocity.length()  * float(is_on_floor())
	camera.transform.origin = _headbob(hbob)

# Makes FOV warp depending on speed, but only to a max.
	var velocity_clamped = clamp(velocity.length(), 0.9, SPRINT_SPEED * 33)
	var target_fov = FOV_BASE + FOV_WARP * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 9)

	move_and_slide() # Oooooooooo, slippery

# HEAD BOB FUNCIONALITY - UNIMPORTANT REALLY SO KEEP IT AT THE BOTTOM YOU FUCKING LOSER
func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos
