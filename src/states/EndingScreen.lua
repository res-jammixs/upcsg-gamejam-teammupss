local EndingScreen = {}

function EndingScreen:new()
    local self = {
        endingTitle = "",
        endingNumber = 0,
        font = nil,
        titleFont = nil,
        buttonFont = nil,
        buttons = {},
        selectedButton = 1,
        fadeAlpha = 0,
        fadeSpeed = 1,
        isReady = false
    }
    
    return setmetatable(self, { __index = EndingScreen })
end

function EndingScreen:enter(endingNumber, endingTitle)
    self.endingNumber = endingNumber
    self.endingTitle = endingTitle
    
    -- Load fonts
    self.titleFont = love.graphics.newFont("assets/fonts/VT323-Regular.ttf", 48)
    self.font = love.graphics.newFont("assets/fonts/VT323-Regular.ttf", 32)
    self.buttonFont = love.graphics.newFont("assets/fonts/VT323-Regular.ttf", 28)
    
    -- Create buttons
    self.buttons = {
        {
            text = "Play Again",
            action = "restart",
            x = 0,
            y = 0,
            width = 200,
            height = 50
        },
        {
            text = "Exit",
            action = "exit",
            x = 0,
            y = 0,
            width = 200,
            height = 50
        }
    }
    
    self.selectedButton = 1
    self.fadeAlpha = 0
    self.isReady = false
end

function EndingScreen:update(dt)
    -- Fade in
    if self.fadeAlpha < 1 then
        self.fadeAlpha = math.min(1, self.fadeAlpha + self.fadeSpeed * dt)
        if self.fadeAlpha >= 1 then
            self.isReady = true
        end
    end
end

function EndingScreen:draw()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Draw black background
    love.graphics.setColor(0, 0, 0, self.fadeAlpha)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    
    if not self.isReady then
        return
    end
    
    -- Draw "THE END"
    love.graphics.setFont(self.titleFont)
    love.graphics.setColor(1, 1, 1, self.fadeAlpha)
    love.graphics.printf("THE END", 0, screenHeight / 2 - 120, screenWidth, "center")
    
    -- Draw ending title
    love.graphics.setFont(self.font)
    love.graphics.printf(self.endingTitle, 0, screenHeight / 2 - 60, screenWidth, "center")
    
    -- Draw ending number
    love.graphics.setFont(self.buttonFont)
    love.graphics.printf("Ending " .. self.endingNumber .. " Complete", 0, screenHeight / 2 - 10, screenWidth, "center")
    
    -- Draw buttons
    local buttonSpacing = 80
    local startY = screenHeight / 2 + 60
    
    for i, button in ipairs(self.buttons) do
        local y = startY + (i - 1) * buttonSpacing
        button.x = screenWidth / 2 - button.width / 2
        button.y = y
        
        -- Draw button background
        if i == self.selectedButton then
            love.graphics.setColor(1, 1, 1, 0.3 * self.fadeAlpha)
        else
            love.graphics.setColor(1, 1, 1, 0.1 * self.fadeAlpha)
        end
        love.graphics.rectangle("fill", button.x, button.y, button.width, button.height, 5, 5)
        
        -- Draw button border
        if i == self.selectedButton then
            love.graphics.setColor(1, 1, 1, self.fadeAlpha)
        else
            love.graphics.setColor(1, 1, 1, 0.5 * self.fadeAlpha)
        end
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", button.x, button.y, button.width, button.height, 5, 5)
        
        -- Draw button text
        love.graphics.setFont(self.buttonFont)
        love.graphics.setColor(1, 1, 1, self.fadeAlpha)
        love.graphics.printf(button.text, button.x, button.y + 10, button.width, "center")
    end
    
    love.graphics.setColor(1, 1, 1, 1)
end

function EndingScreen:keypressed(key)
    if not self.isReady then return end
    
    if key == "up" or key == "w" then
        self.selectedButton = self.selectedButton - 1
        if self.selectedButton < 1 then
            self.selectedButton = #self.buttons
        end
    elseif key == "down" or key == "s" then
        self.selectedButton = self.selectedButton + 1
        if self.selectedButton > #self.buttons then
            self.selectedButton = 1
        end
    elseif key == "return" or key == "space" then
        self:executeButton()
    end
end

function EndingScreen:executeButton()
    local button = self.buttons[self.selectedButton]
    
    if button.action == "restart" then
        -- Restart the game
        love.load()
    elseif button.action == "exit" then
        -- Exit the game
        love.event.quit()
    end
end

function EndingScreen:mousepressed(x, y, button)
    if not self.isReady or button ~= 1 then return end
    
    for i, btn in ipairs(self.buttons) do
        if x >= btn.x and x <= btn.x + btn.width and
           y >= btn.y and y <= btn.y + btn.height then
            self.selectedButton = i
            self:executeButton()
            return
        end
    end
end

return EndingScreen
