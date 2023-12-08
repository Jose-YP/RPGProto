extends Control
signal advance

func _on_button_pressed():
	advance.emit()
