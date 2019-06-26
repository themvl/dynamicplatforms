tool
extends Control

var style = null
var pivot:Vector2 = Vector2(rect_size.x/2,rect_size.x/2)
var anglerange:Array = []
var clickablepoints:Array 
var selectedpoint = null
var activeangle = 0
var activerange = -1
onready var settings = $"../anglerangesettings"
onready var spinbox1 = $"../anglerangesettings/VBoxContainer/HBoxContainer/SpinBox"
onready var spinbox2 = $"../anglerangesettings/VBoxContainer/HBoxContainer/SpinBox2"
onready var label = $selectedangle
var texture:Texture = null

export(Texture) var textures

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _enter_tree():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func convertangle(angle:int):
	if angle >=360:
		if angle -360 >= 360:
			return convertangle(angle-360)
		else:
			return angle-360
	elif angle < 0:
		if angle +360 < 0:
			return convertangle(angle+360)
		else:
			return angle+360
	else:
		return angle
#
#func draw_anglepoint(angle:int):
#	print("draw line")
#	#convert to standard degrees
#	angle = convertangle(angle)
#	var topoint = Vector2(0,0)
#
#	if(angle/90 <= 1):
#		topoint.x = sin(angle)*pivot.x-5
#		topoint.y = cos(angle)*pivot.x-5
#
#	draw_line(pivot, topoint, Color.black, 2)
#
func _gui_input(event):
	if style == null:
		return
	
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		#check which endpoint is clicked and set it to selected until button is released 
		#if not clicked on a end point create one
		if event.pressed:
			for point in clickablepoints:
				if(get_local_mouse_position().distance_to(point[0]) <=5):
					#select this point
					selectedpoint = point
					print(point[1])
					
		else:
			if selectedpoint != null and selectedpoint[1] != -1:
				print(anglerange[selectedpoint[1]])
			selectedpoint = null
		
	elif event is InputEventMouseMotion and selectedpoint != null:
		#move the selected point to (approximation) mouse position
		var ang = rad2deg(asin((get_local_mouse_position()-pivot).normalized().x))
		if (get_local_mouse_position()-pivot).y > 0:
			ang = 180-ang
		if selectedpoint[1] == -1:
			activeangle = convertangle(ang)
		else:
			changeRangeValue(selectedpoint[1],selectedpoint[2],convertangle(ang))
	update()

func draw_circle_arc(center, radius, angle_from, angle_to, color):
	
	
	var nb_points = 64
	var points_arc = PoolVector2Array()
	
	#doesnt change the actual angle but ensures distance doesnt go into the negative
	if(angle_to < angle_from):
		angle_to += 360
	if angle_to - angle_from > 180:
		nb_points = 100
	
	if inrange(activeangle,angle_from,angle_to):
		color = Color("#26afff")
	
	
	for i in range(nb_points + 1):
		var angle_point = deg2rad(angle_from + i * (angle_to-angle_from) / nb_points - 90)
		points_arc.push_back(center + Vector2(cos(angle_point), sin(angle_point)) * radius)

	for index_point in range(nb_points):
		draw_line(points_arc[index_point], points_arc[index_point + 1], color, 8)
		
	draw_circle(points_arc[0],5,Color.black)
	draw_circle(points_arc[nb_points],5,Color("#031b5b"))
	

func _draw():
	if style == null:
		return 
	
	rect_min_size.y = rect_size.x
	pivot = Vector2(rect_size.x/2,rect_size.x/2)
	draw_circle(pivot,pivot.x-2,Color("#1f7182"))
	draw_circle(pivot,pivot.x-8,Color("#659df7"))

	if not(texture == null) and activerange != -1:
		draw_set_transform(pivot, deg2rad(activeangle), Vector2(1,1))
		#draw the fill texture
		#draw_texture_rect(style.fillTexture, Rect2(-Vector2(200,-50),Vector2(300,150)),true)
		#draw the range texture
		draw_texture_rect(texture, Rect2(-Vector2(50,50),Vector2(100,100)),false)
		draw_set_transform(Vector2(0,0), 0, Vector2(1,1))
	
	updateclickable()
	
	#draw anglerange points
	for ran in anglerange:
		draw_circle_arc(pivot,pivot.x-5, ran.x,ran.y,Color("#004fce"))
	
	#draw activeanglepoint
	var ang = deg2rad(activeangle-90)
	var pos = pivot + (Vector2(cos(ang), sin(ang)) *(pivot.x-5))
	draw_line(pivot, pos, Color.white, 1)
	draw_circle( pos,5,Color.red)
	
	#change active range
	var i = 0
	var oldactiverange = activerange
	activerange = -1
	for ran in anglerange:
		if inrange(activeangle,ran.x,ran.y):
			activerange = i
		i +=1
	
	#hide range settings if no range is selected
	if activerange == -1:
		settings.visible = false
	else:
		settings.visible = true
		#update spinboxes
		spinbox1.value = anglerange[activerange].x
		spinbox2.value = anglerange[activerange].y
		
		#check if new active if so then update settings
		if activerange != oldactiverange:
			updateSettings()
	
	label.text = str(activeangle) + " : " +str(activerange)

func updateclickable():
	clickablepoints.clear()
	var i =0
	for ran in anglerange:
		
		var pointang = deg2rad(ran.x-90)
		var point = pivot + Vector2(cos(pointang), sin(pointang)) * (pivot.x-5)
		
		#first the point then the index used to find the range then 0 for the first value
		clickablepoints.push_back([point,i,0])

		
		pointang = deg2rad(ran.y-90)
		point = pivot + Vector2(cos(pointang), sin(pointang)) * (pivot.x-5)

		#first the point then the index used to find the range then 1 for the second value
		clickablepoints.push_back([point,i,1])

		i+=1
	
	var ang = deg2rad(activeangle-90)
	var pos = pivot + (Vector2(cos(ang), sin(ang)) *(pivot.x-5))
	clickablepoints.push_back([pos,-1,0])


func create_new_range():
	if anglerange.size() == 0:
		addrange(-45,45)
	else:
		addrange(anglerange[anglerange.size()-1].y, anglerange[anglerange.size()-1].y +90)


func _on_SpinBox_value_changed(value, extra_arg_0):
	changeRangeValue(activerange, 0, value)
	update()


func _on_SpinBox2_value_changed(value):
	changeRangeValue(activerange, 1, value)
	update()
	
func addrange(var start, var end):
	start = convertangle(start)
	end = convertangle(end)
	anglerange.push_back(Vector2(start,end))
	style.addAngleRange(start,end)
	update()

func inrange(value, begin,end):
	value = convertangle(value)
	begin = convertangle(begin)
	end = convertangle(end)
	
	if begin > end:
		return value > begin or value <= end
	else:
		return value > begin and value <= end

func deleteactiverange():
	anglerange.remove(activerange)
	style.removeAngleRange(activerange)
	update()

func setStyle(var s):
	style = s
	#reset ranges and load
	
	anglerange.clear()
	for ran in style.angleranges:
		anglerange.push_back(Vector2(ran.x,ran.y))
	
	#set the fill texture 
	$"../Fillsettings/VBoxContainer/textureselector/HBoxContainer2".setTexture(style.fillTexture)
	
	update()
	
func changeRangeValue(var ranid:int, var begorend:int, var newValue:int):
	if begorend == 0:
		anglerange[ranid].x = newValue
		style.angleranges[ranid].x = newValue
	else:
		anglerange[ranid].y = newValue
		style.angleranges[ranid].y = newValue
	
	update()

func _on_texture_loaded(var tex,var id, var changed:bool):
	if(id == 0):
		texture = tex
	
	print("ontexloaded id: "+str(id)+" : "+str(changed))
	
	if !changed:
		print("texcount1: " +str(id))
		style.addTexture(activerange, tex)
	else:
		style.textures[activerange][id] = tex
	update()

func _on_texture_removed(var id):
	style.removeTexture(activerange,id)
	updateSettings()
	
func _on_texture_moved(var id, var direction):
	style.moveTexture(activerange, id, direction)
	updateSettings()

func updateSettings():
	#clear and readd necesarry panels
	var container = $"../anglerangesettings/VBoxContainer/PanelContainer2/VBoxContainer"
	var texsel = $"../anglerangesettings/VBoxContainer/PanelContainer2/VBoxContainer/textureselectors"
	for i in range(0, texsel.get_child_count()):
		texsel.get_child(i).queue_free()
		
	container.texturecount = 0
	print("cont: " + str(container.texturecount) )
	if  activerange != -1 and activerange < style.textures.size():
		if style.textures[activerange].size() > 0:
			texture = style.textures[activerange][0]
		else:
			texture = null
		for tex in style.textures[activerange]:
			#add a new panel
			container.addNewTexturePanel(tex)



func _on_textureselector_textureOpened(texture, id, changed):
	style.fillTexture = texture


func _on_textureselector_textureRemoved(id):
	style.fillTexture = null
