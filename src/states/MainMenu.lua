local MainMenu = {}

local function newButton(text, fn)
    return {
        text = text,
        fn = fn
    }
end

local buttons = {}
local selected = 1

local fontTitle
local fontMenu
local background

function MainMenu:enter()
    background = love.graphics.newImage("assets/graphics/ui/background.png")
    fontTitle = love.graphics.newFont("assets/fonts/VT323-Regular.ttf", 90)
    fontMenu = love.graphics.newFont("assets/fonts/VT323-Regular.ttf", 52)
    
    buttons = {}
    selected = 1
    
    table.insert(buttons, newButton("START", function()
        local Game = require('src.game')
        switchState(Game)
    end))
    
    table.insert(buttons, newButton("CONTINUE", function()
        print("Continue Game")
        -- TODO: Load saved game
    end))
    
    table.insert(buttons, newButton("EXIT", function()
        love.event.quit()
    end))
end

function MainMenu:keypressed(key)
    if key == "down" then
        selected = selected + 1
        if selected > #buttons then selected = 1 end

    elseif key == "up" then
        selected = selected - 1
        if selected < 1 then selected = #buttons end

    elseif key == "return" or key == "space" then
        buttons[selected].fn()
    end
end

function MainMenu:draw()
    local ww = love.graphics.getWidth()
    local wh = love.graphics.getHeight()

    local bgW = background:getWidth()
    local bgH = background:getHeight()

    local scaleX = ww / bgW
    local scaleY = wh / bgH

    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(background, 0, 0, 0, scaleX, scaleY)

    love.graphics.setFont(fontTitle)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("FEATHERLESS", 80, 90)

    love.graphics.setFont(fontMenu)
    local startY = 250
    local spacing = 60
    local textX = 120
    local cursorX = 90

    for i, button in ipairs(buttons) do
        local y = startY + (i - 1) * spacing

        if i == selected then
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(">", cursorX, y)
        else
            love.graphics.setColor(0.75, 0.75, 0.75)
        end

        love.graphics.print(button.text, textX, y)
    end

    love.graphics.setColor(1, 1, 1)
end

return MainMenu
