tool
extends HBoxContainer

var texture:Texture setget setTexture
onready var textureRect = $TextureRect
var id:int
export var showUpAndDown:bool = true setget setShowUpAndDown

signal textureOpened(texture, id, changed)
signal textureRemoved(id)
signal textureMove(id, direction)
	

func setTexture(var tex:Texture):
	texture = tex
	if tex != null:
		textureRect.texture = tex
	else:
		#set to default raster tex
		textureRect.texture = load("res://addons/dynamicplatforms/textures-icons/raster_back.png")
	

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
	$"VBoxContainer/up".visible = show
	$"VBoxContainer/Down".visible = show