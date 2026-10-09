extends Control

func populate(page: int, after: bool) -> void:
	size=Vector2(1440,900)
	mouse_filter=MOUSE_FILTER_IGNORE
	var background := Panel.new()
	background.size=size
	background.add_theme_stylebox_override("panel",Palette.box(Palette.PANEL,0))
	add_child(background)
	for slot in range(12):
		var index := page*12+slot
		if index>=Content.UPGRADES.size():
			break
		var item: Dictionary=Content.UPGRADES[index]
		var p := Vector2(25+(slot%4)*355,16+(slot/4)*292)
		var title := Label.new()
		title.position=p
		title.text=item.name
		title.add_theme_font_size_override("font_size",17)
		add_child(title)
		var preview := DiscoveryPreview.new()
		preview.position=p+Vector2(0,34)
		preview.size=Vector2(300,200)
		preview.item=item
		preview.motion=0 if after else 1
		add_child(preview)
		preview.time=0
		preview.set_process(false)
		var caption := Label.new()
		caption.position=p+Vector2(0,246)
		caption.text="AFTER" if after else "BEFORE"
		caption.add_theme_font_size_override("font_size",11)
		caption.add_theme_color_override("font_color",Palette.MUTED)
		add_child(caption)
