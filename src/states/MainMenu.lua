local MainMenuManager = require('src.managers.MainMenuManager')
local MainMenu = {}
local Game = require('src.game')

local manager
local fontTitle
local fontMenu
local buttonPressed = false

function MainMenu:enter()
    -- Initialize manager
    manager = MainMenuManager:new()
    
    -- Reset global inventory when entering main menu
    if _G.inventory then
        _G.inventory = nil
    end
    
    -- Load fonts
    fontTitle = love.graphics.newFont("assets/fonts/VT323-Regular.ttf", 90)
    fontMenu = love.graphics.newFont("assets/fonts/VT323-Regular.ttf", 52)
    
    -- Load assets via manager
    manager:loadAssets()
    
    -- Reset button press state
    buttonPressed = false
    
    -- Add buttons via manager
    manager:addButton("START", function()
        -- Prevent multiple clicks during transition
        if manager:isInTransition() then return end
        manager:startTransition()
        
        -- Stop menu music
        manager:stopMusic()
        
        local transition = getTransition()
        transition:fadeIn(0.5, function()
            switchState(Game)
        end)
    end)
    
    manager:addButton("EXIT", function()
        love.event.quit()
    end)
end

function MainMenu:exit()
    manager:cleanup()
end

function MainMenu:update(dt)
    -- Update video loop
    manager:updateVideo(dt)
    
    -- Update mouse hover
    local mx, my = love.mouse.getPosition()
    local ww = love.graphics.getWidth()
    local wh = love.graphics.getHeight()
    manager:updateMouseHover(mx, my, fontMenu, ww, wh)
end

function MainMenu:keypressed(key)
    if manager:isInTransition() then return end
    
    if key == "down" or key == "s" then
        manager:moveSelection(1)
    elseif key == "up" or key == "w" then
        manager:moveSelection(-1)
    elseif key == "return" or key == "space" then
        manager:activateSelected()
    end
end

-- Mouse click detection
function MainMenu:mousepressed(x, y, button)
    if manager:isInTransition() then return end
    
    if button == 1 then
        local ww = love.graphics.getWidth()
        local wh = love.graphics.getHeight()
        local spacing = 60
        local startY = wh * 0.40
        local buttons = manager:getButtons()
        
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
    if manager:isInTransition() then return end
    
    if button == 1 and buttonPressed then
        local ww = love.graphics.getWidth()
        local wh = love.graphics.getHeight()
        local spacing = 60
        local startY = wh * 0.40
        local buttons = manager:getButtons()
        
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
    
    local bgVideo = manager:getBackgroundVideo()
    local videoWidth = bgVideo:getWidth()
    local videoHeight = bgVideo:getHeight()
    local scaleX = ww / videoWidth
    local scaleY = wh / videoHeight
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(bgVideo, 0, 0, 0, scaleX, scaleY)
    
    love.graphics.setFont(fontMenu)
    
    local spacing = 60
    local startY = wh * 0.40
    local buttons = manager:getButtons()
    local selected = manager:getSelected()
    
    for i, button in ipairs(buttons) do
        local y = startY + (i - 1) * spacing
        local buttonWidth = fontMenu:getWidth(button.text)
        local textX = (ww - buttonWidth) / 2
        
        if i == selected then
            -- Mouse press visual feedback
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