tool
extends PanelContainer

const style_script = preload("../dynamicplatformstyle.gd")
var style = null
onready var editor = $VBoxContainer/editor
onready var selector = $VBoxContainer/editor/Anglerangeselector
onready var save = $VBoxContainer/newandopen/save

func loadStyle(var file):
	style = load(file)
	selector.setStyle(style)

	$"VBoxContainer/editor/Fillsettings/VBoxContainer/size settings/SpinBox width".value = style.fillsize.x
	$"VBoxContainer/editor/Fillsettings/VBoxContainer/size settings/SpinBox height".value = style.fillsize.y

	$"VBoxContainer/editor/Cornersettings/VBoxContainer/VBoxContainer/leftuppercorner_tex".set_texture(style.leftTopOuterCorner)
	$"VBoxContainer/editor/Cornersettings/VBoxContainer/VBoxContainer/rightuppercorner_tex".set_texture(style.rightTopOuterCorner)
	$"VBoxContainer/editor/Cornersettings/VBoxContainer/VBoxContainer/leftbottomcorner_tex".set_texture(style.leftBottomOuterCorner)
	$"VBoxContainer/editor/Cornersettings/VBoxContainer/VBoxContainer/rightbottomcorner_tex".set_texture(style.rightBottomOuterCorner)
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

func _fill_width_changed(value):
	style.fillsize.x = value

func _fill_height_changed(value):
	style.fillsize.y = value

func _on_leftuppercorner_tex_textureOpened(texture, id, changed):
	style.leftTopOuterCorner = texture

func _on_leftuppercorner_tex_textureRemoved(id):
	style.leftTopOuterCorner = null

func _on_rightuppercorner_tex_textureOpened(texture, id, changed):
	style.rightTopOuterCorner = texture

func _on_rightuppercorner_tex_textureRemoved(id):
	style.rightTopOuterCorner = null

func _on_leftbottomcorner_tex_textureOpened(texture, id, changed):
	style.leftBottomOuterCorner = texture

func _on_leftbottomcorner_tex_textureRemoved(id):
	style.leftBottomOuterCorner = null

func _on_rightbottomcorner_tex_textureOpened(texture, id, changed):
	style.rightBottomOuterCorner = texture

func _on_rightbottomcorner_tex_textureRemoved(id):
	style.rightBottomOuterCorner = null
