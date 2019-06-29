tool
extends Resource

export(Array, Vector2) var angleranges = []
export(Array, Texture) var textures = []
export(Texture) var fillTexture = null
export(Vector2) var fillsize
export(Array, float) var offsets

#corner textures
export(Texture) var leftTopOuterCorner
export(Texture) var rightTopOuterCorner
export(Texture) var leftBottomOuterCorner
export(Texture) var rightBottomOuterCorner

export(Texture) var leftTopInnerCorner
export(Texture) var rightTopInnerCorner
export(Texture) var leftBottomInnerCorner
export(Texture) var rightBottomInnerCorner

func _init():
	angleranges = []
	textures = []
	fillTexture = null
	fillsize = Vector2(1,1)
	offsets = []

func addAngleRange(var begin:int, var end:int):
	angleranges.push_back(Vector2(begin, end))
	textures.push_back([])
	offsets.push_back(0)
	emit_signal("changed")

func addTexture(var rangeid:int, var texture:Texture):
	textures[rangeid].push_back(texture)
	emit_signal("changed")

func removeTexture(var rangeid:int, var texid:int):
	textures[rangeid].remove(texid)
	emit_signal("changed")

func moveTexture(var rangeid, var id:int, var direction):
	print("about to move texture "+ str(id)+ " from range id "+ str(rangeid)+ ", " +str(direction) +" spaces")
	print("while size of textures is: " + str(textures[rangeid].size()))
	if id >= textures[rangeid].size()-1 and direction == 1:
		return
	if id <= 0 and direction == -1:
		return
	var temp = textures[rangeid][id+direction]
	textures[rangeid][id+direction] = textures[rangeid][id]
	textures[rangeid][id] = temp
	emit_signal("changed")

func getTexture(var rangeid:int, var texid:int) -> Texture:
	return textures[rangeid][texid]

func removeAngleRange(var ranid:int):
	angleranges.remove(ranid)
	textures.remove(ranid)
	emit_signal("changed")

func getAngleRangeID(var angle)->int:
	var i = 0
	for ran in angleranges:
		if ran.x > ran.y:
			if angle > ran.x or angle <= ran.y:
				return i
		else:
			if angle > ran.x and angle <= ran.y:
				return i
		i+=1
	return -1

func setOffset(var ranid:int, var offset):
	offsets[ranid] = wrapf(offset, 0,1)
	emit_signal("changed")
	
func getOffset(var ranid:int) -> float:
	return offsets[ranid]
	
func changeAngleRange(var id, var begin, var end):
	angleranges[id].x = begin
	angleranges[id].y = end
	emit_signal("changed")