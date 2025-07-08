local BaseTask = require(script.Parent.BaseTask)

-- Schedule class extending BaseTask
local Schedule = {}
Schedule.__index = Schedule
setmetatable(Schedule, { __index = BaseTask })

--[[
    Creates a new schedule with tick interval
]]
function Schedule.new(name: string, tick: number, schedules: { any })
	local existing = BaseTask.findByName(name, schedules)
	if existing then
		return existing
	end

	local self = BaseTask.new(name, schedules)
	self.Tick = tick
	self.Elapsed = 0

	return setmetatable(self, Schedule)
end

--[[
    Updates the schedule's elapsed time and executes tasks if needed
]]
function Schedule:update(dt: number)
	self.Elapsed += dt
	if self.Elapsed < self.Tick then
		return
	end

	self.Elapsed = 0
	self:executeTasks(dt)
end

--[[
    Adds a task to this schedule
]]
function Schedule:addTask(taskRef: any, callback: (number) -> nil)
	BaseTask.addTask(self, taskRef, callback)
	return self
end

--[[
    Removes a task from this schedule
]]
function Schedule:removeTask(taskRef: any)
	BaseTask.removeTask(self, taskRef)
	return self
end

return Schedule
