tool
class_name TextureSelector
extends PanelContainer

# This is a custom build Control node to select a texture, the texture can be
# read from the texture variable. Show_up_and_down is used to hide or show up 
# and down buttons to be used in ordering by StyleEditor. (probably need a 
# cleaner way of handling this) The below listed signals are used to communicate
# with other classes.

# signals for actions performed on the texture
signal texture_opened(texture, id, changed)
signal texture_removed(id)
signal texture_moved(id, direction)

# variable that determines wheter the up and down buttons are shown this makes
# it easy to disable in case its used outside of the angle ranges
export var show_up_and_down:bool = true setget set_show_up_and_down

# the texture that is set for this texture selector
var texture:Texture = null setget set_texture

# the internal id of the texture used to order the textures and reload them when
# loading the style or changing active range
var id:int

# reference to get the texture to set to draw the preview
onready var texture_rect = $HBoxContainer/TextureRect


func set_texture(var tex:Texture):
	texture = tex
	if tex != null:
		texture_rect.texture_normal = tex
	else:
		# set to default raster tex
		texture_rect.texture_normal = load("addons/dynamicplatforms/textures-icons/raster_back.png")


func set_show_up_and_down(var show:bool):
	show_up_and_down = show
	$"HBoxContainer/VBoxContainer/up".visible = show
	$"HBoxContainer/VBoxContainer/down".visible = show


# the following functions emit signals correstponding to the buttons pressed
# and do related actions this centralises the signals to a place that a instance
# of this scene can use
func _on_FileDialog_file_selected(path):
	var changed = !(texture == null)
	set_texture(load(path))
	emit_signal("texture_opened", texture, id, changed)


func _on_remove_pressed():
	set_texture(null)
	emit_signal("texture_removed", id)


func _on_up_pressed():
	emit_signal("texture_moved", id, -1)


func _on_Down_pressed():
	emit_signal("texture_moved", id, 1)



func _on_hide_toggled(button_pressed):
	$"HBoxContainer/VBoxContainer/open".visible = !button_pressed
	$"HBoxContainer/VBoxContainer/up".visible = !button_pressed
	$"HBoxContainer/VBoxContainer/down".visible = !button_pressed
	$"HBoxContainer/VBoxContainer/remove".visible = !button_pressed
	texture_rect.visible = !button_pressed
	update()


