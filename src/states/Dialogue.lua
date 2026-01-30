local DialogueManager = require('src.managers.DialogueManager')

Dialogue = {}

function Dialogue:new(gameInstance, dialogueKey)
    local self = {
        dialogueManager = DialogueManager:new(),
        gameInstance = gameInstance, -- The game instance (not the class)
        dialogueKey = dialogueKey or "testDialogue"
    }
    
    return setmetatable(self, { __index = Dialogue })
end

function Dialogue:enter()
    -- Stop player SFX if they exist
    if self.gameInstance.player then
        if self.gameInstance.player.walkingSound then
            self.gameInstance.player.walkingSound:pause()
        end
        if self.gameInstance.player.sprintSound then
            self.gameInstance.player.sprintSound:pause()
        end
    end
    
    -- Initialize dialogue manager
    self.dialogueManager:enter()
    
    -- Start the dialogue with callback to return to game
    self.dialogueManager:startDialogue(self.dialogueKey, function()
        -- Don't resume sounds - they will auto-start when player moves
        -- When dialogue completes, return to the game instance without calling enter()
        returnToState(self.gameInstance)
    end)
end

function Dialogue:update(dt)
    self.dialogueManager:update(dt)
end

function Dialogue:draw()
    -- Draw the game in the background (frozen)
    if self.gameInstance and self.gameInstance.draw then
        self.gameInstance:draw()
    end
    
    -- Draw dialogue on top
    self.dialogueManager:draw()
end

function Dialogue:keypressed(key)
    -- Handle dialogue input
    self.dialogueManager:keypressed(key)
end

return Dialogue
