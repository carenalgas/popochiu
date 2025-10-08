@tool
extends Control

signal template_copy_completed
signal size_calculated

enum SetupMode {
	WIZARD,
	CUSTOM,
}

enum GameType {
	MODERN,
	RETRO,
}

enum GameResolutionScale {
	HALF,
	FULL,
	DOUBLE,
	QUAD,
}

enum GameResolution {
	# --- Separator = 0 ---
	RETRO_NEO_RETRO = 1,
	# --- Separator = 2 ---
	RETRO_VGA_4_3 = 3,
	RETRO_VGA_16_9 = 4,
	# --- Separator = 5 ---
	RETRO_CEGA_4_3 = 6,
	RETRO_CEGA_16_9 = 7,
	# --- Modern / Hi-Res has no separatos ---
	MODERN_4K = 8,
	MODERN_QHD = 9,
	MODERN_FHD = 10,
	MODERN_HDR = 11,
	MODERN_RETRO = 12,
}

enum CustomResRatio {
	RATIO_16_9,
	RATIO_4_3,
	RATIO_FREE,
}

# Used to control the direction of ratio adjustment
# in custom resolution settings.
enum {
	WIDTH_CHANGED,
	HEIGHT_CHANGED
}


const PopochiuGuiTemplatesHelper = preload(
	"res://addons/popochiu/editor/helpers/popochiu_gui_templates_helper.gd"
)
const PopochiuResources = preload("res://addons/popochiu/popochiu_resources.gd")
const PopochiuConfig = preload("res://addons/popochiu/editor/config/config.gd")


# ---- Game configuration section ----------------------------------------------
var _current_mode: SetupMode = SetupMode.WIZARD
var _game_type: GameType
var _game_resolution: Vector2i
var _game_window_resolution: Vector2i

# Dictionary to store GUI templates by target resolution
var _templates_by_res: Dictionary = {
	PopochiuGUIInfo.GUITargetRes.LOW_RESOLUTION: [],
	PopochiuGUIInfo.GUITargetRes.HIGH_RESOLUTION: []
}

# Template tracking for change detection
var _current_template_name: String = ""
var _selected_template_name: String = ""
var _template_change_confirmed: bool = false
var _copy_in_progress: bool = false

var _is_closing: bool = false
var _es: EditorSettings = EditorInterface.get_editor_settings()

# Internal reference to the dialog's OK button.
# used to enable/disable it based on validation and change
# its text based on setup state.
var _dialog_ok_button: Button = null

# ---- General items -----------------------------------------------------------
@onready var wizard_steps: TabContainer = %WizardSteps
# -------- Main Areas Containers -----------------------------------------------
@onready var wizard_container: PanelContainer = %WizardContainer
@onready var custom_container: PanelContainer = %CustomContainer
# -------- Separators ----------------------------------------------------------
@onready var nav_separator: HSeparator = %NavSeparator
@onready var resolution_separator: HSeparator = %ResolutionSeparator
# -------- Navigation Area -----------------------------------------------------
@onready var btn_prev: Button = %BtnPrev
@onready var btn_next: Button = %BtnNext
@onready var btn_custom: LinkButton = %BtnCustom
@onready var btn_wizard: LinkButton = %BtnWizard
@onready var filler_prev: Panel = %FillerPrev
@onready var filler_next: Panel = %FillerNext
@onready var lbl_step: Label = %LabelStep
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
@onready var gui_grid: GridContainer = %BtnGrid
@onready var btn_gui_type_template: Button = %BtnGUIType
@onready var tooltip_gui: PanelContainer = %TooltipGUI
@onready var tooltip_gui_text: RichTextLabel = %TooltipGUIText
# ---- Custom section ----------------------------------------------------------
@onready var opt_game_ui: OptionButton = %OptGameUI
@onready var tooltip_no_gui_text: RichTextLabel = %TooltipNoGUIText
@onready var tooltip_custom_gui_text: RichTextLabel = %TooltipCustomGUIText
@onready var opt_game_type: OptionButton = %OptGameType
@onready var custom_width: SpinBox = %CustomWidth
@onready var custom_height: SpinBox = %CustomHeight
@onready var preview_width: SpinBox = %PreviewWidth
@onready var preview_height: SpinBox = %PreviewHeight
@onready var opt_keep_ratio: OptionButton = %OptKeepRatio
# -------- Underfield Labels ---------------------------------------------------
@onready var lbl_width: Label = %LblWidth
@onready var lbl_height: Label = %LblHeight
@onready var lbl_ratio: Label = %LblRatio
@onready var lbl_preview_width: Label = %LblPreviewWidth
@onready var lbl_preview_height: Label = %LblPreviewHeight
# ---- ButtonGroups -------------------------------------------------------------
@onready var game_type_button_group: ButtonGroup = btn_gametype_retro.button_group
@onready var gui_button_group: ButtonGroup = btn_gui_type_template.button_group
# ---- CopyProcess Elements -----------------------------------------------------
@onready var copy_process_container: PanelContainer = %CopyProcessContainer
@onready var copy_process_label: Label = %CopyProcessLabel
@onready var copy_process_bar: ProgressBar = %CopyProcessBar


#region Godot #################################################################

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Select the first tab
	wizard_steps.set_current_tab(0)

	# Apply some base styling and properties
	_style_navigation_buttons()
	_style_tooltips()
	_style_selection_buttons()
	_style_separators()
	_style_underfield_labels()
	_style_progress_container()

	# Connect navigation buttons
	btn_prev.pressed.connect(_on_prev_pressed)
	btn_next.pressed.connect(_on_next_pressed)

	# Connect mode switch buttons
	btn_custom.pressed.connect(_on_btn_custom_pressed)
	btn_wizard.pressed.connect(_on_btn_wizard_pressed)

	# Connect visibility signals to automatically manage fillers
	btn_prev.visibility_changed.connect(_on_prev_visibility_changed)
	btn_next.visibility_changed.connect(_on_next_visibility_changed)

	# Connect game type buttons to handle all game type changes
	btn_gametype_retro.pressed.connect(_on_game_type_changed)
	btn_gametype_modern.pressed.connect(_on_game_type_changed)

	# Connect validation signals for Step 1 (Game Type)
	btn_gametype_retro.pressed.connect(_update_navigation)
	btn_gametype_modern.pressed.connect(_update_navigation)

	# Connect validation signals for Step 2 (Resolution)
	opt_res_retro.item_selected.connect(_on_resolution_option_changed)
	opt_res_modern.item_selected.connect(_on_resolution_option_changed)
	opt_res_preview_scale.item_selected.connect(_on_resolution_option_changed)

	# Note: GUI validation is handled in _on_wizard_gui_selected() for dynamic buttons

	# Connect tab change signal to trigger validation when switching tabs
	wizard_steps.tab_changed.connect(_on_wizard_tab_changed)

	# Connect custom resolution SpinBox signals for aspect ratio management
	custom_width.value_changed.connect(_on_custom_width_changed)
	custom_height.value_changed.connect(_on_custom_height_changed)
	preview_width.value_changed.connect(_on_preview_width_changed)
	preview_height.value_changed.connect(_on_preview_height_changed)
	
	# Also connect to focus_exited to catch manual text input changes
	custom_width.get_line_edit().focus_exited.connect(func(): _on_custom_width_changed(custom_width.value))
	custom_height.get_line_edit().focus_exited.connect(func(): _on_custom_height_changed(custom_height.value))
	preview_width.get_line_edit().focus_exited.connect(func(): _on_preview_width_changed(preview_width.value))
	preview_height.get_line_edit().focus_exited.connect(func(): _on_preview_height_changed(preview_height.value))

	# Connect custom mode validation signals
	opt_game_type.item_selected.connect(_on_custom_field_changed)
	custom_width.value_changed.connect(_on_custom_field_changed)
	custom_height.value_changed.connect(_on_custom_field_changed)
	preview_width.value_changed.connect(_on_custom_field_changed)
	preview_height.value_changed.connect(_on_custom_field_changed)

	# Connect custom GUI select signal
	opt_game_ui.item_selected.connect(_on_custom_game_ui_changed)

	# Connect custom ratio change signal
	opt_keep_ratio.item_selected.connect(_on_custom_ratio_changed)

	# Initialize step label
	_on_btn_wizard_pressed()
	_update_navigation()
	_update_resolution_options()
	_update_custom_gui_tooltip()

	# Load GUI templates
	_load_templates()


#endregion

#region Public ################################################################
# Invoked right before the pupup opens.
# We are using this to apply styling and colors to the setup window elements.
# Doing it before popping up ensures that if the user changes editor theme,
# the elements will be updated accordingly.
func on_about_to_popup() -> void:
	# Reset session state flag when dialog is shown
	_is_closing = false
	_template_change_confirmed = false
	_copy_in_progress = false

	# Set the text of the confirmation dialog depending on the setup state.
	# Get reference to the dialog's OK button if we're inside a ConfirmationDialog.
	var parent: Node = get_parent()
	if parent is ConfirmationDialog:
		_dialog_ok_button = parent.get_ok_button()
		# Update button label based on setup state.
		_dialog_ok_button.text = "Update" if PopochiuResources.is_setup_done() else "Create"
		# Initialize the OK button state.
		_update_dialog_ok_button()

	# Should be ok, but for good measure, we are going to select the correct template
	_set_template_selected_in_ui(_current_template_name)


func on_close() -> void:
	if _is_closing:
		return

	# Clean up any open confirmation dialogs
	_cleanup_pending_dialogs()

	_is_closing = true

	# Save the current mode for next time
	PopochiuResources.set_data_value("setup", "last_mode", _current_mode)

	# Calculate resolution values based on current mode
	var resolution_values: Dictionary = _get_values_for_current_mode()

	# Set project settings for game and window resolution
	ProjectSettings.set_setting(PopochiuResources.DISPLAY_WIDTH, resolution_values.game_width)
	ProjectSettings.set_setting(PopochiuResources.DISPLAY_HEIGHT, resolution_values.game_height)
	ProjectSettings.set_setting(PopochiuResources.TEST_WIDTH, resolution_values.test_width)
	ProjectSettings.set_setting(PopochiuResources.TEST_HEIGHT, resolution_values.test_height)

	# Configure stretch mode and pixel art settings based on game type
	match resolution_values.game_type_config:
		GameType.MODERN:
			ProjectSettings.set_setting(PopochiuResources.STRETCH_MODE, "canvas_items")
			ProjectSettings.set_setting(PopochiuResources.STRETCH_ASPECT, "expand")
			PopochiuConfig.set_pixel_art_textures(false)
		GameType.RETRO:
			ProjectSettings.set_setting(PopochiuResources.STRETCH_MODE, "canvas_items")
			ProjectSettings.set_setting(PopochiuResources.STRETCH_ASPECT, "keep")
			PopochiuConfig.set_pixel_art_textures(true)

	# Handle GUI template copying based on setup state and user choices
	await _handle_gui_template_copying(resolution_values.gui_template_name)

	# Make sure to syncronize buttons and dropdown
	_set_template_selected_in_ui(_current_template_name)


func define_content() -> void:
	# Get current template for change detection
	_current_template_name = PopochiuResources.get_data_value("ui", "template", "")
	_selected_template_name = _current_template_name


	# Restore last used mode if setup was done before, otherwise default to wizard
	_current_mode = PopochiuResources.get_data_value("setup", "last_mode", SetupMode.WIZARD)

	# Populate fields with current project settings
	_restore_from_settings()

	# Show appropriate container and update UI
	match _current_mode:
		SetupMode.WIZARD:
			_on_btn_wizard_pressed()
		SetupMode.CUSTOM:
			_on_btn_custom_pressed()

	# Games that have been already setup in wizard mode need this
	# to properly set buttons status when the popup gets open by the user.
	if PopochiuResources.is_setup_done() and _current_mode == SetupMode.WIZARD:
		# Ensure wizard starts at step 0 and navigation is properly updated.
		wizard_steps.current_tab = 0
		_update_navigation()
		# Disable Update button until user completes the wizard
		if _dialog_ok_button:
			_dialog_ok_button.disabled = true

	# Ensure correct tooltip is shown for custom GUI select
	_update_custom_gui_tooltip()

	# Check for GUI scene open warning
	if PopochiuResources.GUI_GAME_SCENE in EditorInterface.get_open_scenes():
		_show_gui_warning()

	_update_size()

	# Ensure both wizard and custom GUI elements are populated with templates
	# For existing games, always populate wizard buttons; for new games, only if game type is selected
	if game_type_button_group.get_pressed_button() != null or PopochiuResources.is_setup_done():
		_populate_wizard_gui_buttons()
	_populate_custom_gui_dropdown()

	# Select the current template in both wizard and custom modes
	_select_current_template()


#endregion

#region Private ###################################################################################
# Populate fields with current project settings
func _restore_from_settings() -> void:
	# Get current project settings
	var game_width: int = ProjectSettings.get_setting(PopochiuResources.DISPLAY_WIDTH, 356)
	var game_height: int = ProjectSettings.get_setting(PopochiuResources.DISPLAY_HEIGHT, 200)
	var test_width: int = ProjectSettings.get_setting(PopochiuResources.TEST_WIDTH, 1280)
	var test_height: int = ProjectSettings.get_setting(PopochiuResources.TEST_HEIGHT, 720)

	# Populate custom fields
	custom_width.value = game_width
	custom_height.value = game_height
	preview_width.value = test_width
	preview_height.value = test_height

	# Determine game type from stretch settings
	var stretch_mode: String = ProjectSettings.get_setting(PopochiuResources.STRETCH_MODE, "disabled")
	var stretch_aspect: String = ProjectSettings.get_setting(PopochiuResources.STRETCH_ASPECT, "ignore")
	var is_pixel_art: bool = PopochiuConfig.is_pixel_art_textures()

	# Set custom game type
	if stretch_mode == "canvas_items":
		if stretch_aspect == "keep" or is_pixel_art:
			opt_game_type.selected = 1 # Pixel Art (index 1 in dropdown)
		else:
			opt_game_type.selected = 2 # High Resolution (index 2 in dropdown)
	else:
		opt_game_type.selected = 0 # Custom (index 0 in dropdown)

	# Set wizard selections based on current settings (only for existing games)
	if PopochiuResources.is_setup_done():
		_populate_wizard_from_settings(Vector2i(game_width, game_height), Vector2i(test_width, test_height), is_pixel_art)


# Set wizard selections from current project settings
func _populate_wizard_from_settings(game_res: Vector2i, test_res: Vector2i, is_pixel: bool) -> void:
	# Determine game type
	if is_pixel:
		btn_gametype_retro.button_pressed = true
		_game_type = GameType.RETRO
	else:
		btn_gametype_modern.button_pressed = true
		_game_type = GameType.MODERN

	# Update resolution options to show the correct dropdown
	_update_resolution_options()

	# Find matching resolution
	_find_and_set_resolution_options(game_res, is_pixel)

	# Calculate and set preview scale
	if game_res.x > 0 and game_res.y > 0:
		var scale_x: float = float(test_res.x) / float(game_res.x)
		var scale_y: float = float(test_res.y) / float(game_res.y)
		var scale: float = min(scale_x, scale_y)

		if abs(scale - 0.5) < 0.1:
			opt_res_preview_scale.selected = GameResolutionScale.HALF
		elif abs(scale - 2.0) < 0.1:
			opt_res_preview_scale.selected = GameResolutionScale.DOUBLE
		elif abs(scale - 4.0) < 0.1:
			opt_res_preview_scale.selected = GameResolutionScale.QUAD
		else:
			opt_res_preview_scale.selected = GameResolutionScale.FULL


# Find and set the closest resolution option
func _find_and_set_resolution_options(game_res: Vector2i, is_pixel: bool) -> void:
	if is_pixel:
		# Try to find matching retro resolution
		if game_res == Vector2i(384, 216):
			opt_res_retro.selected = GameResolution.RETRO_NEO_RETRO
		elif game_res == Vector2i(320, 200):
			opt_res_retro.selected = GameResolution.RETRO_VGA_4_3
		elif game_res == Vector2i(356, 200):
			opt_res_retro.selected = GameResolution.RETRO_VGA_16_9
		elif game_res == Vector2i(240, 180):
			opt_res_retro.selected = GameResolution.RETRO_CEGA_4_3
		elif game_res == Vector2i(320, 180):
			opt_res_retro.selected = GameResolution.RETRO_CEGA_16_9
		else:
			opt_res_retro.selected = GameResolution.RETRO_VGA_16_9 # Default
	else:
		# Try to find matching modern resolution
		if game_res == Vector2i(3840, 2160):
			opt_res_modern.selected = GameResolution.MODERN_4K
		elif game_res == Vector2i(2560, 1440):
			opt_res_modern.selected = GameResolution.MODERN_QHD
		elif game_res == Vector2i(1920, 1080):
			opt_res_modern.selected = GameResolution.MODERN_FHD
		elif game_res == Vector2i(1280, 720):
			opt_res_modern.selected = GameResolution.MODERN_HDR
		elif game_res == Vector2i(1024, 768):
			opt_res_modern.selected = GameResolution.MODERN_RETRO
		else:
			opt_res_modern.selected = GameResolution.MODERN_FHD # Default


# Select current template in both wizard and custom modes
func _select_current_template() -> void:
	if _current_template_name.is_empty():
		return

	# Use the helper to set UI selection
	_set_template_selected_in_ui(_current_template_name)

	# Update tooltips for both modes
	_update_custom_gui_tooltip()
	_update_wizard_gui_tooltip()


# Show warning when GUI scene is open
func _show_gui_warning() -> void:
	var warning_dialog: AcceptDialog = AcceptDialog.new()
	warning_dialog.title = "GUI template warning"
	warning_dialog.dialog_text = "The GUI scene (gui.tscn) is currently opened in the Editor.\n\n" + \
		"In order to change the GUI template please close that scene first."
	warning_dialog.dialog_autowrap = true
	warning_dialog.min_size.x = size.x - 64

	# Disable template selection in both modes
	for child in gui_grid.get_children():
		if child.has_meta("template_button"):
			child.disabled = true

	opt_game_ui.disabled = true

	add_child(warning_dialog)
	warning_dialog.popup_centered()
	warning_dialog.tree_exited.connect(warning_dialog.queue_free)


# Show confirmation dialog for template changes
func _show_template_change_confirmation(new_template_name: String) -> void:
	var confirmation_dialog: ConfirmationDialog = ConfirmationDialog.new()
	confirmation_dialog.title = "Confirm GUI template change"
	confirmation_dialog.dialog_text = "Changing your GUI template will override any changes you made to the files in res://game/gui/.\nAlso, your game scripts may need to be updated.\n\nAre you sure you want to make the change?"
	confirmation_dialog.dialog_autowrap = true
	confirmation_dialog.min_size.x = size.x - 64

	confirmation_dialog.confirmed.connect(
		func():
			_template_change_confirmed = true
			_selected_template_name = new_template_name
			_cleanup_confirmation_dialog(confirmation_dialog)
	)

	confirmation_dialog.canceled.connect(
		func():
			# Revert UI selections to current template
			_revert_template_selection()
			_cleanup_confirmation_dialog(confirmation_dialog)
	)

	# Also handle if dialog is closed via X button or Escape
	confirmation_dialog.close_requested.connect(
		func():
			_revert_template_selection()
			_cleanup_confirmation_dialog(confirmation_dialog)
	)

	add_child(confirmation_dialog)
	confirmation_dialog.popup_centered()


# Clean up confirmation dialog and its signals
func _cleanup_confirmation_dialog(dialog: ConfirmationDialog) -> void:
	# Since we're using lambda functions, we can't easily disconnect them
	# Just remove from tree and queue for deletion - the signals will be cleaned up automatically
	if dialog.get_parent():
		dialog.get_parent().remove_child(dialog)
	dialog.queue_free()


# Clean up any pending confirmation dialogs when main dialog closes
func _cleanup_pending_dialogs() -> void:
	# Reset copy state to prevent issues if closing during copy
	_copy_in_progress = false

	# Find and clean up any confirmation dialogs that might still be open
	for child in get_children():
		if child is ConfirmationDialog or child is AcceptDialog:
			child.hide()
			if child.get_parent():
				child.get_parent().remove_child(child)
			child.queue_free()


# Revert UI template selection to current template
func _revert_template_selection() -> void:
	_set_template_selected_in_ui(_current_template_name)


# Set template selection in both wizard and custom UI modes
func _set_template_selected_in_ui(template_name: String) -> void:
	# Set wizard GUI buttons
	for child in gui_grid.get_children():
		if child.has_meta("template_button"):
			var button_template_name: String = _get_button_template_name(child)
			child.set_pressed_no_signal(button_template_name == template_name)

	# Set custom dropdown
	for i in range(opt_game_ui.item_count):
		var dropdown_template_name: String = _get_dropdown_template_name(i)
		if dropdown_template_name == template_name:
			opt_game_ui.selected = i
			break


# Extract template name from GUI button
func _get_button_template_name(button: Button) -> String:
	# Get template data from button metadata
	var template_data: Dictionary = button.get_meta("template_data", null)
	if template_data:
		return _get_template_name_from_data(template_data)

	return ""


# Extract template name from dropdown index
func _get_dropdown_template_name(index: int) -> String:
	if index == 0: # "No GUI" option
		return ""

	# Get template data from item metadata
	var template_data := opt_game_ui.get_item_metadata(index)
	if template_data:
		return _get_template_name_from_data(template_data)

	return ""


# Updates the container size to fit the content.
func _update_size() -> void:
	# Wait for the popup content to be rendered in order to get its size
	await get_tree().create_timer(0.05).timeout

	custom_minimum_size = get_child(0).size
	size_calculated.emit()


# Updates tooltip visibility for custom GUI select
func _update_custom_gui_tooltip() -> void:
	if opt_game_ui.selected == 0:
		tooltip_no_gui_text.show()
		tooltip_custom_gui_text.hide()
	else:
		tooltip_no_gui_text.hide()
		tooltip_custom_gui_text.show()


# Update wizard GUI tooltip based on currently selected button
func _update_wizard_gui_tooltip() -> void:
	# Find the currently pressed button and update tooltip
	for child in gui_grid.get_children():
		if child.has_meta("template_button") and child.button_pressed:
			var template_info: PopochiuGUIInfo = child.get_meta("template_info")
			if template_info:
				tooltip_gui_text.text = template_info.description
				tooltip_gui.show()
			return
	
	# No button selected, hide tooltip
	tooltip_gui.hide()


# Update navigation buttons and step label.
func _update_navigation() -> void:
	# Update step label
	var current_step: int = wizard_steps.current_tab + 1
	var total_steps: int = wizard_steps.get_tab_count()
	lbl_step.text = "Step %d / %d" % [current_step, total_steps]

	# Control button visibility (fillers will be handled automatically by signals)
	btn_prev.visible = wizard_steps.current_tab > 0

	# For the next button, check if we're not on the last step AND the current step is valid
	if wizard_steps.current_tab < wizard_steps.get_tab_count() - 1:
		btn_next.visible = _validate_wizard_current_step()
	else:
		btn_next.visible = false

	# Update the dialog's OK button state based on complete wizard validation
	_update_dialog_ok_button()


# Generic function to update the sibling SpinBox maintaining aspect ratio
func _update_aspect_ratio_sibling(source_spinbox: SpinBox, target_spinbox: SpinBox, new_value: float, source_dimension: int) -> void:
	var ratio: float = _get_custom_resolution_ratio()
	if ratio == 0.0:
		return # Free ratio, no enforcement

	# Determine the appropriate signal handler based on which SpinBox we're updating
	var target_signal_handler: Callable
	if target_spinbox == custom_width:
		target_signal_handler = _on_custom_width_changed
	elif target_spinbox == custom_height:
		target_signal_handler = _on_custom_height_changed
	elif target_spinbox == preview_width:
		target_signal_handler = _on_preview_width_changed
	elif target_spinbox == preview_height:
		target_signal_handler = _on_preview_height_changed
	else:
		return # Unknown SpinBox, shouldn't happen

	# Temporarily disconnect the target signal to avoid infinite loops
	target_spinbox.value_changed.disconnect(target_signal_handler)

	# Calculate and set the new value (keeping it as integer)
	var calculated_value: float
	match source_dimension:
		WIDTH_CHANGED:
			calculated_value = new_value / ratio # Width changed, calculate height
		HEIGHT_CHANGED:
			calculated_value = new_value * ratio # Height changed, calculate width

	target_spinbox.value = int(round(calculated_value))

	# Reconnect the signal
	target_spinbox.value_changed.connect(target_signal_handler)


func _update_resolution_options() -> void:
	# Check which game type button is pressed (they are mutually exclusive)
	if btn_gametype_retro.button_pressed:
		opt_res_retro_cont.show()
		opt_res_modern_cont.hide()
	elif btn_gametype_modern.button_pressed:
		opt_res_retro_cont.hide()
		opt_res_modern_cont.show()
	else:
		# No game type selected, hide both containers
		opt_res_retro_cont.hide()
		opt_res_modern_cont.hide()

	# Trigger navigation update to handle next button visibility via validation
	_update_navigation()


# Update the confirmation dialog's OK button state
func _update_dialog_ok_button() -> void:
	if _dialog_ok_button != null:
		var is_valid: bool = false
		match _current_mode:
			SetupMode.WIZARD:
				is_valid = _validate_wizard_complete()
			SetupMode.CUSTOM:
				is_valid = _validate_custom_complete()

		_dialog_ok_button.disabled = not is_valid


# Set game resolution based on user's preferences
func _set_wizard_game_resolution() -> void:
	# Reset game resolution
	_game_resolution = Vector2i.ZERO

	# We need to know which game type is selected,
	# so we can use the right option button.
	if game_type_button_group.get_pressed_button() == null:
		return

	match _game_type:
		GameType.RETRO:
			match opt_res_retro.selected:
				GameResolution.RETRO_NEO_RETRO:
					_game_resolution = Vector2(384, 216)
				GameResolution.RETRO_VGA_4_3:
					_game_resolution = Vector2(320, 200)
				GameResolution.RETRO_VGA_16_9:
					_game_resolution = Vector2(356, 200)
				GameResolution.RETRO_CEGA_4_3:
					_game_resolution = Vector2(240, 180)
				GameResolution.RETRO_CEGA_16_9:
					_game_resolution = Vector2(320, 180)
		GameType.MODERN:
			match opt_res_modern.selected:
				GameResolution.MODERN_4K:
					_game_resolution = Vector2(3840, 2160)
				GameResolution.MODERN_QHD:
					_game_resolution = Vector2(2560, 1440)
				GameResolution.MODERN_FHD:
					_game_resolution = Vector2(1920, 1080)
				GameResolution.MODERN_HDR:
					_game_resolution = Vector2(1280, 720)
				GameResolution.MODERN_RETRO:
					_game_resolution = Vector2(1024, 768)


func _set_wizard_window_resolution() -> void:
	# Let's start from the 1x case
	var resolution_scale: float = 1.0

	# Map the proper scale to selection
	match opt_res_preview_scale.selected:
		GameResolutionScale.HALF:
			resolution_scale = 0.5
		GameResolutionScale.DOUBLE:
			resolution_scale = 2.0
		GameResolutionScale.QUAD:
			resolution_scale = 4.0

	# set_game_window_resolution (make it int!)
	_game_window_resolution = _game_resolution * resolution_scale


func _get_custom_resolution_ratio() -> float:
	match opt_keep_ratio.selected:
		CustomResRatio.RATIO_16_9:
			return 16.0 / 9.0
		CustomResRatio.RATIO_4_3:
			return 4.0 / 3.0

	return 0.0 # Free ratio (default), no need to enforce anything


# Load all GUI templates from the filesystem
func _load_templates() -> void:
	# Clear existing template data
	_templates_by_res[PopochiuGUIInfo.GUITargetRes.LOW_RESOLUTION].clear()
	_templates_by_res[PopochiuGUIInfo.GUITargetRes.HIGH_RESOLUTION].clear()

	# Get template directory
	var template_dir: String = PopochiuResources.GUI_TEMPLATES_FOLDER

	# Get all directories inside the template folder
	var dir: DirAccess = DirAccess.open(template_dir)
	if not dir:
		printerr("[Popochiu] Could not open GUI templates directory: %s" % template_dir)
		return

	dir.list_dir_begin()
	var dir_name: String = dir.get_next()

	# For each directory, look for template info resource
	while dir_name != "":
		if dir.current_is_dir() and not dir_name.begins_with("."):
			var info_path: String = "%s/%s/%s_gui_info.tres" % [template_dir, dir_name, dir_name]

			if FileAccess.file_exists(info_path):
				var template_info: PopochiuGUIInfo = load(info_path)

				if template_info is PopochiuGUIInfo:
					# Store the template in the appropriate category
					var target_res: PopochiuGUIInfo.GUITargetRes = template_info.target_resolution
					var template_data: Dictionary = {
						"path": "%s/%s" % [template_dir, dir_name],
						"title": template_info.title,
						"description": template_info.description,
						"icon": template_info.icon,
						"target_resolution": target_res,
						"info_resource": template_info
					}

					_templates_by_res[target_res].append(template_data)

		dir_name = dir.get_next()

	dir.list_dir_end()

	# Update the GUI dropdown in custom mode
	_populate_custom_gui_dropdown()


# Populate GUI buttons based on selected game type
func _populate_wizard_gui_buttons() -> void:
	# Hide the template button
	btn_gui_type_template.visible = false

	# Hide the GUI tooltip since we are repopulating
	# the buttons grid and none will be selected
	tooltip_gui.hide()

	# Clear existing dynamic buttons (except the template)
	for child in gui_grid.get_children():
		if child != btn_gui_type_template and child.get_meta("template_button", false):
			# Disconnect the signal before freeing to prevent potential issues
			if child.pressed.is_connected(_on_wizard_gui_selected):
				child.pressed.disconnect(_on_wizard_gui_selected)
			child.queue_free()

	# Don't populate if no game type is selected yet
	if game_type_button_group.get_pressed_button() == null:
		return

	# Get the template list based on game type
	var templates_list: Array = []
	if _game_type == GameType.RETRO:
		templates_list = _templates_by_res[PopochiuGUIInfo.GUITargetRes.LOW_RESOLUTION]
	else:
		templates_list = _templates_by_res[PopochiuGUIInfo.GUITargetRes.HIGH_RESOLUTION]

	# If no templates found for this resolution
	if templates_list.is_empty():
		printerr("[Popochiu] No GUI templates found for selected game type")
		return

	# Create a button for each template
	for template in templates_list:
		var template_button: Button = btn_gui_type_template.duplicate()
		template_button.visible = true
		template_button.text = template.title
		template_button.icon = template.icon

		# Store template data in the button for later access
		template_button.set_meta("template_data", template) # Store full template dictionary
		template_button.set_meta("template_button", true)
		template_button.set_meta("template_info", template.info_resource) # Keep for tooltip compatibility
		template_button.button_group = gui_button_group
		template_button.pressed.connect(_on_wizard_gui_selected.bind(template_button))

		# Note: Styling is automatically inherited from btn_gui_type_template
		# Add to grid
		gui_grid.add_child(template_button)


# Populate the GUI dropdown in custom mode
func _populate_custom_gui_dropdown() -> void:
	# Clear existing items except "None"
	while opt_game_ui.item_count > 1:
		opt_game_ui.remove_item(1)

	# Iterate through each resolution category
	for resolution_key in _templates_by_res.keys():
		var templates_list: Array = _templates_by_res[resolution_key]

		# Skip empty categories
		if templates_list.is_empty():
			continue

		# Convert enum name to readable format (e.g., "LOW_RESOLUTION" -> "Low Resolution")
		var enum_name: String = PopochiuGUIInfo.GUITargetRes.keys()[resolution_key]
		var readable_name: String = enum_name.replace("_", " ").capitalize()

		# Add separator with readable name
		opt_game_ui.add_separator(readable_name)

		# Add templates for this resolution category
		for template in templates_list:
			opt_game_ui.add_item(template.title)
			var idx: int = opt_game_ui.item_count - 1
			opt_game_ui.set_item_metadata(idx, template)

	# Select "None" by default
	opt_game_ui.selected = 0


#endregion

#region Private / Setup Logic ####################################################################

# Extract appropriate values based on current mode (wizard vs custom)
func _get_values_for_current_mode() -> Dictionary:
	var result: Dictionary = {
		"game_width": 0,
		"game_height": 0,
		"test_width": 0,
		"test_height": 0,
		"game_type_config": GameType.MODERN,
		"gui_template_name": ""
	}

	match _current_mode:
		SetupMode.WIZARD:
			# Calculate resolution values from wizard selections
			_set_wizard_game_resolution()
			_set_wizard_window_resolution()

			result.game_width = _game_resolution.x
			result.game_height = _game_resolution.y
			result.test_width = _game_window_resolution.x
			result.test_height = _game_window_resolution.y
			result.game_type_config = _game_type

			# Get template data from selected wizard button
			var template_data: Dictionary = _get_selected_wizard_template()
			result.gui_template_name = _get_template_name_from_data(template_data)

		SetupMode.CUSTOM:
			result.game_width = int(custom_width.value)
			result.game_height = int(custom_height.value)
			result.test_width = int(preview_width.value)
			result.test_height = int(preview_height.value)

			# Map custom game type selection to GameType enum
			# Custom OptionButton: 0="Custom", 1="Pixel Art", 2="High Resolution"
			match opt_game_type.selected:
				0: # Custom - default to Modern
					result.game_type_config = GameType.MODERN
				1: # Pixel Art
					result.game_type_config = GameType.RETRO
				2: # High Resolution
					result.game_type_config = GameType.MODERN
				_: # Fallback
					result.game_type_config = GameType.MODERN

			# Get template data from selected custom dropdown
			var template_data: Dictionary = _get_selected_custom_template()
			result.gui_template_name = _get_template_name_from_data(template_data)

	return result


# Get the selected template data from wizard mode buttons
func _get_selected_wizard_template() -> Dictionary:
	var pressed_btn: Button = gui_button_group.get_pressed_button()
	return pressed_btn.get_meta("template_data") if pressed_btn else {}


# Get the selected template data from custom mode dropdown
func _get_selected_custom_template() -> Dictionary:
	if opt_game_ui.selected > 0: # Skip "None" option
		return opt_game_ui.get_item_metadata(opt_game_ui.selected)
	return {}


# Extract template name from template data (works for both wizard and custom modes)
func _get_template_name_from_data(template_data) -> String:
	# template_data should be the template dictionary with the path
	if template_data and template_data.has("path"):
		return _get_template_name_from_path(template_data.path)

	return ""


# Extract template name from the stored GUI path
func _get_template_name_from_path(gui_path: String) -> String:
	if gui_path.is_empty():
		return ""

	# Extract template name from path like "res://addons/popochiu/engine/templates/gui/simple_click/"
	var path_parts: Array = gui_path.split("/")
	for i in range(path_parts.size() - 1, -1, -1):
		if not path_parts[i].is_empty():
			return path_parts[i].to_pascal_case()

	return ""


# Handle GUI template copying based on setup state and user preferences
func _handle_gui_template_copying(template_name: String) -> void:
	# First setup: always copy the template and mark setup as complete
	if not PopochiuResources.is_setup_done() or not PopochiuResources.is_gui_set():
		PopochiuResources.set_data_value("setup", "done", true)
		await _copy_template(template_name)
		return
	
	# Subsequent setups: only copy if user confirmed a template change
	if _selected_template_name != _current_template_name and _template_change_confirmed:
		await _copy_template(_selected_template_name)
	else:
		# No template change: show fake settings update progress
		# to make sure the user receives proper feedback
		await _fake_settings_update_progress()


# Copy the selected GUI template using the existing helper
func _copy_template(template_name: String) -> void:
	if template_name.is_empty() or _copy_in_progress:
		# No template selected or copy already in progress, skip copying
		return

	_copy_in_progress = true

	# Show progress UI and disable controls
	_show_copy_progress()

	# Copy template with progress callbacks
	await PopochiuGuiTemplatesHelper.copy_gui_template(
		template_name,
		_template_copy_progressed,
		_template_copy_completed
	)


# This function fakes progress for settings update when no template copying is needed.
# Yes, it's silly but it gives the user a clear feedback about what changed pressing "Update".
func _fake_settings_update_progress() -> void:
	if _copy_in_progress:
		return
		
	_copy_in_progress = true
	
	# Reuse existing progress UI
	_show_copy_progress()
	
	# Step 1: Update game settings
	_template_copy_progressed(33, "Updating game settings...")
	await get_tree().create_timer(1.0).timeout
	
	# Step 2: Apply resolution changes
	_template_copy_progressed(66, "Applying resolution changes...")
	await get_tree().create_timer(1.0).timeout
	
	# Step 3: Complete
	_template_copy_progressed(100, "Configuration complete!")
	await get_tree().create_timer(1.0).timeout
	
	# Finish using existing completion logic
	_template_copy_completed()


# Show progress container and hide main UI during template copying
func _show_copy_progress() -> void:
	# Hide main containers
	wizard_container.hide()
	custom_container.hide()

	# Show progress container
	copy_process_container.show()

	# Initialize progress bar
	copy_process_bar.value = 0
	copy_process_label.text = "Preparing to copy GUI template..."

	# Disable dialog OK button during copying
	if _dialog_ok_button:
		_dialog_ok_button.disabled = true


# Called during template copying to update progress
func _template_copy_progressed(value: int, message: String) -> void:
	copy_process_label.text = message
	copy_process_bar.value = value


# Called when template copying is completed
func _template_copy_completed() -> void:
	# Clear copy in progress flag
	_copy_in_progress = false

	# Update stored template name and current tracking
	PopochiuResources.set_data_value("ui", "template", _selected_template_name)
	_current_template_name = _selected_template_name

	# Hide progress UI
	copy_process_container.hide()

	# Show the appropriate main container based on current mode
	match _current_mode:
		SetupMode.WIZARD:
			wizard_container.show()
			wizard_steps.current_tab = 0
		SetupMode.CUSTOM:
			custom_container.show()

	# Re-enable dialog OK button
	if _dialog_ok_button:
		_dialog_ok_button.disabled = false

	# Emit completion signal
	template_copy_completed.emit()


#endregion

#region Private / Validation logic ################################################################
# Validate the current step based on the active tab
func _validate_wizard_current_step() -> bool:
	match wizard_steps.current_tab:
		0: # Step Type
			return _validate_wizard_step_type()
		1: # Step Resolution
			return _validate_wizard_step_resolution()
		2: # Step GUI
			return _validate_wizard_step_gui()

	return false


# Validate Step 1: Game Type selection
func _validate_wizard_step_type() -> bool:
	# Check if any button in the game type button group is pressed
	return game_type_button_group.get_pressed_button() != null


# Validate Step 2: Resolution selection
func _validate_wizard_step_resolution() -> bool:
	# Must have the preview scale selected
	if opt_res_preview_scale.selected == -1:
		return false

	# Must have the appropriate resolution option selected based on game type
	if btn_gametype_retro.button_pressed:
		return opt_res_retro.selected != -1
	elif btn_gametype_modern.button_pressed:
		return opt_res_modern.selected != -1
	else:
		# No game type selected (shouldn't happen if step 1 validation worked)
		return false


# Validate Step 3: GUI selection
func _validate_wizard_step_gui() -> bool:
	# Check if any button in the GUI button group is pressed
	return gui_button_group.get_pressed_button() != null


# Validate if the entire wizard is complete (all steps valid)
func _validate_wizard_complete() -> bool:
	return _validate_wizard_step_type() and _validate_wizard_step_resolution() and _validate_wizard_step_gui()


# Validate custom mode fields
func _validate_custom_complete() -> bool:
	# Check if game type option is selected (not -1)
	if opt_game_type.selected == -1:
		return false

	# Check if game resolution fields have valid values (> 0)
	if custom_width.value <= 0 or custom_height.value <= 0:
		return false

	# Check if preview window size fields have valid values (> 0)
	if preview_width.value <= 0 or preview_height.value <= 0:
		return false

	return true


#endregion

#region Private / Styling #########################################################################
func _style_separators() -> void:
	# This will hold the various stylebox while we go through the elements.
	var separators_stylebox: StyleBoxLine = StyleBoxLine.new()

	separators_stylebox.color = get_theme_color("highlight_color", "Editor")
	# Apply color to the division line
	for separator in [nav_separator, resolution_separator]:
		separator.add_theme_stylebox_override("separator", separators_stylebox)


func _style_underfield_labels() -> void:
	for label in [lbl_width, lbl_height, lbl_ratio, lbl_preview_width, lbl_preview_height]:
		label.add_theme_font_size_override("font_size", int(get_theme_font_size("main_size", "EditorFonts") * 0.85))


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

	var btn_base_style: StyleBoxFlat = existing_style.duplicate(true) as StyleBoxFlat

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

	var btn_normal_style: StyleBoxFlat = btn_base_style.duplicate(true) as StyleBoxFlat
	btn_normal_style.bg_color = btn_bg_color.darkened(0.5)

	var btn_hover_style: StyleBoxFlat = btn_base_style.duplicate(true) as StyleBoxFlat
	btn_hover_style.bg_color = btn_bg_color

	var btn_pressed_style: StyleBoxFlat = btn_base_style.duplicate(true) as StyleBoxFlat
	btn_pressed_style.bg_color = btn_bg_color.darkened(0.25)

	# Create focus style (this is what creates the selection border)
	var btn_focus_style: StyleBoxFlat = btn_base_style.duplicate(true) as StyleBoxFlat
	btn_focus_style.bg_color = btn_bg_color.darkened(0.5)
	btn_focus_style.border_color = get_theme_color("selection_color", "Editor")
	btn_focus_style.set_border_width_all(2)

	for button in [btn_gametype_retro, btn_gametype_modern, btn_gui_type_template]:
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
	for button in [btn_custom, btn_wizard]:
		button.add_theme_color_override("font_color", accent_color)
		button.add_theme_color_override("font_hover_color", accent_color.lightened(0.3))
		button.add_theme_color_override("font_pressed_color", accent_color.lightened(0.6))


func _style_progress_container() -> void:
	# Apply consistent theming to progress container elements
	var base_font_size: int = get_theme_font_size("main_size", "EditorFonts")

	# Style the progress label
	copy_process_label.add_theme_font_size_override("font_size", base_font_size)
	copy_process_label.add_theme_color_override("font_color", get_theme_color("font_color", "Editor"))

	# Style the progress bar
	copy_process_bar.add_theme_color_override("font_color", get_theme_color("font_color", "Editor"))


#endregion

#region Signals handlers ######################################################
func _on_custom_game_ui_changed(index: int) -> void:
	# Get template name from dropdown selection
	var new_template_name: String = _get_dropdown_template_name(index)
	
	# Always update the selected template name to track current UI state
	_selected_template_name = new_template_name

	# Check if this is actually a change from the original
	if new_template_name == _current_template_name:
		# User reverted back to original - reset confirmation flag
		_template_change_confirmed = false
		_update_custom_gui_tooltip()
		return

	# Check if GUI scene is open
	if PopochiuResources.GUI_GAME_SCENE in EditorInterface.get_open_scenes():
		# Revert selection and show warning
		_revert_template_selection()
		_show_gui_warning()
		return

	# Show confirmation for template change only if there's an existing GUI to override
	if PopochiuResources.is_setup_done():
		_show_template_change_confirmation(new_template_name)

	_update_custom_gui_tooltip()


func _on_prev_pressed() -> void:
	if wizard_steps.current_tab > 0:
		wizard_steps.current_tab -= 1
		_update_navigation()


func _on_next_pressed() -> void:
	if wizard_steps.current_tab < wizard_steps.get_tab_count() - 1:
		wizard_steps.current_tab += 1
		_update_navigation()


func _on_wizard_tab_changed(_tab: int) -> void:
	# When tab changes, update navigation to trigger validation for the new tab
	_update_navigation()


func _on_resolution_option_changed(_index: int) -> void:
	# When any resolution option changes, trigger validation
	_update_navigation()


func _on_custom_field_changed(_value = null) -> void:
	# When any custom field changes, trigger validation (only affects custom mode)
	_update_dialog_ok_button()


func _on_btn_custom_pressed() -> void:
	_current_mode = SetupMode.CUSTOM
	wizard_container.hide()
	custom_container.show()
	# Update dialog button state for custom mode
	_update_dialog_ok_button()


func _on_btn_wizard_pressed() -> void:
	_current_mode = SetupMode.WIZARD
	custom_container.hide()
	wizard_container.show()
	# Update dialog button state for wizard mode
	_update_dialog_ok_button()


func _on_prev_visibility_changed() -> void:
	# When prev button visibility changes, toggle the filler visibility inversely
	filler_prev.visible = not btn_prev.visible


func _on_next_visibility_changed() -> void:
	# When next button visibility changes, toggle the filler visibility inversely
	filler_next.visible = not btn_next.visible


func _on_wizard_gui_selected(btn: Button) -> void:
	# Get template name from button
	var new_template_name: String = _get_button_template_name(btn)
	
	# Always update the selected template name to track current UI state
	_selected_template_name = new_template_name

	# Check if this is actually a change from the original
	if new_template_name == _current_template_name:
		# User reverted back to original - reset confirmation flag
		_template_change_confirmed = false
		return

	# Check if GUI scene is open
	if PopochiuResources.GUI_GAME_SCENE in EditorInterface.get_open_scenes():
		# Revert selection and show warning
		btn.set_pressed_no_signal(false)
		_revert_template_selection()
		_show_gui_warning()
		return

	# Show confirmation for template change only if there's an existing GUI to override
	if PopochiuResources.is_setup_done():
		_show_template_change_confirmation(new_template_name)

	# Update tooltip
	_update_wizard_gui_tooltip()

	# Update navigation buttons
	_update_navigation()


func _on_custom_width_changed(new_value: float) -> void:
	_update_aspect_ratio_sibling(custom_width, custom_height, new_value, WIDTH_CHANGED)


func _on_custom_height_changed(new_value: float) -> void:
	_update_aspect_ratio_sibling(custom_height, custom_width, new_value, HEIGHT_CHANGED)


func _on_preview_width_changed(new_value: float) -> void:
	_update_aspect_ratio_sibling(preview_width, preview_height, new_value, WIDTH_CHANGED)


func _on_preview_height_changed(new_value: float) -> void:
	_update_aspect_ratio_sibling(preview_height, preview_width, new_value, HEIGHT_CHANGED)


func _on_custom_ratio_changed(index: int) -> void:
	# Check the index
	if index < 2:  # Not free ratio
		# Recalculate game resolution width based on height
		_update_aspect_ratio_sibling(custom_height, custom_width, custom_height.value, HEIGHT_CHANGED)
		# Recalculate preview resolution width based on height
		_update_aspect_ratio_sibling(preview_height, preview_width, preview_height.value, HEIGHT_CHANGED)


# Handle game type selection
func _on_game_type_changed() -> void:
	# Only update if a button is actually pressed
	if btn_gametype_retro.button_pressed:
		_game_type = GameType.RETRO
		# Update resolution options and GUI buttons based on selected game type
		_update_resolution_options()
		_populate_wizard_gui_buttons()
	elif btn_gametype_modern.button_pressed:
		_game_type = GameType.MODERN
		# Update resolution options and GUI buttons based on selected game type
		_update_resolution_options()
		_populate_wizard_gui_buttons()
	# If neither button is pressed, don't update anything


#endregion
