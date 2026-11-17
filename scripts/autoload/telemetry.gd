extends Node
## Estatísticas ANÔNIMAS para o Painel dos Jogos (servidor do Recess Club,
## página /admin). Mostra quem entra, que horas, quantos, quanto tempo ficam
## e se voltam (retenção).
##
## O aparelho ganha um código aleatório (não é nome, e-mail, telefone,
## localização nem ID de publicidade). Envia:
##   session_start  ao abrir o jogo (versão e plataforma)
##   heartbeat      a cada minuto com os segundos jogados na sessão
##   session_end    ao fechar ou ir para segundo plano
##   level          quando uma fase/partida termina (Telemetry.level(...))
## Sem internet, a fila espera (limitada) e tenta depois. Não envia nada
## rodando pelo editor nem nos testes (headless).

const GAME_ID := "arrow-survival"
const SERVER := "https://escola-production-061f.up.railway.app"
const FLUSH_EVERY := 60.0
const MAX_QUEUE := 300
const NEW_SESSION_AFTER := 300.0 ## segundos em segundo plano que contam como nova sessão
const FILE := "user://telemetry.cfg"

var _queue: Array = []
var _pending: Array = []
var _http: HTTPRequest
var _sending := false
var _t := 0.0
var _uid := ""
var _sid := ""
var _seconds := 0.0
var _active := false
var _paused_at := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not enabled():
		set_process(false)
		return
	_http = HTTPRequest.new()
	_http.timeout = 15.0
	add_child(_http)
	_http.request_completed.connect(_on_done)
	_uid = _load_uid()
	_start_session()
	# primeiro envio logo, para o painel já mostrar quem entrou
	get_tree().create_timer(8.0, true).timeout.connect(flush)


func enabled() -> bool:
	if OS.has_feature("editor") or DisplayServer.get_name() == "headless":
		return false
	return " ".join(OS.get_cmdline_args()).find("res://tests/") == -1


## Fase ou partida terminada. `level` pode ser o número da fase ou um nome.
func level(level_id: Variant, won: bool, score := 0) -> void:
	track("level", {"level": level_id, "won": won, "score": score})


## Evento livre do jogo (ex.: "loja_aberta"). Só números, textos curtos e sim/não.
func event(event_name: String, data := {}) -> void:
	var d := data.duplicate()
	d["name"] = event_name
	track("event", d)


func track(type: String, data := {}) -> void:
	if not enabled():
		return
	_queue.append({"type": type, "at": int(Time.get_unix_time_from_system() * 1000.0), "data": data})
	if _queue.size() > MAX_QUEUE:
		_queue = _queue.slice(_queue.size() - MAX_QUEUE)


func _load_uid() -> String:
	var cfg := ConfigFile.new()
	cfg.load(FILE)
	var id := str(cfg.get_value("t", "uid", ""))
	if id.length() < 8:
		id = Crypto.new().generate_random_bytes(12).hex_encode()
		cfg.set_value("t", "uid", id)
		cfg.save(FILE)
	return id


func _start_session() -> void:
	_sid = Crypto.new().generate_random_bytes(8).hex_encode()
	_seconds = 0.0
	_active = true
	_t = 0.0
	track("session_start", {"sid": _sid, "platform": OS.get_name(), "lang": OS.get_locale_language(),
		"version": str(ProjectSettings.get_setting("application/config/version", ""))})


func _process(delta: float) -> void:
	if not _active:
		return
	_seconds += delta
	_t += delta
	if _t >= FLUSH_EVERY:
		_t = 0.0
		track("heartbeat", {"sid": _sid, "seconds": int(_seconds)})
		flush()


func _pause() -> void:
	if not _active:
		return
	_active = false
	_paused_at = Time.get_ticks_msec() / 1000.0
	track("heartbeat", {"sid": _sid, "seconds": int(_seconds)})
	flush()


func _resume() -> void:
	if _active or _sid == "":
		return
	if Time.get_ticks_msec() / 1000.0 - _paused_at > NEW_SESSION_AFTER:
		track("session_end", {"sid": _sid, "seconds": int(_seconds)})
		_start_session()
		flush()
	else:
		_active = true


func _notification(what: int) -> void:
	if not enabled() or _http == null:
		return
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			_pause()
		NOTIFICATION_APPLICATION_RESUMED, NOTIFICATION_APPLICATION_FOCUS_IN:
			_resume()
		NOTIFICATION_WM_CLOSE_REQUEST:
			_active = false
			track("session_end", {"sid": _sid, "seconds": int(_seconds)})
			flush()


func flush() -> void:
	if _sending or _queue.is_empty() or _http == null:
		return
	var batch := _queue.slice(0, 100)
	var body := JSON.stringify({"game": GAME_ID, "uid": _uid, "events": batch})
	var err := _http.request(SERVER + "/api/games/events", ["Content-Type: application/json"], HTTPClient.METHOD_POST, body)
	if err == OK:
		_sending = true
		_queue = _queue.slice(batch.size())
		_pending = batch


func _on_done(result: int, code: int, _h: PackedStringArray, _b: PackedByteArray) -> void:
	_sending = false
	if result != HTTPRequest.RESULT_SUCCESS or code >= 500:
		# sem internet: devolve para a fila e tenta depois
		_queue = _pending + _queue
		if _queue.size() > MAX_QUEUE:
			_queue = _queue.slice(_queue.size() - MAX_QUEUE)
	_pending = []
