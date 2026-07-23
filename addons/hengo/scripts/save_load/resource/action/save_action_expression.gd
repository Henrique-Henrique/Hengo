@tool
class_name HenSaveActionExpression extends Resource

# free-text GDScript expression used as an action input value
@export var code: String = ''
# the expression's free identifiers, each an editable prop (name = identifier)
@export var words: Array[HenSaveParam]
# word_name -> bind_code (var/prop); absent = literal (raw code fragment)
@export var word_bindings: Dictionary
