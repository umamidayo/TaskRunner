local BaseTask = {}
BaseTask.__index = BaseTask

--[[
    Creates a new base task instance
]]
function BaseTask.new(name: string, taskList: { any })
	local self = {
		Name = name,
		Tasks = {},
	}

	table.insert(taskList, self)
	return setmetatable(self, BaseTask)
end

--[[
    Finds a task by name in the given list
]]
function BaseTask.findByName(name: string, taskList: { any })
	for _, task in taskList do
		if task.Name == name then
			return task
		end
	end
	return nil
end

--[[
    Waits for a task to exist in the given list
]]
function BaseTask.waitForTask(name: string, taskList: { any }, timeout: number)
	local startTick = tick()
	local foundTask

	repeat
		task.wait()
		foundTask = BaseTask.findByName(name, taskList)
	until foundTask or tick() - startTick >= timeout

	return foundTask
end

--[[
    Adds a task to this instance
]]
function BaseTask:addTask(taskRef: any, callback: (number) -> nil)
	self.Tasks[taskRef] = callback
end

--[[
    Removes a task from this instance
]]
function BaseTask:removeTask(taskRef: any)
	if self.Tasks[taskRef] then
		self.Tasks[taskRef] = nil
	end
end

--[[
    Executes all tasks with the given delta time
]]
function BaseTask:executeTasks(dt: number)
	for _, taskCallback in self.Tasks do
		task.spawn(function()
			taskCallback(dt)
		end)
	end
end

--[[
    Destroys this task instance
]]
function BaseTask:destroy(taskList: { any })
	local index = table.find(taskList, self)
	if index then
		table.remove(taskList, index)
	end
	setmetatable(self, nil)
end

return BaseTask
