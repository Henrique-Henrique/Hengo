@tool
extends Resource

var in_out_ref: Array = []

var name: String = '':
    set(new_name):
        name = new_name
        
        # changing name of all references
        for in_out in in_out_ref:
            in_out.change_name(new_name)
var type: String = 'Variant':
    set(new_type):
        type = new_type

        # changing type of all references
        for in_out in in_out_ref:
            in_out.change_type(new_type)