local MapManager = require('src.world.MapManager')

Game = {}

function Game:init()
    self.player = require('src.entities.Player'):new()
    self.mapManager = MapManager:new()
    self.mapManager:init()
    
    -- Create player collider in the current world
    local world = self.mapManager:getWorld()
    self.player.collider = world:newBSGRectangleCollider(self.player.x, self.player.y, 37, 30, 10)
    self.player.collider:setFixedRotation(true)
end

function Game:enter()
    self:init()
    
    -- Trigger fade-out transition when entering the game (screen starts black and fades to reveal room)
    local transition = getTransition()
    transition:fadeOut(0.5)
end

function Game:update(dt)
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
    
    -- Show interaction prompt when near a portal
    local portal = self:checkPortalInteraction()
    if portal then
        self:drawInteractionPrompt()
    end
    
    love.graphics.pop()
end

function Game:keypressed(key)
    if key == 'f' or key == 'F' then
        self:interact()
    end
end

function Game:checkPortalInteraction()
    local playerX = self.player.collider:getX()
    local playerY = self.player.collider:getY()
    return self.mapManager:checkPortalInteraction(playerX, playerY)
end

function Game:drawInteractionPrompt()
    local interactFont = love.graphics.newFont("assets/fonts/VT323-Regular.ttf", 24)
    love.graphics.setFont(interactFont)
    
    local screenWidth = love.graphics.getWidth()
    
    -- Draw shadow (dark text below)
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.printf("Press F to interact", 0, 20 + 2, screenWidth, "center")
    
    -- Draw white text on top
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Press F to interact", 0, 20, screenWidth, "center")
end

function Game:interact()
    local portal = self:checkPortalInteraction()
    
    if portal then
        print("Interacting with portal! Target: " .. tostring(portal.targetMap))
        
        if portal.targetMap then
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
                
                print("Teleported to: " .. portal.targetMap)
                
                -- Then fade out to reveal the new room
                transition:fadeOut(0.5)
            end)
        end
    else
        print("No portal nearby to interact with!")
    end
end

return Game
