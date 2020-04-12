tool
extends VBoxContainer

var textureselectorscene = preload("textureselector.tscn")
onready var textureselectors = $textureselectors
var texturecount = 0
#var texture:Texture = null

func _on_Button_pressed():
	#instance new textureselector scene
	addNewTexturePanel()
	print("button press")
	textureselectors.get_child(0).get_child(0).emit_signal("textureOpened", null, texturecount-1, false)

func addNewTexturePanel( var texture = null):
	var instance = textureselectorscene.instance()
	instance.set_name("textureselector")
	instance.connect("texture_opened", $"../../../../Anglerangeselector", "_on_texture_loaded")
	instance.connect("texture_removed", $"../../../../Anglerangeselector", "_on_texture_removed")
	instance.connect("texture_moved", $"../../../../Anglerangeselector", "_on_texture_moved")
	textureselectors.add_child(instance)
	
	instance.set_texture(texture)
	instance.id = texturecount
#	if texturecount == 0:
#		texture = texture
	texturecount +=1

func _on_showhidebutton_toggled(button_pressed):
	$textureselectors.visible = !button_pressed
	$Button.visible = !button_pressed
