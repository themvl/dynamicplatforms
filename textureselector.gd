tool
extends PanelContainer

export var showUpDown:bool = true setget setShowUpDown

signal textureOpened(texture, id, changed)
signal textureRemoved(id)
signal textureMove(id, direction)

func setShowUpDown(var show):
	$HBoxContainer2.showUpAndDown =show

func _on_HBoxContainer2_textureMove(id, direction):
	emit_signal("textureMove", id,direction)


func _on_HBoxContainer2_textureOpened(texture, id, changed):
	emit_signal("textureOpened", texture,id, changed)


func _on_HBoxContainer2_textureRemoved(id):
	emit_signal("textureRemoved", id)
