@tool
class_name TestHenFlowHistoryDigest extends HenTestSuite

# the digest is what decides whether an edit happened at all: a stored field it
# does not read is a field undo silently refuses to restore. the sweep walks the
# resource itself, so a field added later has to answer for itself here

# nothing about these reaches the generated script, so they are out on purpose
const OUT_OF_DIGEST: Array[String] = ['name']


func _stored_fields(_action: HenSaveAction) -> Array[String]:
	var out: Array[String] = []

	for prop: Dictionary in _action.get_property_list():
		if int(prop.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE == 0:
			continue

		if int(prop.usage) & PROPERTY_USAGE_STORAGE == 0:
			continue

		out.append(str(prop.name))

	return out


# a typed value the field did not already hold. set() drops a mismatched type in
# silence, so a probe of the wrong type would read as a digest that ignores it
func _probes() -> Dictionary:
	var expression: HenSaveActionExpression = HenSaveActionExpression.new()

	expression.code = 'probe'

	# typed arrays refuse an untyped literal through set(), which reads as a field the
	# digest ignores instead of as a bad probe
	var params: Array[HenSaveParam] = [HenSaveParam.create({name = 'Probe', type = 'int', id = &'probe'})]
	var steps: Array[HenSaveAction] = [HenSaveAction.new()]

	return {
		id = &'probe_id',
		macro_id = &'probe_macro',
		inputs = params,
		input_bindings = {probe = 'probe_var'},
		input_expressions = {probe = expression},
		input_actions = {probe = {action = HenSaveAction.new(), output = &'result'}},
		input_wires = {probe = {action_id = &'7', output = &'collider'}},
		phase = &'exit',
		branches = {probe = {state_id = &'7', label = ''}},
		output_bindings = {probe = 'probe_var'},
		body_actions = steps,
		branch_actions = {probe = [HenSaveAction.new()]},
		disabled = true,
		label = 'probe'
	}


func test_every_stored_field_of_an_action_reaches_the_digest() -> void:
	var probes: Dictionary = _probes()
	var fields: Array[String] = _stored_fields(HenSaveAction.new())

	assert_int(fields.size()).is_greater(5)

	for field: String in fields:
		if OUT_OF_DIGEST.has(field):
			continue

		assert_bool(probes.has(field)).override_failure_message(
			'field "' + field + '" is new here: give it a probe value and check the digest reads it'
		).is_true()

		if not probes.has(field):
			continue

		var action: HenSaveAction = HenSaveAction.new()
		var before: String = HenFlowHistory.digest([action])

		action.set(field, probes[field])

		assert_str(var_to_str(action.get(field))).override_failure_message(
			'the probe for "' + field + '" was refused, so it is the wrong type'
		).is_not_equal(var_to_str(HenSaveAction.new().get(field)))

		assert_str(HenFlowHistory.digest([action])).override_failure_message(
			'field "' + field + '" is stored but the digest ignores it, so undo drops it'
		).is_not_equal(before)


# the three this sweep was written for: the wire, and the mute and the rename it
# turned up on the way
func test_a_wire_a_mute_and_a_label_each_change_the_digest() -> void:
	var plain: String = HenFlowHistory.digest([HenSaveAction.new()])
	var wired: HenSaveAction = HenSaveAction.new()
	var muted: HenSaveAction = HenSaveAction.new()
	var named: HenSaveAction = HenSaveAction.new()

	wired.input_wires['value'] = {action_id = &'7', output = &'collider'}
	muted.disabled = true
	named.label = 'renamed'

	assert_str(HenFlowHistory.digest([wired])).is_not_equal(plain)
	assert_str(HenFlowHistory.digest([muted])).is_not_equal(plain)
	assert_str(HenFlowHistory.digest([named])).is_not_equal(plain)
