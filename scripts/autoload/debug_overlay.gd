extends Node
## Debug Overlay (STO-TOOLS-002) — centralized debug-aspect registry
## with observer-based filtering. Adapted from the proven mdes design.
##
## Usage:
##   DebugOverlay.log("enemy/ai", self, "AI: %s -> %s", [old, new])
##   if DebugOverlay.should_draw("player/velocity", self): ...
##
## Aspects form a 2-level hierarchy: "group/sub". Observers ("human",
## "test:<name>", "script:<id>") independently request VISUAL and/or
## TEXTUAL output; the actualized state is the union of all observers.

enum TextMode { NONE, LOG }

const SAVE_PATH := "user://debug_profile.json"


class ObserverRequest:
	var visual := false
	var textual: int = TextMode.NONE


class AspectInfo:
	var path := ""
	var group := ""
	var sub := ""
	var description := ""
	var observers: Dictionary = {}  # observer_id -> ObserverRequest
	var actual_visual := false
	var actual_textual: int = TextMode.NONE


## Master gate for VISUAL output only. Textual logging bypasses this —
## tests need logs without the visual overlay.
var global_enabled := false

## Rolling tail of recent DBG lines (for the F3 panel).
const LOG_HISTORY_MAX := 200
var log_history: PackedStringArray = PackedStringArray()

var _aspects: Dictionary = {}       # path -> AspectInfo
var _aspect_order: Array[String] = []

# 3D gizmo channel (STO-TOOLS-003): systems queue lines/points via
# draw_line3/draw_point3 (gated by should_draw); we rebuild one
# unshaded ImmediateMesh from the live queue every frame.
var _draw_items: Array = []         # {a, b, c: Color, until: msec}
var _draw_root: MeshInstance3D
var _draw_mesh: ImmediateMesh


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_profile()

	_draw_mesh = ImmediateMesh.new()
	_draw_root = MeshInstance3D.new()
	_draw_root.name = "DebugGizmos"
	_draw_root.mesh = _draw_mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.no_depth_test = true  # gizmos read through walls
	_draw_root.material_override = mat
	add_child(_draw_root)


func _process(_delta: float) -> void:
	_draw_mesh.clear_surfaces()
	if _draw_items.is_empty():
		return
	var now := Time.get_ticks_msec()
	var live: Array = []
	for item in _draw_items:
		if item["until"] >= now:
			live.append(item)
	_draw_items = live
	if _draw_items.is_empty() or not global_enabled:
		return
	_draw_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for item in _draw_items:
		_draw_mesh.surface_set_color(item["c"])
		_draw_mesh.surface_add_vertex(item["a"])
		_draw_mesh.surface_add_vertex(item["b"])
	_draw_mesh.surface_end()


# -- Registration ------------------------------------------------------

func register(path: String, description := "") -> void:
	if _aspects.has(path):
		if description != "":
			_aspects[path].description = description
		return
	var info := AspectInfo.new()
	info.path = path
	info.description = description
	var parts := path.split("/", false, 2)
	info.group = parts[0] if parts.size() > 0 else path
	info.sub = parts[1] if parts.size() > 1 else ""
	_aspects[path] = info
	_aspect_order.append(path)


func get_aspect_paths() -> Array[String]:
	return _aspect_order


func has_aspect(path: String) -> bool:
	return _aspects.has(path)


# -- Observer management -----------------------------------------------

## observer_id: "human", "test:<name>", "script:<id>".
func set_observer(path: String, observer_id: String, visual: bool,
		textual: int = TextMode.NONE) -> void:
	if not _aspects.has(path):
		register(path)
	var info: AspectInfo = _aspects[path]
	if not visual and textual == TextMode.NONE:
		info.observers.erase(observer_id)
	else:
		var req: ObserverRequest = info.observers.get(observer_id)
		if req == null:
			req = ObserverRequest.new()
			info.observers[observer_id] = req
		req.visual = visual
		req.textual = textual
	_recompute(info)


## Current [visual, textual] request for an observer on an aspect.
func get_observer_state(path: String, observer_id: String) -> Array:
	var info: AspectInfo = _aspects.get(path)
	if info == null:
		return [false, TextMode.NONE]
	var req: ObserverRequest = info.observers.get(observer_id)
	if req == null:
		return [false, TextMode.NONE]
	return [req.visual, req.textual]


func remove_observer(observer_id: String) -> void:
	for path in _aspects:
		var info: AspectInfo = _aspects[path]
		if info.observers.erase(observer_id):
			_recompute(info)


## Remove all non-human observers (tests/scripts).
func clear_transient_observers() -> void:
	for path in _aspects:
		var info: AspectInfo = _aspects[path]
		var doomed: Array = []
		for obs_id in info.observers:
			if obs_id != "human":
				doomed.append(obs_id)
		for obs_id in doomed:
			info.observers.erase(obs_id)
		if not doomed.is_empty():
			_recompute(info)


func _recompute(info: AspectInfo) -> void:
	info.actual_visual = false
	info.actual_textual = TextMode.NONE
	for obs_id in info.observers:
		var req: ObserverRequest = info.observers[obs_id]
		if req.visual:
			info.actual_visual = true
		if req.textual != TextMode.NONE:
			info.actual_textual = req.textual


# -- Hot-path API -------------------------------------------------------

## Gate for visual debug rendering (requires global_enabled).
func should_draw(path: String, _entity: Node = null) -> bool:
	if not global_enabled:
		return false
	var info: AspectInfo = _aspects.get(path)
	return info != null and info.actual_visual


## Run a draw lambda only when the aspect is visually enabled.
func vis(path: String, entity: Node, draw_fn: Callable) -> void:
	if should_draw(path, entity):
		draw_fn.call()


## Gated, formatted textual output. Prefix "DBG <path>:" makes lines
## greppable in logs; lines also land in log_history for the F3 panel.
func log(path: String, _entity: Node, msg: String, args: Array = []) -> void:
	var info: AspectInfo = _aspects.get(path)
	if info == null or info.actual_textual == TextMode.NONE:
		return
	var formatted := msg % args if not args.is_empty() else msg
	var line := "DBG %s: %s" % [path, formatted]
	print(line)
	log_history.append(line)
	if log_history.size() > LOG_HISTORY_MAX:
		log_history = log_history.slice(log_history.size() - LOG_HISTORY_MAX)


## Queue a gizmo line for this frame (or ttl seconds). Gated by
## should_draw, so callers can emit unconditionally.
func draw_line3(path: String, entity: Node, from: Vector3, to: Vector3,
		color := Color.YELLOW, ttl := 0.0) -> void:
	if not should_draw(path, entity):
		return
	_draw_items.append({"a": from, "b": to, "c": color,
			"until": Time.get_ticks_msec() + maxi(int(ttl * 1000.0), 50)})


## Queue a small 3-axis cross marker at a point.
func draw_point3(path: String, entity: Node, pos: Vector3,
		size := 0.15, color := Color.YELLOW, ttl := 0.0) -> void:
	if not should_draw(path, entity):
		return
	var until := Time.get_ticks_msec() + maxi(int(ttl * 1000.0), 50)
	for axis in [Vector3.RIGHT, Vector3.UP, Vector3.BACK]:
		_draw_items.append({"a": pos - axis * size, "b": pos + axis * size,
				"c": color, "until": until})


# -- Persistence (human observer only) -----------------------------------

func save_profile() -> void:
	var data := {"global_enabled": global_enabled, "aspects": {}}
	for path in _aspect_order:
		var info: AspectInfo = _aspects[path]
		var req: ObserverRequest = info.observers.get("human")
		if req != null:
			data["aspects"][path] = {"visual": req.visual, "textual": req.textual}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()


func load_profile() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		file.close()
		return
	file.close()
	var data: Dictionary = json.data
	global_enabled = data.get("global_enabled", false)
	var aspects: Dictionary = data.get("aspects", {})
	for path in aspects:
		var ad: Dictionary = aspects[path]
		set_observer(path, "human", ad.get("visual", false),
				int(ad.get("textual", TextMode.NONE)))


# -- Status (for RCON "debug list") ---------------------------------------

func get_status_text() -> String:
	var lines: Array[String] = []
	lines.append("global visual: %s" % ("ON" if global_enabled else "OFF"))
	lines.append("aspects: %d registered" % _aspects.size())
	var current_group := ""
	for path in _aspect_order:
		var info: AspectInfo = _aspects[path]
		if info.group != current_group:
			current_group = info.group
			lines.append("  %s/" % current_group)
		var vis_str := "V" if info.actual_visual else "."
		var txt_str := "log" if info.actual_textual == TextMode.LOG else "."
		var obs := ",".join(PackedStringArray(info.observers.keys()))
		if obs == "":
			obs = "-"
		lines.append("    %-24s [%s|%-3s] obs=%s  %s"
				% [info.sub, vis_str, txt_str, obs, info.description])
	return "\n".join(lines)
