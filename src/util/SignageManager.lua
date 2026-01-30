local SignageManager = {}

function SignageManager:new()
    local self = {
        signs = {},
        font = nil,
        dialogueBox = nil,
        dialogueBoxScale = 1,
        boxHeight = 180,
        boxY = 0,
        textPadding = 40,
        textOffsetX = 80,
        textOffsetY = 210,
        
        -- Current sign display
        isShowingSign = false,
        currentSignText = "",
        displayedText = "",
        fullText = "",
        textSpeed = 30,
        animationTimer = 0,
        isTextComplete = false
    }
    return setmetatable(self, { __index = SignageManager })
end

function SignageManager:init()
    -- Load font
    self.font = love.graphics.newFont("assets/fonts/VT323-Regular.ttf", 28)
    
    -- Load duckie dialogue box for signs
    local boxPath = "assets/graphics/dialogue box/duckie-dialogue-box.png"
    local success, result = pcall(love.graphics.newImage, boxPath)
    if success then
        self.dialogueBox = result
        local screenWidth = love.graphics.getWidth()
        self.dialogueBoxScale = (screenWidth - 40) / self.dialogueBox:getWidth()
        self.boxHeight = self.dialogueBox:getHeight() * self.dialogueBoxScale
        self.boxY = love.graphics.getHeight() - self.boxHeight - 20
    end
end

function SignageManager:loadSignsForMap(mapName, mapObject)
    self.signs = {}
    
    if not mapObject or not mapObject.layers then
        return
    end
    
    local signageLayer = mapObject.layers["Signage"]
    if not signageLayer or not signageLayer.objects then
        return
    end
    
    -- Determine scale based on map type (outdoor = 3, indoor = 3)
    local scale = 3
    
    for i, obj in pairs(signageLayer.objects) do
        local signX = (obj.x * scale)
        local signY = (obj.y * scale)
        local signW = obj.width * scale
        local signH = obj.height * scale
        
        -- Get signText property
        local signText = ""
        if obj.properties and obj.properties.signText then
            signText = obj.properties.signText
        end
        
        table.insert(self.signs, {
            x = signX,
            y = signY,
            width = signW,
            height = signH,
            text = signText
        })
    end
end

function SignageManager:checkSignInteraction(playerX, playerY)
    if #self.signs == 0 then
        return nil
    end
    
    local interactionRange = 50
    
    for i, sign in ipairs(self.signs) do
        local signCenterX = sign.x + sign.width / 2
        local signCenterY = sign.y + sign.height / 2
        
        local dist = math.sqrt(
            (playerX - signCenterX) ^ 2 + 
            (playerY - signCenterY) ^ 2
        )
        
        if dist < interactionRange + (math.max(sign.width, sign.height) / 2) then
            return sign
        end
    end
    
    return nil
end

function SignageManager:showSign(signText)
    self.isShowingSign = true
    self.fullText = signText
    self.displayedText = ""
    self.animationTimer = 0
    self.isTextComplete = false
    self.currentSignText = signText
end

function SignageManager:closeSign()
    self.isShowingSign = false
    self.currentSignText = ""
    self.displayedText = ""
    self.fullText = ""
    self.isTextComplete = false
end

function SignageManager:update(dt)
    if not self.isShowingSign or self.isTextComplete then
        return
    end
    
    self.animationTimer = self.animationTimer + dt
    local charsToShow = math.floor(self.animationTimer * self.textSpeed)
    
    if charsToShow >= #self.fullText then
        self.displayedText = self.fullText
        self.isTextComplete = true
    else
        self.displayedText = string.sub(self.fullText, 1, charsToShow)
    end
end

function SignageManager:draw()
    if not self.isShowingSign then
        return
    end
    
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Draw background overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    
    if not self.dialogueBox then
        love.graphics.setColor(1, 1, 1, 1)
        return
    end
    
    -- Draw dialogue box
    love.graphics.setColor(1, 1, 1, 1)
    local boxX = (screenWidth - (self.dialogueBox:getWidth() * self.dialogueBoxScale)) / 2
    love.graphics.draw(self.dialogueBox, boxX, self.boxY, 0, self.dialogueBoxScale, self.dialogueBoxScale)
    
    -- Draw text
    love.graphics.setFont(self.font)
    love.graphics.setColor(0, 0, 0, 1)
    
    local textX = boxX + self.textOffsetX
    local textY = self.boxY + self.textOffsetY
    local textWidth = (self.dialogueBox:getWidth() * self.dialogueBoxScale) - (self.textPadding * 2) - self.textOffsetX
    
    love.graphics.printf(self.displayedText, textX, textY, textWidth, "center")
    
    -- Show continue indicator if text is complete
    if self.isTextComplete then
        love.graphics.setColor(0, 0, 0, 0.8)
        local promptText = "Press Space to close"
        local promptY = self.boxY + self.boxHeight - 80
        love.graphics.printf(promptText, boxX, promptY, self.dialogueBox:getWidth() * self.dialogueBoxScale, "center")
    end
    
    love.graphics.setColor(1, 1, 1, 1)
end

function SignageManager:isActive()
    return self.isShowingSign
end

return SignageManager
