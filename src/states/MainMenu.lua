local MainMenu = {}
local Game = require('src.game')  

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
local bgVideo
local buttonPressed = false

function MainMenu:enter()
    bgVideo = love.graphics.newVideo("assets/graphics/ui/menu.ogv")
    bgVideo:play()
    fontTitle = love.graphics.newFont("assets/fonts/VT323-Regular.ttf", 90)
    fontMenu = love.graphics.newFont("assets/fonts/VT323-Regular.ttf", 52)
    
    buttons = {}
    selected = 1
    buttonPressed = false
    
    table.insert(buttons, newButton("START", function()
        switchState(Game)  
    end))
    
    table.insert(buttons, newButton("CONTINUE", function()
        print("Continue Game")
    end))
    
    table.insert(buttons, newButton("EXIT", function()
        love.event.quit()
    end))
end

function MainMenu:exit()
    if bgVideo then
        bgVideo:release()
    end
end

function MainMenu:update(dt)
    if bgVideo and not bgVideo:isPlaying() then
        bgVideo:rewind()
        bgVideo:play()
    end
    
    local mx, my = love.mouse.getPosition()
    local ww = love.graphics.getWidth()
    local wh = love.graphics.getHeight()
    local spacing = 60
    local startY = wh * 0.50
    
    for i, buttonObj in ipairs(buttons) do
        local buttonY = startY + (i - 1) * spacing
        local buttonWidth = fontMenu:getWidth(buttonObj.text)
        local buttonHeight = fontMenu:getHeight()
        local textX = (ww - buttonWidth) / 2
        
        if mx >= textX and mx <= textX + buttonWidth and
           my >= buttonY and my <= buttonY + buttonHeight then
            selected = i
            break
        end
    end
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

function MainMenu:mousepressed(x, y, button)
    if button == 1 then  
        local ww = love.graphics.getWidth()
        local wh = love.graphics.getHeight()
        local spacing = 60
        local startY = wh * 0.50
        
        for i, buttonObj in ipairs(buttons) do
            local buttonY = startY + (i - 1) * spacing
            local buttonWidth = fontMenu:getWidth(buttonObj.text)
            local buttonHeight = fontMenu:getHeight()
            local textX = (ww - buttonWidth) / 2
            
            if y >= buttonY and y <= buttonY + buttonHeight then
                if x >= textX and x <= textX + buttonWidth then
                    buttonPressed = true
                    break
                end
            end
        end
    end
end

function MainMenu:mousereleased(x, y, button)
    if button == 1 and buttonPressed then
        local ww = love.graphics.getWidth()
        local wh = love.graphics.getHeight()
        local spacing = 60
        local startY = wh * 0.50
        
        for i, buttonObj in ipairs(buttons) do
            local buttonY = startY + (i - 1) * spacing
            local buttonWidth = fontMenu:getWidth(buttonObj.text)
            local buttonHeight = fontMenu:getHeight()
            local textX = (ww - buttonWidth) / 2
            
            if y >= buttonY and y <= buttonY + buttonHeight then
                if x >= textX and x <= textX + buttonWidth then
                    buttonObj.fn()
                    break
                end
            end
        end
        
        buttonPressed = false
    end
end

function MainMenu:draw()
    local ww = love.graphics.getWidth()
    local wh = love.graphics.getHeight()
    
    local videoWidth = bgVideo:getWidth()
    local videoHeight = bgVideo:getHeight()
    local scaleX = ww / videoWidth
    local scaleY = wh / videoHeight
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(bgVideo, 0, 0, 0, scaleX, scaleY)
    
    love.graphics.setFont(fontMenu)
    
    local spacing = 60
    local totalHeight = (#buttons - 1) * spacing
    local startY = wh * 0.40
    
    for i, button in ipairs(buttons) do
        local y = startY + (i - 1) * spacing
        local buttonWidth = fontMenu:getWidth(button.text)
        local textX = (ww - buttonWidth) / 2
        
        if i == selected then
            if buttonPressed and love.mouse.isDown(1) then
                love.graphics.setColor(225/255, 223/255, 174/255, 0.7)  
            else
                love.graphics.setColor(225/255, 223/255, 174/255)  
            end
        else
            love.graphics.setColor(225/255, 223/255, 174/255, 0.5)  
        end
        
        love.graphics.print(button.text, textX, y)
    end
    
    love.graphics.setColor(1, 1, 1)
end

return MainMenu