extends CharacterBody2D

@export var SPEED := 600.0
@export var ACCELERATION := 5000.0
@export var FRICTION := 5000.0
@export var JUMP_VELOCITY := -800.0
@export var TERMINAL_VELOCITY := 3000.0
@export var DASH_SPEED := Vector2(1200, 800)

var direction := Vector2()
var DashToken = 1
var DashLimit = 1
var topvelocity := Vector2(0.0, 0.0)
var koyote:= true
var goat:= false
var wall:= Vector2(0, 0)

func _physics_process(delta):
	PlayerMovement(delta)
	Indicator()
	Debug()
	move_and_slide()

func PlayerMovement(delta):
	# Get the input direction and handle the movement/deceleration.
	direction = Input.get_vector("action_left", "action_right","action_up", "action_down")
	var velocity_weight: float = (ACCELERATION if direction else FRICTION) * delta
	
	# Koyote + Air Drag
	if is_on_floor() and not koyote:
		$KoyoteTimer.stop()
		koyote = true
		ACCELERATION = 5000.0
		FRICTION = 5000.0
	if not is_on_floor() and koyote:
		koyote = false
		$KoyoteTimer.start()
	
	# Gravity.
	if not is_on_floor() and $DashTimer.is_stopped() and $KoyoteTimer.is_stopped():
		# Wall friction
		ACCELERATION = 2000.0
		FRICTION = 2000.0
		if is_on_wall_only() and velocity.y > 400 and not direction.y == 1:
			velocity.y = 400
		else:
			velocity += get_gravity() * delta
			if velocity.y > TERMINAL_VELOCITY:
				velocity.y = TERMINAL_VELOCITY
			

	# Handle jump.
	if Input.is_action_just_pressed("action_jump"):
		if is_on_floor() or not is_on_floor() and $KoyoteTimer.time_left > 0:
			velocity.y = JUMP_VELOCITY
			koyote = false
			$KoyoteTimer.stop()
		if is_on_wall_only() or not is_on_wall_only() and $KoyoteTimer.time_left > 0:
			wall = get_wall_normal()
			velocity.x = JUMP_VELOCITY * 0.8 * -wall.x
			velocity.y = JUMP_VELOCITY
			koyote = false
			$KoyoteTimer.stop()



	#Basic movement
	if direction.x and $DashTimer.is_stopped():
		velocity.x = move_toward(velocity.x, roundf(direction.x) * SPEED, velocity_weight)
	else:
		if $DashTimer.is_stopped():
			velocity.x = move_toward(velocity.x, 0, velocity_weight)

# Dash mechanic WIP
	if is_on_floor() and DashToken == 0:
		DashToken = DashLimit
	if Input.is_action_just_pressed("action_dash") and $DashTimer.is_stopped() and $DashDelay.is_stopped() and DashToken > 0:
		velocity = Vector2.ZERO
		$DashTimer.start()
		$DashDelay.start()
		$KoyoteTimer.stop()
		DashToken -= 1
		if direction:
			velocity = direction.normalized() * DASH_SPEED
		else:
			velocity.x = DASH_SPEED.x * $Placeholder.scale.x

func Indicator(): # For testing and debugging
	# Dash Christmas tree
	if not $DashTimer.is_stopped():
		$Placeholder.set_modulate(Color("Green"))
	if $DashTimer.is_stopped() and not $DashDelay.is_stopped() or $KoyoteTimer.time_left > 0:
		$Placeholder.set_modulate(Color("Yellow"))
	if $DashTimer.is_stopped() and $DashDelay.is_stopped() and not is_on_floor() and DashToken <= 0 and $KoyoteTimer.is_stopped():
		$Placeholder.set_modulate(Color("Red"))
	if $DashTimer.is_stopped() and $DashDelay.is_stopped() and is_on_floor() or $DashTimer.is_stopped() and $DashDelay.is_stopped() and DashToken > 0 and $KoyoteTimer.is_stopped():
		$Placeholder.set_modulate(Color("White"))
	
	#Skew player face
	if direction.x:
		$Placeholder/Face.set_skew(deg_to_rad(13.5))
		$Placeholder.scale.x = round(direction.x)
	else:
		$Placeholder/Face.set_skew(deg_to_rad(0))

func Debug(): # Useful info
	if abs(velocity.x) > abs(topvelocity.x):
		topvelocity.x = roundf(abs(velocity.x))
	if abs(velocity.y) > abs(topvelocity.y):
		topvelocity.y = roundf(abs(velocity.y))
	$Debug.text = \
	"Top Velocity.x: "+str(topvelocity.x) + "\n" + \
	"Top Velocity.y: "+str(topvelocity.y) + "\n" + \
	"Wall Normal: " + str(get_wall_normal().x)
