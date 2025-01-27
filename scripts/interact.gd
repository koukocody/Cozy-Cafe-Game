extends TextureButton

signal interacted

func _on_pressed() -> void:
	interacted.emit()
	print("customer clicked")
