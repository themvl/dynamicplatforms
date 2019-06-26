tool
extends PanelContainer

#the texture that is set for this texture selector
var texture:Texture setget setTexture

#variable that determines wheter the up and down buttons are shown this makes it easy to disable in case its used outside of the angle ranges
export var showUpAndDown:bool = true setget setShowUpAndDown

#reference to get the texture to set to draw the preview
onready var textureRect = $HBoxContainer/TextureRect

#the internal id of the texture used to order the textures and reload them when loading the style or changing active range
var id:int

#signals for actions performed on the texture
signal textureOpened(texture, id, changed)
signal textureRemoved(id)
signal textureMove(id, direction)

#the following functions emit signals correstponding to the buttons pressed
#and do related actions this centralises the signals to a place that a instance of thsi scene can use
func _on_FileDialog_file_selected(path):
	var changed = texture == null
	setTexture(load(path))
	emit_signal("textureOpened", texture, id, changed)

func _on_remove_pressed():
	setTexture(null)
	emit_signal("textureRemoved",id)

func _on_up_pressed():
	emit_signal("textureMove", id, -1)

func _on_Down_pressed():
	emit_signal("textureMove", id, 1)

func setShowUpAndDown(var show:bool):
	showUpAndDown = show
	$"HBoxContainer/VBoxContainer/up".visible = show
	$"HBoxContainer/VBoxContainer/Down".visible = show

func setTexture(var tex:Texture):
	texture = tex
	if tex != null:
		textureRect.texture = tex
	else:
		#set to default raster tex
		textureRect.texture = load("res://addons/dynamicplatforms/textures-icons/raster_back.png")
