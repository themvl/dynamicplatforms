tool
extends Node2D

const style_script = preload("dynamicplatformstyle.gd")
export(Resource) var style = null
onready var path = $Path2D

#determines wheter the curve is closed or not when it is it draws a filltexture and sets the end and start points to the same position
export var closed:bool = true setget setClosed
#determines the thickness of the border
export var thicknes:float = 30 setget setThicknes
#this draws red dots or red vertex at points of bad polygons that normally have been fixed
export var mark_bad:bool = true setget setMarkBad

#determines what method of fixing bad polygons is used 
#quad switch is the older method and just switches the 2 points
#the other method uses normals to set the points at a median point offset by their normals by a small margin
export var quad_switch:bool = false setget setQuadSwitch

#determines edge draw method the older method draws full textures and is way less heavy to draw but much worse and not supported
#the new method segments the texture based on the bake interval of the curve
export var segmented:bool = true #this should be a dictionary or similar with different options especially if more draw options become available
#determines if corners are drawn this is not always desired
export var drawcorners:bool = true setget setDrawCorners
#determines between which angles a corner will be drawn
export var angle_treshold = Vector2(30,120) setget setAngleThreshold

var corner_quads = []
var corner_uvs = []
export var corner_ranges = []
var corner_tex = []

class_name dynamicplatform

func _enter_tree():
	if style == null:
		style = Resource.new()
		style.set_script(style_script)

#function that draws a point
func drawPoint(var pos, var color):
	draw_circle(pos, 1, color)
	
func resetpath():
	#called every frame to ensure the translation of the path is the same as the dynamic shape
	#this is a temp cheat to take advantage of the curve editor of path
	path.position = Vector2(0,0)
	path.rotation = 0
	path.scale = Vector2(1,1)

func _process(delta):
	#create a path2d child if none exists this is absolutely neceserry and should never be deleted
	if $Path2D == null:
		var p = Path2D.new()
		add_child(p)
		p.set_owner(get_tree().get_edited_scene_root())
		#everytime the curve changes redraw
		path.curve.connect("changed",self, "update")
	else:
		#ensure path is set
		path = $Path2D
		if !path.curve.is_connected("changed",self, "update"):
			path.curve.connect("changed",self, "update")
	resetpath()

func drawFill():
	#dont fill when theres less than 3 points or when closed is not enabled
	if path.curve.get_point_count() < 3 or !closed or style.fillTexture == null:
		return
	
	#determine the scale at which to draw the fill texture
	var scale = style.fillsize/style.fillTexture.get_width() 
	var uvs = PoolVector2Array()
	#set an uv for every baked point
	for p in path.curve.get_baked_points():
		uvs.append(p*scale)
	draw_colored_polygon(path.curve.get_baked_points(),Color(1,1,1), uvs, style.fillTexture)

func drawNormal(var point:Vector2, var normal:Vector2):
	draw_line(point, point+normal*5,Color.white,1,true)

func getNormal(var offset, var inverted = false):
	var normalcalcrange = thicknes #set to thickness later
	var normal = path.curve.interpolate_baked(offset+normalcalcrange) -path.curve.interpolate_baked(offset-normalcalcrange)
	if inverted:
		return Vector2(normal.y,-normal.x).normalized()
	else:
		return Vector2(-normal.y,normal.x).normalized()
	
func drawBorderPoly(var offset):
	if offset > path.curve.get_baked_length():
		return
	
	var point = path.curve.interpolate_baked(offset)
	var normal = getNormal(offset)
	
	var rangeid=style.getAngleRangeID(wrapi(rad2deg(normal.angle())-90,0,359))
	var texture = style.getTexture(rangeid,0)
	var factor = float(thicknes/texture.get_height())
	var polygon = PoolVector2Array()
	polygon.push_back(point)
	polygon.push_back(point-normal*(texture.get_height()*factor))
	
	point = path.curve.interpolate_baked(offset+texture.get_width()*factor)
	normal = getNormal(offset+texture.get_width()*factor)
	polygon.push_back(point-normal*(texture.get_height()*factor))
	polygon.push_back(point)
	
	var uvs = PoolVector2Array()
	uvs.push_back(Vector2(0,1))
	uvs.push_back(Vector2(0,0))
	uvs.push_back(Vector2(1,0))
	uvs.push_back(Vector2(1,1))
	
	var colors = PoolColorArray()
	colors.push_back(Color(1,1,1))
	colors.push_back(Color(1,1,1))
	colors.push_back(Color(1,1,1))
	colors.push_back(Color(1,1,1))
	
	polygon = fixQuad(polygon,  colors)
	draw_polygon(polygon,colors, uvs,texture)
	
	drawBorderPoly(offset+texture.get_width()*factor)

func fixQuad(var quad:PoolVector2Array, var colors) -> PoolVector2Array:
	if (quad[2].y -quad[1].y)*(quad[3].x-quad[2].x)-(quad[3].y-quad[2].y)*(quad[2].x-quad[1].x) < 0:
		if (quad[1].y -quad[0].y)*(quad[2].x-quad[1].x)-(quad[2].y-quad[1].y)*(quad[1].x-quad[0].x) > 0:
			#quad switch method
			if quad_switch:
				var temp = quad[0]
				quad[0] = quad[1]
				quad[1] = temp
			else:
				var middle = quad[1]+(quad[0]-quad[1])/2
				var offset = (quad[0]-quad[1]).normalized()/thicknes
				quad[0] = middle-offset
				quad[1] = middle+offset
			if mark_bad and Engine.is_editor_hint():
				colors[0] = Color.red
				colors[1] = Color.red
				drawPoint(quad[0],Color.red)
				drawPoint(quad[1],Color.red)
	else:
		if quad_switch:
			var temp = quad[3]
			quad[3] = quad[2]
			quad[2] = temp
		else:
			var middle = quad[2]+(quad[3]-quad[2])/2
			var offset = (quad[3]-quad[2]).normalized()/thicknes
			quad[2] = middle+offset
			quad[3] = middle-offset
		if mark_bad and Engine.is_editor_hint():
			colors[2] = Color.red
			colors[3] = Color.red
			drawPoint(quad[2],Color.red)
			drawPoint(quad[3],Color.red)
	return quad

func offsetInCornerRange(var offset, var cornerrange )->bool:
	if cornerrange == 0:
		if offset < corner_ranges[cornerrange].x or offset > corner_ranges[cornerrange].y:
			return true
	elif offset < corner_ranges[cornerrange].x and offset > corner_ranges[cornerrange].y:
		return true
	return false
		
func fixQuadForCorners(var offset1, var offset2, var quad):
	for i in range(corner_ranges.size()):
		if offsetInCornerRange(offset1,i):
			if offsetInCornerRange(offset2,i):
				return null
			else:
				drawPoint(corner_quads[i][2], Color.red)
				drawPoint(corner_quads[i][3], Color.red)
				quad[0] = corner_quads[i][3]
				quad[3] = corner_quads[i][2]
				return quad
		else:
			if offsetInCornerRange(offset2,i):
				drawPoint(corner_quads[i][1], Color.yellow)
				drawPoint(corner_quads[i][2], Color.yellow)
				quad[1] = corner_quads[i][1]
				quad[2] = corner_quads[i][2]
				return quad
	return quad

func drawBorderSegmentedPoly():
	#loop over baked points and add quad for all
	var baked_points = path.curve.get_baked_points()
	var uv_remember_spot =0
	
	var colors = PoolColorArray()
	colors.push_back(Color(1,1,1))
	colors.push_back(Color(1,1,1))
	colors.push_back(Color(1,1,1))
	colors.push_back(Color(1,1,1))
	#variable that holds the quad to be drawn put here so it can be used to draw the closing rect for the corners
	var quad
	for i in range(baked_points.size()-1):
		var normal
		if i == 0:
			normal = baked_points[i+1] - baked_points[baked_points.size()-2]
		else:
			normal = baked_points[i+1] - baked_points[i-1]
		normal = Vector2(-normal.y,normal.x).normalized()
		
		
		var normal2
		if i == baked_points.size()-2:
			normal2 = baked_points[1] - baked_points[i-1]
		else:
			normal2 = baked_points[i+2] - baked_points[i]
		normal2 = Vector2(-normal2.y,normal2.x).normalized()
		
		var rangeid=style.getAngleRangeID(wrapi(rad2deg(normal.angle())-90,0,359))
		var texture = style.getTexture(rangeid,0)
		
		quad = PoolVector2Array()
		quad.push_back(baked_points[i]-normal*style.getOffset(rangeid)*thicknes)
		quad.push_back(baked_points[i+1]-normal2*style.getOffset(rangeid)*thicknes)
		quad.push_back(baked_points[i+1]+normal2*(1-style.getOffset(rangeid))*thicknes)
		quad.push_back(baked_points[i]+normal*(1-style.getOffset(rangeid))*thicknes)
		
		quad = fixQuadForCorners(path.curve.get_closest_offset(baked_points[i]),path.curve.get_closest_offset(baked_points[i+1]),quad)
		
		uv_remember_spot = wrapf(uv_remember_spot,0,1)
		var increase = path.curve.bake_interval/texture.get_width()*(texture.get_height()/thicknes)
		
		var uv = PoolVector2Array()
		uv.push_back(Vector2(uv_remember_spot,0.01))
		uv.push_back(Vector2(uv_remember_spot+increase,0.01))
		uv.push_back(Vector2(uv_remember_spot+increase,0.99))
		uv.push_back(Vector2(uv_remember_spot,0.99))
		
		#make bad polygons gud polygons like a doggy
		if quad != null:
			quad = fixQuad(quad, colors)
		
		if !(drawcorners and quad == null):
			draw_polygon(quad,colors,uv,texture)
		uv_remember_spot += increase
			
	#draw extra quad to join ends
	if closed and !offsetInCornerRange(0,0):
		var normal
		normal = baked_points[1] - baked_points[baked_points.size()-2]
		normal = Vector2(-normal.y,normal.x).normalized()
		
		var normal2
		normal2 = baked_points[1] - baked_points[baked_points.size()-3]
		normal2 = Vector2(-normal2.y,normal2.x).normalized()
		
		var rangeid=style.getAngleRangeID(wrapi(rad2deg(normal.angle())-90,0,359))
		var texture = style.getTexture(rangeid,0)
		
		quad = PoolVector2Array()
		quad.push_back(baked_points[0]-normal2*style.getOffset(rangeid)*thicknes)
		quad.push_back(baked_points[baked_points.size()-1]-normal*style.getOffset(rangeid)*thicknes)
		quad.push_back(baked_points[baked_points.size()-1]+normal*(1-style.getOffset(rangeid))*thicknes)
		quad.push_back(baked_points[0]+normal2*(1-style.getOffset(rangeid))*thicknes)
		
		uv_remember_spot = wrapf(uv_remember_spot,0,1)
		var increase = path.curve.bake_interval/texture.get_width()*(texture.get_height()/thicknes)
		
		var uv = PoolVector2Array()
		uv.push_back(Vector2(uv_remember_spot,0.01))
		uv.push_back(Vector2(uv_remember_spot+increase,0.01))
		uv.push_back(Vector2(uv_remember_spot+increase,0.99))
		uv.push_back(Vector2(uv_remember_spot,0.99))
		
		quad = fixQuad(quad, colors)
		
		draw_polygon(quad,colors,uv,texture)
		

func drawBorderSegmentedMesh():
	var baked_points = path.curve.get_baked_points()
	var uv_remember_spot =0
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i in range(baked_points.size()-2):
		var normal = baked_points[i+1] - baked_points[i-1]
		if i == 0:
			normal = baked_points[i+1] - baked_points[i]
		normal = Vector2(-normal.y,normal.x).normalized()
		
		var normal2 = baked_points[i+2] - baked_points[i]
		if i == baked_points.size()-1:
			normal = baked_points[i] - baked_points[i-1]
		normal2 = Vector2(-normal2.y,normal2.x).normalized()
		
		var rangeid=style.getAngleRangeID(wrapi(rad2deg(normal.angle())-90,0,359))
		var texture = style.getTexture(rangeid,0)
		
		uv_remember_spot = wrapf(uv_remember_spot,0,1)
		var increase = wrapf(path.curve.bake_interval/texture.get_width()/thicknes*40,0,1)
		
		st.add_uv()
		st.add_vertex(Vector3(baked_points[i].x,baked_points[i].y,0))
		st.add_vertex(Vector3(baked_points[i+1].x,baked_points[i+1].y,0))
		st.add_vertex(Vector3(baked_points[i+1].x,baked_points[i+1].y,0)+Vector3(normal2.x,normal2.y,0)*thicknes)
		st.add_vertex(Vector3(baked_points[i].x,baked_points[i].y,0)+Vector3(normal.x,normal.y,0)*thicknes)
		
		uv_remember_spot += increase
		
#function determines corners beforehand and stores them in the corner_quads and corner_uvs variables to use draw later 
#and to skip when drawing border the ranges to skip are stored in corner_ranges variable
func determineCorners():
	#clear from previous draw
	corner_quads.clear()
	corner_ranges.clear()
	corner_uvs.clear()
	corner_tex.clear()
	
	for i in range(path.curve.get_point_count()-1):
		var angle
		var curve = path.curve
		#the position of the corner on the curve
		var point = curve.get_point_position(i)
		#the 2 vectors going in both directions used to calculate the angle for the corner treshhold
		var vector1 = (curve.interpolate_baked(curve.get_closest_offset(point)-thicknes)-point).normalized()
		var vector2 = (curve.interpolate_baked(curve.get_closest_offset(point)+thicknes)-point).normalized()
		
		#a fix for the start/end points if its the first and its a closed shape also 
		#calculate the backwards going vector based on the endlength -thickness as offset
		if i == 0 and closed:
			vector1 = (curve.interpolate_baked((curve.get_baked_length()-thicknes))-point).normalized()
		
		#when in editor draw the vectors to visualise the corners and their angles
		if Engine.is_editor_hint():
			draw_line(point,point+vector1*10,Color.yellow, 2,true)
			draw_line(point,point+vector2*10,Color.red, 2,true)
		
		#calculate the angle using the 2 vectors and convert to degrees for ease of working with
		angle = wrapf(rad2deg(vector2.angle_to(vector1)),0,359)
		
		#something went wrong if its a closed curve and the angle is 0 at the first point
		if angle ==0 and closed:
			if i ==0:
				print("oops")
		
		#determine if its a angle based on angle treshhold
		if angle <=angle_treshold.y and angle!=0 and angle >= angle_treshold.x:
			#variable storing the range of offsets the corner covers used to not draw the border there
			var cornerrange = Vector2(0,0)
			
			#in editor draw a blue dot signifying it is reconised as a corner used for when a texture is missing
			#when there is a texture it is obscured
			if Engine.is_editor_hint():
				drawPoint(point,Color.blue)
			
			#calculate the normal of the corner using the 2 vectors
			var normal = vector2-vector1
			normal = Vector2(normal.y,-normal.x).normalized()
			
			#draw the normal line 
			draw_line(point, point+normal*10,Color.red,1)
			
			#variables for the texture and the points used to draw the corner texture
			var points = PoolVector2Array()
			var tex
			
			#empty variable containing future uvs
			var uvs = PoolVector2Array()
			
			#calculate the length towards the corner point and multiply by normal to get coordinate
			var l = normal*(thicknes/2)/sin(deg2rad((angle/2)))
			points.push_back(point+l)
			
			#find what kind of corner it is and set uvs and texture based on that
			if normal.x > 0:
				if normal.y > 0:
					tex = style.rightBottomOuterCorner
					uvs.push_back(Vector2(1,1))
					uvs.push_back(Vector2(1,0))
					uvs.push_back(Vector2(0,0))
					uvs.push_back(Vector2(0,1))
				else:
					tex = style.rightTopOuterCorner
					uvs.push_back(Vector2(1,0))
					uvs.push_back(Vector2(0,0))
					uvs.push_back(Vector2(0,1))
					uvs.push_back(Vector2(1,1))
			else:
				if normal.y > 0:
					tex = style.leftBottomOuterCorner
					uvs.push_back(Vector2(0,1))
					uvs.push_back(Vector2(1,1))
					uvs.push_back(Vector2(1,0))
					uvs.push_back(Vector2(0,0))
				else:
					tex = style.leftTopOuterCorner
					uvs.push_back(Vector2(0,0))
					uvs.push_back(Vector2(0,1))
					uvs.push_back(Vector2(1,1))
					uvs.push_back(Vector2(1,0))
			
			#calculate corner point depending on normal of earlier or further point 
			#this is done in a way that closed end points still work
			var p = point+vector1*thicknes/2
			cornerrange.y = curve.get_closest_offset(p)
			p = curve.interpolate_baked(cornerrange.y)
			var p_normal = curve.interpolate_baked(cornerrange.y+thicknes/4)-curve.interpolate_baked(cornerrange.y-thicknes/4)
			p_normal = Vector2(p_normal.y, -p_normal.x)
			p = p+p_normal
			points.push_back(p)
			
			points.push_back(point-l)
			
			p = point+vector2*thicknes/2
			cornerrange.x = curve.get_closest_offset(p)
			p = curve.interpolate_baked(cornerrange.x)
			p_normal = curve.interpolate_baked(cornerrange.x+thicknes/4)-curve.interpolate_baked(cornerrange.x-thicknes/4)
			p_normal = Vector2(p_normal.y, -p_normal.x)
			p = p+p_normal
			points.push_back(p)
			
			#put the quads and uvs in the global variables
			corner_quads.push_back(points)
			corner_uvs.push_back(uvs)
			corner_tex.push_back(tex)
			corner_ranges.push_back(cornerrange)


func drawCorners():
	#just assign white for the texture
	var colors = PoolColorArray()
	colors.push_back(Color.white)
	colors.push_back(Color.white)
	colors.push_back(Color.white)
	colors.push_back(Color.white)
		
	for i in range(corner_quads.size()):
		var tex = corner_tex[i]
		
		#only draw when theres a texture
		if tex != null:
			draw_polygon(corner_quads[i],colors,corner_uvs[i],tex)

func drawBorder():
	if drawcorners:
		determineCorners()
	
	if !segmented:
		drawBorderPoly(0)
	else:
		drawBorderSegmentedPoly()
	
	drawBorderSegmentedCurve()
	
	if drawcorners:
		drawCorners()

func drawBorderSegmentedCurve():
	pass
#	var curve_inner = path.curve
#	curve_inner.bake_interval = curve_inner.get_baked_length()/(path.curve.get_baked_length()/path.curve.bake_interval)
#	curve_inner.transform = curve_inner.transform.scaled(0.5)
	
func _draw():
	#this sets the end point and start point to the same position when the curve is set to closed this still allows moving the points together
	if closed and  path.curve.get_point_count() > 3 and path.curve.get_point_position(0) != path.curve.get_point_position(path.curve.get_point_count()-1):
		path.curve.set_point_position(path.curve.get_point_count()-1, path.curve.get_point_position(0))
	drawFill()
	drawBorder()

#setters and getters with update
func setDrawCorners(var value):
	drawcorners = value
	update()
	
func setAngleThreshold(value):
	angle_treshold = value
	update()

func setQuadSwitch(value):
	quad_switch = value
	update()

func setClosed(value):
	closed = value
	update()

func setThicknes(value):
	thicknes = value
	update()
	
func setMarkBad(value):
	mark_bad = value
	update()