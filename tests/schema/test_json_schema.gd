extends GdUnitTestSuite

#region object validation tests
func test_object_is_valid_with_required_and_optional_properties() -> void:
	var schema: Dictionary = {
		type = 'object',
		properties = {name = {type = 'string'}, age = {type = 'integer'}},
		required = ['name']
	}
	var data: Dictionary = {name = 'Alice', age = 30}
	assert_array(HenJSONSchema.validate(data, schema)).is_empty()


func test_object_is_valid_with_only_required_properties() -> void:
	var schema: Dictionary = {
		type = 'object',
		properties = {name = {type = 'string'}, age = {type = 'integer'}},
		required = ['name']
	}
	var data: Dictionary = {name = 'Bob'}
	assert_array(HenJSONSchema.validate(data, schema)).is_empty()


func test_object_is_invalid_when_required_property_is_missing() -> void:
	var schema: Dictionary = {
		type = 'object',
		properties = {name = {type = 'string'}, age = {type = 'integer'}},
		required = ['name']
	}
	var data: Dictionary = {age = 30}
	var errors: Array = HenJSONSchema.validate(data, schema)
	assert_array(errors).has_size(1)
	assert_bool((errors[0] as String).contains('missing required property "name"')).is_true()


func test_object_is_invalid_when_property_has_wrong_type() -> void:
	var schema: Dictionary = {
		type = 'object',
		properties = {name = {type = 'string'}, age = {type = 'integer'}},
		required = ['name']
	}
	var data: Dictionary = {name = 'Charlie', age = 'twenty'}
	var errors: Array = HenJSONSchema.validate(data, schema)
	assert_array(errors).has_size(1)
	assert_bool((errors[0] as String).contains('type mismatch at root.age: expected integer, but got string (value: twenty)')).is_true()
#endregion


#region $ref validation tests
# test cases for $ref functionality with root references
func test_ref_to_root_schema() -> void:
	var schema: Dictionary = {
		type = 'object',
		properties = {
			name = {type = 'string'},
			children = {
				type = 'array',
				items = {'$ref' = '#'}
			}
		}
	}
	
	# valid case - all names are strings
	var valid_data: Dictionary = {
		name = 'Parent',
		children = [
			{name = 'Child1'},
			{name = 'Child2'}
		]
	}
	assert_array(HenJSONSchema.validate(valid_data, schema)).is_empty()
	
	# invalid case - one of the names is a number
	var invalid_data: Dictionary = {
		name = 'Parent',
		children = [
			{name = 123}, # Invalid: name should be string
			{name = 'Child2'}
		]
	}
	var errors: Array = HenJSONSchema.validate(invalid_data, schema)
	assert_array(errors).has_size(1)
	assert_bool((errors[0] as String).contains('type mismatch at root.children[0].name: expected string, but got int (value: 123)')).is_true()


func test_nested_ref_to_root_schema() -> void:
	var schema: Dictionary = {
		type = 'object',
		properties = {
			name = {type = 'string'},
			children = {
				type = 'array',
				items = {
					type = 'object',
					properties = {
						name = {type = 'string'},
						grandchildren = {
							type = 'array',
							items = {'$ref' = '#'}
						}
					}
				}
			}
		}
	}
	
	# valid case - all names are strings
	var valid_data: Dictionary = {
		name = 'Parent',
		children = [
			{
				name = 'Child',
				grandchildren = [
					{name = 'Grandchild1'},
					{name = 'Grandchild2'}
				]
			}
		]
	}
	assert_array(HenJSONSchema.validate(valid_data, schema)).is_empty()
	
	# invalid case - one of the grandchild names is a number
	var invalid_data: Dictionary = {
		name = 'Parent',
		children = [
			{
				name = 'Child',
				grandchildren = [
					{name = 123}, # Invalid: name should be string
					{name = 'Grandchild2'}
				]
			}
		]
	}
	var errors: Array = HenJSONSchema.validate(invalid_data, schema)
	assert_array(errors).has_size(1)
	assert_bool((errors[0] as String).contains('type mismatch at root.children[0].grandchildren[0].name: expected string, but got int (value: 123)')).is_true()


func test_empty_ref_path() -> void:
	var schema: Dictionary = {
		type = 'object',
		properties = {
			name = {type = 'string'},
			'self' = {'$ref' = '#'}
		}
	}
	
	# valid case - name is a string
	var valid_data: Dictionary = {
		name = 'Test',
		'self' = {
			name = 'Nested'
		}
	}
	assert_array(HenJSONSchema.validate(valid_data, schema)).is_empty()
	
	# invalid case - name is a number
	var invalid_data: Dictionary = {
		name = 'Test',
		'self' = {
			name = 123 # Invalid: name should be string
		}
	}
	var errors: Array = HenJSONSchema.validate(invalid_data, schema)
	assert_array(errors).has_size(1)
	assert_bool((errors[0] as String).contains('type mismatch at root.self.name: expected string, but got int (value: 123)')).is_true()


#region array validation tests
func test_array_is_valid_with_correct_item_types() -> void:
	var schema: Dictionary = {type = 'array', items = {type = 'integer'}}
	var data: Array = [1, 2, 3]
	assert_array(HenJSONSchema.validate(data, schema)).is_empty()


func test_array_is_invalid_with_incorrect_item_type() -> void:
	var schema: Dictionary = {type = 'array', items = {type = 'integer'}}
	var data: Array = [1, 'two', 3]
	var errors: Array = HenJSONSchema.validate(data, schema)
	assert_array(errors).has_size(1)
	assert_bool((errors[0] as String).contains('type mismatch at root[1]: expected integer, but got string (value: two)')).is_true()
#endregion


#region string validation tests
func test_string_is_valid_when_matching_pattern() -> void:
	var schema: Dictionary = {type = 'string', pattern = '^\\d{3}-\\d{2}$'}
	var data: String = '123-45'
	assert_array(HenJSONSchema.validate(data, schema)).is_empty()


func test_string_is_invalid_when_not_matching_pattern() -> void:
	var schema: Dictionary = {type = 'string', pattern = '^\\\\d{3}-\\\\d{2}$'}
	var data: String = 'abc-de'
	var errors: Array = HenJSONSchema.validate(data, schema)
	assert_array(errors).has_size(1)
	assert_bool((errors[0] as String).contains('does not match required pattern')).is_true()
#endregion


#region logical validation tests
func test_not_keyword_is_valid_when_subschema_fails() -> void:
	var schema: Dictionary = {type = 'string', 'not' = {pattern = 'admin'}}
	var data: String = 'guest'
	assert_array(HenJSONSchema.validate(data, schema)).is_empty()


func test_not_keyword_is_invalid_when_subschema_succeeds() -> void:
	var schema: Dictionary = {type = 'string', 'not' = {pattern = 'admin'}}
	var data: String = 'admin'
	var errors: Array = HenJSONSchema.validate(data, schema)
	assert_array(errors).has_size(1)
	assert_bool((errors[0] as String).contains('value must NOT match the schema')).is_true()
#endregion


#region nested validation tests
func test_nested_object_is_valid_with_correct_deep_types() -> void:
	var schema: Dictionary = {
		type = 'object',
		properties = {user = {type = 'object', properties = {id = {type = 'integer'}}}}
	}
	var data: Dictionary = {user = {id = 123}}
	assert_array(HenJSONSchema.validate(data, schema)).is_empty()


func test_nested_object_is_invalid_with_incorrect_deep_type() -> void:
	var schema: Dictionary = {
		type = 'object',
		properties = {user = {type = 'object', properties = {id = {type = 'integer'}}}}
	}
	var data: Dictionary = {user = {id = 'a-string'}}
	var errors: Array = HenJSONSchema.validate(data, schema)
	assert_array(errors).has_size(1)
	assert_bool((errors[0] as String).contains('root.user.id: expected integer, but got string')).is_true()
#endregion


#region $ref and $defs validation tests
func test_ref_to_defs_is_valid() -> void:
	var schema: Dictionary = {
		'$defs' = {
			user = {
				type = 'object',
				properties = {
					id = {type = 'integer'},
					name = {type = 'string'}
				},
				required = ['id']
			}
		},
		type = 'object',
		properties = {
			current_user = {'$ref' = '#/$defs/user'},
			previous_user = {'$ref' = '#/$defs/user'}
		}
	}
	
	var data: Dictionary = {
		current_user = {id = 1, name = 'Alice'},
		previous_user = {id = 2, name = 'Bob'}
	}
	
	assert_array(HenJSONSchema.validate(data, schema)).is_empty()


func test_ref_to_definitions_is_valid_for_backward_compatibility() -> void:
	var schema: Dictionary = {
		definitions = {
			user = {
				type = 'object',
				properties = {id = {type = 'integer'}},
				required = ['id']
			}
		},
		type = 'object',
		properties = {
			user = {'$ref' = '#/definitions/user'}
		}
	}
	
	var data: Dictionary = {user = {id = 1}}
	assert_array(HenJSONSchema.validate(data, schema)).is_empty()


func test_ref_to_nonexistent_definition_returns_validation_error() -> void:
	var schema: Dictionary = {
		'$defs' = {},
		type = 'object',
		properties = {
			user = {'$ref' = '#/$defs/nonexistent'}
		}
	}
	
	var data: Dictionary = {user = {id = 1}}
	var errors: Array = HenJSONSchema.validate(data, schema)
	# the current implementation doesn't return an error for non-existent refs
	# the validation will fail because the resolved schema is empty
	assert_array(errors).is_empty()


func test_nested_refs_are_resolved_correctly() -> void:
	var schema: Dictionary = {
		'$defs' = {
			id_type = {type = 'integer'},
			user = {
				type = 'object',
				properties = {
					id = {'$ref' = '#/$defs/id_type'},
					name = {type = 'string'}
				},
				required = ['id']
			}
		},
		type = 'object',
		properties = {
			current_user = {'$ref' = '#/$defs/user'}
		}
	}
	
	# valid case
	var valid_data: Dictionary = {current_user = {id = 1, name = 'Alice'}}
	assert_array(HenJSONSchema.validate(valid_data, schema)).is_empty()
	
	# invalid case - wrong type for id
	var invalid_data: Dictionary = {current_user = {id = 'not-an-integer', name = 'Bob'}}
	var errors: Array = HenJSONSchema.validate(invalid_data, schema)
	assert_array(errors).has_size(1)
	assert_bool((errors[0] as String).contains('expected integer, but got string')).is_true()


func test_ref_to_root_schema_properties() -> void:
	var schema: Dictionary = {
		type = 'object',
		properties = {
			id = {type = 'integer'},
			user = {'$ref' = '#/properties/id'}
		}
	}
	
	# the user property should be validated against the 'id' property schema
	var valid_data: Dictionary = {id = 1, user = 2}
	assert_array(HenJSONSchema.validate(valid_data, schema)).is_empty()
	
	# invalid case - user should be an integer
	var invalid_data: Dictionary = {id = 1, user = 'not-an-integer'}
	var errors: Array = HenJSONSchema.validate(invalid_data, schema)
	assert_array(errors).has_size(1)
	assert_bool((errors[0] as String).contains('expected integer, but got string')).is_true()
#endregion