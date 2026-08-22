extends CharacterBody2D

@export var SPEED := 600.0
@export var ACCELERATION := 5000.0
@export var FRICTION := 5000.0
@export var FALL_VELOCITY := -800.0
@export var TERMINAL_VELOCITY := 3000.0
@export var DASH_SPEED := Vector2(1200, 800)

var direction := Vector2()
var dash_token = 1
var dash_limit = 1
var topvelocity := Vector2(0.0, 0.0)
var wall : Vector2
var detection: Vector2
enum States
{
	NEUTRAL,
	FALL,
	DASH,
	ATTACK,
	DEFLECT
}
enum Surface
{
	GROUND,
	WALL
}
var _state : States = States.NEUTRAL
var _last_touched_surface: Surface

func _ready():
	pass
func _physics_process(delta):
	state_machine(delta)
	indicator()
	debug()
	move_and_slide()
func state_machine(delta):
	match _state:
		States.NEUTRAL:
			state_neutral(delta)
		States.FALL:
			state_fall(delta)
		States.DASH:
			state_dash(direction)
		States.ATTACK:
			state_attack()
		States.DEFLECT:
			state_deflect()

func set_state(new_state: States): # DRY.
	if new_state == _state:
		return
	_state = new_state

func state_neutral(delta): # Stand, walk and enjoy laws of the universe.
	walk(delta)
	gravity(delta)
	koyote()
	jump()
	dash()
	
func state_fall(delta): # You're now free falling.
	walk(delta)
	gravity(delta)
	if is_on_floor() or is_on_wall_only() or $WallDetector.is_colliding():
		set_state(States.NEUTRAL)
	dash()

func state_dash(to: Vector2): # Defy gravity, move fast and avoid damage.
	if to:
		velocity = to.normalized() * DASH_SPEED
	else:
		velocity.x = DASH_SPEED.x * $Placeholder.scale.x
	if $DashTimer.is_stopped():
		set_state(States.NEUTRAL)

func state_attack(): # TODO: Deal damage, finish posture broken opponents.
	pass

func state_deflect(): # TODO: Prevent taking damage and deal posture damage in return also send back projectiles.
	pass

func walk(delta):
	# Get the input direction and handle the movement/deceleration.
	direction = Input.get_vector("action_left", "action_right","action_up", "action_down")
	var velocity_weight: float = (ACCELERATION if direction else FRICTION) * delta
	
		# Smooth accel/decel movement.
	if direction.x:
		velocity.x = move_toward(velocity.x, roundf(direction.x) * SPEED, velocity_weight)
		$WallDetector.scale.x = round(direction.x)
	else:
		velocity.x = move_toward(velocity.x, 0, velocity_weight)

func jump(): # They see me jumpin', they hatin'

	if is_on_floor():
		_last_touched_surface = Surface.GROUND
	if $WallDetector.is_colliding() and not is_on_floor():
		_last_touched_surface = Surface.WALL
		wall = $WallDetector.get_collision_normal(0)
		$WallJumpTimer.start()
	if Input.is_action_just_pressed("action_jump"):
			match _last_touched_surface:
				Surface.GROUND:
					if $KoyoteTimer.time_left > 0:
						velocity.y = FALL_VELOCITY
						$KoyoteTimer.stop()
						$WallJumpTimer.stop()
						set_state(States.FALL)
				Surface.WALL:
					if $WallJumpTimer.time_left > 0:
						velocity.y = FALL_VELOCITY
						velocity.x = FALL_VELOCITY * -wall.x
						$KoyoteTimer.stop()
						$WallJumpTimer.stop()
						set_state(States.FALL)

func dash(): # Gravity need not apply.
	if is_on_floor():
		dash_token = dash_limit # This resets you ability to dash.
	if Input.is_action_just_pressed("action_dash"):
		if $DashDelay.is_stopped() and dash_token > 0:
			dash_token -= 1
			$DashTimer.start()
			$DashDelay.start()
			set_state(States.DASH)

func gravity(delta): # Applies global world gravity to the player.
	#if Input.is_action_just_pressed("action_down"):
		if is_on_floor():
			air_drag(false)
		if not is_on_floor():
			velocity += get_gravity() * delta
			air_drag(true)
			if $WallDetector.is_colliding():
				if velocity.y > 400 and direction.y < 1:
					velocity.y = 400
			if velocity.y > TERMINAL_VELOCITY:
				velocity.y = TERMINAL_VELOCITY

func koyote(): # I can fly now.
	if is_on_floor():
		$KoyoteTimer.start()
	if $KoyoteTimer.time_left > 0:
		if velocity.y > 0:
			velocity.y = 0

func air_drag(on: bool): # This will prevent climbing up walls.
	if on:
		ACCELERATION = 2000.0
		FRICTION = 2000.0
	else:
		ACCELERATION = 5000.0
		FRICTION = 5000.0

func indicator(): # For testing and differentiating all states the player could be in.
	if not $DashTimer.is_stopped():
			$Placeholder.set_modulate(Color("Green"))
	if $DashTimer.is_stopped() and not $DashDelay.is_stopped():
		$Placeholder.set_modulate(Color("Blue"))
	if $DashDelay.is_stopped() and $KoyoteTimer.time_left > 0 and $KoyoteTimer.time_left != $KoyoteTimer.wait_time:
		$Placeholder.set_modulate(Color("Yellow"))
	if $DashDelay.is_stopped() and $WallJumpTimer.time_left > 0 and $WallJumpTimer.time_left != $WallJumpTimer.wait_time:
			$Placeholder.set_modulate(Color("Purple"))
	if $DashTimer.is_stopped() and $DashDelay.is_stopped() and not is_on_floor() and dash_token <= 0 and $KoyoteTimer.is_stopped():
			$Placeholder.set_modulate(Color("Red"))
	if $DashTimer.is_stopped() and $DashDelay.is_stopped() and is_on_floor()\
	or $DashTimer.is_stopped() and $DashDelay.is_stopped() and dash_token > 0 and $KoyoteTimer.is_stopped() and $WallJumpTimer.is_stopped():
			$Placeholder.set_modulate(Color("White"))
	#Skew player face
	if direction.x:
		$Placeholder/Face.set_skew(deg_to_rad(13.5))
		$Placeholder.scale.x = round(direction.x)
	else:
		$Placeholder/Face.set_skew(deg_to_rad(0))

func debug(): # Useful or interesting info.
	if abs(velocity.x) > abs(topvelocity.x):
		topvelocity.x = roundf(abs(velocity.x))
	if abs(velocity.y) > abs(topvelocity.y):
		topvelocity.y = roundf(abs(velocity.y))
	var debug_state: String
	for key in States:
		if States[key] == _state:
			debug_state = key
	$Debug.text = \
	"Current State: "+str(debug_state) + "\n" + \
	"Top Velocity.x: "+str(topvelocity.x) + "\n" + \
	"Top Velocity.y: "+str(topvelocity.y) + "\n" + \
	"WallDetector: " + str(wall)
