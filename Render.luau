local BaseTask = require(script.Parent.BaseTask)

-- Render class extending BaseTask
local Render = {}
Render.__index = Render
setmetatable(Render, { __index = BaseTask })

--[[
    Creates a new render
]]
function Render.new(name: string, renders: { any })
	local existing = BaseTask.findByName(name, renders)
	if existing then
		return existing
	end

	local self = BaseTask.new(name, renders)
	return setmetatable(self, Render)
end

--[[
    Adds a task to this render
]]
function Render:addTask(taskRef: any, callback: (number) -> nil)
	BaseTask.addTask(self, taskRef, callback)
	return self
end

--[[
    Removes a task from this render
]]
function Render:removeTask(taskRef: any)
	BaseTask.removeTask(self, taskRef)
	return self
end

return Render
