local MainMenuManager = {}

function MainMenuManager:new()
    local self = {
        buttons = {},
        selected = 1,
        isTransitioning = false,
        bgVideo = nil,
        menuMusic = nil
    }
    
    return setmetatable(self, { __index = MainMenuManager })
end

function MainMenuManager:createButton(text, fn)
    return {
        text = text,
        fn = fn
    }
end

function MainMenuManager:addButton(text, fn)
    table.insert(self.buttons, self:createButton(text, fn))
end

function MainMenuManager:loadAssets()
    -- Load background video
    self.bgVideo = love.graphics.newVideo("assets/graphics/background/menu.ogv")
    self.bgVideo:play()
    
    -- Load and play menu music
    self.menuMusic = love.audio.newSource("assets/sounds/music/main-menu.mp3", "stream")
    self.menuMusic:setLooping(true)
    self.menuMusic:setVolume(0.3)
    self.menuMusic:play()
end

function MainMenuManager:cleanup()
    if self.bgVideo then
        self.bgVideo:release()
        self.bgVideo = nil
    end
    if self.menuMusic then
        self.menuMusic:stop()
        self.menuMusic:release()
        self.menuMusic = nil
    end
end

function MainMenuManager:updateVideo(dt)
    if self.bgVideo and not self.bgVideo:isPlaying() then
        self.bgVideo:rewind()
        self.bgVideo:play()
    end
end

function MainMenuManager:updateMouseHover(mx, my, fontMenu, screenWidth, screenHeight)
    if self.isTransitioning then return end
    
    local spacing = 60
    local startY = screenHeight * 0.40
    
    for i, buttonObj in ipairs(self.buttons) do
        local buttonY = startY + (i - 1) * spacing
        local buttonWidth = fontMenu:getWidth(buttonObj.text)
        local buttonHeight = fontMenu:getHeight()
        local textX = (screenWidth - buttonWidth) / 2
        
        if mx >= textX and mx <= textX + buttonWidth and
           my >= buttonY and my <= buttonY + buttonHeight then
            self.selected = i
            break
        end
    end
end

function MainMenuManager:moveSelection(direction)
    if self.isTransitioning then return end
    
    self.selected = self.selected + direction
    if self.selected > #self.buttons then
        self.selected = 1
    elseif self.selected < 1 then
        self.selected = #self.buttons
    end
end

function MainMenuManager:activateSelected()
    if self.isTransitioning then return end
    
    local button = self.buttons[self.selected]
    if button and button.fn then
        button.fn()
    end
end

function MainMenuManager:startTransition()
    self.isTransitioning = true
end

function MainMenuManager:stopMusic()
    if self.menuMusic then
        self.menuMusic:stop()
    end
end

function MainMenuManager:getButtons()
    return self.buttons
end

function MainMenuManager:getSelected()
    return self.selected
end

function MainMenuManager:getBackgroundVideo()
    return self.bgVideo
end

function MainMenuManager:isInTransition()
    return self.isTransitioning
end

return MainMenuManager
