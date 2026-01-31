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
        _isActive = false,
        
        -- Route/Choice system
        currentRoute = nil, -- Current dialogue route (DialogueRoute1, DialogueRoute2, DialogueRoute3)
        isWaitingForChoice = false, -- Is showing a choice prompt
        choiceCallback = nil, -- Callback for when a choice is made
        choiceOptions = {}, -- Array of choice options
        choiceFont = nil
    }
    
    return setmetatable(self, { __index = DialogueManager })
end

function DialogueManager:enter()
    -- Load fonts
    self.font = love.graphics.newFont("assets/fonts/VT323-Regular.ttf", 28)
    self.smallFont = love.graphics.newFont("assets/fonts/VT323-Regular.ttf", 18)
    self.choiceFont = love.graphics.newFont("assets/fonts/VT323-Regular.ttf", 24)
    
    -- Map character names to their dialogue box file names (case-sensitive)
    local characterFileMap = {
        duckie = "duckie-dialogue-box.png",
        mama = "mama-dialogue-box.png",
        papa = "papa-dialogue-box.png",
        mistress = "mistress-dialogue-box.png",
        beaky = "beaky-dialogue-box.png",
        flappy = "flappy-dialogue-box.png",
        mrfeather = "MrFeather-dialogue-box.png",
        waddle = "waddle-dialogue-box.png",
        mrandy = "Mr.Andy-dialogue-box.png",
        shadyduck = "ShadyDuck-dialogue-box.png",
        kurt = "kurt-dialogue-box.png",
        rita = "Rita-dialogue-box.png"
    }
    
    -- Load dialogue boxes for all characters
    for characterName, fileName in pairs(characterFileMap) do
        local boxPath = "assets/graphics/dialogue box/" .. fileName
        local success, result = pcall(love.graphics.newImage, boxPath)
        if success then
            self.dialogueBoxImages[characterName] = result
        else
            print("Warning: Could not load dialogue box for " .. characterName .. " at " .. boxPath)
        end
    end
    
    -- Add character aliases
    if self.dialogueBoxImages["papa"] then
        self.dialogueBoxImages["father"] = self.dialogueBoxImages["papa"]
    end
    if self.dialogueBoxImages["duckie"] then
        self.dialogueBoxImages["ducky"] = self.dialogueBoxImages["duckie"]
    end
    if self.dialogueBoxImages["mama"] then
        self.dialogueBoxImages["mother"] = self.dialogueBoxImages["mama"]
    end
    if self.dialogueBoxImages["beaky"] then
        self.dialogueBoxImages["npc"] = self.dialogueBoxImages["beaky"]
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

function DialogueManager:showSignText(signText, onComplete)
    -- Show a single piece of text (for signs) using the dialogue system
    self._isActive = true
    self.dialogues = {{character = "duckie", text = signText}}
    self.currentDialogueIndex = 1
    self.onComplete = onComplete
    
    -- Initialize fonts if not already loaded
    if not self.font then
        self:enter()
    end
    
    -- Load the text
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
    
    -- Load dialogue box for character (skip for system messages)
    if self.currentCharacterName:lower() ~= "system" then
        self.currentDialogueBox = self.dialogueBoxImages[string.lower(self.currentCharacterName)]
        
        if self.currentDialogueBox then
            local screenWidth = love.graphics.getWidth()
            self.dialogueBoxScale = (screenWidth - 40) / self.currentDialogueBox:getWidth()
            self.boxHeight = self.currentDialogueBox:getHeight() * self.dialogueBoxScale
            self.boxY = love.graphics.getHeight() - self.boxHeight - 20
        end
    else
        -- For system messages, don't use a dialogue box
        self.currentDialogueBox = nil
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
    local screenHeight = love.graphics.getHeight()
    
    -- Draw background overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    
    -- Handle system messages (no dialogue box)
    if self.currentCharacterName:lower() == "system" then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(self.font)
        
        -- Draw system text centered
        love.graphics.printf(self.displayedText, 0, screenHeight / 2 - 50, screenWidth, "center")
        
        -- Draw choice prompt if waiting
        if self.isWaitingForChoice and self.isTextComplete then
            love.graphics.setFont(self.choiceFont or self.font)
            for i, option in ipairs(self.choiceOptions) do
                local choiceText = "Press " .. i .. ": " .. option
                love.graphics.printf(choiceText, 0, screenHeight / 2 + 20 + (i - 1) * 40, screenWidth, "center")
            end
        end
        
        love.graphics.setColor(1, 1, 1, 1)
        return
    end
    
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
    
    -- Ensure textWidth is valid
    if textWidth < 10 then
        textWidth = 100
    end
    
    love.graphics.setFont(self.font)
    love.graphics.setColor(0, 0, 0, 1)
    
    -- Safe text rendering with error handling
    local displayText = self.displayedText or ""
    pcall(function()
        love.graphics.printf(displayText, textX, textY, textWidth, "left")
    end)
    
    -- Draw continue indicator
    if self.isTextComplete then
        if self.isWaitingForChoice then
            -- Draw choice prompt
            love.graphics.setFont(self.choiceFont or self.font)
            local choiceY = self.boxY + (self.currentDialogueBox:getHeight() * self.dialogueBoxScale) - 100
            
            for i, option in ipairs(self.choiceOptions) do
                local choiceText = "Press " .. i .. ": " .. option
                local choiceX = boxX + 100
                local thisChoiceY = choiceY + (i - 1) * 40
                
                love.graphics.setColor(0, 0, 0, 0.8)
                love.graphics.print(choiceText, choiceX, thisChoiceY)
            end
        else
            -- Draw continue indicator
            local indicatorText = "Press SPACE to continue..."
            love.graphics.setFont(self.smallFont or self.font)
            local indicatorWidth = (self.smallFont or self.font):getWidth(indicatorText)
            local indicatorX = boxX + (self.currentDialogueBox:getWidth() * self.dialogueBoxScale) - indicatorWidth - 130
            local indicatorY = self.boxY + (self.currentDialogueBox:getHeight() * self.dialogueBoxScale) - 50
            local pulse = (math.sin(love.timer.getTime() * 3) + 1) / 2
            
            love.graphics.setColor(0, 0, 0, 0.4 + pulse * 0.6)
            pcall(function()
                love.graphics.print(indicatorText, indicatorX, indicatorY)
            end)
        end
    end
    
    love.graphics.setColor(1, 1, 1, 1)
end

function DialogueManager:keypressed(key)
    
    -- Handle choice selection
    if self.isWaitingForChoice then
        if key == "1" then
            self:selectChoice(1)
        elseif key == "2" then
            self:selectChoice(2)
        end
        return
    end
    
    -- Handle normal dialogue progression
    if key ~= "space" then return end
    
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
        local dialogue = self.dialogues[self.currentDialogueIndex]
        
        -- Check if this is a choice prompt
        if dialogue.character == "system" and dialogue.text:find("%(%(") then
            self:handleChoiceDialogue(dialogue.text)
        else
            self:loadDialogue(self.currentDialogueIndex)
        end
    else
        self:close()
    end
end

function DialogueManager:handleChoiceDialogue(text)
    -- Extract choice options from text like "((Go with Dad))  ((Find the last Ingredient))"
    local option1 = text:match("%(%((.-)%)%)")
    local remaining = text:gsub("%%(%(.-%))%%)", "", 1)
    local option2 = remaining:match("%(%((.-)%)%)")
    
    if option1 and option2 then
        self.isWaitingForChoice = true
        self.choiceOptions = {option1, option2}
        self.fullText = text
        self.displayedText = text
        self.isTextComplete = true
    else
        -- Not a valid choice, continue normally
        self:loadDialogue(self.currentDialogueIndex)
    end
end

function DialogueManager:selectChoice(choiceIndex)
    if not self.isWaitingForChoice or not self.choiceCallback then return end
    
    self.isWaitingForChoice = false
    local callback = self.choiceCallback
    self.choiceCallback = nil
    
    -- Close current dialogue
    self._isActive = false
    
    -- Execute callback with choice
    callback(choiceIndex)
end

function DialogueManager:startDialogueRoute(routeModule, sceneKey, onComplete, choiceCallback)
    local dialogueSet = routeModule[sceneKey]
    
    if not dialogueSet then
        return
    end
    
    self._isActive = true
    self.dialogues = dialogueSet
    self.currentDialogueIndex = 1
    self.onComplete = onComplete
    self.choiceCallback = choiceCallback
    self.currentRoute = routeModule
    
    -- Initialize fonts if not already loaded
    if not self.font then
        self:enter()
    end
    
    -- Load first dialogue
    self:loadDialogue(1)
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
