tool
extends VBoxContainer

var textureselectorscene = load("res://addons/dynamicplatforms/StyleEditor/textureselector.tscn")
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
	instance.get_node("HBoxContainer2").connect("textureOpened", $"../../../../Anglerangeselector", "_on_texture_loaded")
	instance.get_node("HBoxContainer2").connect("textureRemoved", $"../../../../Anglerangeselector", "_on_texture_removed")
	instance.get_node("HBoxContainer2").connect("textureMove", $"../../../../Anglerangeselector", "_on_texture_moved")
	textureselectors.add_child(instance)
	
	instance.get_node("HBoxContainer2").setTexture(texture)
	instance.get_node("HBoxContainer2").id = texturecount
#	if texturecount == 0:
#		texture = texture
	texturecount +=1
