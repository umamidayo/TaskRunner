local RunService = game:GetService("RunService")

local Config = require(script.Config)
local BaseTask = require(script.BaseTask)
local Schedule = require(script.Schedule)
local Render = require(script.Render)

local TaskRunner = {
	priority = 1,
	Schedules = {},
	Renders = {},
}
TaskRunner.__index = TaskRunner

local schedules = {}
local renders = {}

--[[
    Creates a new schedule
]]
function TaskRunner.newSchedule(name: string, tick: number)
	local schedule = Schedule.new(name, tick, schedules)
	TaskRunner.Schedules[name] = schedule
	return schedule
end

--[[
    Gets a schedule by name
]]
function TaskRunner.getSchedule(name: string)
	return TaskRunner.Schedules[name] or BaseTask.findByName(name, schedules)
end

--[[
    Waits for a schedule to exist
]]
function TaskRunner.waitForSchedule(name: string, timeout: number)
	return BaseTask.waitForTask(name, schedules, timeout)
end

--[[
    Creates a new render
]]
function TaskRunner.newRender(name: string)
	local render = Render.new(name, renders)
	TaskRunner.Renders[name] = render
	return render
end

--[[
    Gets a render by name
]]
function TaskRunner.getRender(name: string)
	return TaskRunner.Renders[name] or BaseTask.findByName(name, renders)
end

--[[
    Waits for a render to exist
]]
function TaskRunner.waitForRender(name: string, timeout: number)
	return BaseTask.waitForTask(name, renders, timeout)
end

--[[
    Cleans up the schedule or render from the respective tables
]]
function TaskRunner:destroy()
	-- Try to destroy as schedule first
	local index = table.find(schedules, self)
	if index then
		table.remove(schedules, index)
		-- Remove from accessible table
		for name, schedule in pairs(TaskRunner.Schedules) do
			if schedule == self then
				TaskRunner.Schedules[name] = nil
				break
			end
		end
		setmetatable(self, nil)
		return
	end

	-- Try to destroy as render
	index = table.find(renders, self)
	if index then
		table.remove(renders, index)
		-- Remove from accessible table
		for name, render in pairs(TaskRunner.Renders) do
			if render == self then
				TaskRunner.Renders[name] = nil
				break
			end
		end
		setmetatable(self, nil)
		return
	end
end

--[[
    Gets all active schedules
]]
function TaskRunner.getAllSchedules()
	return TaskRunner.Schedules
end

--[[
    Gets all active renders
]]
function TaskRunner.getAllRenders()
	return TaskRunner.Renders
end

--[[
    Checks if a schedule exists
]]
function TaskRunner.hasSchedule(name: string)
	return TaskRunner.Schedules[name] ~= nil
end

--[[
    Checks if a render exists
]]
function TaskRunner.hasRender(name: string)
	return TaskRunner.Renders[name] ~= nil
end

--[[
    Initializes the task runner system
]]
function TaskRunner.init()
	-- Create default schedules
	for name, scheduleConfig in Config.Schedules do
		TaskRunner.newSchedule(name, scheduleConfig.tick)
	end

	-- Create default renders (only on client)
	if RunService:IsClient() then
		for name, _ in Config.Renders do
			TaskRunner.newRender(name)
		end
	end

	-- Set up heartbeat loop for schedules
	RunService.Heartbeat:Connect(function(dt)
		for _, schedule in schedules do
			task.spawn(function()
				schedule:update(dt)
			end)
		end
	end)

	-- Set up render loop for renders (client only)
	if RunService:IsClient() then
		RunService.RenderStepped:Connect(function(dt)
			for _, render in renders do
				task.spawn(function()
					render:executeTasks(dt)
				end)
			end
		end)
	end
end

return TaskRunner
