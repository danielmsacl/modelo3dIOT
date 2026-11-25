extends Node3D

var ventilador_prendido = false
var led_prendido = false
func _ready() -> void:
	$perrito_simple_pintado/AnimationPlayer.play("caminando")
func _process(delta: float) -> void:
	if ventilador_prendido == false:
		$Ventilador/ventiladoranim.play("apagado")
	if ventilador_prendido == true:
		$Ventilador/ventiladoranim.play("prendido")
	if led_prendido == false:
		$luz_led/LUZLED.visible = false
	if led_prendido == true:
		$luz_led/LUZLED.visible = true

func _on_prender_ventilador_pressed() -> void:
	cambiar_estado_ventilador()
func _on_prender_led_pressed() -> void:
	cambiar_estado_led()

func cambiar_estado_ventilador():
	if ventilador_prendido == false:
		ventilador_prendido = true
	elif ventilador_prendido == true:
		ventilador_prendido = false

func cambiar_estado_led():
	if led_prendido == false:
		led_prendido = true
	elif led_prendido == true:
		led_prendido = false

func _on_safe_pet_mqtt_medicion_recibida(temperatura: float, humedad: float) -> void:
	$pantalla_led_amarilla/textopantalla.set_text("Safepet\ntemperatura: %.1f | humedad: %.1f" % [temperatura, humedad])
