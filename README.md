# TaskRunner System

A modular and maintainable task runner system for Roblox games that supports both time-based schedules and frame-based renders. Perfect for managing recurring game logic, UI updates, and other time-sensitive operations in your Roblox experiences.

## Architecture

- **BaseTask**: Core functionality for task management
- **Schedule**: Handles time-based game systems
- **Render**: Manages frame-based updates (UI, effects)
- **Config**: Centralizes system configuration
- **TaskRunner**: Main module that coordinates all systems
- **Access Tables**: Easy access to all game systems via `Schedules` and `Renders`

## Benefits

1. **Simplified RunService Management**
   - No need to manage multiple RunService connections manually
   - Automatic cleanup of connections when tasks are removed
   - Proper handling of both Heartbeat and RenderStepped events

2. **Better Code Organization**
   - Group related functionality into named schedules
   - Keep timing-based code separate from business logic
   - Easy to find and modify update frequencies

3. **Improved Maintainability**
   - Single place to manage all recurring tasks
   - Clear separation between client and server tasks
   - Easy to enable/disable systems during development

4. **Developer Quality of Life**
   - Simple API for adding and removing tasks
   - No boilerplate code for timing or intervals
   - Consistent pattern for all recurring operations

5. **Safer Runtime Behavior**
   - Tasks run in protected calls to prevent cascading errors
   - Automatic cleanup when scripts are destroyed
   - Proper handling of script lifetime and connections

6. **Performance Considerations**
   - Control update frequency to match needs
   - Avoid unnecessary per-frame updates
   - Group similar timing needs into shared schedules

This system aims to make your development process smoother by handling the complexities of RunService connections and timing logic, letting you focus on building your game mechanics.

## Structure

- `init.lua` - Main task runner module with public API
- `Config.lua` - Dictionary-based configuration for default schedules and renders
- `BaseTask.lua` - Shared functionality between schedules and renders
- `Schedule.lua` - Schedule class for time-based task execution
- `Render.lua` - Render class for frame-based task execution
- `README.md` - This documentation file

## Setup and Initialization

### 1. Module Setup
First, place the TaskRunner module in a suitable location in your game. Common locations include:
- `ReplicatedStorage.Shared` for code shared between client and server
- `ServerScriptService.Modules` for server-only functionality
- `StarterPlayerScripts.Modules` for client-only functionality

### 2. System Initialization
The TaskRunner MUST be initialized on both the client and server to start running. Add this to your initialization scripts:

```lua
-- In a Server Script (e.g. game.ServerScriptService.GameInit)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TaskRunner = require(ReplicatedStorage.Shared.TaskRunner)

-- Initialize the system on the server
TaskRunner.init()
```

```lua
-- In a Local Script (e.g. game.StarterPlayerScripts.ClientInit)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TaskRunner = require(ReplicatedStorage.Shared.TaskRunner)

-- Initialize the system on the client
TaskRunner.init()
```

The `.init()` function will:
- Create all configured schedules from `Config.lua`
- Create renders on the client (renders only work client-side)
- Start the update loops for both schedules and renders
- Set up proper task execution timing

⚠️ **Important Notes:**
- Always call `.init()` before adding any tasks
- Call `.init()` only once per context (server/client)
- Server initialization handles game logic schedules
- Client initialization handles both schedules and renders

## Configuration

Customize the system by editing `Config.lua`. This configuration file allows you to define schedules and renders that will be automatically initialized when the TaskRunner starts:

- **Schedules**: Define named intervals with their tick rates (in seconds)
- **Renders**: Define render groups for frame-by-frame updates
- **Extensible**: Add new schedules and renders as your game grows
- **Centralized**: Keep all timing configurations in one place

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

```lua
local TaskRunner = require(ReplicatedStorage.Shared.TaskRunner)

TaskRunner.Schedules.Interval_1s:addTask("UpdatePlayerStats", function(dt)
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
```

### Render Example (Client-side only)

Renders are perfect for smooth UI updates and visual effects that need to run every frame:

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