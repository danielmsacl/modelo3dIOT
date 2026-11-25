extends Node3D

@export var safepet_mqtt: Node

var ventilador_prendido = false
var led_prendido = false

func _ready() -> void:
	$perrito_simple_pintado/AnimationPlayer.play("caminando")
	if safepet_mqtt == null:
		safepet_mqtt = get_node_or_null("SafePetMqtt")
	if safepet_mqtt:
		if not safepet_mqtt.led_cambiado.is_connected(_on_safe_pet_mqtt_led_cambiado):
			safepet_mqtt.led_cambiado.connect(_on_safe_pet_mqtt_led_cambiado)
		if not safepet_mqtt.ventilador_cambiado.is_connected(_on_safe_pet_mqtt_ventilador_cambiado):
			safepet_mqtt.ventilador_cambiado.connect(_on_safe_pet_mqtt_ventilador_cambiado)
		if not safepet_mqtt.medicion_recibida.is_connected(_on_safe_pet_mqtt_medicion_recibida):
			safepet_mqtt.medicion_recibida.connect(_on_safe_pet_mqtt_medicion_recibida)
		if not safepet_mqtt.estado_conexion_cambiado.is_connected(_on_safe_pet_mqtt_estado_conexion_cambiado):
			safepet_mqtt.estado_conexion_cambiado.connect(_on_safe_pet_mqtt_estado_conexion_cambiado)

func _process(delta: float) -> void:
	if ventilador_prendido == false:
		$Ventilador/ventiladoranim.play("apagado")
	if ventilador_prendido == true:
		$Ventilador/ventiladoranim.play("prendido")
	if led_prendido == false:
		$luz_led/LUZLED.visible = false
	if led_prendido == true:
		$luz_led/LUZLED.visible = true

# Al presionar botones en Godot solo se envía la orden por MQTT;
# la animación y la luz NO cambian hasta que el Arduino real responda.
func _on_prender_ventilador_pressed() -> void:
	if safepet_mqtt:
		safepet_mqtt.toggle_ventilador()

func _on_prender_led_pressed() -> void:
	if safepet_mqtt:
		safepet_mqtt.toggle_led()

# Solo cambian cuando llega confirmación real desde /led/estado y /ventilador/estado
func _on_safe_pet_mqtt_ventilador_cambiado(encendido: bool) -> void:
	ventilador_prendido = encendido

func _on_safe_pet_mqtt_led_cambiado(encendido: bool) -> void:
	led_prendido = encendido

func _on_safe_pet_mqtt_estado_conexion_cambiado(conectado: bool) -> void:
	if not conectado:
		ventilador_prendido = false
		led_prendido = false

func _on_safe_pet_mqtt_medicion_recibida(temperatura: float, humedad: float) -> void:
	$pantalla_led_amarilla/textopantalla.set_text("Safepet\ntemperatura: %.1f | humedad: %.1f" % [temperatura, humedad])
