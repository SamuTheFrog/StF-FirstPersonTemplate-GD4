extends CharacterBody3D

const WALK_SPEED = 9.0 # Obvious
const MOVE_SMOOTH = 9.0 # This one is used for linear interpolation of movement slowdowns and speed ups
const SPRINT_SPEED = 15.0 # You
const CROUCH_SLOWDOWN = 6.0 # Absolute
const CROUCH_AMP = 0.9 # Stupid-
const CROUCH_SMOOTH = 9 # Okay, maybe not this one... It's the value for crouch-state enter/exit
const STANDING_HEIGHT = 0.6# -SMOOTH BRAINED
const JUMP_VELOCITY = 9.69 # Fucking
const LOOK_SENSITIVITY = 0.0016 # Idiot
const BOB_FREQ = 2.0 # Head-bob frequency
const BOB_AMP = 0.06 # Head-bob amplitude
const FOV_BASE = 80.0 # Field of View base
const FOV_WARP = 0.3 # Field of view motion warping strength
const DODGE_AMP = 900.0 # Dodge amplitude
const DODGE_SMOOTH = 6.0 # Dodge dodge smoothing
const DODGE_COOLDOWN = 0.6 # Dodge cooldown
const AFTERJUMP_AMP = 15.0 # Afterjump amplitude

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") # Gravity, this adds it, dumbass.

@onready var head = $head # Creates reference to head
@onready var camera = $head/Camera3D # Creates reference to camera
@onready var fov = "fov" # Makes FOV a publicably editable value
@onready var standing_collider =  $standing_collider
@onready var crouch_collider = $crouch_collider
@onready var crouch_check_raycast = $crouch_check_raycast

func _ready():

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) # Track mouse movement + Lock in window

func _unhandled_input(event):

# Makes player look around with mouse
	if event is InputEventMouseMotion:
		head.rotate_y(event.relative.x * -LOOK_SENSITIVITY)
		camera.rotate_x(event.relative.y * -LOOK_SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-85), deg_to_rad(90))

func _physics_process(delta):

	var move_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var move_direction = (head.transform.basis * Vector3(move_dir.x, 0, move_dir.y)).normalized()
	var movement_speed = 6.0 # Temporary value for adjusting movement speeds on the go
	var is_crouched = false
	var can_dodge = true # Temporary value to prevent Afterjump spam
	var can_afterjump = true # Temporary value to prevent Temporal Jump spam
	var hbob = 0.0 # Not entirely sure what this does... something to do with head bobbin'... BUT AS TODD HOWARD SAYS
  # # # # # # # # # # # # # # IT # # # # # # # # # # JUST # # # # # # # # # # WORKS # # # # # # # # # # # # # # # # 

	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_pressed("move_crouch"):
		movement_speed = lerp(movement_speed, WALK_SPEED - CROUCH_SLOWDOWN, delta * CROUCH_SMOOTH)
		head.position.y = lerp(head.position.y, STANDING_HEIGHT - CROUCH_AMP, delta * CROUCH_SMOOTH)
		standing_collider.disabled = true
		crouch_collider.disabled = false
		can_dodge = false
		is_crouched = true
	else:
		if not crouch_check_raycast.is_colliding():
			head.position.y = lerp(head.position.y, STANDING_HEIGHT, delta * CROUCH_SMOOTH)
			standing_collider.disabled = false
			crouch_collider.disabled = true
			can_dodge = true
			is_crouched = false
		# FAST AS FUCK BOIIIIIIIIII
		if Input.is_action_pressed("move_sprint"):
			movement_speed = SPRINT_SPEED
		else:
			movement_speed = WALK_SPEED
	# So with this, we can dodge things now. That's cool.
	if Input.is_action_just_pressed("move_dodge"):
		if can_dodge:
			velocity.x = lerp(velocity.x, move_direction.x * DODGE_AMP, delta * DODGE_SMOOTH)
			velocity.z = lerp(velocity.z, move_direction.z * DODGE_AMP, delta * DODGE_SMOOTH)
			can_dodge = false
			await get_tree().create_timer(DODGE_COOLDOWN).timeout
			can_dodge = true

	# If they on the floor, they can run, lol.
	if is_on_floor():
		if move_direction:
			velocity.x = lerp(velocity.x, move_direction.x * movement_speed, delta * MOVE_SMOOTH)
			velocity.z = lerp(velocity.z, move_direction.z * movement_speed, delta * MOVE_SMOOTH)
		else:
			velocity.x = lerp(velocity.x, move_direction.x * movement_speed, delta * MOVE_SMOOTH)
			velocity.z = lerp(velocity.z, move_direction.z * movement_speed, delta * MOVE_SMOOTH)
	else:
		velocity.x = lerp(velocity.x, move_direction.x * movement_speed, delta * MOVE_SMOOTH)
		velocity.z = lerp(velocity.z, move_direction.z * movement_speed, delta * MOVE_SMOOTH)

	# Bunny hops FTW
	if Input.is_action_pressed("move_jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# I always liked double jumps in games... Metroid did it best.
	if Input.is_action_just_pressed("move_jump") and not is_on_floor():
		if can_afterjump:
			velocity.y = AFTERJUMP_AMP
			can_afterjump = false
	# Prevents infinite Afterjump
	if is_on_floor():
		can_afterjump = true
		
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
