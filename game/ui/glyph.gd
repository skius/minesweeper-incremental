class_name Glyph
extends Control

var kind: String = "prism"
var color: Color = Palette.MINT
var icon_size: float = 22

func _draw() -> void:
	Palette.icon(self, kind, size/2, icon_size, color)
