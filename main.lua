local MainMenu = require('src.states.MainMenu')
local Game = require('src.game')
local Transition = require('src.util.Transition')

local currentState
local transition

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")

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

-- Function to get the transition object
function getTransition()
    return transition
end
