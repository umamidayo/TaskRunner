# TaskRunner System

An object-oriented RunService system for projects that require functions to run on an interval-based schedule: a great way to manage recurring game logic, automate functions in intervals, and manage all RunService connections in a centralized location.

## Benefits of Centralized Task Scheduling
1. **Simplified RunService Management**
   - No need to manage multiple RunService connections manually
   - Automatic cleanup of connections when tasks are removed
   - Proper handling of both Heartbeat and RenderStepped events

2. **Improved Maintainability**
   - Single place to manage all recurring tasks
   - Clear separation between client and server tasks
   - Easy to enable/disable systems during development
   - Group similar timing needs into shared schedules

3. **Developer Quality of Life**
   - Simple API for adding and removing tasks
   - No boilerplate code for timing or intervals
   - Consistent pattern for all recurring operations
   - Control update frequency to match needs

This system aims to make your development process smoother by handling the complexities of RunService connections and timing logic, letting you focus on building your game mechanics.

## Structure
- `init.lua` - The main module; handles RunService connections and scheduled tasks
- `Config.lua` - Dictionary-based configuration for defining your own schedules
- `BaseTask.lua` - Base class for schedules and renders (inherited methods)
- `Schedule.lua` - Time-based task executor
- `Render.lua` - Frame-based task executor (client-side)
- `README.md` - This documentation file

## Setup and Initialization
### 1. Module Setup
It's recommended to place the TaskRunner files under `ReplicatedStorage` with the `init.luau` file as the primary parent, since TaskRunner can run on both the server and client.

### 2. System Initialization
The TaskRunner is initialized by `TaskRunner.init()`, then it will start executing your tasks in timed intervals. To do this, write the initialization in your initialization script:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TaskRunner = require(ReplicatedStorage.Shared.TaskRunner)

TaskRunner.init()
```

The `.init()` function will:
1. Start the RunService connection
2. Start executing tasks added to your schedules and renders

⚠️ **Important Notes:**
- Call TaskRunner's `.init()` function once per context (server / client)
- If you've setup your configuration file to have existing Schedules and Renders, you do not need to use if-statements for `hasScheduler` to check if they're defined; the provided examples with if-statements are only showing you how they work.
- It's highly recommended to update your user interface through a state machine or through event signals, rather than the TaskRunner. The examples provided are for typically for specific situations where the user interface requires a RunService connection.

#### Alternative Initialization
You can also convert the TaskRunner file (`init.luau`) into a Script / LocalScript, parent all of the modules under it, and modify the `TaskRunner.init()` function to run on server start; this is an acceptable alternative for projects that don't have an initializing script.

## Configuration
Customize the system by editing `Config.lua`. This configuration file allows you to define schedules and renders that will be automatically initialized when the TaskRunner starts:
- **Schedules**: Define named intervals with their tick rates (in seconds)
- **Renders**: Define render groups for frame-by-frame updates

Config Example:
```lua
Config.Schedules = {
    gameLoop = {
        tick = 1, -- Run your entire game loop
    },
    npcSimulation = {
        tick = 0.1, -- Simulate your NPC's behaviors and actions
    },
    Weather = {
        tick = 60, -- Perform weather events every minute
    }
}

Config.Renders = {
    Interface = {}, -- Render specific user interfaces
    Particles = {}, -- Auto-emit particle systems
    MeshAnimation = {} -- Update editable mesh deformations
}
```

## Examples

### Schedule Example
This example demonstrates how to use TaskRunner's scheduling system to manage recurring game logic. It shows:
- How to add tasks to predefined schedules
- Managing multiple updates in a single task
- Creating custom schedules with specific intervals
- Removing tasks when they're no longer needed
- Method chaining for creating sequences of tasks
```lua
local TaskRunner = require(ReplicatedStorage.Shared.TaskRunner)

-- Using a predefined schedule
TaskRunner.Schedules.Interval_1s:addTask("UpdatePlayerStats", function()
    for _, player in ipairs(game.Players:GetPlayers()) do
        local stats = player:FindFirstChild("Stats")
        if not stats then continue end
        
        -- Regenerate health if below max
        local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
        if humanoid and humanoid.Health < humanoid.MaxHealth then
            humanoid.Health = math.min(humanoid.Health + 1, humanoid.MaxHealth)
        end
        
        -- Restore energy over time
        local energy = stats:FindFirstChild("Energy") 
        if energy and energy.Value < 100 then
            energy.Value = math.min(energy.Value + 2, 100)
        end
        
        -- Reduce hunger level
        local hunger = stats:FindFirstChild("Hunger")
        if hunger then
            hunger.Value = math.max(hunger.Value - 0.1, 0)
            
            -- Apply damage if starving
            if hunger.Value <= 0 and humanoid then
                humanoid.Health = math.max(0, humanoid.Health - 1)
            end
        end
    end
end)

-- Creating a custom schedule (runs every 0.1 seconds)
local combatSystem = TaskRunner.newSchedule("CombatSystem", 0.1)

-- Add multiple tasks with method chaining
combatSystem
    :addTask("ProcessAttacks", function()
        -- Process player attacks
        for _, player in ipairs(game.Players:GetPlayers()) do
            local character = player.Character
            if not character then continue end
            
            local weapon = character:FindFirstChild("Weapon")
            if not weapon then continue end
            
            -- Process weapon attacks
            if weapon:GetAttribute("IsAttacking") then
                -- Your attack logic here
            end
        end
    end)
    :addTask("UpdateCooldowns", function()
        -- Update ability cooldowns
        for _, player in ipairs(game.Players:GetPlayers()) do
            local abilities = player:FindFirstChild("Abilities")
            if not abilities then continue end
            
            for _, ability in ipairs(abilities:GetChildren()) do
                local cooldown = ability:GetAttribute("Cooldown")
                if cooldown and cooldown > 0 then
                    ability:SetAttribute("Cooldown", cooldown - 0.1)
                end
            end
        end
    end)

-- Remove tasks when they're not needed
TaskRunner.Schedules.Interval_1s:removeTask("UpdatePlayerStats")

-- Or remove tasks from custom schedules
combatSystem:removeTask("ProcessAttacks")

-- Check if schedules exist before using them
if TaskRunner.hasSchedule("CombatSystem") then
    print("Combat system is running")
end

-- Get a schedule to modify it
local schedule = TaskRunner.getSchedule("CombatSystem")
if schedule then
    schedule:addTask("NewTask", function()
        -- Add new functionality
    end)
end
```

### Render Example (Client-side only)
This example shows how TaskRunner handles frame-based updates on the client. It demonstrates:
- Creating and managing render tasks for user interface updates
- Creating custom renderers for specific needs
- Task cleanup when transitioning between scenes
```lua
local TaskRunner = require(ReplicatedStorage.Shared.TaskRunner)

-- Update UI elements every frame
TaskRunner.Renders.Interface:addTask("UpdateHealthBar", function(dt)
    local player = Players.LocalPlayer
    local healthGui: ScreenGui = player.PlayerGui.HealthGui
    local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
    if humanoid then
        -- Update health bar UI
        local healthBar = healthGui:FindFirstChild("HealthBar")
        if healthBar then
            healthBar.Fill.Size = UDim2.new(humanoid.Health / humanoid.MaxHealth, 0, 1, 0)
        end
    end
end)

-- Create custom render for special effects
local effectsRenderer = TaskRunner.newRenderer("SpecialEffects")
effectsRenderer:addTask("ParticleSystem", function(dt)
    -- Update particle effects
    for _, effect in ipairs(workspace.Effects:GetChildren()) do
        -- Process particle animations
    end
end)

-- Remove render tasks when transitioning scenes
TaskRunner.Renders.Interface:removeTask("UpdateHealthBar")
```

### Utility Functions

```lua
local TaskRunner = require(ReplicatedStorage.Shared.TaskRunner)

-- Check if game systems are initialized
if TaskRunner.hasScheduler("Interval_1s") then
    print("1 second interval schedule is running")
end

-- Get specific schedules for system modifications
local playerSystem = TaskRunner.getSchedule("Interval_1s")
if playerSystem then
    playerSystem:addTask("UpdateHealth", function(dt)
        -- Update player health every second
        local player = game.Players.LocalPlayer
        local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.Health = math.min(humanoid.Health + 1, humanoid.MaxHealth)
        end
    end)
end

-- Monitor active systems
local allSchedules = TaskRunner.getAllSchedulers()
for name, schedule in pairs(allSchedules) do
    print("Active schedules:", name)
end

-- Monitor active renderers
local allRenders = TaskRunner.getAllRenderers()
for name, render in pairs(allRenders) do
    print("Active renders:", name)
end
``` 