local DialogueData = require('data.DialogueData')

local DialogueManager = {}

function DialogueManager:new()
    local self = {
        -- Dialogue data
        dialogues = {},
        currentDialogueIndex = 1,
        
        -- Text animation
        fullText = "",
        displayedText = "",
        textSpeed = 30,
        animationTimer = 0,
        isTextComplete = false,
        
        -- UI elements
        font = nil,
        dialogueBoxImages = {}, -- Store multiple dialogue boxes per character
        currentDialogueBox = nil,
        dialogueBoxScale = 1,
        boxHeight = 180,
        boxY = 0,
        textPadding = 40, -- Padding for text inside the box
        textOffsetX = 80, -- X offset for text from left edge
        textOffsetY = 210, -- Y offset for text to avoid name area
        
        -- Character names
        currentCharacterName = "",
        
        -- Callback when dialogue ends
        onComplete = nil,
        
        -- State tracking
        _isActive = false
    }
    
    return setmetatable(self, { __index = DialogueManager })
end

function DialogueManager:enter()
    -- Load fonts
    self.font = love.graphics.newFont("assets/fonts/VT323-Regular.ttf", 28)
    self.smallFont = love.graphics.newFont("assets/fonts/VT323-Regular.ttf", 18)
    
    -- Load dialogue boxes for all characters
    local characters = {"duckie", "mama", "papa", "mistress"}
    for _, characterName in ipairs(characters) do
        local boxPath = "assets/graphics/dialogue box/" .. characterName .. "-dialogue-box.png"
        local success, result = pcall(love.graphics.newImage, boxPath)
        if success then
            self.dialogueBoxImages[characterName] = result
        end
    end
    
    -- Calculate box position (will be updated when dialogue starts)
    local screenHeight = love.graphics.getHeight()
    self.boxY = screenHeight - 200 -- Default, will recalculate
end

function DialogueManager:startDialogue(dialogueKey, onComplete)
    local dialogueSet = DialogueData[dialogueKey]
    
    if not dialogueSet then
        return
    end
    
    self._isActive = true
    self.dialogues = dialogueSet
    self.currentDialogueIndex = 1
    self.onComplete = onComplete
    
    -- Initialize fonts if not already loaded
    if not self.font then
        self:enter()
    end
    
    -- Load first dialogue
    self:loadDialogue(1)
end

function DialogueManager:loadDialogue(index)
    if index > #self.dialogues then return end
    
    local dialogue = self.dialogues[index]
    self.currentCharacterName = dialogue.character or "Unknown"
    self.fullText = dialogue.text or ""
    self.displayedText = ""
    self.animationTimer = 0
    self.isTextComplete = false
    
    -- Load dialogue box for character
    self.currentDialogueBox = self.dialogueBoxImages[string.lower(self.currentCharacterName)]
    
    if self.currentDialogueBox then
        local screenWidth = love.graphics.getWidth()
        self.dialogueBoxScale = (screenWidth - 40) / self.currentDialogueBox:getWidth()
        self.boxHeight = self.currentDialogueBox:getHeight() * self.dialogueBoxScale
        self.boxY = love.graphics.getHeight() - self.boxHeight - 20
    end
end

function DialogueManager:update(dt)
    if not self._isActive or self.isTextComplete then return end
    
    self.animationTimer = self.animationTimer + dt
    local charsToShow = math.floor(self.animationTimer * self.textSpeed)
    
    if charsToShow >= #self.fullText then
        self.displayedText = self.fullText
        self.isTextComplete = true
    else
        self.displayedText = string.sub(self.fullText, 1, charsToShow)
    end
end

function DialogueManager:draw()
    if not self._isActive then 
        return 
    end
    
    local screenWidth = love.graphics.getWidth()
    
    -- Draw background overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, screenWidth, love.graphics.getHeight())
    
    if not self.currentDialogueBox then
        love.graphics.setColor(1, 1, 1, 1)
        return
    end
    
    -- Draw dialogue box
    love.graphics.setColor(1, 1, 1, 1)
    local boxX = (screenWidth - (self.currentDialogueBox:getWidth() * self.dialogueBoxScale)) / 2
    love.graphics.draw(self.currentDialogueBox, boxX, self.boxY, 0, self.dialogueBoxScale, self.dialogueBoxScale)
    
    -- Draw text
    local textX = boxX + self.textPadding + self.textOffsetX
    local textY = self.boxY + self.textOffsetY
    local rightMargin = 80 -- Right margin to prevent text overflow
    local textWidth = (self.currentDialogueBox:getWidth() * self.dialogueBoxScale) - (self.textPadding * 2) - self.textOffsetX - rightMargin
    
    love.graphics.setFont(self.font)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.printf(self.displayedText, textX, textY, textWidth, "left")
    
    -- Draw continue indicator
    if self.isTextComplete then
        local indicatorText = "Press SPACE to continue..."
        love.graphics.setFont(self.smallFont or self.font)
        local indicatorWidth = (self.smallFont or self.font):getWidth(indicatorText)
        local indicatorX = boxX + (self.currentDialogueBox:getWidth() * self.dialogueBoxScale) - indicatorWidth - 130
        local indicatorY = self.boxY + (self.currentDialogueBox:getHeight() * self.dialogueBoxScale) - 50
        local pulse = (math.sin(love.timer.getTime() * 3) + 1) / 2
        
        love.graphics.setColor(0, 0, 0, 0.4 + pulse * 0.6)
        love.graphics.print(indicatorText, indicatorX, indicatorY)
    end
    
    love.graphics.setColor(1, 1, 1, 1)
end

function DialogueManager:keypressed(key)
    if not self._isActive or key ~= "space" then return end
    
    if not self.isTextComplete then
        self.displayedText = self.fullText
        self.isTextComplete = true
    else
        self:nextDialogue()
    end
end

function DialogueManager:nextDialogue()
    self.currentDialogueIndex = self.currentDialogueIndex + 1
    
    if self.currentDialogueIndex <= #self.dialogues then
        self:loadDialogue(self.currentDialogueIndex)
    else
        self:close()
    end
end

function DialogueManager:close()
    self._isActive = false
    
    if self.onComplete then
        self.onComplete()
    end
end

function DialogueManager:isActive()
    return self._isActive
end

return DialogueManager
