#  HenJSONSchema Library Documentation

`HenJSONSchema` is a library for Hengo Script that validates data (Dictionaries and Arrays) against a JSON schema, ensuring data structure and types are correct.

## Basic Usage

The main method is `HenJSONSchema.validate(data, schema)`.
- If the data is valid according to the schema, it returns an empty `Array`.
- If the data is invalid, it returns an `Array` of `String`s describing each validation error.

**Example:**

```gdscript
var schema: Dictionary = {
	"type": "object",
	"properties": {
		"name": {"type": "string"},
		"age": {"type": "integer"}
	},
	"required": ["name"]
}

var valid_data: Dictionary = {"name": "Alice", "age": 30}
var errors: Array = HenJSONSchema.validate(valid_data, schema)

if errors.is_empty():
	print("Data is valid!")
else:
	print("Validation errors: ", errors)
```

---

## ✨ Supported Features

### 1. 📦 Object Validation (`object`)

Validates dictionaries, checking their properties and types.

> **Schema Keywords:**
> - `properties`: Defines the allowed keys in the object and the schema for each.
> - `required`: Lists the keys that must be present in the object.

**Example Schema:**
```gdscript
var schema: Dictionary = {
	"type": "object",
	"properties": {
		"name": {"type": "string"},
		"age": {"type": "integer"}
	},
	"required": ["name"]
}
```

**Use Cases:**

| Description | Data | Result |
| :--- | :--- | :--- |
| ✅ Valid (with required and optional properties) | `{ "name": "Alice", "age": 30 }` | `[]` (Valid) |
| ✅ Valid (with only required properties) | `{ "name": "Bob" }` | `[]` (Valid) |
| ❌ Invalid (missing required property) | `{ "age": 30 }` | `[ '... missing required property "name"' ]` |
| ❌ Invalid (incorrect property type) | `{ "name": "Charlie", "age": "twenty" }` | `[ '... type mismatch at root.age: expected integer, but got string ...' ]` |


### 2. ⛓️ Array Validation (`array`)

Validates arrays, ensuring all its items match a specific schema.

> **Schema Keyword:**
> - `items`: Defines the schema that every element in the array must follow.

**Example Schema:**
```gdscript
var schema: Dictionary = {
	"type": "array",
	"items": {"type": "integer"}
}
```

**Use Cases:**

| Description | Data | Result |
| :--- | :--- | :--- |
| ✅ Valid (all items are integers) | `[1, 2, 3]` | `[]` (Valid) |
| ❌ Invalid (one item has the wrong type) | `[1, "two", 3]` | `[ '... type mismatch at root[1]: expected integer, but got string ...' ]` |


### 3. 📝 String Validation (`string`)

Validates strings, including pattern matching with regular expressions (regex).

> **Schema Keyword:**
> - `pattern`: A regular expression that the string must match.

**Example Schema:**
```gdscript
# The string must contain 3 digits, a hyphen, and 2 digits.
var schema: Dictionary = {
	"type": "string",
	"pattern": "^\\d{3}-\\d{2}$"
}
```

**Use Cases:**

| Description | Data | Result |
| :--- | :--- | :--- |
| ✅ Valid (string matches the pattern) | `"123-45"` | `[]` (Valid) |
| ❌ Invalid (string does not match) | `"abc-de"` | `[ '... does not match required pattern ...' ]` |


### 4. 🚫 Logical Validation (`not`)

The `not` keyword is used to ensure that the data does **not** validate against a specific sub-schema.

**Example Schema:**
```gdscript
# The string cannot contain the word "admin".
var schema: Dictionary = {
	"type": "string",
	"not": {"pattern": "admin"}
}
```

**Use Cases:**

| Description | Data | Result |
| :--- | :--- | :--- |
| ✅ Valid (the sub-schema fails) | `"guest"` | `[]` (Valid) |
| ❌ Invalid (the sub-schema succeeds) | `"admin"` | `[ '... value must NOT match the schema ...' ]` |


### 5. 🌳 Nested Validation

HenJSONSchema supports validation of complex, nested data structures.

**Example Schema:**
```gdscript
var schema: Dictionary = {
	"type": "object",
	"properties": {
		"user": {
			"type": "object",
			"properties": {
				"id": {"type": "integer"}
			}
		}
	}
}
```

**Use Cases:**

| Description | Data | Result |
| :--- | :--- | :--- |
| ✅ Valid (correct type in nested object) | `{ "user": { "id": 123 } }` | `[]` (Valid) |
| ❌ Invalid (incorrect type in nested object) | `{ "user": { "id": "a-string" } }` | `[ '... root.user.id: expected integer, but got string ...' ]` |


### 6. 🔗 References (`$ref`, `$defs`, `definitions`)

HenJSONSchema supports schema references using `$ref`, allowing schema reuse and recursive structures.

#### References to Definitions (`$defs` & `definitions`)
Use `$defs` (modern standard) or `definitions` (for backward compatibility) to create reusable schema "components".

**Example Schema with `$defs`:**
```gdscript
var schema: Dictionary = {
	"$defs": {
		"user": {
			"type": "object",
			"properties": {
				"id": {"type": "integer"},
				"name": {"type": "string"}
			},
			"required": ["id"]
		}
	},
	"type": "object",
	"properties": {
		"current_user": {"$ref": "#/$defs/user"},
		"previous_user": {"$ref": "#/$defs/user"}
	}
}
```

#### References to Root (`#`)
A `'$ref': '#'` points to the root schema itself, which is ideal for creating recursive data structures.

**Example Schema (Parent/Children Structure):**
```gdscript
var schema: Dictionary = {
	"type": "object",
	"properties": {
		"name": {"type": "string"},
		"children": {
			"type": "array",
			"items": {"$ref": "#"}
		}
	}
}
```

#### References to Properties
It's possible to reference the schema of another property within the same schema.

**Example Schema:**
```gdscript
var schema: Dictionary = {
	"type": "object",
	"properties": {
		"id": {"type": "integer"},
		"user": {"$ref": "#/properties/id"}
	}
}
```