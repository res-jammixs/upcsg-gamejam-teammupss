local MainMenu = require('src.states.MainMenu')
local Game = require('src.game')
local Transition = require('src.managers.TransitionManager')

local currentState
local transition

-- Define the game's intended resolution (virtual resolution)
GAME_WIDTH = 1024
GAME_HEIGHT = 768

function love.load()
    -- Set nearest neighbor filtering FIRST before any images are loaded
    love.graphics.setDefaultFilter("nearest", "nearest")
    
    -- Ensure the window is exactly the intended size
    -- This helps prevent spawn point misalignment across different devices
    local windowWidth, windowHeight = love.window.getMode()
    if windowWidth ~= GAME_WIDTH or windowHeight ~= GAME_HEIGHT then
        love.window.setMode(GAME_WIDTH, GAME_HEIGHT, {
            resizable = false,
            highdpi = true,
            usedpiscale = true
        })
    end

    -- Initialize transition system
    transition = Transition:new()

    -- Start with the main menu
    currentState = MainMenu
    currentState:enter()
end

function love.update(dt)
    transition:update(dt)
    
    if currentState.update then
        currentState:update(dt)
    end
end

function love.draw()
    currentState:draw()
    transition:draw()
end

function love.keypressed(key)
    if currentState.keypressed then
        currentState:keypressed(key)
    end
end

-- ADD THESE TWO FUNCTIONS:
function love.mousepressed(x, y, button)
    if currentState.mousepressed then
        currentState:mousepressed(x, y, button)
    end
end

function love.mousereleased(x, y, button)
    if currentState.mousereleased then
        currentState:mousereleased(x, y, button)
    end
end

-- Function to switch states
function switchState(newState)
    currentState = newState
    if currentState.enter then
        currentState:enter()
    end
end

-- Function to return to a state without calling enter (for dialogue)
function returnToState(state)
    currentState = state
end

-- Function to get the transition object
function getTransition()
    return transition
end
