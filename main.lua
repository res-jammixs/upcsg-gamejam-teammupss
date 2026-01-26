local MainMenu = require('src.states.MainMenu')
local Game = require('src.game')

local currentState

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- Start with the main menu
    currentState = MainMenu
    currentState:enter()
end

function love.update(dt)
    if currentState.update then
        currentState:update(dt)
    end
end

function love.draw()
    currentState:draw()
end

function love.keypressed(key)
    if currentState.keypressed then
        currentState:keypressed(key)
    end
end

-- Function to switch states
function switchState(newState)
    currentState = newState
    if currentState.enter then
        currentState:enter()
    end
end