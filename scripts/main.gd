extends Control
## Stage-C: duration modes, pause, high score, menu.

const COMBO_WINDOW := 0.8
const MODES: Array[Dictionary] = [
	{"id": "short", "name": "短局 15s", "time": 15.0},
	{"id": "normal", "name": "标准 30s", "time": 30.0},
	{"id": "long", "name": "长局 45s", "time": 45.0},
]

@onready var _hud: Label = $UI/HUD
@onready var _btn: Button = $Center/Tap
@onready var _overlay: ColorRect = $UI/Overlay
@onready var _over_msg: Label = $UI/Overlay/VBox/Msg
@onready var _retry: Button = $UI/Overlay/VBox/Retry
@onready var _pulse: ColorRect = $Pulse

var _score: int = 0
var _combo: int = 0
var _best_combo: int = 0
var _time_left: float = 30.0
var _time_limit: float = 30.0
var _alive: bool = false
var _paused: bool = false
var _in_menu: bool = true
var _last_tap: float = -10.0
var _menu: ColorRect
var _to_menu: Button
var _pause_btn: Button

func _ready() -> void:
	_btn.pressed.connect(_on_tap)
	_retry.pressed.connect(_restart_play)
	_build_shell()
	_show_menu()

func _build_shell() -> void:
	_menu = ColorRect.new()
	_menu.color = Color(0.12, 0.1, 0.16, 1)
	_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_CENTER)
	vb.offset_left = -130
	vb.offset_top = -140
	vb.offset_right = 130
	vb.offset_bottom = 140
	vb.add_theme_constant_override("separation", 12)
	var title := Label.new()
	title.text = "点击奏鸣"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.95, 0.55, 0.75))
	vb.add_child(title)
	var hi := Label.new()
	hi.name = "High"
	hi.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(hi)
	for m in MODES:
		var b := Button.new()
		b.text = str(m["name"])
		b.custom_minimum_size = Vector2(240, 40)
		var mid: String = str(m["id"])
		b.pressed.connect(func() -> void: _start_mode(mid))
		vb.add_child(b)
	_menu.add_child(vb)
	$UI.add_child(_menu)
	_to_menu = Button.new()
	_to_menu.text = "返回菜单"
	_to_menu.pressed.connect(_show_menu)
	$UI/Overlay/VBox.add_child(_to_menu)
	_pause_btn = Button.new()
	_pause_btn.text = "暂停"
	_pause_btn.position = Vector2(270, 8)
	_pause_btn.size = Vector2(80, 28)
	_pause_btn.pressed.connect(_toggle_pause)
	$UI.add_child(_pause_btn)

func _show_menu() -> void:
	_alive = false
	_paused = false
	_in_menu = true
	_overlay.visible = false
	_menu.visible = true
	_pause_btn.visible = false
	$Center.visible = false
	(_menu.get_node("VBoxContainer/High") as Label).text = "最高分 %d" % SaveData.high_score
	_hud.text = "点击奏鸣"

func _start_mode(mode_id: String) -> void:
	for m in MODES:
		if str(m["id"]) == mode_id:
			_time_limit = float(m["time"])
			break
	_in_menu = false
	_menu.visible = false
	$Center.visible = true
	_pause_btn.visible = true
	_restart_play()

func _restart_play() -> void:
	_score = 0
	_combo = 0
	_best_combo = 0
	_time_left = _time_limit
	_alive = true
	_paused = false
	_last_tap = -10.0
	_overlay.visible = false
	_btn.disabled = false
	_pulse.modulate.a = 0.0
	_update_hud()

func _toggle_pause() -> void:
	if not _alive or _in_menu:
		return
	_paused = not _paused
	_btn.disabled = _paused
	_update_hud()

func _process(delta: float) -> void:
	if not _alive or _paused or _in_menu:
		return
	_time_left -= delta
	if _time_left <= 0.0:
		_time_left = 0.0
		_end()
	_pulse.modulate.a = maxf(0.0, _pulse.modulate.a - delta * 2.5)
	_update_hud()

func _on_tap() -> void:
	if not _alive or _paused or _in_menu:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_tap <= COMBO_WINDOW:
		_combo += 1
	else:
		_combo = 1
	_last_tap = now
	_best_combo = maxi(_best_combo, _combo)
	_score += 1 + mini(_combo - 1, 9)
	_pulse.modulate.a = 0.45
	_btn.scale = Vector2(1.08, 1.08)
	get_tree().create_timer(0.08).timeout.connect(func() -> void: _btn.scale = Vector2.ONE)
	_update_hud()

func _fmt_hud() -> String:
	return "得分 %d  最高 %d\n连击 %d（局内最高 %d）\n剩余 %.1fs%s" % [
		_score, SaveData.high_score, _combo, _best_combo, _time_left, "\n[暂停]" if _paused else ""
	]

func _update_hud() -> void:
	_hud.text = _fmt_hud()

func _end() -> void:
	_alive = false
	_btn.disabled = true
	var best: int = SaveData.record(_score)
	_over_msg.text = "时间到\n得分 %d\n最高连击 %d\n最高分 %d" % [_score, _best_combo, best]
	_overlay.visible = true
