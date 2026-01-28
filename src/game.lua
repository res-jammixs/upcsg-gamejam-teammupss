local MapManager = require('src.world.MapManager')
local DialogueManager = require('src.util.DialogueManager')

Game = {}
local gameMusic = nil -- Store music reference globally

function Game:init()
    self.player = require('src.entities.Player'):new()
    self.mapManager = MapManager:new()
    self.mapManager:init()
    
    -- Create player collider in the current world
    local world = self.mapManager:getWorld()
    self.player.collider = world:newBSGRectangleCollider(self.player.x, self.player.y, 37, 30, 10)
    self.player.collider:setFixedRotation(true)
    
    -- Initialize dialogue manager
    self.dialogueManager = DialogueManager:new()
    self.dialogueManager:enter()
    
    -- Cache font for UI prompts
    self.uiFont = love.graphics.newFont("assets/fonts/VT323-Regular.ttf", 24)
    
    -- Interaction cooldown
    self.isTransitioning = false
    
    -- Stop any existing game music and start fresh
    if gameMusic then
        gameMusic:stop()
        gameMusic:release()
    end
    
    gameMusic = love.audio.newSource("assets/sounds/music/game-start.mp3", "stream")
    gameMusic:setLooping(true)
    gameMusic:setVolume(0.4)
    gameMusic:play()
end

function Game:enter()
    self:init()
    
    -- Trigger fade-out transition when entering the game (screen starts black and fades to reveal room)
    local transition = getTransition()
    transition:fadeOut(0.5, function()
        -- Allow movement after fade completes
        self.isTransitioning = false
    end)
end

function Game:update(dt)
    -- Update dialogue if active
    if self.dialogueManager:isActive() then
        self.dialogueManager:update(dt)
        return -- Don't update player or map during dialogue
    end
    
    -- Don't update player during transition
    if self.isTransitioning then
        return
    end
    
    self.player:update(dt)
    self.mapManager:update(dt)
    
    self.player.x = self.player.collider:getX() - 19
    self.player.y = self.player.collider:getY() - 35
end

function Game:draw()
    self.mapManager:draw()

    love.graphics.push()
    love.graphics.scale(1, 1)
    self.player:draw()
    love.graphics.pop()
    
    -- Show interaction prompt when near a portal (only if dialogue is not active)
    if not self.dialogueManager:isActive() then
        local portal = self:checkPortalInteraction()
        if portal then
            self:drawInteractionPrompt()
        end
        
        -- Draw E prompt for dialogue trigger
        self:drawDialoguePrompt()
    end
    
    -- Draw dialogue on top of everything (outside camera transform)
    self.dialogueManager:draw()
end

function Game:keypressed(key)
    -- Handle ESC to return to main menu
    if key == 'escape' then
        -- Stop game music
        if gameMusic then
            gameMusic:stop()
        end
        
        local MainMenu = require('src.states.MainMenu')
        local transition = getTransition()
        transition:fadeIn(0.5, function()
            switchState(MainMenu)
        end)
        return
    end
    
    -- Handle dialogue input
    if self.dialogueManager:isActive() then
        self.dialogueManager:keypressed(key)
        return
    end
    
    if key == 'f' or key == 'F' then
        self:interact()
    elseif key == 'e' or key == 'E' then
        self:triggerDialogue()
    end
end

function Game:checkPortalInteraction()
    local playerX = self.player.collider:getX()
    local playerY = self.player.collider:getY()
    return self.mapManager:checkPortalInteraction(playerX, playerY)
end

function Game:drawTextWithShadow(text, y)
    local screenWidth = love.graphics.getWidth()
    
    -- Draw shadow
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.printf(text, 0, y + 2, screenWidth, "center")
    
    -- Draw main text
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(text, 0, y, screenWidth, "center")
end

function Game:drawInteractionPrompt()
    love.graphics.setFont(self.uiFont)
    self:drawTextWithShadow("Press F to interact", 20)
end

function Game:interact()
    -- Prevent interaction during transition
    if self.isTransitioning then return end
    
    local portal = self:checkPortalInteraction()
    
    if portal and portal.targetMap then
        self.isTransitioning = true
        local transition = getTransition()
        -- Fade to black first, then load the map and fade out
        transition:fadeIn(0.5, function()
            -- Load the target map while screen is black
            self.mapManager:loadMap(portal.targetMap)
            
            -- Recreate player collider in the new world
            self.mapManager:recreatePlayerCollider(self.player)
            
            -- Position player at spawn location if defined, otherwise at portal center
            if portal.spawnX and portal.spawnY then
                self.player.x = portal.spawnX
                self.player.y = portal.spawnY
            else
                self.player.x = portal.x + portal.width / 2
                self.player.y = portal.y + portal.height / 2
            end
            self.player.collider:setPosition(self.player.x, self.player.y)
            
            -- Then fade out to reveal the new room
            transition:fadeOut(0.5)
            self.isTransitioning = false
        end)
    end
end

function Game:triggerDialogue()
    -- Start a test dialogue when E is pressed
    self.dialogueManager:startDialogue("testDialogue")
end

function Game:drawDialoguePrompt()
    love.graphics.setFont(self.uiFont)
    self:drawTextWithShadow("Press E to talk", 50)
end

return Game
