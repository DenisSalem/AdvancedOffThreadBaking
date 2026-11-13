extends Node3D

var _is_child_process:bool
var _timestamp:float
var _delay_to_not_spam_stdout:float
var _voxel_gi:VoxelGI
var _child_process_manager:Thread
var _child_process_pid:int

func _ready() -> void:
	self._is_child_process = "--child-process-baking" in OS.get_cmdline_args()
	self._voxel_gi = $VoxelGI
	self.connect_signals()

	if self._is_child_process:
		self.get_tree().root.mode = Window.MODE_MINIMIZED
		self.get_tree().root.get_window().set_title("AdvancedOffThreadBaking")
		Engine.max_fps = 1
		self._voxel_gi.bake()
		ResourceSaver.save(self._voxel_gi.data, "user://voxel_gi_data.res")
		self.get_tree().quit()
		
	else:
		self._child_process_manager = Thread.new()
	
func connect_signals() -> void:
	self._voxel_gi.bake_begin.connect(self.trace_bake_begin)
	self._voxel_gi.bake_step.connect(self.trace_bake_step)
	self._voxel_gi.bake_end.connect(self.trace_bake_end)
			
func _physics_process(_delta: float) -> void:
	if not self._is_child_process:
		$Camera3D.rotate(Vector3(0,1,0), 0.0005)

func _input(event:InputEvent) -> void:
	if (event is InputEventKey) and event.is_pressed():
		if ((event as InputEventKey).as_text_keycode() == "B"):
			self.bake_in_the_main_thread()
		elif ((event as InputEventKey).as_text_keycode() == "O"):
			self.bake_off_the_main_thread()
		elif ((event as InputEventKey).as_text_keycode() == "D"):
			self.delete_voxel_gi_data()
		elif ((event as InputEventKey).as_text_keycode() == "I"):
			self.delete_voxel_gi_node()
		elif ((event as InputEventKey).as_text_keycode() == "R"):
			self.renew_voxel_gi_node()
		elif ((event as InputEventKey).as_text_keycode() == "C"):
			self.bake_in_child_process()
			
func bake_in_the_main_thread() -> void:
	self._voxel_gi.bake()

func bake_off_the_main_thread() -> void:
	# What if this is called many times before completion ?
	self._voxel_gi.bake(null, false, true)

func delete_voxel_gi_data() -> void:
	self._voxel_gi.data = null
	
func delete_voxel_gi_node() -> void:
	if self._voxel_gi != null:
		self._voxel_gi.queue_free()
	
func renew_voxel_gi_node() -> void:
	self.delete_voxel_gi_node()
	self._voxel_gi = VoxelGI.new()
	self._voxel_gi.transform.origin.x = -0.5
	self._voxel_gi.transform.origin.y = 12.45
	self._voxel_gi.transform.origin.z = 0.5
	self._voxel_gi.size.x = 66
	self._voxel_gi.size.y = 25.1
	self._voxel_gi.size.z = 66
	add_child(self._voxel_gi)
	self.connect_signals()

func bake_in_child_process() -> void:
	self._child_process_manager.start(child_process_manager_worker)

func child_process_manager_worker() -> void:
	if OS.get_name() == "Windows":
		self._child_process_pid = OS.create_process("./AdvancedOffThreadBaking.exe", ["--child-process-baking"])

	else:
		self._child_process_pid = OS.create_process("./AdvancedOffThreadBaking.x86_64", ["--child-process-baking"])
		
	while OS.is_process_running(self._child_process_pid):
		OS.delay_msec(1000)
	
	if FileAccess.file_exists("user://voxel_gi_data.res"):
		self._voxel_gi.set_deferred("data", load("user://voxel_gi_data.res"))
		
func trace_bake_begin() -> void:
	self._timestamp = Time.get_unix_time_from_system()
	self._delay_to_not_spam_stdout = Time.get_unix_time_from_system()
	var output:String = "VoxelGI: Baking begin."
	print(output)
	$StatusLabel.text = output
	
func trace_bake_step(step: int, step_status: String):
	if Time.get_unix_time_from_system() - self._delay_to_not_spam_stdout > 2.0:
		var output:String = "VoxelGI: Baking step: "+str(step)+",Baking status: "+step_status
		self._delay_to_not_spam_stdout = Time.get_unix_time_from_system()
		print(output)
		$StatusLabel.text = output
		
func trace_bake_end() -> void:
	var output:String = "VoxelGI: Baking done in "+str(int(Time.get_unix_time_from_system()-self._timestamp))+" seconds."
	print(output)
	$StatusLabel.text = output
	
