local MapManager = require('src.managers.MapManager')   
local EnemyManager = require('src.managers.EnemyManager')

Game = {}
local gameMusic = nil -- Store music reference globally
local houseMusic = nil -- Store house music reference
local currentMusicTrack = nil -- Track which music is currently playing

function Game:switchMusic(mapName)
    -- Clean up the map name (remove path and extension if present)
    local cleanMapName = mapName
    if mapName:find('/') then
        cleanMapName = mapName:gsub('.*/', '')
    end
    if cleanMapName:find('%.lua$') then
        cleanMapName = cleanMapName:gsub('%.lua$', '')
    end
    
    -- Indoor maps: all house interior rooms
    local indoorMaps = {"duckyroomMap", "houseMap", "parentroomMap", "zoomedDuckroomMap", "zoomedHouseMap"}
    
    -- Outdoor maps: yard and intersection
    local outdoorMaps = {"frontyardMap", "intersectionMap"}
    
    local isIndoor = false
    
    -- Check if current map is an indoor map
    for _, map in ipairs(indoorMaps) do
        if cleanMapName == map then
            isIndoor = true
            break
        end
    end
    
    -- Switch music if needed
    if isIndoor and currentMusicTrack ~= "house" then
        if gameMusic then gameMusic:stop() end
        if not houseMusic then
            houseMusic = love.audio.newSource("assets/sounds/music/house-music.mp3", "stream")
            houseMusic:setLooping(true)
            houseMusic:setVolume(0.05)
        end
        houseMusic:play()
        currentMusicTrack = "house"
    elseif not isIndoor and currentMusicTrack ~= "game" then
        if houseMusic then houseMusic:stop() end
        if not gameMusic then
            gameMusic = love.audio.newSource("assets/sounds/music/game-start.mp3", "stream")
            gameMusic:setLooping(true)
            gameMusic:setVolume(0.05)
        end
        gameMusic:play()
        currentMusicTrack = "game"
    end
end

function Game:init()
    self.player = require('src.entities.Player'):new()
    self.mapManager = MapManager:new()
    self.mapManager:init()
    
    -- Store initial player spawn position for current map
    self.initialPlayerX = self.player.x
    self.initialPlayerY = self.player.y
    
    -- Track where player first entered whisperMap (for respawn)
    self.whisperMapEntryX = nil
    self.whisperMapEntryY = nil
    
    -- Create player collider in the current world
    local world = self.mapManager:getWorld()
    self.player.collider = world:newBSGRectangleCollider(self.player.x, self.player.y, 37, 30, 10)
    self.player.collider:setFixedRotation(true)
    
    -- Initialize enemy manager
    self.enemyManager = EnemyManager:new()
    self.enemyManager:init()
    self.enemyManager:spawnEnemiesForMap(self.mapManager.currentMap, world)
    
    -- Cache font for UI prompts
    self.uiFont = love.graphics.newFont("assets/fonts/VT323-Regular.ttf", 24)
    
    -- Interaction cooldown
    self.isTransitioning = false
    
    -- Stop any existing music and initialize music system
    if gameMusic then
        gameMusic:stop()
        gameMusic:release()
        gameMusic = nil
    end
    if houseMusic then
        houseMusic:stop()
        houseMusic:release()
        houseMusic = nil
    end
    
    -- Start with appropriate music for starting map (houseMap is indoor)
    currentMusicTrack = nil
    self:switchMusic(self.mapManager.currentMap)
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
    -- Don't update player during transition
    if self.isTransitioning then
        return
    end
    
    self.player:update(dt)
    self.mapManager:update(dt)
    
    -- Update enemies with player position
    self.enemyManager:update(dt, self.player.x, self.player.y)
    
    self.player.x = self.player.collider:getX() - 19
    self.player.y = self.player.collider:getY() - 35
    
    -- Check for collision with enemies (using sprite dimensions)
    local collidedEnemy = self.enemyManager:checkPlayerCollision(self.player.x, self.player.y, 36, 54)
    if collidedEnemy then
        self:handlePlayerDeath(collidedEnemy)
    end
    
    -- Camera follows player in outdoor maps
    if self.mapManager:isOutdoorMap() then
        cam:lookAt(self.player.x, self.player.y)

        local w = love.graphics.getWidth()
        local h = love.graphics.getHeight()
        
        -- Calculate scaled map dimensions (outdoor maps use scale 3)
        local scale = 3
        local mapW = self.mapManager.currentMapObject.width * self.mapManager.currentMapObject.tilewidth * scale
        local mapH = self.mapManager.currentMapObject.height * self.mapManager.currentMapObject.tileheight * scale

        if cam.x < w / 2 then
            cam.x = w / 2
        end
        if cam.y < h / 2 then
            cam.y = h / 2
        end

        if cam.x > mapW - w / 2 then
            cam.x = mapW - w / 2
        end
        if cam.y > mapH - h / 2 then
            cam.y = mapH - h / 2
        end
    end
end

function Game:draw()
    -- Handle camera for outdoor maps
    if self.mapManager:isOutdoorMap() then
        cam:attach()
        self.mapManager:draw()
        self.enemyManager:draw()

        love.graphics.push()
        love.graphics.scale(1, 1)
        self.player:draw()
        love.graphics.pop()

        -- Draw layers that should appear above the player (fog, overhangs, etc.)
        self.mapManager:drawAbovePlayer()

        cam:detach()
    else
        -- Indoor maps don't use camera
        self.mapManager:draw()
        self.enemyManager:draw()
        
        love.graphics.push()
        love.graphics.scale(1, 1)
        self.player:draw()
        love.graphics.pop()
    end
    
    -- Show interaction prompt when near a portal
    local portal = self:checkPortalInteraction()
    if portal then
        self:drawInteractionPrompt()
    end
    
    -- Draw E prompt for dialogue trigger
    self:drawDialoguePrompt()
end

function Game:keypressed(key)
    -- Handle ESC to return to main menu
    if key == 'escape' then
        -- Stop all game music
        if gameMusic then
            gameMusic:stop()
        end
        if houseMusic then
            houseMusic:stop()
        end
        
        local MainMenu = require('src.states.MainMenu')
        local transition = getTransition()
        transition:fadeIn(0.5, function()
            switchState(MainMenu)
        end)
        return
    end
    
    if key == 'f' or key == 'F' then
        self:interact()
    elseif key == 'e' or key == 'E' then
        self:triggerDialogue()
    elseif key == 'space' then
        -- Test: Remove last enemy
        self.enemyManager:removeLastEnemy()
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
            
            -- Switch music based on new map
            self:switchMusic(portal.targetMap)
            
            -- Recreate player collider in the new world
            self.mapManager:recreatePlayerCollider(self.player)
            
            -- Position player at spawn location if defined, otherwise at portal center
            if portal.spawnX and portal.spawnY then
                -- Spawn coordinates are for the player sprite, but collider needs offset adjustment
                self.player.collider:setPosition(portal.spawnX + 19, portal.spawnY + 35)
                self.player.x = portal.spawnX
                self.player.y = portal.spawnY
                
                -- Track whisperMap entry point
                local cleanTargetMap = portal.targetMap:gsub('.*/', ''):gsub('%.lua$', '')
                if cleanTargetMap == 'whisperMap' then
                    self.whisperMapEntryX = portal.spawnX
                    self.whisperMapEntryY = portal.spawnY
                    print("DEBUG: Entered whisperMap at " .. portal.spawnX .. ", " .. portal.spawnY)
                end
                
                -- Set respawn position when entering frontyardMap (use the portal's spawn coords)
                if portal.targetMap == 'frontyardMap' or portal.targetMap == 'maps/frontyardMap' or portal.targetMap == 'maps/frontyardMap.lua' then
                    self.initialPlayerX = portal.spawnX
                    self.initialPlayerY = portal.spawnY
                end
                print(string.format("Player spawned at: x=%.2f, y=%.2f (window: %dx%d)", 
                    portal.spawnX, portal.spawnY, 
                    love.graphics.getWidth(), love.graphics.getHeight()))
            else
                self.player.x = portal.x + portal.width / 2
                self.player.y = portal.y + portal.height / 2
                self.player.collider:setPosition(self.player.x + 19, self.player.y + 35)
                print(string.format("Player spawned at portal center: x=%.2f, y=%.2f (window: %dx%d)", 
                    self.player.x, self.player.y,
                    love.graphics.getWidth(), love.graphics.getHeight()))
            end
            
            -- Spawn enemies for the new map
            self.enemyManager:spawnEnemiesForMap(portal.targetMap, self.mapManager:getWorld())
            
            -- Then fade out to reveal the new room
            transition:fadeOut(0.5)
            self.isTransitioning = false
        end)
    end
end

function Game:triggerDialogue()
    -- Switch to Dialogue state, passing the current game instance
    local Dialogue = require('src.states.Dialogue')
    local dialogueState = Dialogue:new(self, "testDialogue")
    switchState(dialogueState)
end

function Game:drawDialoguePrompt()
    love.graphics.setFont(self.uiFont)
    self:drawTextWithShadow("Press E to talk", 50)
end

function Game:findSafeRespawnPoint(baseX, baseY)
    local attempts = 0
    local maxAttempts = 30
    local minDistanceFromEnemies = 300
    
    while attempts < maxAttempts do
        -- Generate random position around player
        local angle = love.math.random() * math.pi * 2
        local distance = minDistanceFromEnemies + love.math.random() * 200
        local testX = baseX + math.cos(angle) * distance
        local testY = baseY + math.sin(angle) * distance
        
        -- Check if position is safe from all enemies
        local isSafe = true
        for i = 1, #self.enemyManager.enemies do
            local enemy = self.enemyManager.enemies[i]
            if not enemy.removed then
                local dist = math.sqrt((testX - enemy.x)^2 + (testY - enemy.y)^2)
                if dist < enemy.detectionRadius + 100 then
                    isSafe = false
                    break
                end
            end
        end
        
        if isSafe then
            return testX, testY
        end
        
        attempts = attempts + 1
    end
    
    -- Fallback: spawn far away
    return baseX + 400, baseY + 400
end

function Game:handlePlayerDeath(enemy)
    self.isTransitioning = true
    
    -- Get respawn position
    local respawnX, respawnY
    local currentMap = self.mapManager.currentMap
    
    print("DEBUG: Current map name: '" .. tostring(currentMap) .. "'")
    
    if currentMap == 'whisperMap' and self.whisperMapEntryX and self.whisperMapEntryY then
        -- Use the entry point where player first entered whisperMap
        print("DEBUG: Using whisperMap entry point respawn")
        respawnX = self.whisperMapEntryX
        respawnY = self.whisperMapEntryY
    else
        -- Use first spawn point of current map or fallback to initial position
        print("DEBUG: Using first spawn point or initial position")
        local mapSpawnX, mapSpawnY = self.mapManager:getFirstSpawnPoint()
        respawnX = mapSpawnX or self.initialPlayerX
        respawnY = mapSpawnY or self.initialPlayerY
        print("DEBUG: Respawn coords: " .. tostring(respawnX) .. ", " .. tostring(respawnY))
    end
    
    -- Calculate CURRENT player position (where caught) for fade IN
    local caughtScreenX, caughtScreenY
    if self.mapManager:isOutdoorMap() then
        caughtScreenX = self.player.x - cam.x + love.graphics.getWidth() / 2
        caughtScreenY = self.player.y - cam.y + love.graphics.getHeight() / 2
    else
        caughtScreenX = self.player.x
        caughtScreenY = self.player.y
    end
    
    -- Calculate respawn screen position for fade OUT
    local respawnScreenX, respawnScreenY
    if self.mapManager:isOutdoorMap() then
        -- For outdoor maps with camera, fade out from screen center
        -- (camera will center on spawn position after respawn)
        respawnScreenX = love.graphics.getWidth() / 2
        respawnScreenY = love.graphics.getHeight() / 2
    else
        -- For indoor maps, use the spawn position directly
        respawnScreenX = self.initialPlayerX
        respawnScreenY = self.initialPlayerY
    end
    
    local transition = getTransition()
    -- Circular fade in (death effect) - closes inward from where player was caught
    transition:circularFadeIn(1.0, function()
        -- Reset player to respawn position
        self.player.collider:setPosition(respawnX + 19, respawnY + 35)
        self.player.x = respawnX
        self.player.y = respawnY
        print("DEBUG: Respawned at " .. respawnX .. ", " .. respawnY)
        
        -- Reset all enemies to their initial positions
        self.enemyManager:resetAllToInitialPositions()
        
        -- Fade back out to reveal the scene from respawn position
        transition:circularFadeOut(1.0, nil, respawnScreenX, respawnScreenY)
        self.isTransitioning = false
    end, caughtScreenX, caughtScreenY)
end

return Game
