@tool
class_name HenCodeSearch extends TabContainer

const CODE_SEARCH = preload('res://addons/hengo/scenes/code_search.tscn')
const CODE_SEARCH_ITEM = preload('res://addons/hengo/scenes/code_search_item.tscn')

var target_class: StringName

const DATA: Dictionary = {
	'Button' = ['Focus']
}

const DATA_LIST: Dictionary = {
	'Focus' = [
		{
			name = 'grab_focus'
		}
	]
}

func _ready() -> void:
	set_current_tab(0)
	HenApiFinder.get_class_api(target_class)
	update()


func update() -> void:
	for chd in %Container.get_children():
		chd.queue_free()

	for key: String in DATA.keys():
		var item = CODE_SEARCH_ITEM.instantiate()
		(item.get_node('%Name') as Button).text = key

		for subcategory: String in DATA[key]:
			var bt: Button = Button.new()
			bt.text = subcategory
			bt.pressed.connect(on_subcategory_click.bind(DATA_LIST[subcategory]))
			item.get_node('%SubCategoryContainer').add_child(bt)

		%Container.add_child(item)
	

func on_subcategory_click(_api_list: Array) -> void:
	set_current_tab(1)
	show_api_list(_api_list)


func show_api_list(_list: Array) -> void:
	var item_list: ItemList = %ItemList
	item_list.clear()

	for item: Dictionary in _list:
		item_list.add_item(item.name)
	

static func load(_class_name: StringName) -> HenCodeSearch:
	var code_search: HenCodeSearch = CODE_SEARCH.instantiate()
	code_search.target_class = _class_name
	return code_search
