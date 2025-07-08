# TaskRunner System

A modular and maintainable task runner system for Roblox games that supports both time-based schedules and frame-based renders. Perfect for managing recurring game logic, UI updates, and other time-sensitive operations in your Roblox experiences.

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

## Usage

### Basic Setup

First, place the TaskRunner module in a suitable location in your game. Common locations include:
- `ReplicatedStorage.Shared` for code shared between client and server
- `ServerScriptService.Modules` for server-only functionality
- `StarterPlayerScripts.Modules` for client-only functionality

### Direct Access

The system provides direct access to all schedules and renders with full IntelliSense support:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TaskRunner = require(ReplicatedStorage.Shared.TaskRunner)

-- Example: Create a schedule for updating player stats
TaskRunner.Schedules.PlayerStats:addTask("UpdateEnergy", function(dt)
    for _, player in ipairs(game.Players:GetPlayers()) do
        -- Update player energy every 10 seconds
        local stats = player:FindFirstChild("Stats")
        if stats then
            stats.Energy.Value = math.min(stats.Energy.Value + 1, 100)
        end
    end
end)

-- Create custom schedules for game mechanics
local combatSystem = TaskRunner.newScheduler("CombatSystem", 0.1) -- Updates every 0.1 seconds
combatSystem:addTask("ProcessCombat", function(dt)
    -- Process combat calculations
    print("Processing combat", dt)
end)

-- Chain multiple tasks for related game systems
TaskRunner.Schedules.GameLoop
    :addTask("UpdateNPCs", function(dt) 
        -- Update NPC behavior
    end)
    :addTask("UpdateEnvironment", function(dt) 
        -- Update environmental effects
    end)

-- Remove tasks when no longer needed
TaskRunner.Schedules.PlayerStats:removeTask("UpdateEnergy")
```

### Using Renders (Client-side only)

Renders are perfect for smooth UI updates and visual effects that need to run every frame:

```lua
local TaskRunner = require(game:GetService("ReplicatedStorage").Shared.TaskRunner)

-- Update UI elements every frame
TaskRunner.Renders.Interface:addTask("UpdateHealthBar", function(dt)
    local player = game.Players.LocalPlayer
    local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
    if humanoid then
        -- Update health bar UI
        local healthBar = player.PlayerGui:FindFirstChild("HealthBar")
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
local TaskRunner = require(game:GetService("ReplicatedStorage").Shared.TaskRunner)

-- Check if game systems are initialized
if TaskRunner.hasScheduler("CombatSystem") then
    print("Combat system is running")
end

-- Get specific schedulers for system modifications
local playerStats = TaskRunner.getScheduler("PlayerStats")
if playerStats then
    playerStats:addTask("UpdateStamina", function(dt) end)
end

-- Monitor active systems
local allSchedules = TaskRunner.getAllSchedulers()
for name, schedule in pairs(allSchedules) do
    print("Active game system:", name)
end

-- Monitor active renderers
local allRenders = TaskRunner.getAllRenderers()
for name, render in pairs(allRenders) do
    print("Active renderer:", name)
end
```

### Default Schedules

The system comes with these pre-configured schedules:

- `TaskRunner.Schedules.GameLoop` - Runs every 10 seconds (for major game state updates)
- `TaskRunner.Schedules.Vitals` - Runs every 1 second (for player stats, health, etc.)

On the client, it also includes:
- `TaskRunner.Renders.Interface` - Runs every frame (for smooth UI updates)

### Configuration

Customize the system by editing `Config.lua`:

```lua
Config.Schedules = {
    PlayerStats = {
        tick = 1, -- Update player stats every second
    },
    NPCBehavior = {
        tick = 0.5, -- Update NPCs twice per second
    },
    Weather = {
        tick = 5, -- Update weather every 5 seconds
    }
}

Config.Renders = {
    Interface = {}, -- UI updates
    Particles = {}, -- Particle system updates
    Animations = {} -- Custom animation handling
}
```

**Benefits of Dictionary Configuration:**
- **IntelliSense Support**: Get autocomplete for your game systems
- **Type Safety**: Catch errors before they happen
- **Maintainable Code**: Clear organization of game systems
- **Easy Updates**: Quickly adjust update frequencies

Access your configured systems:
```lua
-- These will have full IntelliSense support
TaskRunner.Schedules.PlayerStats:addTask("UpdateStats", function(dt) end)
TaskRunner.Schedules.NPCBehavior:addTask("ProcessAI", function(dt) end)
TaskRunner.Renders.Interface:addTask("UpdateUI", function(dt) end)
```

### Advanced Usage

```lua
local TaskRunner = require(game:GetService("ReplicatedStorage").Shared.TaskRunner)

-- Create a complex game system
local battleSystem = TaskRunner.newScheduler("BattleSystem", 1/30) -- 30 updates per second
battleSystem
    :addTask("CombatCalculations", function(dt) 
        -- Process damage, healing, etc.
    end)
    :addTask("StatusEffects", function(dt)
        -- Update player buffs/debuffs
    end)
    :addTask("BattleState", function(dt)
        -- Check victory/defeat conditions
    end)

-- Access systems from different scripts
TaskRunner.Schedules.BattleSystem:addTask("Rewards", function(dt)
    -- Process battle rewards
end)

-- Wait for systems to initialize
local combatSystem = TaskRunner.waitForScheduler("BattleSystem", 5) -- 5 second timeout
if combatSystem then
    combatSystem:addTask("LateSetup", function(dt) end)
end

-- Clean up when battle ends
battleSystem:destroy() -- Removes all battle-related tasks
```

## Architecture

- **BaseTask**: Core functionality for task management
- **Schedule**: Handles time-based game systems
- **Render**: Manages frame-based updates (UI, effects)
- **Config**: Centralizes system configuration
- **TaskRunner**: Main module that coordinates all systems
- **Access Tables**: Easy access to all game systems via `Schedules` and `Renders`

## Benefits

1. **Roblox-Optimized**: Designed specifically for Roblox game development
2. **Performance**: Efficient task scheduling and execution
3. **Flexibility**: Works for both server and client-side systems
4. **Maintainability**: Well-organized game systems
5. **Error Handling**: Robust error catching and reporting
6. **Debug-Friendly**: Easy to monitor and troubleshoot
7. **Scalable**: Grows with your game's complexity
8. **Modern Design**: Uses latest Roblox and Luau features
9. **Best Practices**: Follows Roblox development standards
10. **Documentation**: Comprehensive examples and explanations

This system helps organize and manage complex game mechanics while maintaining performance and code quality in your Roblox experiences. 