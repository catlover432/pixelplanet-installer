extends Control


const SUCCESS_COLOR: Color = Color(0., 1., 0.)
const DOWNLOAD_COLOR: Color = Color(0., 1., 0.3)
const ERR_COLOR: Color = Color(1., 0., 0.)
const HTTP_SUCCESS_STR: String = "Downloading Pixel Planet Classic"
const HTTP_ERR_STR: String = "Cannot download: HTTP request error!"
const METADATA_ERR_STR: String = "Error: Cannot fetch proper metadata!"
const DOWNLOAD_SUCCESS_STR: String = "Pixel Planet has successfully downloaded!"

var DEFAULT_DOWNLOAD_DIR: String = OS.get_user_data_dir() + "/bin/"

var downloading := false
var current_download_dir := DEFAULT_DOWNLOAD_DIR
var ppc_version: String = ""

@onready var http := $HTTPRequest
@onready var status_label := $HBoxContainer/StatusLabel
@onready var byte_count_label := $HBoxContainer/ByteCountLabel
@onready var install_button := $HBoxContainer/InstallButton
@onready var select_folder_button := $HBoxContainer/SelectFolderButton
@onready var start_menu_checkbox := $HBoxContainer/CenterContainer/StartMenuCheckBox
@onready var file_dialog := $FileDialog
@onready var install_dir_label := $InstallDirLabel
@onready var byte_progress_bar := $HBoxContainer/ByteProgressBar


func _ready() -> void:
	if not DirAccess.dir_exists_absolute(current_download_dir):
		DirAccess.make_dir_absolute(current_download_dir)
	
	http.request_completed.connect(_info_request_completed)
	http.request("https://api.github.com/repos/catlover432/pixel-planet-releases/releases/latest")


func _process(_delta: float) -> void:
	if downloading == true:
		var bytes: int = http.get_downloaded_bytes()
		byte_count_label.text = str(bytes / 1000000) + " MB Downloaded"
		byte_progress_bar.value = bytes * 1.01
	install_dir_label.text = "Installing to " + current_download_dir


func _on_install_button_pressed() -> void:
	downloading = true
	
	install_button.disabled = true
	select_folder_button.disabled = true
	start_menu_checkbox.disabled = true
	byte_count_label.visible = true
	byte_count_label.text = ""
	byte_progress_bar.visible = true
	byte_progress_bar.value = 0
	
	http.connect("request_completed", _binary_request_completed)
	var result: int = http.request("https://github.com/catlover432/pixel-planet-releases/releases/latest/download/PixelPlanetClassic.exe")
	if result == OK:
		status_label.set("theme_override_colors/font_color", SUCCESS_COLOR)
		status_label.text = "%s (ver. %s)" % [HTTP_SUCCESS_STR, ppc_version]
	else:
		status_label.set("theme_override_colors/font_color", ERR_COLOR)
		status_label.text = HTTP_ERR_STR


func _info_request_completed(result: int, _response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result == OK:
		var json = JSON.parse_string(body.get_string_from_utf8())
		
		byte_progress_bar.max_value = json.assets[0].size
		ppc_version = json.tag_name
		install_button.disabled = false
	else:
		status_label.set("theme_override_colors/font_color", SUCCESS_COLOR)
		status_label.text = METADATA_ERR_STR
	
	http.request_completed.disconnect(_info_request_completed)


func _binary_request_completed(result: int, _response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	downloading = false
	
	install_button.disabled = false
	select_folder_button.disabled = false
	start_menu_checkbox.disabled = false
	
	if result == OK:
		var file := FileAccess.open(current_download_dir + "PixelPlanetClassic.exe", FileAccess.WRITE)
		file.store_buffer(body)
		file.close()
		status_label.set("theme_override_colors/font_color", DOWNLOAD_COLOR)
		status_label.text = DOWNLOAD_SUCCESS_STR
		
		if start_menu_checkbox.button_pressed == true:
			OS.shell_open(current_download_dir)
	else:
		status_label.set("theme_override_colors/font_color", ERR_COLOR)
		status_label.text = HTTP_ERR_STR
	
	http.request_completed.disconnect(_binary_request_completed)


func _on_select_folder_button_pressed() -> void:
	file_dialog.visible = true


func _on_file_dialog_dir_selected(dir: String) -> void: 
	current_download_dir = dir + "\\"


func _on_github_button_pressed() -> void:
	OS.shell_open("https://github.com/catlover432/pixelplanet-installer")
