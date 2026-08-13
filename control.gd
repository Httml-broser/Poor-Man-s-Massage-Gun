extends Control

var joy_array = [Vector2(1,0.7), Vector2(0,1),Vector2(1,0.3)]
var default_file_path: String = "user://joysavedata.dat"
var default_folder_path: String = "user://"
var joy_id: int = -1
var vib_active: bool = false
var vib_power: float = 0.5
var last_sttp_state: bool = false
var first_load: bool = false
var spliting_method: Array[String] = [":","-"]
const precision_level: int = 100
var asyncvar: int = 0
var update_vib: int = 20000

func _on_joy_connection_changed(device: int, connected: bool) -> void:
	if connected and joy_id == -1: 
		joy_id = device
	elif not connected and joy_id == device: 
		_reconnect_joypad()

func _reconnect_joypad() -> void:
	var pads = Input.get_connected_joypads()
	if pads.size() > 0:
		joy_id = pads[0]
	else:
		joy_id = -1
		vib_active = false
		Input.stop_joy_vibration(joy_id)

var _dynamic_button_container: ScrollContainer = null
func create_dynamic_row_of_buttons(callback: Callable, count: int, button_height: int, wall_distance: int, spacing: int = 15) -> void:
	# Optional: Clear any existing buttons before creating new ones to prevent overlapping
	delete_dynamic_buttons()
	
	if count <= 0:
		return
		
	var screen_size: Vector2 = get_viewport().get_visible_rect().size
	var container_width: float = screen_size.x * 0.8
	var start_x: float = (screen_size.x - container_width) / 2.0
	
	var scroll := ScrollContainer.new()
	
	# 2. Store the newly created container in your class variable
	_dynamic_button_container = scroll 
	
	scroll.position = Vector2(start_x, 70)
	scroll.size = Vector2(container_width, 310)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	scroll.add_child(vbox)
	
	var margin_container := MarginContainer.new()
	margin_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin_container.add_theme_constant_override("margin_left", wall_distance)
	margin_container.add_theme_constant_override("margin_right", wall_distance)
	vbox.add_child(margin_container)
	
	var flow := HFlowContainer.new()
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flow.alignment = FlowContainer.ALIGNMENT_CENTER
	flow.add_theme_constant_override("h_separation", spacing)
	flow.add_theme_constant_override("v_separation", spacing)
	margin_container.add_child(flow)
	
	var min_button_width: int = 100
	
	for i in range(count):
		var new_button := Button.new()
		new_button.text = "Mode " + str(i + 1)
		new_button.custom_minimum_size = Vector2(min_button_width, button_height)
		
		flow.add_child(new_button)
		new_button.pressed.connect(callback.bind(i + 1))

func delete_dynamic_buttons() -> void:
	# Check if the container exists and hasn't already been destroyed
	if is_instance_valid(_dynamic_button_container):
		_dynamic_button_container.queue_free()
		_dynamic_button_container = null

func _on_button_pressed(button_id: int) -> void:
	print(button_id)
	_update_label(str(button_id),"Current Mode: " , mode_label, 320)
	apply_vibe(joy_array[button_id-1])
	
	pass

var file_dialog := FileDialog.new()

var mode_label = Label.new()
var input_line = LineEdit.new()

var slider1 = VSlider.new()
var slider2 = VSlider.new()

var try_value =  Button.new()
var value_enter = Button.new()
var slider_label = Label.new()


func _ready() -> void:
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.use_native_dialog = true
	file_dialog.file_selected.connect(_on_file_selected)


	
	mode_label.position = Vector2(300,42)
	_update_label(str(0), "Current Mode: ", mode_label, 320)
	
	input_line.size = Vector2(476, 28)
	input_line.position = Vector2(82,10)
	input_line.text = "1:0-1:1-0:1- 1:0.5 - 0.3:1 - 0.7:0.5"
	input_line.text_submitted.connect(func(text: String):_update_joy_array(parce_input(text)))
	input_line.focus_exited.connect(func(text: String):_update_joy_array(parce_input(text)))
	input_line.focus_entered.connect(_focus_auto_delete)
	
	var stop_button = Button.new()
	stop_button.size = Vector2(160,60)
	stop_button.position = Vector2(240,400)
	stop_button.text = "Stop Joy"
	stop_button.pressed.connect(_flipidyflopidy)
	_refresh()
	
	var save_button = Button.new()
	save_button.text = "Save"
	save_button.add_theme_font_size_override("font_size", 14)
	save_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	save_button.pressed.connect(save_array)
	save_button.position = Vector2(11,11)
	save_button.size = Vector2(64,40)
	
	var load_button = Button.new()
	load_button.text = "Load"
	load_button.add_theme_font_size_override("font_size", 14)
	load_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	load_button.pressed.connect(_reload_dynamic_settings)
	load_button.position = Vector2(565,11)
	load_button.size = Vector2(64,40)
	
	var file_path_sel = Button.new()
	file_path_sel.text = "Change File"
	file_path_sel.add_theme_font_size_override("font_size", 14)
	file_path_sel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	file_path_sel.pressed.connect(_on_open_button_pressed)
	file_path_sel.position = Vector2(565,152)
	file_path_sel.size = Vector2(64,40)
	
	
	slider1.max_value = 1
	slider1.min_value = 0
	slider1.step = 0.01
	slider1.value = 0.1
	slider1.scrollable = true
	slider1.size = Vector2(17, 152)
	slider1.position = Vector2(48, 158)
	slider1.value_changed.connect(_slider_label_update)
	
	slider2.max_value = 1
	slider2.min_value = 0
	slider2.step = 0.01
	slider2.value = 0.1
	slider2.scrollable = true
	slider2.size = Vector2(17, 152)
	slider2.position = Vector2(86, 158)
	slider2.value_changed.connect(_slider_label_update)
	
	slider_label.text = "0.11:0.11"
	slider_label.size = Vector2(50, 23)
	slider_label.position = Vector2(51, 125)
	
	try_value.text = "Try"
	try_value.size = Vector2(62, 22)
	try_value.position = Vector2(44, 100)
	try_value.pressed.connect(try_sence)
	
	value_enter.text = "Add"
	value_enter.size = Vector2(62, 32)
	value_enter.position = Vector2(44, 320)
	value_enter.pressed.connect(append_to_input)
	
	add_child(value_enter)
	add_child(try_value)
	add_child(slider_label)
	add_child(slider1)
	add_child(slider2)
	add_child(save_button)
	add_child(load_button)
	add_child(file_path_sel)
	add_child(stop_button)
	add_child(mode_label)
	add_child(input_line)
	add_child(file_dialog)
	
	_reconnect_joypad()
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	
	print(size)
	print(get_viewport_rect().size)

func _process(delta: float) -> void:
	if joy_id == -1: return
	
	if(Time.get_ticks_msec()>(asyncvar + update_vib)):
		asyncvar += update_vib
		var vib_temp: Vector2 = Input.get_joy_vibration_strength(joy_id)
		if !(vib_temp == Vector2(0,0)):
			Input.stop_joy_vibration(joy_id)
			await get_tree().create_timer(0.1).timeout
			apply_vibe(vib_temp)
			pass
		pass


func apply_vibe(vib:Vector2, time:float = 0.0) -> void:
	# Weak motor (left), Strong motor (right), Duration (0 = infinite)
	Input.start_joy_vibration(joy_id, vib.x, vib.y, time)
	pass

func _reload_dynamic_settings():
	var text = load_from_file(default_file_path)
	if text.is_empty():
		print("Empty Filer")
		return
	var data = str_to_var(text)
	if data is Array:
		joy_array = data
		_refresh()
		input_line.text = semihuman_unparcer()
	else:
		push_error("Invalid save file.")

func _refresh():
	delete_dynamic_buttons()
	create_dynamic_row_of_buttons(_on_button_pressed, joy_array.size(), 64, 80, 15)
	print("Refreshed!")
	

func _exit_tree() -> void:
	if joy_id != -1:
		Input.stop_joy_vibration(joy_id)

func _flipidyflopidy() -> void:
	Input.stop_joy_vibration(joy_id)
	_update_label("0","Current Mode: ", mode_label, 320)

func save_array():
	save_to_file(joy_array)

func save_to_file(content):
	var file = FileAccess.open(default_file_path, FileAccess.WRITE)
	file.store_string(var_to_str(content))
	pass

func load_from_file(file_path: String) -> String:
	if not FileAccess.file_exists(file_path):
		return ""

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return ""

	return file.get_as_text()

func _update_label(input_text: String, prefix: String, _label: Label, centrer) -> void:
	_label.text = prefix + input_text

	var font := _label.get_theme_font("font")
	var font_size := _label.get_theme_font_size("font_size")
	var width := font.get_string_size(_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x

	_label.position.x = (centrer*2 - width) / 2

func sanitize_input(text: String) -> String:
	var regex := RegEx.new()
	regex.compile("[^0-9." + str(spliting_method[0]) + str(spliting_method[1])+ "]")
	return regex.sub(text, "", true)

func parce_input(input: String) -> Array[Vector2]:
	var data = sanitize_input(input).split(str(spliting_method[1]), false)
	if (data.is_empty()):
		return []
	var data3: Array[Vector2] = []
	for i in range(data.size()):
		var data2 = data[i].split(str(spliting_method[0]), false)
		if (data2.size() == 2):
			data3.append(Vector2(data2[0].to_float(),data2[1].to_float()))
		else:
			print("Error in Input Line: " + str(i))
	
	return data3

func semihuman_unparcer() -> String:
	var output: String = str(round(precision_level*joy_array[0].x)/precision_level) + ":" + str(round(precision_level*joy_array[0].y)/precision_level)
	for i in range(1, joy_array.size()):
		output = output + " - " + str(round(precision_level*joy_array[i].x)/precision_level) + ":" + str(round(precision_level*joy_array[i].y)/precision_level)
	
	return output

func _update_joy_array(somthing: Array[Vector2]):
	if !(somthing.is_empty()):
		joy_array = somthing
		_refresh()

func _focus_auto_delete():
	if first_load:
		input_line.clear()
		first_load = false

func _slider_label_update(value):
	_update_label((str(slider1.value) + ":" + str(slider2.value)), "", slider_label, 76)

func try_sence():
	apply_vibe(Vector2(slider1.value,slider2.value),5)

func append_to_input():
	input_line.text += "-" + str(slider1.value) + ":" + str(slider2.value)

func _on_open_button_pressed():
	file_dialog.popup_centered()

func _on_file_selected(path: String):
	default_file_path = path
	print(path)
