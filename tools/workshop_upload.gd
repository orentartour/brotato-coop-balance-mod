extends SceneTree

# Uploads a new version of an existing Workshop item, headless.
# Run from the Brotato install folder:
#   GodotWorkshopUtility.exe --no-window -s <abs path>/workshop_upload.gd \
#       --ws-id=<item id> [--ws-zip=<abs zip path>] --ws-note="change note"
#       [--ws-desc=<abs path to description file>] [--ws-title=<title>]
#       [--ws-preview=<abs path to png/jpg>]
# Only what is passed changes (title, description, preview, content).

const APP_ID = 1942280

var _t := 0.0
var _done := false
var _ok := false


func _arg(name: String) -> String:
	for a in OS.get_cmdline_args():
		if a.begins_with("--" + name + "="):
			return a.substr(name.length() + 3)
	return ""


func _init() -> void:
	var item_id: = int(_arg("ws-id"))
	var zip: = _arg("ws-zip")
	var note: = _arg("ws-note")
	var desc_path: = _arg("ws-desc")
	var title: = _arg("ws-title")
	var preview: = _arg("ws-preview")
	if item_id == 0 or (zip != "" and not File.new().file_exists(zip)):
		print("ERROR missing --ws-id or invalid --ws-zip")
		_done = true
		return
	print("init: ", Steam.steamInitEx(APP_ID, true))
	Steam.connect("item_updated", self, "_updated")
	var h = Steam.startItemUpdate(APP_ID, item_id)
	if desc_path != "":
		var f = File.new()
		if f.open(desc_path, File.READ) == OK:
			Steam.setItemDescription(h, f.get_as_text())
			f.close()
	if title != "":
		Steam.setItemTitle(h, title)
	if preview != "":
		Steam.setItemPreview(h, preview)
	if zip != "":
		Steam.setItemContent(h, zip)
	Steam.submitItemUpdate(h, note)
	print("submitted item ", item_id)


func _updated(result: int, accept_tos: bool, _file_id = 0) -> void:
	_ok = result == 1
	print("RESULT %s (1 = OK) accept_tos=%s" % [result, accept_tos])
	_done = true


func _idle(delta: float) -> bool:
	Steam.run_callbacks()
	_t += delta
	if _done or _t > 150.0:
		print("UPLOAD %s" % ("OK" if _ok else "FAILED"))
		return true
	return false
