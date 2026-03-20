extends Node2D

@onready var anim_enemy: AnimationPlayer = $Combatants/AnimationEnemy
@onready var anim_player: AnimationPlayer = $Combatants/AnimationPlayer
@onready var label_hp_player = $UI/HealthBars/PlayerHealthBar/LabelHPPlayer
@onready var label_hp_enemy = $UI/HealthBars/EnemyHealthBar/LabelHPEnemy
@onready var battle_log: Label = $UI/BattleLog
@onready var action_menu = $UI/ActionMenu
@onready var mochila_menu = $UI/MochilaMenu
@onready var player_bar: ProgressBar = $UI/HealthBars/PlayerHealthBar
@onready var enemy_bar: ProgressBar = $UI/HealthBars/EnemyHealthBar
@onready var btn_vida = $UI/MochilaMenu/BtnVida
@onready var btn_fuerza = $UI/MochilaMenu/BtnFuerza
@onready var btn_inmunidad = $UI/MochilaMenu/BtnInmunidad
@onready var btn_agilidad = $UI/MochilaMenu/BtnAgilidad
@onready var panel_inicio = $UI/Menus/Inicio
@onready var panel_derrota = $UI/Menus/Derrota
@onready var panel_victoria = $UI/Menus/Victoria
@onready var panel_pausa = $UI/Menus/Pausa

# --- Sonidos ---
@onready var Musica_Fondo = $Sonidos/MusicaFondo
@onready var Sfx_Attq_Player = $Sonidos/SfxAtaquePlayer
@onready var Sfx_AttqRapido_Player = $Sonidos/SfxAtaqueRapidoPlayer
@onready var Sfx_Attq_Dragon = $Sonidos/SfxAtaqueDragon
@onready var Sfx_Esquive = $Sonidos/SfxEsquive
@onready var Sfx_Danio_Player = $Sonidos/SfxDanioPlayer
@onready var Sfx_Danio_Dragon = $Sonidos/SfxDanioDragon
@onready var Sfx_Danio_Demonio = $Sonidos/SfxDanioDemonio
@onready var Sfx_Danio_Golem = $Sonidos/SfxDanioGolem
@onready var Sfx_VictoriaA = $Sonidos/SfxVictoriaA
@onready var Sfx_VictoriaB_Loop = $Sonidos/SfxVictoriaB_Loop
@onready var Sfx_Cine = $Sonidos/SfxCinematica

# --- VARIABLES ---
var tipo_enemigo_actual: String = ""
var player_hp_max: int = 100
var player_hp_actual: int = 100
var enemy_hp_max: int = 0
var enemy_hp_actual: int = 0

var estado_jugador: String = "normal" 
var turnos_estado: int = 0
var turnos_inmunidad: int = 0
var daño_quemadura: int = 5
var boost_ataque: bool = false # Mantengo por compatibilidad, pero usamos multiplicador_fuerza

# Inventario e Items
var items = {"vida": 3, "fuerza": 2, "inmunidad": 1, "agilidad": 2}
var tiene_inmunidad: bool = false
var probabilidad_esquiva: float = 0.1 
var multiplicador_fuerza: float = 1.0

# Correr
var cooldown_huida: int = 0

# Contador de Enemigos
var enemigos_derrotados: int = 0

# Bandera que indica que el juego ha terminado
var juego_terminado: bool = false

# Contador de barra para ganar
var enemigos_para_ganar: int = 5 # 5
var enemigos_actuales: int = 0
@onready var progreso_victoria = $UI/ProgresoVictoria
@onready var label_progreso = $UI/ProgresoVictoria/LabelProgreso

@onready var fondo_dia = $Fondo_dia
@onready var fondo_noche = $Fondo_noche
@onready var princess = $Combatants/Princess
@onready var anim_princess = $Combatants/AnimationPrincess
@onready var victory = $Combatants/Victory

func _ready():
	panel_victoria.visible = false
	panel_derrota.visible = false
	panel_pausa.visible = false
	
	Musica_Fondo.play()
	mostrar_pantalla(panel_inicio)
	Engine.time_scale = 0 # Pausa el motor
	progreso_victoria.max_value = enemigos_para_ganar
	progreso_victoria.value = 0
	mochila_menu.visible = false
	action_menu.visible = false
	seleccionar_enemigo_al_azar()
	actualizar_barra_progreso()
	anim_player.play("player_moverse")

func mostrar_pantalla(panel_objetivo: Panel):
	# Ocultamos todos primero
	panel_inicio.visible = false
	panel_derrota.visible = false
	panel_victoria.visible = false
	panel_pausa.visible = false
	
	# Mostramos el que queremos
	if panel_objetivo:
		Musica_Fondo.volume_db = -15
		panel_objetivo.visible = true

# --- SISTEMA DE LOG ---
func escribir_en_log(texto: String):
	battle_log.text = texto
	print(texto)
	get_tree().create_timer(1.5).timeout.connect(func(): 
		if battle_log.text == texto: 
			battle_log.text = "" 
	)

# --- LÓGICA DE ENEMIGOS ---
func seleccionar_enemigo_al_azar():
	var opciones = ["Golem", "Dragon", "Demonio"]
	tipo_enemigo_actual = opciones.pick_random()
	$Combatants/Enemy.position = Vector2(2000, 230)
	$Combatants/Enemy.visible = true
	
	match tipo_enemigo_actual:
		"Golem":
			enemy_hp_max = 200 # 200
			anim_enemy.play("Entrada_Golem")
			await anim_enemy.animation_finished
			anim_enemy.play("Golem_normal")
		"Dragon":
			enemy_hp_max = 80 # 80
			anim_enemy.play("Entrada_Dragon")
			await anim_enemy.animation_finished
			anim_enemy.play("Dragon_volando")
		"Demonio":
			enemy_hp_max = 150 # 150
			anim_enemy.play("Entrada_Demonio")
			await anim_enemy.animation_finished
			anim_enemy.play("Demonio_mov")
	
	enemy_hp_actual = enemy_hp_max
	actualizar_salud_visual(enemy_bar, enemy_hp_actual, enemy_hp_max, label_hp_enemy)
	actualizar_salud_visual(player_bar, player_hp_actual, player_hp_max, label_hp_player)
	escribir_en_log("¡Un " + tipo_enemigo_actual + " bloquea el camino!")
	action_menu.visible = true

'''func actualizar_barras_ui():
	player_bar.max_value = player_hp_max
	player_bar.value = player_hp_actual
	enemy_bar.max_value = enemy_hp_max
	enemy_bar.value = enemy_hp_actual'''

# --- SISTEMA DE COMBATE ---

func actualizar_barra_progreso():
	progreso_victoria.value = enemigos_actuales
	label_progreso.text = str(enemigos_actuales) + " / " + str(enemigos_para_ganar) + " Enemigos"

func ejecutar_ciclo_ataque(cantidad_daño: int):
	action_menu.visible = false 
	
	# 1. Cálculo de daño (Críticos y Fuerza)
	var es_critico = randf() < 0.15
	var danio_final = cantidad_daño
	if es_critico:
		danio_final = int(danio_final * 1.5)
	
	danio_final = int(danio_final * multiplicador_fuerza)
	# Resetear bufos
	multiplicador_fuerza = 1.0
	
	# 2. Animación
	anim_player.play("player_atacar")
	
	match tipo_enemigo_actual:
		"Golem": Sfx_Danio_Golem.play()
		"Dragon": Sfx_Danio_Dragon.play()
		"Demonio": Sfx_Danio_Demonio.play()
	
	await anim_player.animation_finished
	anim_player.play("player_moverse")
	
	# 3. Aplicar Daño
	if es_critico: escribir_en_log("¡GOLPE CRÍTICO!")
	recibir_danio_enemigo(danio_final)
	escribir_en_log("¡Le has quitado " + str(danio_final) + " de vida!")
	
	
	await get_tree().create_timer(1.5).timeout
	
	if enemy_hp_actual > 0:
		turno_enemigo()
	# Si murió, la función recibir_danio_enemigo ya llama a morir_enemigo()

func turno_enemigo():
	if enemy_hp_actual <= 0: return
	
	escribir_en_log("Turno del enemigo...")
	await get_tree().create_timer(1.0).timeout
	
	# Esquiva del jugador
	if randf() < probabilidad_esquiva:
		match tipo_enemigo_actual:
			"Golem": anim_enemy.play("Golem_Ataque")
			"Dragon": anim_enemy.play("Dragon_atacando")
			"Demonio": anim_enemy.play("Demonio_ataque")
		await get_tree().create_timer(0.5).timeout
		anim_player.play("esquivar")
		Sfx_Esquive.play()
		await anim_player.animation_finished
		escribir_en_log("¡Increíble! Has esquivado el ataque.")
		anim_player.play("player_moverse")
		regresar_a_idle_enemigo()
		await get_tree().create_timer(1.0).timeout
		finalizar_ronda()
		return

	# Animación de ataque
	match tipo_enemigo_actual:
		"Golem": anim_enemy.play("Golem_Ataque")
		"Dragon": anim_enemy.play("Dragon_atacando")
		"Demonio": anim_enemy.play("Demonio_ataque")
	await anim_enemy.animation_finished
	
	# Decisión de ataque (Normal o Estado)
	if estado_jugador == "normal" and randf() < 0.5:
		aplicar_efecto_enemigo()
	else:
		var dmg = 15
		if tipo_enemigo_actual == "Dragon": dmg = 25
		elif tipo_enemigo_actual == "Golem": dmg = 20
		escribir_en_log("¡El " + tipo_enemigo_actual + " te golpea!")
		recibir_danio_jugador(dmg)
	
	regresar_a_idle_enemigo()
	await get_tree().create_timer(1.0).timeout
	finalizar_ronda()

func finalizar_ronda():
	procesar_estados_post_turno()
	if player_hp_actual > 0:
		action_menu.visible = true

func aplicar_efecto_enemigo():
	if tiene_inmunidad:
		escribir_en_log("¡El estado falló por tu Inmunidad!")
		return
		
	match tipo_enemigo_actual:
		"Golem":
			estado_jugador = "dormido"
			turnos_estado = randi_range(1, 3)
			escribir_en_log("¡Estás dormido!")
		"Dragon":
			estado_jugador = "quemado"
			turnos_estado = 3
			escribir_en_log("¡Estás quemado!")
		"Demonio":
			estado_jugador = "confundido"
			turnos_estado = 3
			escribir_en_log("¡Estás confundido!")

func recibir_danio_enemigo(cantidad: int):
	enemy_hp_actual = clamp(enemy_hp_actual - cantidad, 0, enemy_hp_max)
	actualizar_salud_visual(enemy_bar, enemy_hp_actual, enemy_hp_max, label_hp_enemy)
	
	if enemy_hp_actual <= 0:
		morir_enemigo()
	else:
		var tween = create_tween()
		var node_enemy = anim_enemy.get_parent().get_node("Enemy")
		tween.tween_property(node_enemy, "position:x", 10, 0.05).as_relative()
		tween.tween_property(node_enemy, "position:x", -10, 0.05).as_relative()

func morir_enemigo():
	# 1. Bloqueamos el menú para que no puedan presionar nada durante la transición
	action_menu.visible = false
	# Dentro de morir_enemigo:
	enemigos_derrotados += 1
	
	# 3. Efecto visual de parpadeo/muerte
	var sprite = anim_enemy.get_parent().get_node("Enemy")
	for i in range(5):
		sprite.visible = false
		await get_tree().create_timer(0.1).timeout
		sprite.visible = true
		await get_tree().create_timer(0.1).timeout
	
	# 4. Desaparece el enemigo
	sprite.visible = false
	
	# 5. TIEMPO DE ESPERA (Pausa de victoria)
	# 2. Mensaje de derrota
	escribir_en_log("¡El " + tipo_enemigo_actual + " ha sido derrotado!")
	# Esto permite que el jugador asimile la victoria antes del siguiente combate
	await get_tree().create_timer(2.0).timeout
	enemigos_actuales += 1
	progreso_victoria.value = enemigos_actuales
	progreso_victoria.custom_minimum_size.x = 200
	actualizar_barra_progreso()
	
	if enemigos_actuales >= enemigos_para_ganar:
		escribir_en_log("¡Has limpiado la zona de monstruos!")
		await get_tree().create_timer(2.0).timeout
		juego_terminado = true	
		ejecutar_cinematica_final()
		return
	
	# 6. Mensaje de transición
	escribir_en_log("Buscando un nuevo oponente...")
	await get_tree().create_timer(1.5).timeout
	
	# 7. Resetear estados temporales del jugador para el nuevo combate
	# estado_jugador = "normal"
	# turnos_estado = 0
	# tiene_inmunidad = false
	probabilidad_esquiva = 0.1
	multiplicador_fuerza = 1.0
	
	# 8. Aparecer nuevo enemigo
	seleccionar_enemigo_al_azar()
	# sprite.visible = true
	
	# 9. Pequeña pausa final antes de devolver el control al jugador
	await get_tree().create_timer(1.0).timeout
	action_menu.visible = true

func _on_btn_attack_1_pressed():
	if no_puede_atacar(): return
	escribir_en_log("¡Usaste Ataque Rápido!")
	Sfx_AttqRapido_Player.play()
	ejecutar_ciclo_ataque(20)

func _on_btn_attack_2_pressed():
	if no_puede_atacar(): return
	
	# Probabilidad de fallo para el ataque fuerte
	if randf() < 0.2:
		escribir_en_log("¡El ataque potente falló!")
		esperar_turno_enemigo()
		return
		
	escribir_en_log("¡Usaste Ataque Potente!")
	Sfx_Attq_Player.play()
	ejecutar_ciclo_ataque(40)

# --- FUNCIONES DE UI Y MOCHILA ---

func _on_btn_mochila_pressed():
	action_menu.visible = false
	mochila_menu.visible = true
	actualizar_visual_mochila()

func _on_btn_volver_pressed():
	mochila_menu.visible = false
	action_menu.visible = true

func actualizar_visual_mochila():
	btn_vida.text = "Poción de Vida 50 HP (x" + str(items["vida"]) + ")"
	btn_fuerza.text = "Poción de Fuerza x1.5 (x" + str(items["fuerza"]) + ")"
	btn_inmunidad.text = "Inmunidad Estados (x" + str(items["inmunidad"]) + ")"
	btn_agilidad.text = "Agilidad / Esquiva (x" + str(items["agilidad"]) + ")"
	
	# OPCIONAL: Desactivar botones si no quedan unidades
	btn_vida.disabled = items["vida"] <= 0
	btn_fuerza.disabled = items["fuerza"] <= 0
	btn_inmunidad.disabled = items["inmunidad"] <= 0
	btn_agilidad.disabled = items["agilidad"] <= 0

func usar_pocion_vida():
	if items["vida"] > 0:
		player_hp_actual = clamp(player_hp_actual + 50, 0, player_hp_max)
		actualizar_salud_visual(player_bar, player_hp_actual, player_hp_max, label_hp_player)
		items["vida"] -= 1
		actualizar_visual_mochila()
		escribir_en_log("¡+50 HP! Quedan: " + str(items["vida"]))
		mochila_menu.visible = false
		esperar_turno_enemigo()
	else: escribir_en_log("No tienes más.")

func usar_pocion_fuerza():
	if items["fuerza"] > 0:
		multiplicador_fuerza = 1.5
		items["fuerza"] -= 1
		actualizar_visual_mochila()
		escribir_en_log("¡Próximo ataque potenciado!")
		mochila_menu.visible = false
		action_menu.visible = true # No consume turno según lo pedido

func usar_inmunidad():
	if items["inmunidad"] > 0:
		tiene_inmunidad = true
		items["inmunidad"] -= 1
		turnos_inmunidad = 3
		
		if estado_jugador != "normal":
			escribir_en_log("¡La inmunidad ha curado tu estado de " + estado_jugador + "!")
			estado_jugador = "normal"
			turnos_estado = 0
		else:
			escribir_en_log("¡Ahora eres inmune a los estados!")
		
		actualizar_visual_mochila()
		mochila_menu.visible = false
		action_menu.visible = true

func usar_agilidad():
	if items["agilidad"] > 0:
		probabilidad_esquiva = 0.4
		items["agilidad"] -= 1
		actualizar_visual_mochila()
		escribir_en_log("¡Reflejos aumentados!")
		mochila_menu.visible = false
		action_menu.visible = true

# --- AUXILIARES ---
func actualizar_salud_visual(barra: ProgressBar, hp_actual: int, hp_max: int, label: Label):
	# 1. Actualizamos el valor de la barra
	barra.max_value = hp_max
	barra.value = hp_actual
	
	# 2. Cambiamos el texto de porcentaje por números
	label.text = str(hp_actual) + " / " + str(hp_max)
	
	# 3. (Opcional) Cambiar el color si le queda poca vida
	if hp_actual < (hp_max * 0.3):
		label.modulate = Color.RED
	else:
		label.modulate = Color.WHITE

func regresar_a_idle_enemigo():
	match tipo_enemigo_actual:
		"Golem": anim_enemy.play("Golem_normal")
		"Dragon": anim_enemy.play("Dragon_volando")
		"Demonio": anim_enemy.play("Demonio_mov")

func procesar_estados_post_turno():
	if turnos_inmunidad > 0:
		turnos_inmunidad -= 1
		if turnos_inmunidad == 0:
			tiene_inmunidad = false
			escribir_en_log("El efecto de la inmunidad ha terminado.")
	
	if cooldown_huida > 0:
		cooldown_huida -= 1
		if cooldown_huida == 0:
			print("Ya puedes intentar huir de nuevo.")

	if turnos_estado > 0:
		turnos_estado -= 1
		
		if estado_jugador == "quemado":
			recibir_danio_jugador(daño_quemadura)
			escribir_en_log("¡Sufres por la quemadura!")
		
		# La confusión no hace daño aquí, hace daño arriba cuando intentas atacar.
		if estado_jugador == "confundido" and turnos_estado > 0:
			escribir_en_log("Sigues sintiéndote mareado...")

		if turnos_estado <= 0:
			escribir_en_log("¡Te has recuperado, ya no estas " + estado_jugador + "!")
			estado_jugador = "normal"

func no_puede_atacar() -> bool:
	if estado_jugador == "dormido":
		escribir_en_log("Estás dormido...")
		esperar_turno_enemigo()
		return true
	
	if estado_jugador == "confundido":
		if randf() < 0.4: # 40% de probabilidad de golpearse a sí mismo
			var danio_autoinfligido = 10
			escribir_en_log("¡Estás confundido! Te has golpeado a ti mismo.")
			recibir_danio_jugador(danio_autoinfligido)
			
			# Importante: Si se golpea a sí mismo, pierde el turno
			esperar_turno_enemigo() 
			return true
		else:
			escribir_en_log("¡Logras concentrarte a pesar de la confusión!")
	return false

func esperar_turno_enemigo():
	action_menu.visible = false
	await get_tree().create_timer(1.0).timeout
	turno_enemigo()

func recibir_danio_jugador(cantidad):
	player_hp_actual = clamp(player_hp_actual - cantidad, 0, player_hp_max)
	actualizar_salud_visual(player_bar, player_hp_actual, player_hp_max, label_hp_player)
	if player_hp_actual <= 0:
		escribir_en_log("HAS MUERTO")
		await get_tree().create_timer(2.0).timeout
		# get_tree().reload_current_scene()
		mostrar_pantalla(panel_derrota)
		Engine.time_scale = 0

func ejecutar_cinematica_final():
	# --- PREPARACIÓN ---
	juego_terminado = true
	action_menu.visible = false
	$UI/HealthBars/EnemyHealthBar.visible = false
	# Aseguramos que empiece de noche y con la princesa atrapada
	fondo_noche.visible = true
	fondo_noche.modulate.a = 1.0
	fondo_dia.modulate.a = 0.0
	fondo_dia.visible = true
	princess.visible = true
	Musica_Fondo.stop()
	Sfx_Cine.play()
	anim_princess.play("Princesa_atrapada")
	
	await anim_princess.animation_finished
	
	# mostrar_pantalla(panel_victoria)
	escribir_en_log("¡El último enemigo ha caído!")
	await get_tree().create_timer(1).timeout

	# --- PASO 1: Efecto Tembloroso ---
	escribir_en_log("¡Algo está pasando...!")
	
	# --- PASO 2: Cambio de Noche a Día ---
	escribir_en_log("Las cuardas se rompen... ¡Sale el sol!")
	
	var tween_cielo = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	
	anim_princess.play("Pricesa_liberada")
	
	tween_cielo.tween_property(fondo_noche, "modulate:a", 0.0, 4.0)
	
	# Transición suave de noche a día
	tween_cielo.tween_property(fondo_dia, "modulate:a", 1.0, 3.0)
	
	await tween_cielo.finished
	fondo_noche.visible = false # Ya no necesitamos el fondo de noche

	# --- PASO 3: Princesa se levanta y festeja ---
	await get_tree().create_timer(3.0).timeout
	escribir_en_log("Princesa: ¡Gracias por rescatarme!")
	
	# Activamos tu animación de festejo
	Sfx_VictoriaA.play()
	victory.visible = true
	anim_princess.play("Princesa_Celebrando")

	# --- FINAL DEL JUEGO ---
	await get_tree().create_timer(2.0).timeout
	battle_log.text = "FIN DE LA AVENTURA\nGracias por Jugar!!!"
	$UI/Menus/Victoria.visible = true
	await Sfx_VictoriaA.finished
	print("Reproduciendo Loop de Victoria")
	Sfx_VictoriaB_Loop.play()

func _on_btn_correr_pressed():
	if cooldown_huida > 0:
		escribir_en_log("¡No puedes huir todavía! Faltan " + str(cooldown_huida) + " turnos.")
		return
		
	# 1. Bloqueamos UI
	action_menu.visible = false
	escribir_en_log("¡Intentas escapar!")
	await get_tree().create_timer(1.0).timeout
	
	# 2. Cálculo de éxito (50% base, sube a 80% si tienes el bufo de agilidad)
	var chance_escape = 0.5
	if probabilidad_esquiva > 0.1: # Si usó la poción de agilidad
		chance_escape = 0.8
		
	if randf() < chance_escape:
		# --- ÉXITO ---
		escribir_en_log("¡Escapaste con éxito!")
		cooldown_huida = 3
		await get_tree().create_timer(1.5).timeout
		
		# Efecto visual: el jugador sale de la pantalla o el enemigo se desvanece
		var tween = create_tween()
		tween.tween_property(anim_player.get_parent(), "modulate:a", 0, 0.5)
		
		await get_tree().create_timer(1.0).timeout
		
		# Resetear escena o buscar nuevo enemigo
		multiplicador_fuerza = 1.0
		tiene_inmunidad = false
		probabilidad_esquiva = 0.1
		
		# Volver a aparecer (Reset de posición/visibilidad)
		anim_player.get_parent().modulate.a = 1
		seleccionar_enemigo_al_azar()
	else:
		# --- FALLO ---
		escribir_en_log("¡No pudiste escapar! El enemigo te bloquea.")
		await get_tree().create_timer(1.5).timeout
		# Pierdes el turno y el enemigo ataca
		turno_enemigo()


func _on_btn_jugar_pressed() -> void:
	panel_inicio.visible = false
	Engine.time_scale = 1
	Musica_Fondo.volume_db = 0
	escribir_en_log("¡Que comience la batalla!")


func _on_btn_reintentar_pressed() -> void:
	Engine.time_scale = 1
	get_tree().reload_current_scene()


func _on_btn_salir_pressed() -> void:
	get_tree().quit()

func _input(event):
	if event.is_action_pressed("ui_cancel"): # Por defecto la tecla ESC
		if juego_terminado:
			return
		gestionar_pausa()

func gestionar_pausa():
	if not panel_pausa.visible:
		mostrar_pantalla(panel_pausa)
		Engine.time_scale = 0
	else:
		panel_pausa.visible = false
		Musica_Fondo.volume_db = 0
		Engine.time_scale = 1

func _on_btn_continuar_pressed() -> void:
	gestionar_pausa()


func _on_btn_menu_principal_pressed() -> void:
	Engine.time_scale = 1
	get_tree().reload_current_scene()
