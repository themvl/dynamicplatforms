tool
extends Node2D

const style_script = preload("dynamicplatformstyle.gd")
export(Resource) var style = null
onready var path = $Path2D

export var closed:bool = true
export var thicknes:float = 10
export var mark_bad:bool = true

export var quad_switch:bool = false
export var segmented:bool = true
export var drawcorners:bool = true

class_name dynamicplatform

func _init():
	pass


func _ready():
	print("ready")


func _enter_tree():
	if style == null:
		style = Resource.new()
		style.set_script(style_script)

func drawPoint(var pos, var color):
	draw_circle(pos, 1, color)
	
func resetpath():
	path.position = Vector2(0,0)
	path.rotation = 0
	path.scale = Vector2(1,1)

func _process(delta):
	if $Path2D == null:
		var p = Path2D.new()
		add_child(p)
		p.set_owner(get_tree().get_edited_scene_root())
		#path.curve.connect("changed",self, "update")
	else:
		path = $Path2D
		#path.curve.connect("changed",self, "update")
	resetpath()
	if closed and  path.curve.get_point_count() > 3 and path.curve.get_point_position(0) != path.curve.get_point_position(path.curve.get_point_count()-1):
		path.curve.set_point_position(path.curve.get_point_count()-1, path.curve.get_point_position(0))
	update()

#func setCurve(var c):
#	if Curve != null:
#		Curve.disconnect("changed", self, "update")
#
#	if c == null:
#		Curve = Curve2D.new()
#		Curve.add_point(-Vector2(400,200),-Vector2(700,200),-Vector2(0,200))
#		Curve.add_point(-Vector2(-400,-200),-Vector2(-0,-200),-Vector2(-700,-200))
#		print("custom default")
#	else:
#		Curve = c
#
#	Curve.connect("changed", self, "update")
#
#	update()

func drawFill():
	#dont fill when theres less than 3 points or when closed is not enabled
	if path.curve.get_point_count() < 3 or !closed or style.fillTexture == null:
		return
	
	var scale = style.fillsize/style.fillTexture.get_width() 
	var uvs = PoolVector2Array()
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
	
	draw_polygon(polygon,colors, uvs,texture)
#	draw_polyline(polygon,Color.white,1)
	
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
			if mark_bad:
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
		if mark_bad:
			colors[2] = Color.red
			colors[3] = Color.red
			drawPoint(quad[2],Color.red)
			drawPoint(quad[3],Color.red)
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
		
		draw_line(baked_points[i], baked_points[i]-normal*thicknes/2, Color.red,1)
		
		var rangeid=style.getAngleRangeID(wrapi(rad2deg(normal.angle())-90,0,359))
		var texture = style.getTexture(rangeid,0)
		
		var quad = PoolVector2Array()
		quad.push_back(baked_points[i]-normal*style.getOffset(rangeid)*thicknes)
		quad.push_back(baked_points[i+1]-normal2*style.getOffset(rangeid)*thicknes)
		quad.push_back(baked_points[i+1]+normal2*(1-style.getOffset(rangeid))*thicknes)
		quad.push_back(baked_points[i]+normal*(1-style.getOffset(rangeid))*thicknes)
		
#		if closed and i == baked_points.size()-2:
#			normal = baked_points[1] - baked_points[0]
#			normal = Vector2(-normal.y,normal.x).normalized()
#			quad[1] = baked_points[0]-normal/2*thicknes
#			quad[2] = baked_points[0]+normal/2*thicknes
		
		uv_remember_spot = wrapf(uv_remember_spot,0,1)
		var increase = path.curve.bake_interval/texture.get_width()*(texture.get_height()/thicknes)
		
		var uv = PoolVector2Array()
		uv.push_back(Vector2(uv_remember_spot,0.01))
		uv.push_back(Vector2(uv_remember_spot+increase,0.01))
		uv.push_back(Vector2(uv_remember_spot+increase,0.99))
		uv.push_back(Vector2(uv_remember_spot,0.99))
		
		#make bad polygons gud polygons like a doggy
		quad = fixQuad(quad, colors)
		
		draw_polygon(quad,colors,uv,texture)
		uv_remember_spot += increase
	#draw extra quad to join ends
	if closed:
		var normal
		normal = baked_points[1] - baked_points[baked_points.size()-2]
		normal = Vector2(-normal.y,normal.x).normalized()
		
		var normal2
		normal2 = baked_points[1] - baked_points[baked_points.size()-3]
		normal2 = Vector2(-normal2.y,normal2.x).normalized()
		
		var rangeid=style.getAngleRangeID(wrapi(rad2deg(normal.angle())-90,0,359))
		var texture = style.getTexture(rangeid,0)
		
		var quad = PoolVector2Array()
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
#		drawPoint(quad[0],Color.green)
#		drawPoint(quad[1],Color.red)
#		drawPoint(quad[2],Color.green)
#		drawPoint(quad[3],Color.red)
		
		quad = fixQuad(quad, colors)
#
#		drawPoint(quad[0],Color.green)
#		drawPoint(quad[1],Color.green)
#		drawPoint(quad[2],Color.green)
#		drawPoint(quad[3],Color.green)
		
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
		

func drawCorners():
	for i in range(path.curve.get_point_count()-1):
		var angle
		var curve = path.curve
		var point = curve.get_point_position(i)
		var vector1 = (curve.interpolate_baked(curve.get_closest_offset(point)-thicknes)-point).normalized()
		var vector2 = (curve.interpolate_baked(curve.get_closest_offset(point)+thicknes)-point).normalized()
		
		if i == 0 and closed:
			vector1 = (curve.interpolate_baked((curve.get_baked_length()-thicknes))-point).normalized()
		
		draw_line(point,point+vector1*10,Color.yellow, 2,true)
		draw_line(point,point+vector2*10,Color.red, 2,true)
		angle = wrapf(rad2deg(vector2.angle_to(vector1)),0,359)
		
		if angle ==0 and closed:
			if i ==0:
				print("oops")

		if angle <=120 and angle!=0:
			drawPoint(point,Color.blue)
			
			var normal = vector2-vector1
			normal = Vector2(normal.y,-normal.x).normalized()
			
			draw_line(point, point+normal*10,Color.red,1)
			var points = PoolVector2Array()
			var tex
			var offset
			
			offset = Vector2(0,0)
			
			var uvs = PoolVector2Array()
			
			
			points.push_back((point+normal*thicknes*0.60))
			if normal.x > 0:
				if normal.y > 0:
					tex = style.rightBottomOuterCorner
					offset = Vector2(-thicknes, -thicknes)/2
				else:
					tex = style.rightTopOuterCorner
					offset = Vector2(-thicknes, thicknes)/2
					uvs.push_back(Vector2(0,1))
					uvs.push_back(Vector2(1,1))
					uvs.push_back(Vector2(1,0))
					uvs.push_back(Vector2(0,0))
			else:
				if normal.y > 0:
					tex = style.leftBottomOuterCorner
					offset = Vector2(thicknes, -thicknes)/2
					uvs.push_back(Vector2(0,1))
					uvs.push_back(Vector2(1,1))
					uvs.push_back(Vector2(1,0))
					uvs.push_back(Vector2(0,0))
				else:
					tex = style.leftTopOuterCorner
					offset = Vector2(thicknes, thicknes)/2
					uvs.push_back(Vector2(0,0))
					uvs.push_back(Vector2(0,1))
					uvs.push_back(Vector2(1,1))
					uvs.push_back(Vector2(1,0))
			
			
			var p = point+vector1*thicknes/2
			p = curve.interpolate_baked(curve.get_closest_offset(p))
			var p_normal = curve.interpolate_baked(curve.get_closest_offset(p)+thicknes/4)-curve.interpolate_baked(curve.get_closest_offset(p)-thicknes/4)
			p_normal = Vector2(p_normal.y, -p_normal.x)
			p = p+p_normal
			drawPoint(p, Color.red)
			points.push_back(p)

			points.push_back(point-normal*thicknes*0.60)

			p = point+vector2*thicknes/2
			p = curve.interpolate_baked(curve.get_closest_offset(p))
			p_normal = curve.interpolate_baked(curve.get_closest_offset(p)+thicknes/4)-curve.interpolate_baked(curve.get_closest_offset(p)-thicknes/4)
			p_normal = Vector2(p_normal.y, -p_normal.x)
			p = p+p_normal
			drawPoint(p, Color.red)
			points.push_back(p)
			
			var colors = PoolColorArray()
			colors.push_back(Color.white)
			colors.push_back(Color.white)
			colors.push_back(Color.white)
			colors.push_back(Color.white)
			
			draw_multiline(points, Color.white,2, true)
			draw_polygon(points,colors,uvs,tex)
#			points.push_back(Vector2(point.x-normal.x*thicknes/2,point.y+normal.y*thicknes/2)+offset)
			
#			draw_texture_rect(tex, Rect2(point.x+normal.x*0.5*thicknes, point.y+normal.y*0.5*thicknes,thicknes,thicknes), false)
			

func drawBorder():
	if !segmented:
		drawBorderPoly(0)
	else:
		drawBorderSegmentedPoly()
	
	drawBorderSegmentedCurve()
	
	if drawcorners:
		drawCorners()
#	drawBorderSegmentedMesh()
	#loop over points
	
#	for i in range(path.curve.get_baked_points()-1):
#		var baked_points = path.curve.get_baked_points()
#
#		var normal = baked_points[i+1] - baked_points[i]
#		normal = Vector2(normal.y,-normal.x)
#
#
	
#	var previous_p = null
#	var i =0
#	for p in path.curve.get_baked_points():
#		#get normal of point
#		if previous_p != null:
#			var normal = (p-previous_p)
#			normal = Vector2(normal.y,-normal.x)
#			var middle = previous_p+((p-previous_p)/2)
#
#			var rangeid=style.getAngleRangeID(rad2deg(normal.angle()))
##			draw_set_transform(middle-normal*-5,normal.angle()+deg2rad(90), Vector2(.2,.2))
##			draw_texture(style.getTexture(rangeid,0),Vector2(0,0))
##			draw_set_transform(Vector2(0,0),0, Vector2(1,1))
#
#			#draw normal only every 10th and half a normal every 5th
##			if i==5:
##				drawNormal(middle, normal/2)
##			if i==10:
##				drawNormal(middle, normal)
##				i=0
##			i+=1
		
#		previous_p = p
		#determine what texture to draw
		#draw the texture

func drawBorderSegmentedCurve():
	pass
#	var curve_inner = path.curve
#	curve_inner.bake_interval = curve_inner.get_baked_length()/(path.curve.get_baked_length()/path.curve.bake_interval)
#	curve_inner.transform = curve_inner.transform.scaled(0.5)
	
func _draw():
	drawFill()
	drawBorder()
	
