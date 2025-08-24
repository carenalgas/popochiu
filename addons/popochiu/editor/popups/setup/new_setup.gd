@tool
extends Control

signal size_calculated

# ---- General items -----------------------------------------------------------
@onready var wizard_steps: TabContainer = %WizardSteps
@onready var btn_prev: Button = %BtnPrev
@onready var btn_next: Button = %BtnNext
@onready var btn_custom: LinkButton = %BtnCustom
@onready var filler_prev: Panel = %FillerPrev
@onready var filler_next: Panel = %FillerNext
@onready var lbl_step: Label = %LabelStep
@onready var div_line: Panel = %DivLine
# ---- Items that need styling -------------------------------------------------
@onready var lbl_cta_type: Label = %LblCTAType
@onready var lbl_cta_res: Label = %LblCTARes
@onready var lbl_cta_preview_scale: Label = %LblCTAPreviewScale
@onready var lbl_cta_gui: Label = %LblCTAUI
# ---- Game Type Step ----------------------------------------------------------
@onready var btn_gametype_retro: Button = %BtnTypeRetro
@onready var btn_gametype_modern: Button = %BtnTypeModern
# ---- Resolution Step ---------------------------------------------------------
@onready var opt_res_retro: OptionButton = %OptResRetro
@onready var opt_res_modern: OptionButton = %OptResModern
@onready var opt_res_preview_scale: OptionButton = %OptPreviewScale
@onready var opt_res_retro_cont: MarginContainer = %OptResRetroContainer
@onready var opt_res_modern_cont: MarginContainer = %OptResModernContainer
@onready var opt_res_preview_scale_cont: MarginContainer = %OptPreviewScaleContainer
@onready var tooltip_res: PanelContainer = %TooltipRes
@onready var tooltip_res_text: RichTextLabel = %TooltipResText
# ---- GUI selection step ------------------------------------------------------
@onready var btn_gui_nineverbs: Button = %BtnNineVerbs
@onready var btn_gui_actionbar: Button = %BtnActionBar
@onready var btn_gui_simpleclick: Button = %BtnSimpleClick
@onready var tooltip_gui: PanelContainer = %TooltipGUI
@onready var tooltip_gui_text: RichTextLabel = %TooltipGUIText

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Apply some base styling and properties

	_style_navigation_buttons()
	_style_tooltips()
	_style_selection_buttons()
	_style_divider_line()

	# Connect navigation buttons
	btn_prev.pressed.connect(_on_prev_pressed)
	btn_next.pressed.connect(_on_next_pressed)
	
	# Connect visibility signals to automatically manage fillers
	btn_prev.visibility_changed.connect(_on_prev_visibility_changed)
	btn_next.visibility_changed.connect(_on_next_visibility_changed)
	
	# Connect GUI selection buttons
	btn_gui_nineverbs.pressed.connect(_on_gui_selected.bind(btn_gui_nineverbs))
	btn_gui_actionbar.pressed.connect(_on_gui_selected.bind(btn_gui_actionbar))
	btn_gui_simpleclick.pressed.connect(_on_gui_selected.bind(btn_gui_simpleclick))
	
	# Initialize step label
	_update_navigation()


func _on_prev_pressed():
	if wizard_steps.current_tab > 0:
		wizard_steps.current_tab -= 1
		_update_navigation()


func _on_next_pressed():
	if wizard_steps.current_tab < wizard_steps.get_tab_count() - 1:
		wizard_steps.current_tab += 1
		_update_navigation()


func _on_prev_visibility_changed():
	# When prev button visibility changes, toggle the filler visibility inversely
	filler_prev.visible = not btn_prev.visible


func _on_next_visibility_changed():
	# When next button visibility changes, toggle the filler visibility inversely
	filler_next.visible = not btn_next.visible


func _update_navigation():
	# Update step label
	var current_step = wizard_steps.current_tab + 1
	var total_steps = wizard_steps.get_tab_count() - 1
	lbl_step.text = "Step %d / %d" % [current_step, total_steps]
	
	# Control button visibility (fillers will be handled automatically by signals)
	btn_prev.visible = wizard_steps.current_tab > 0
	btn_next.visible = wizard_steps.current_tab < wizard_steps.get_tab_count() - 1


func _on_gui_selected(btn: Button):
	tooltip_gui_text.text = btn.editor_description
	tooltip_gui.show()


# Invoked right before the pupup opens.
# We are using this to apply styling and colors to the setup window elements.
# Doing it before popping up ensures that if the user changes editor theme,
# the elements will be updated accordingly.
func on_about_to_popup() -> void:
	pass


func _style_divider_line() -> void:
	# This will hold the various stylebox while we go through the elements.
	var existing_style: StyleBox
	
	# Apply color to the division line
	existing_style = div_line.get_theme_stylebox("panel")
	if existing_style is StyleBoxFlat:
		existing_style.bg_color = get_theme_color("highlight_color", "Editor")



func _style_tooltips() -> void:
	# This will hold the various stylebox while we go through the elements.
	var existing_style: StyleBox

	# Make sure the tooltips have the correct background and font size.
	# Get the existing stylebox and modify its background color
	existing_style = tooltip_gui.get_theme_stylebox("panel")
	if existing_style is StyleBoxFlat:
		existing_style.bg_color = get_theme_color("dark_color_1", "Editor")

	# Make the tooltip text font smaller than the editor base font
	var smaller_font_size = int(get_theme_font_size("main_size", "EditorFonts") * 0.85)
	# Apply the smaller size to the resolution and GUI tooltips
	for tooltip in [tooltip_res_text, tooltip_gui_text]:
		tooltip.add_theme_font_size_override("normal_font_size", smaller_font_size)
		tooltip.add_theme_font_size_override("bold_font_size", smaller_font_size)
		tooltip.add_theme_font_size_override("italic_font_size", smaller_font_size)
		tooltip.add_theme_font_size_override("bold_italics_font_size", smaller_font_size)
		tooltip.add_theme_font_size_override("mono_font_size", smaller_font_size)


func _style_selection_buttons() -> void:
	# This will hold the various stylebox while we go through the elements.
	var existing_style: StyleBox

	# Style all buttons
	existing_style = btn_gametype_modern.get_theme_stylebox("normal")
	if not existing_style is StyleBoxFlat:
		return

	var btn_base_style = existing_style.duplicate(true) as StyleBoxFlat
	
	# Set corner radius for both background and border
	btn_base_style.corner_radius_top_left = 12
	btn_base_style.corner_radius_top_right = 12
	btn_base_style.corner_radius_bottom_left = 12
	btn_base_style.corner_radius_bottom_right = 12

	# Or add content margin to the StyleBox for overall padding
	btn_base_style.content_margin_left = 6
	btn_base_style.content_margin_right = 6
	btn_base_style.content_margin_top = 6
	btn_base_style.content_margin_bottom = 6

	btn_base_style.corner_detail = 8
	
	var btn_bg_color: Color = get_theme_color("highlight_color", "Editor")

	var btn_normal_style:StyleBoxFlat = btn_base_style.duplicate(true) as StyleBoxFlat
	btn_normal_style.bg_color = btn_bg_color.darkened(0.5)

	var btn_hover_style:StyleBoxFlat = btn_base_style.duplicate(true) as StyleBoxFlat
	btn_hover_style.bg_color = btn_bg_color

	var btn_pressed_style:StyleBoxFlat = btn_base_style.duplicate(true) as StyleBoxFlat
	btn_pressed_style.bg_color = btn_bg_color.darkened(0.25)

	# Create focus style (this is what creates the selection border)
	var btn_focus_style:StyleBoxFlat = btn_base_style.duplicate(true) as StyleBoxFlat
	btn_focus_style.bg_color = btn_bg_color.darkened(0.5)
	btn_focus_style.border_color = get_theme_color("selection_color", "Editor")
	btn_focus_style.set_border_width_all(2)

	for button in [btn_gametype_retro, btn_gametype_modern, btn_gui_nineverbs, btn_gui_actionbar, btn_gui_simpleclick]:
		# Normal state
		button.add_theme_stylebox_override("normal", btn_normal_style)	
		# Hover state
		button.add_theme_stylebox_override("hover", btn_hover_style)
		# Pressed/selected state
		button.add_theme_stylebox_override("pressed", btn_pressed_style)
		# Focus state (selection border)
		button.add_theme_stylebox_override("focus", btn_focus_style)
		# Set color overrides
		button.add_theme_color_override("font_color", get_theme_color("accent_color", "Editor").lightened(0.7))
		button.add_theme_color_override("icon_normal_color", get_theme_color("accent_color", "Editor").lightened(0.7))
		button.add_theme_color_override("font_pressed_color", Color.WHITE)
		button.add_theme_color_override("icon_pressed_color", Color.WHITE)


func _style_navigation_buttons() -> void:
	# Assign icons to navigation buttons
	btn_prev.icon = get_theme_icon("PagePrevious", "EditorIcons")
	btn_next.icon = get_theme_icon("PageNext", "EditorIcons")

	var accent_color: Color = get_theme_color("accent_color", "Editor")
	btn_custom.add_theme_color_override("font_color", accent_color)
	btn_custom.add_theme_color_override("font_hover_color", accent_color.lightened(0.3))
	btn_custom.add_theme_color_override("font_pressed_color", accent_color.lightened(0.6))


func on_close() -> void:
	# if _is_closing:
	# 	return
	
	# _is_closing = true
	
	# ProjectSettings.set_setting(PopochiuResources.DISPLAY_WIDTH, int(game_width.value))
	# ProjectSettings.set_setting(PopochiuResources.DISPLAY_HEIGHT, int(game_height.value))
	# ProjectSettings.set_setting(PopochiuResources.TEST_WIDTH, int(test_width.value))
	# ProjectSettings.set_setting(PopochiuResources.TEST_HEIGHT, int(test_height.value))
	
	# match game_type.selected:
	# 	GameTypes.HD:
	# 		ProjectSettings.set_setting(PopochiuResources.STRETCH_MODE, "canvas_items")
	# 		ProjectSettings.set_setting(PopochiuResources.STRETCH_ASPECT, "expand")
			
	# 		PopochiuConfig.set_pixel_art_textures(false)
	# 	GameTypes.RETRO_PIXEL:
	# 		ProjectSettings.set_setting(PopochiuResources.STRETCH_MODE, "canvas_items")
	# 		ProjectSettings.set_setting(PopochiuResources.STRETCH_ASPECT, "keep")
			
	# 		PopochiuConfig.set_pixel_art_textures(true)
	
	# if not PopochiuResources.is_setup_done() or not PopochiuResources.is_gui_set():
	# 	PopochiuResources.set_data_value("setup", "done", true)
	# 	await _copy_template(true)
	
	# get_parent().queue_free()
	return

func define_content(show_welcome := false) -> void:
	# _is_closing = false
	# _selected_template = null
	# btn_change_template.hide()
	# copy_process_container.hide()
	
	# scale_message.modulate = Color(
	# 	"#000" if "Light3D" in _es.get_setting("interface/theme/preset") else "#fff"
	# )
	# scale_message.modulate.a = 0.8
	
	# copy_process_panel.add_theme_stylebox_override(
	# 	"panel", get_theme_stylebox("panel", "PopupPanel")
	# )

	# if not show_welcome:
	# 	welcome.text = "[center][b]POPOCHIU [shake]\\( u )3(u)/[/shake][/b][/center]"
	# 	btn_change_template.disabled = true
	# 	btn_change_template.show()
	
	# # ---- Set initial values for fields ---------------------------------------
	# game_width.value = ProjectSettings.get_setting(PopochiuResources.DISPLAY_WIDTH)
	# game_height.value = ProjectSettings.get_setting(PopochiuResources.DISPLAY_HEIGHT)
	# test_width.value = ProjectSettings.get_setting(PopochiuResources.TEST_WIDTH)
	# test_height.value = ProjectSettings.get_setting(PopochiuResources.TEST_HEIGHT)
	# scale_message.text = _get_scale_message()
	
	# game_type.selected = GameTypes.CUSTOM
	
	# if ProjectSettings.get_setting(PopochiuResources.STRETCH_MODE) == "canvas_items":
	# 	match ProjectSettings.get_setting(PopochiuResources.STRETCH_ASPECT):
	# 		"expand":
	# 			game_type.selected = GameTypes.HD
	# 		"keep":
	# 			game_type.selected = GameTypes.RETRO_PIXEL
	
	# # Load the list of templates
	# await _load_templates()
	
	# _select_config_template()
	
	# if show_welcome:
	# 	# Make Pixel the default game type checked during first run
	# 	game_type.selected = GameTypes.RETRO_PIXEL
	
	# if PopochiuResources.GUI_GAME_SCENE in EditorInterface.get_open_scenes():
	# 	_show_gui_warning()
		
	# 	for btn: Button in gui_templates.get_children():
	# 		btn.disabled = true
		
	# 	template_description_container.hide()
	
	_update_size()


func _update_size() -> void:
	# Wait for the popup content to be rendered in order to get its size
	await get_tree().create_timer(0.05).timeout
	
	custom_minimum_size = get_child(0).size
	size_calculated.emit()
