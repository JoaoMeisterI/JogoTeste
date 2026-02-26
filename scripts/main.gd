extends Control

const CLASSES := {
	"Lógico": {
		"description": "Dano elevado, mas penalidade maior em erros.",
		"stats": {"power": 2, "speed": 0, "precision": -1}
	},
	"Analista": {
		"description": "Estilo estável, reduz bastante a penalidade por erro.",
		"stats": {"power": 0, "speed": 0, "precision": 2}
	},
	"Sintetizador": {
		"description": "Mais tempo por desafio e bônus por rapidez.",
		"stats": {"power": 0, "speed": 2, "precision": 0}
	}
}

const WORLDS := [
	{
		"id": "aritmetico",
		"name": "Planeta Aritmético",
		"theme": "Tecnológico espacial",
		"focus": "Operações básicas",
		"enemies": ["Drone Somador", "Drone Divisor"],
		"boss": "Guardião das Operações",
		"palette": Color("#19324a")
	},
	{
		"id": "algebrico",
		"name": "Planeta Algébrico",
		"theme": "Ruínas antigas flutuantes",
		"focus": "Equações de 1º grau",
		"enemies": ["Variável Corrompida", "Sentinela de Incógnitas"],
		"boss": "Mestre das Incógnitas",
		"palette": Color("#3f2a56")
	},
	{
		"id": "geometrico",
		"name": "Planeta Geométrico",
		"theme": "Cidade fractal cristalina",
		"focus": "Área, perímetro e ângulos",
		"enemies": ["Entidade Vetorial", "Fragmento Angular"],
		"boss": "Arquiteto Espacial",
		"palette": Color("#1f3f3a")
	}
]

var player := {
	"class": "",
	"level": 1,
	"xp": 0,
	"xp_to_next": 80,
	"base_hp": 100,
	"base_power": 12,
	"attr_points": 0,
	"attributes": {"power": 0, "speed": 0, "precision": 0},
	"skills": {"power": 0, "speed": 0, "precision": 0}
}

var world_progress := {
	"aritmetico": {"cleared": false, "battles": 0},
	"algebrico": {"cleared": false, "battles": 0},
	"geometrico": {"cleared": false, "battles": 0}
}

var post_game := false
var game_state := "title"
var active_world := {}
var active_enemy := {}
var battle := {}

var title_screen: Control
var class_screen: Control
var world_screen: Control
var battle_screen: Control
var progression_screen: Control
var ending_screen: Control

var title_label: Label
var class_info: RichTextLabel
var world_info: RichTextLabel
var status_label: Label
var question_label: Label
var timer_label: Label
var battle_feedback: Label
var hp_label: Label
var enemy_label: Label
var answer_input: LineEdit
var options_box: VBoxContainer
var world_buttons: VBoxContainer
var progression_label: RichTextLabel
var ending_label: RichTextLabel

var turn_timer: Timer
var turn_started_at := 0

func _ready() -> void:
	randomize()
	build_ui()
	show_screen("title")

func build_ui() -> void:
	var bg := ColorRect.new()
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.color = Color("#0f1220")
	add_child(bg)

	title_screen = create_screen()
	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.text = "CHRONOS: Academia do Infinito\n\nO Paradoxo corrompeu os Códigos Primordiais.\nTorne-se um Arquiteto do Conhecimento e restaure 3 mundos!"
	title_label.anchor_right = 1.0
	title_label.anchor_bottom = 0.6
	title_screen.add_child(title_label)
	var start_btn := Button.new()
	start_btn.text = "Iniciar Campanha"
	start_btn.anchor_left = 0.4
	start_btn.anchor_top = 0.65
	start_btn.anchor_right = 0.6
	start_btn.anchor_bottom = 0.75
	start_btn.pressed.connect(func() -> void: show_screen("class"))
	title_screen.add_child(start_btn)

	class_screen = create_screen()
	var class_title := Label.new()
	class_title.text = "Escolha sua Classe"
	class_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	class_title.anchor_right = 1.0
	class_title.anchor_bottom = 0.1
	class_screen.add_child(class_title)

	var class_buttons := HBoxContainer.new()
	class_buttons.anchor_left = 0.15
	class_buttons.anchor_top = 0.2
	class_buttons.anchor_right = 0.85
	class_buttons.anchor_bottom = 0.5
	class_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	class_buttons.add_theme_constant_override("separation", 20)
	class_screen.add_child(class_buttons)

	for class_name in CLASSES.keys():
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(220, 80)
		btn.text = class_name
		btn.pressed.connect(Callable(self, "select_class").bind(class_name))
		class_buttons.add_child(btn)

	class_info = RichTextLabel.new()
	class_info.anchor_left = 0.2
	class_info.anchor_top = 0.55
	class_info.anchor_right = 0.8
	class_info.anchor_bottom = 0.9
	class_info.fit_content = true
	class_info.bbcode_enabled = true
	class_info.text = "Selecione uma classe para visualizar os bônus iniciais."
	class_screen.add_child(class_info)

	world_screen = create_screen()
	var world_title := Label.new()
	world_title.text = "Seleção de Mundo"
	world_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	world_title.anchor_right = 1.0
	world_title.anchor_bottom = 0.1
	world_screen.add_child(world_title)

	world_buttons = VBoxContainer.new()
	world_buttons.anchor_left = 0.08
	world_buttons.anchor_top = 0.15
	world_buttons.anchor_right = 0.45
	world_buttons.anchor_bottom = 0.85
	world_buttons.add_theme_constant_override("separation", 12)
	world_screen.add_child(world_buttons)

	world_info = RichTextLabel.new()
	world_info.anchor_left = 0.5
	world_info.anchor_top = 0.15
	world_info.anchor_right = 0.93
	world_info.anchor_bottom = 0.85
	world_info.bbcode_enabled = true
	world_info.fit_content = true
	world_screen.add_child(world_info)

	var progress_btn := Button.new()
	progress_btn.text = "Progressão / Atributos"
	progress_btn.anchor_left = 0.32
	progress_btn.anchor_top = 0.88
	progress_btn.anchor_right = 0.52
	progress_btn.anchor_bottom = 0.96
	progress_btn.pressed.connect(func() -> void: open_progression())
	world_screen.add_child(progress_btn)

	battle_screen = create_screen()
	status_label = Label.new()
	status_label.anchor_left = 0.05
	status_label.anchor_top = 0.02
	status_label.anchor_right = 0.95
	status_label.anchor_bottom = 0.12
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	battle_screen.add_child(status_label)

	hp_label = Label.new()
	hp_label.anchor_left = 0.05
	hp_label.anchor_top = 0.12
	hp_label.anchor_right = 0.45
	hp_label.anchor_bottom = 0.2
	battle_screen.add_child(hp_label)

	enemy_label = Label.new()
	enemy_label.anchor_left = 0.55
	enemy_label.anchor_top = 0.12
	enemy_label.anchor_right = 0.95
	enemy_label.anchor_bottom = 0.2
	enemy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	battle_screen.add_child(enemy_label)

	question_label = Label.new()
	question_label.anchor_left = 0.1
	question_label.anchor_top = 0.26
	question_label.anchor_right = 0.9
	question_label.anchor_bottom = 0.38
	question_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	battle_screen.add_child(question_label)

	timer_label = Label.new()
	timer_label.anchor_left = 0.44
	timer_label.anchor_top = 0.38
	timer_label.anchor_right = 0.56
	timer_label.anchor_bottom = 0.45
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	battle_screen.add_child(timer_label)

	answer_input = LineEdit.new()
	answer_input.anchor_left = 0.35
	answer_input.anchor_top = 0.5
	answer_input.anchor_right = 0.65
	answer_input.anchor_bottom = 0.58
	answer_input.placeholder_text = "Digite sua resposta"
	battle_screen.add_child(answer_input)

	var submit_btn := Button.new()
	submit_btn.text = "Responder"
	submit_btn.anchor_left = 0.42
	submit_btn.anchor_top = 0.6
	submit_btn.anchor_right = 0.58
	submit_btn.anchor_bottom = 0.68
	submit_btn.pressed.connect(func() -> void: submit_answer(answer_input.text))
	battle_screen.add_child(submit_btn)

	options_box = VBoxContainer.new()
	options_box.anchor_left = 0.32
	options_box.anchor_top = 0.5
	options_box.anchor_right = 0.68
	options_box.anchor_bottom = 0.78
	options_box.add_theme_constant_override("separation", 8)
	battle_screen.add_child(options_box)

	battle_feedback = Label.new()
	battle_feedback.anchor_left = 0.2
	battle_feedback.anchor_top = 0.73
	battle_feedback.anchor_right = 0.8
	battle_feedback.anchor_bottom = 0.84
	battle_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	battle_screen.add_child(battle_feedback)

	progression_screen = create_screen()
	progression_label = RichTextLabel.new()
	progression_label.anchor_left = 0.08
	progression_label.anchor_top = 0.1
	progression_label.anchor_right = 0.92
	progression_label.anchor_bottom = 0.72
	progression_label.bbcode_enabled = true
	progression_screen.add_child(progression_label)

	var attr_buttons := HBoxContainer.new()
	attr_buttons.anchor_left = 0.1
	attr_buttons.anchor_top = 0.74
	attr_buttons.anchor_right = 0.9
	attr_buttons.anchor_bottom = 0.84
	attr_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	attr_buttons.add_theme_constant_override("separation", 12)
	progression_screen.add_child(attr_buttons)

	for attr in ["power", "speed", "precision"]:
		var btn := Button.new()
		btn.text = "+ %s" % attr.capitalize()
		btn.pressed.connect(Callable(self, "invest_point").bind(attr))
		attr_buttons.add_child(btn)

	var back_btn := Button.new()
	back_btn.text = "Voltar ao Mapa"
	back_btn.anchor_left = 0.4
	back_btn.anchor_top = 0.88
	back_btn.anchor_right = 0.6
	back_btn.anchor_bottom = 0.96
	back_btn.pressed.connect(func() -> void: show_screen("world"))
	progression_screen.add_child(back_btn)

	ending_screen = create_screen()
	ending_label = RichTextLabel.new()
	ending_label.anchor_left = 0.12
	ending_label.anchor_top = 0.14
	ending_label.anchor_right = 0.88
	ending_label.anchor_bottom = 0.72
	ending_label.bbcode_enabled = true
	ending_screen.add_child(ending_label)

	var continue_btn := Button.new()
	continue_btn.text = "Pós-jogo: Revisitar Mundos"
	continue_btn.anchor_left = 0.35
	continue_btn.anchor_top = 0.8
	continue_btn.anchor_right = 0.65
	continue_btn.anchor_bottom = 0.9
	continue_btn.pressed.connect(func() -> void:
		post_game = true
		show_screen("world")
	)
	ending_screen.add_child(continue_btn)

	turn_timer = Timer.new()
	turn_timer.one_shot = true
	turn_timer.timeout.connect(_on_turn_timeout)
	add_child(turn_timer)

func create_screen() -> Control:
	var c := Control.new()
	c.anchor_right = 1.0
	c.anchor_bottom = 1.0
	add_child(c)
	return c

func show_screen(name: String) -> void:
	game_state = name
	title_screen.visible = name == "title"
	class_screen.visible = name == "class"
	world_screen.visible = name == "world"
	battle_screen.visible = name == "battle"
	progression_screen.visible = name == "progression"
	ending_screen.visible = name == "ending"
	if name == "world":
		refresh_worlds()
	if name == "progression":
		refresh_progression()

func select_class(class_name: String) -> void:
	var class_data: Dictionary = CLASSES[class_name]
	if player["class"] == "":
		player["class"] = class_name
		for attr in class_data["stats"].keys():
			player["attributes"][attr] += class_data["stats"][attr]
	class_info.text = "[b]%s[/b]\n%s\nAtributos iniciais: %s" % [class_name, class_data["description"], str(class_data["stats"])]
	await get_tree().create_timer(0.2).timeout
	show_screen("world")

func refresh_worlds() -> void:
	for child in world_buttons.get_children():
		child.queue_free()
	var completed := 0
	for world in WORLDS:
		if world_progress[world["id"]]["cleared"]:
			completed += 1
		var btn := Button.new()
		var status := "Concluído" if world_progress[world["id"]]["cleared"] else "Disponível"
		btn.text = "%s (%s)" % [world["name"], status]
		btn.custom_minimum_size = Vector2(0, 70)
		btn.pressed.connect(Callable(self, "preview_world").bind(world))
		world_buttons.add_child(btn)
	world_info.text = "[b]Classe:[/b] %s\n[b]Nível:[/b] %d\n[b]XP:[/b] %d / %d\n[b]Mundos restaurados:[/b] %d/3" % [player["class"], player["level"], player["xp"], player["xp_to_next"], completed]
	if completed == 3 and not post_game:
		show_ending()

func preview_world(world: Dictionary) -> void:
	active_world = world
	var progress: Dictionary = world_progress[world["id"]]
	world_info.text = "[b]%s[/b]\nTema: %s\nFoco matemático: %s\nInimigos: %s\nBoss: %s\n\nCombates vencidos neste mundo: %d\n%s" % [
		world["name"], world["theme"], world["focus"], ", ".join(world["enemies"]), world["boss"], progress["battles"],
		"[color=gold]Mundo já restaurado. Rejogue com dificuldade +1.[/color]" if progress["cleared"] else "Derrote 2 inimigos e 1 boss para restaurar o planeta."
	]
	var go_btn := Button.new()
	go_btn.text = "Explorar e iniciar combate"
	go_btn.custom_minimum_size = Vector2(0, 44)
	go_btn.pressed.connect(start_encounter)
	for child in world_info.get_children():
		child.queue_free()
	world_info.add_child(go_btn)

func start_encounter() -> void:
	if active_world.is_empty():
		return
	var progress: Dictionary = world_progress[active_world["id"]]
	var is_boss := progress["battles"] >= 2
	active_enemy = {
		"name": active_world["boss"] if is_boss else active_world["enemies"][randi() % active_world["enemies"].size()],
		"hp": 120 + player["level"] * 8 if is_boss else 70 + player["level"] * 5,
		"damage": 18 + player["level"] * 2 if is_boss else 10 + player["level"]
	}
	battle = {
		"player_hp": player_max_hp(),
		"enemy_hp": active_enemy["hp"],
		"is_boss": is_boss,
		"question": {}
	}
	show_screen("battle")
	start_turn()

func player_max_hp() -> int:
	return player["base_hp"] + player["level"] * 6 + player["attributes"]["speed"] * 2

func player_attack_power() -> float:
	var skill_bonus := 1.0 + player["skills"]["power"] * 0.1
	return (player["base_power"] + player["level"] * 1.2 + player["attributes"]["power"] * 2.5) * skill_bonus

func mistake_reduction() -> float:
	var class_mod := 0.85 if player["class"] == "Analista" else 1.0
	var skill_mod := 1.0 - player["skills"]["precision"] * 0.1
	return max(0.55, class_mod * skill_mod - player["attributes"]["precision"] * 0.03)

func extra_time() -> float:
	var class_bonus := 2.0 if player["class"] == "Sintetizador" else 0.0
	return class_bonus + player["skills"]["speed"] * 2.0 + player["attributes"]["speed"] * 0.3

func speed_damage_bonus(remaining_time: float, total_time: float) -> float:
	var class_bonus := 0.06 if player["class"] == "Sintetizador" else 0.0
	var speed_factor := clamp(remaining_time / total_time, 0.0, 1.0)
	return 1.0 + class_bonus + speed_factor * 0.22

func start_turn() -> void:
	var question := generate_question(active_world["id"], player["level"], battle["is_boss"])
	battle["question"] = question
	status_label.text = "Combate em %s | %s" % [active_world["name"], "Boss" if battle["is_boss"] else "Inimigo"]
	hp_label.text = "HP Arquiteto: %d / %d" % [battle["player_hp"], player_max_hp()]
	enemy_label.text = "%s HP: %d" % [active_enemy["name"], battle["enemy_hp"]]
	question_label.text = question["prompt"]
	battle_feedback.text = ""
	update_feedback_color(Color.WHITE)
	answer_input.text = ""
	for child in options_box.get_children():
		child.queue_free()
	if question["type"] == "direct":
		answer_input.visible = true
	else:
		answer_input.visible = false
		for option in question["options"]:
			var btn := Button.new()
			btn.text = str(option)
			btn.pressed.connect(Callable(self, "submit_answer").bind(str(option)))
			options_box.add_child(btn)
	turn_started_at = Time.get_ticks_msec()
	var limit := 9.0 + extra_time() - float(min(player["level"], 6)) * 0.3
	limit = max(5.0, limit)
	turn_timer.start(limit)
	set_timer_label(limit)

func _process(_delta: float) -> void:
	if game_state == "battle" and turn_timer.time_left > 0.0:
		set_timer_label(turn_timer.time_left)

func set_timer_label(seconds: float) -> void:
	timer_label.text = "Tempo: %.1fs" % seconds

func submit_answer(raw_answer: String) -> void:
	if game_state != "battle":
		return
	if turn_timer.is_stopped():
		return
	turn_timer.stop()
	resolve_turn(raw_answer)

func _on_turn_timeout() -> void:
	resolve_turn("__timeout__")

func resolve_turn(raw_answer: String) -> void:
	var q: Dictionary = battle["question"]
	var is_correct := false
	if raw_answer != "__timeout__":
		is_correct = str(raw_answer).strip_edges() == str(q["answer"])
	if is_correct:
		var elapsed := float(Time.get_ticks_msec() - turn_started_at) / 1000.0
		var remaining := max(0.0, q["time_limit"] - elapsed)
		var dmg := int(round(player_attack_power() * speed_damage_bonus(remaining, q["time_limit"])))
		battle["enemy_hp"] -= dmg
		battle_feedback.text = "[ACERTO] Dano causado: %d" % dmg
		update_feedback_color(Color("#61ff8b"))
	else:
		var incoming := int(round(active_enemy["damage"] * mistake_reduction()))
		if raw_answer == "__timeout__":
			battle_feedback.text = "[TEMPO ESGOTADO] Você sofreu %d de dano." % incoming
		else:
			battle_feedback.text = "[ERRO] Resposta correta: %s | Dano recebido: %d" % [str(q["answer"]), incoming]
		update_feedback_color(Color("#ff5f5f"))
		battle["player_hp"] -= incoming
	hp_label.text = "HP Arquiteto: %d / %d" % [max(0, battle["player_hp"]), player_max_hp()]
	enemy_label.text = "%s HP: %d" % [active_enemy["name"], max(0, battle["enemy_hp"])]
	if battle["enemy_hp"] <= 0:
		finish_battle(true)
	elif battle["player_hp"] <= 0:
		finish_battle(false)
	else:
		await get_tree().create_timer(1.0).timeout
		start_turn()

func update_feedback_color(color: Color) -> void:
	battle_feedback.add_theme_color_override("font_color", color)

func finish_battle(victory: bool) -> void:
	if victory:
		var gained_xp := 100 if battle["is_boss"] else 45
		if post_game:
			gained_xp += 15
		grant_xp(gained_xp)
		world_progress[active_world["id"]]["battles"] += 1
		if battle["is_boss"]:
			world_progress[active_world["id"]]["cleared"] = true
		battle_feedback.text = "Vitória! +%d XP" % gained_xp
		update_feedback_color(Color("#61ff8b"))
	else:
		battle_feedback.text = "Derrota... Você retorna ao hub da Academia."
		update_feedback_color(Color("#ff5f5f"))
		world_progress[active_world["id"]]["battles"] = max(world_progress[active_world["id"]]["battles"] - 1, 0)
	await get_tree().create_timer(1.5).timeout
	show_screen("world")

func grant_xp(amount: int) -> void:
	player["xp"] += amount
	while player["xp"] >= player["xp_to_next"]:
		player["xp"] -= player["xp_to_next"]
		player["level"] += 1
		player["xp_to_next"] = int(round(player["xp_to_next"] * 1.18))
		player["base_hp"] += 4
		player["base_power"] += 1
		player["attr_points"] += 1

func open_progression() -> void:
	show_screen("progression")

func refresh_progression() -> void:
	progression_label.text = "[b]Progressão do Arquiteto[/b]\nClasse: %s\nNível: %d\nXP: %d/%d\nPontos disponíveis: %d\n\nPotência Lógica: %d\nVelocidade Cognitiva: %d\nPrecisão Mental: %d\n\n[b]Árvore de Habilidades (0-3)[/b]\nPotência: %d\nVelocidade: %d\nPrecisão: %d" % [
		player["class"], player["level"], player["xp"], player["xp_to_next"], player["attr_points"],
		player["attributes"]["power"], player["attributes"]["speed"], player["attributes"]["precision"],
		player["skills"]["power"], player["skills"]["speed"], player["skills"]["precision"]
	]

func invest_point(attr: String) -> void:
	if player["attr_points"] <= 0:
		return
	player["attr_points"] -= 1
	if player["skills"][attr] < 3:
		player["skills"][attr] += 1
	else:
		player["attributes"][attr] += 1
	refresh_progression()

func show_ending() -> void:
	show_screen("ending")
	ending_label.text = "[center][b]Ato 3 Concluído[/b][/center]\n\nVocê derrotou os 3 guardiões e selou temporariamente O Paradoxo.\nEntropy recuou... por enquanto.\n\nCréditos:\n- Academia do Infinito\n- Mentor(a): Guia do Conhecimento\n- Você: Arquiteto(a) do Conhecimento\n\nNo pós-jogo, os mundos permanecem acessíveis com dificuldade levemente aumentada."

func generate_question(world_id: String, level: int, is_boss: bool) -> Dictionary:
	var difficulty := level + (2 if is_boss else 0) + (1 if post_game else 0)
	var mode := "direct" if randi() % 2 == 0 else "mcq"
	var payload := {}
	match world_id:
		"aritmetico":
			payload = arithmetic_question(difficulty)
		"algebrico":
			payload = algebra_question(difficulty)
		_:
			payload = geometry_question(difficulty)
	payload["type"] = mode
	payload["time_limit"] = max(5.0, 9.0 + extra_time() - float(min(level, 6)) * 0.3)
	if mode == "mcq":
		payload["options"] = build_options(int(payload["answer"]))
	return payload

func arithmetic_question(difficulty: int) -> Dictionary:
	var a := randi_range(2, 8 + difficulty * 2)
	var b := randi_range(2, 8 + difficulty * 2)
	var op := ["+", "-", "×", "÷"][randi() % 4]
	if op == "÷":
		a = b * randi_range(2, 5 + int(difficulty / 2))
	var result := 0
	match op:
		"+": result = a + b
		"-": result = a - b
		"×": result = a * b
		_: result = a / b
	return {"prompt": "Resolva: %d %s %d = ?" % [a, op, b], "answer": int(result)}

func algebra_question(difficulty: int) -> Dictionary:
	var x := randi_range(1, 8 + difficulty)
	var a := randi_range(1, 6 + int(difficulty / 2))
	var b := randi_range(-6, 9 + difficulty)
	var c := a * x + b
	return {"prompt": "Encontre x: %dx %s %d = %d" % [a, "+" if b >= 0 else "-", abs(b), c], "answer": x}

func geometry_question(difficulty: int) -> Dictionary:
	var kind := randi() % 3
	if kind == 0:
		var w := randi_range(2, 8 + difficulty)
		var h := randi_range(2, 8 + difficulty)
		return {"prompt": "Área do retângulo (%d x %d)?" % [w, h], "answer": w * h}
	elif kind == 1:
		var side := randi_range(3, 10 + difficulty)
		return {"prompt": "Perímetro do quadrado de lado %d?" % side, "answer": side * 4}
	else:
		var angle := [30, 45, 60, 90, 120][randi() % 5]
		return {"prompt": "Ângulo suplementar de %d°?" % angle, "answer": 180 - angle}

func build_options(correct: int) -> Array:
	var options: Array = [correct]
	while options.size() < 4:
		var delta := randi_range(1, 8)
		var candidate := correct + (delta if randi() % 2 == 0 else -delta)
		if candidate not in options:
			options.append(candidate)
	options.shuffle()
	return options
