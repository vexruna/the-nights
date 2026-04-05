extends CharacterBody2D

@export var SPEED := 500.0
@export var ACCELERATION := 1920.0
@export var FRICTION := 1920.0
@export var JUMP_VELOCITY := -700.0
@export var DASH_SPEED := 1200.0
@export var DASH_SPEED_V := 900.0
var DashToken = 1
var DashLimit = 2
var topvelocity := Vector2(0.0, 0.0)

func _physics_process(delta):
	PlayerMovement(delta)
	DashIndicator()
	TopVelocity()
	move_and_slide()

func PlayerMovement(delta):
	# Add the gravity.
	if not is_on_floor() and $DashTimer.is_stopped():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("action_jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var direction = Vector2()
	direction = Input.get_vector("action_left", "action_right","action_up", "action_down")
	var velocity_weight: float = (ACCELERATION if direction else FRICTION) * delta

	#Basic movement
	if direction.x and $DashTimer.is_stopped():
		velocity.x = move_toward(velocity.x, direction.x * SPEED, velocity_weight)
	else:
		if $DashTimer.is_stopped():
			velocity.x = move_toward(velocity.x, 0, velocity_weight)

	#Skew player face (Testing purposes only)
	if direction.x:
		$Placeholder/Face.set_skew(deg_to_rad(13.5))
		$Placeholder.scale.x = round(direction.x)
	else:
		$Placeholder/Face.set_skew(deg_to_rad(0))

# Dash mechanic WIP
	if is_on_floor():
		DashToken = DashLimit
	if Input.is_action_just_pressed("action_dash") and $DashTimer.is_stopped() and $DashDelay.is_stopped() and DashToken > 0:
		velocity = Vector2.ZERO
		$DashTimer.start()
		$DashDelay.start()
		DashToken -= 1
		if direction:
			if direction.y and not direction.x:
				velocity = direction.normalized() * DASH_SPEED_V
				return
			velocity = direction.normalized() * DASH_SPEED
		else:
			velocity.x += DASH_SPEED * $Placeholder.scale.x

func DashIndicator():
	if not $DashTimer.is_stopped():
		$Placeholder.set_modulate(Color("Green"))
	if $DashTimer.is_stopped() and not $DashDelay.is_stopped():
		$Placeholder.set_modulate(Color("Yellow"))
	if $DashTimer.is_stopped() and $DashDelay.is_stopped() and not is_on_floor() and DashToken <= 0:
		$Placeholder.set_modulate(Color("Red"))
	if $DashTimer.is_stopped() and $DashDelay.is_stopped() and is_on_floor() or $DashTimer.is_stopped() and $DashDelay.is_stopped() and DashToken > 0:
		$Placeholder.set_modulate(Color("White"))

func TopVelocity():
	if abs(velocity.x) > topvelocity.x:
		topvelocity.x = velocity.x
		$VectorText.text = "Top Velocity.x: " + str(topvelocity.x)
	if abs(velocity.y) > topvelocity.y:
		topvelocity.y = velocity.y
		$VectorText2.text = "Top Velocity.y: " + str(topvelocity.y)
