class_name Wheel
extends RayCast3D


@export var visuals : Node3D

@export var radius := 0.2

@export var rest_length := 0.3

@export var stiffness := 20000.0

@export var stiffness_curve : Curve

@export var damping := 1500.0



var _spring_displacement := 0.0

var _suspension_force := 0.0

var _contact_velocity := Vector3.ZERO


func _ready() -> void:
	var total_length := rest_length + radius
	target_position.y = -total_length


func get_suspension_force() -> float:
	return _suspension_force


func is_bottoming_out() -> bool:
	return -_spring_displacement > rest_length


func apply_suspension_force(vehicle_state : PhysicsDirectBodyState3D) -> void:
	if not is_colliding():
		_suspension_force = 0.0
		return

	var up := global_transform.basis.y
	var contact_point := get_collision_point()
	var contact_distance := (global_position - contact_point).dot(up)
	var previous_displacement := _spring_displacement
	_spring_displacement = contact_distance - (rest_length + radius)
	var displacement_velocity = (_spring_displacement - previous_displacement) / vehicle_state.step

	var effective_stiffness := stiffness
	if stiffness_curve != null:
		effective_stiffness *= stiffness_curve.sample_baked(-_spring_displacement / rest_length)
	_suspension_force = -effective_stiffness * _spring_displacement - damping * displacement_velocity

	var force_vector := _suspension_force * up
	var force_position := contact_point - vehicle_state.transform.origin
	vehicle_state.apply_force(force_vector, force_position)

	_contact_velocity = vehicle_state.get_velocity_at_local_position(contact_point - vehicle_state.transform.origin)


func apply_bottom_out_impulse(vehicle_state : PhysicsDirectBodyState3D, virtual_mass : float) -> void:
	var up := global_transform.basis.y
	var wheel_velocity_along_spring := _contact_velocity.dot(up)
	if wheel_velocity_along_spring < 0.0:
		var bottom_out_impulse := -virtual_mass * wheel_velocity_along_spring * up
		var impulse_position := get_collision_point() - vehicle_state.transform.origin
		vehicle_state.apply_force(bottom_out_impulse / vehicle_state.step, impulse_position)
		#vehicle_state.apply_impulse(bottom_out_impulse, impulse_position)
		#_contact_velocity = vehicle_state.get_velocity_at_local_position(get_collision_point() - vehicle_state.transform.origin)


func _physics_process(_delta : float) -> void:
	_update_visuals()


func _update_visuals() -> void:
	if is_colliding():
		visuals.global_position = get_collision_point()
	else:
		visuals.position = target_position

	visuals.position.y += radius
