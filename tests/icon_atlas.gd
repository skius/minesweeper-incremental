extends Control

var icon_rects: Dictionary = {}

func _ready() -> void:
	mouse_filter=MOUSE_FILTER_IGNORE
	size=Vector2(1440,900)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Palette.PANEL)
	var font := ThemeDB.fallback_font
	draw_string(font,Vector2(42,43),"DISCOVERY SYMBOLS",HORIZONTAL_ALIGNMENT_LEFT,-1,22,Palette.WHITE)
	UpgradeIcons.draw(self,"lens",Vector2(1118,37),32,Palette.WHITE)
	draw_string(font,Vector2(1150,43),"Survey lens",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Palette.WHITE)
	icon_rects.lens=Rect2i(1097,16,42,42)
	for branch in range(6):
		var x := 28+branch*235
		draw_string(font,Vector2(x+10,93),Content.BRANCH_NAMES[branch],HORIZONTAL_ALIGNMENT_LEFT,-1,14,Palette.MINT)
		var row := 0
		for item in Content.UPGRADES:
			if item.branch!=branch:
				continue
			var y := 113+row*74
			var rect := Rect2(x,y,220,66)
			draw_style_box(Palette.surface(Palette.PANEL_LIGHT),rect)
			var p := Vector2(x+30,y+32)
			UpgradeIcons.draw(self,item.id,p,32,Palette.WHITE)
			icon_rects[item.id]=Rect2i(Vector2i(p)-Vector2i(21,21),Vector2i(42,42))
			UpgradeIcons.draw(self,item.id,Vector2(x+197,y+32),18,Palette.MUTED)
			var words: PackedStringArray=item.name.split(" ")
			var lines: Array[String]=[""]
			for word in words:
				if (lines[-1]+" "+word).length()>16:
					lines.append(word)
				else:
					lines[-1]+=(" " if not lines[-1].is_empty() else "")+word
			for i in range(lines.size()):
				draw_string(font,Vector2(x+59,y+28+i*17),lines[i],HORIZONTAL_ALIGNMENT_LEFT,-1,12,Palette.WHITE)
			row+=1
	draw_string(font,Vector2(42,874),"32 px / 18 px · six related families · one semantic symbol for every discovery",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Palette.MUTED)
