tool
extends EditorPlugin

var dock
var master_folder

func _enter_tree():
	#find out the plugin folder name
	master_folder = get_path()
	
	# Initialization of the plugin goes here
	# Add the new type with a name, a parent type, a script and an icon
	dock = preload("StyleEditor/StyleEditor.tscn").instance()
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, dock)

func _exit_tree():
	# Clean-up of the plugin goes here
	# Always remember to remove it from the engine when deactivated
	remove_control_from_docks(dock)
	dock.free()
