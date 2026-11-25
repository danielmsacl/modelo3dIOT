extends Node

# Arrastra aquí en el Inspector tu nodo MqttClient (el que tiene el script largo de MQTT)
@export var mqtt: Node

# Desktop / Android / iOS -> TCP 1883
# Si exportas Godot a Web (HTML5) cambia a: "wss://broker.hivemq.com:8884/mqtt"
@export var broker_url: String = "tcp://broker.hivemq.com:1883"

const BASE_TOPIC := "safepet/danielmsacl/uno-r4-01"
const TOPIC_LED := BASE_TOPIC + "/led"
const TOPIC_FAN := BASE_TOPIC + "/ventilador"
const TOPIC_QUERY := BASE_TOPIC + "/consulta"
const TOPIC_LED_STATE := BASE_TOPIC + "/led/estado"
const TOPIC_FAN_STATE := BASE_TOPIC + "/ventilador/estado"
const TOPIC_SENSOR := BASE_TOPIC + "/sensores"
const TOPIC_SENSOR_STATE := BASE_TOPIC + "/sensor/estado"
const TOPIC_EVENTS := BASE_TOPIC + "/eventos"

signal estado_conexion_cambiado(conectado: bool)
signal led_cambiado(encendido: bool)
signal ventilador_cambiado(encendido: bool)
signal medicion_recibida(temperatura: float, humedad: float)
signal sensor_error()

var conectado := false
var led_encendido := false
var ventilador_encendido := false
var temperatura := 0.0
var humedad := 0.0

var _reconectando := false


func _ready() -> void:
	if mqtt == null:
		push_error("Asigna el nodo MqttClient en la propiedad 'Mqtt' del Inspector.")
		return

	randomize()
	mqtt.client_id = "petsafe-godot-%d" % (randi() % 1000000)
	mqtt.binarymessages = false

	mqtt.broker_connected.connect(_on_broker_connected)
	mqtt.broker_disconnected.connect(_on_broker_disconnected)
	mqtt.broker_connection_failed.connect(_on_broker_failed)
	mqtt.received_message.connect(_on_received_message)

	conectar()


func conectar() -> void:
	if mqtt == null:
		return
	if mqtt.brokerconnectmode != mqtt.BCM_NOCONNECTION:
		return
	mqtt.connect_to_broker(broker_url)


func _on_broker_connected() -> void:
	conectado = true
	_reconectando = false
	emit_signal("estado_conexion_cambiado", true)

	mqtt.subscribe(TOPIC_LED_STATE, 0)
	mqtt.subscribe(TOPIC_FAN_STATE, 0)
	mqtt.subscribe(TOPIC_SENSOR, 0)
	mqtt.subscribe(TOPIC_SENSOR_STATE, 0)
	mqtt.subscribe(TOPIC_EVENTS, 0)

	consultar_estado()


func _on_broker_disconnected() -> void:
	conectado = false
	emit_signal("estado_conexion_cambiado", false)
	_programar_reconexion()


func _on_broker_failed() -> void:
	conectado = false
	emit_signal("estado_conexion_cambiado", false)
	_programar_reconexion()


func _programar_reconexion() -> void:
	if _reconectando:
		return
	_reconectando = true
	await get_tree().create_timer(3.0).timeout
	_reconectando = false
	if is_inside_tree():
		conectar()


func _on_received_message(topic: String, message: String) -> void:
	match topic:
		TOPIC_LED_STATE:
			if message == "led_prendido" or message == "led_apagado":
				led_encendido = (message == "led_prendido")
				emit_signal("led_cambiado", led_encendido)

		TOPIC_FAN_STATE:
			if message == "ventilador_prendido" or message == "ventilador_apagado":
				ventilador_encendido = (message == "ventilador_prendido")
				emit_signal("ventilador_cambiado", ventilador_encendido)

		TOPIC_SENSOR:
			var datos = JSON.parse_string(message)
			if typeof(datos) == TYPE_DICTIONARY and datos.has("temperatura") and datos.has("humedad"):
				temperatura = float(datos["temperatura"])
				humedad = float(datos["humedad"])
				emit_signal("medicion_recibida", temperatura, humedad)

		TOPIC_SENSOR_STATE:
			if message == "error_dht22":
				emit_signal("sensor_error")


func prender_led() -> void:
	_publicar(TOPIC_LED, "prender_led")

func apagar_led() -> void:
	_publicar(TOPIC_LED, "apagar_led")

func toggle_led() -> void:
	_publicar(TOPIC_LED, "apagar_led" if led_encendido else "prender_led")

func prender_ventilador() -> void:
	_publicar(TOPIC_FAN, "prender_ventilador")

func apagar_ventilador() -> void:
	_publicar(TOPIC_FAN, "apagar_ventilador")

func toggle_ventilador() -> void:
	_publicar(TOPIC_FAN, "apagar_ventilador" if ventilador_encendido else "prender_ventilador")

func consultar_estado() -> void:
	_publicar(TOPIC_QUERY, "consultar_estado")

func _publicar(topic: String, payload: String) -> void:
	if not conectado or mqtt.brokerconnectmode != mqtt.BCM_CONNECTED:
		push_warning("MQTT no conectado; no se envió: %s -> %s" % [topic, payload])
		return
	mqtt.publish(topic, payload, false, 0)
