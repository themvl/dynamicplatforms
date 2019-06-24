tool
extends EditorPlugin

#var dynamicplatform_script = preload("res://addons/dynamicplatforms/dynamicplatform.gd")
#var dynamicplatformstyle_script = preload("res://addons/dynamicplatforms/dynamicplatformstyle.gd")
#var HBoxContainer2_script = preload("res://addons/dynamicplatforms/HBoxContainer2.gd")
#var radiusrange_script = preload("res://addons/dynamicplatforms/radiusrange.gd")
#var textureselector_script = preload("res://addons/dynamicplatforms/textureselector.gd")
#var VBoxContainer_script = preload("res://addons/dynamicplatforms/VBoxContainer.gd")

var dock

func _enter_tree():
    # Initialization of the plugin goes here
    # Add the new type with a name, a parent type, a script and an icon
	dock = preload("res://addons/dynamicplatforms/menu_circlecontrol.tscn").instance()
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, dock)


func _exit_tree():
    # Clean-up of the plugin goes here
    # Always remember to remove it from the engine when deactivated
	remove_control_from_docks(dock)
	dock.free()