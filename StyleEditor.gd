tool
extends PanelContainer

const style_script = preload("dynamicplatformstyle.gd")
export(Resource) var style = null
onready var editor = $VBoxContainer/editor
onready var selector = $VBoxContainer/editor/Anglerangeselector
onready var save = $VBoxContainer/newandopen/save

func loadStyle(var file):
	style = load(file)
	selector.setStyle(style)
	update()

func newStyle(var file):
	print("new style in: " +file)
	style = Resource.new()
	style.set_script(style_script)
	style.set_path(file)
	selector.setStyle(style)
	ResourceSaver.save(file, style)
	update()

func saveStyle():
	var s = selector.style
	if s == null:
		print("cant save style that does not exist")
		return
	print("saving: "+ s.get_path())
	print("value of first range: " + str(s.angleranges[0].x))
	ResourceSaver.save(s.get_path(), s)

func _on_FileDialogNewStyle_file_selected(path):
	newStyle(path)

func _on_FileDialogLoadStyle_file_selected(path):
	loadStyle(path)

func _draw():
	if style == null:
		editor.visible = false
		save.visible = false
	else:
		editor.visible = true
		save.visible = true

func _on_save_pressed():
	saveStyle()
