class_name DriftSample
extends Control

var kind := "ballast"

func _ready() -> void:
	mouse_filter=MOUSE_FILTER_IGNORE

func _draw() -> void:
	if kind=="stasis":
		Palette.bevel(self,Rect2(2,14,76,46),Palette.GLASS,2,false)
		UpgradeIcons.draw(self,"ballast",Vector2(20,37),23,Palette.MINT)
		draw_string(ThemeDB.fallback_font,Vector2(39,44),"6s",HORIZONTAL_ALIGNMENT_LEFT,-1,19,Palette.GOLD)
		return
	for y in range(3):
		for x in range(3):
			var rect := Rect2(9+x*21,9+y*21,19,19)
			Palette.bevel(self,rect,Palette.TILE,1.5)
			if kind=="mooring":
				draw_line(rect.position+Vector2(3,7),rect.position+Vector2(3,3),Palette.INK,2)
				draw_line(rect.position+Vector2(3,3),rect.position+Vector2(7,3),Palette.INK,2)
	if kind=="ballast":
		draw_rect(Rect2(7,7,65,65),Palette.MINT,false,2)
		Palette.mouse(self,Vector2(40,41),1,Palette.INK,0.6)
	elif kind=="tracer":
		Palette.plating(self,Vector2(39.5,39.5),19,3,Color("42556f"))
		Palette.safe_wake(self,Vector2(45,34))
