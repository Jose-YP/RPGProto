extends CanvasLayer

signal advance
signal target
signal attack

func _on_button_pressed():
	advance.emit()
