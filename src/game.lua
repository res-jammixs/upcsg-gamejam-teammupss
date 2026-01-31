local MapManager = require('src.managers.MapManager')   
local EnemyManager = require('src.managers.EnemyManager')
local NPCManager = require('src.managers.NPCManager')
local ItemManager = require('src.managers.ItemManager')
local InventoryUI = require('src.managers.InventoryUI')
local SignageManager = require('src.util.SignageManager')
local StoryManager = require('src.managers.StoryManager')
local DialogueRoute1 = require('data.DialogueRoute1')
local DialogueRoute2 = require('data.DialogueRoute2')
local DialogueRoute3 = require('data.DialogueRoute3')
local EndingScreen = require('src.states.EndingScreen')

Game = {}
local gameMusic = nil -- Store music reference globally
local houseMusic = nil -- Store house music reference
local ashMapMusic = nil -- Store ashMap music reference
local whisperMapMusic = nil -- Store whisperMap music reference
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
    
    -- Handle ashMap exclusive music
    if cleanMapName == "ashMap" then
        if gameMusic then gameMusic:stop() end
        if houseMusic then houseMusic:stop() end
        if whisperMapMusic then whisperMapMusic:stop() end
        
        if not ashMapMusic then
            ashMapMusic = love.audio.newSource("assets/sounds/music/ashmap-music.mp3", "stream")
            ashMapMusic:setLooping(true)
            ashMapMusic:setVolume(0.04)
        else
            -- Always ensure looping and volume are correct
            ashMapMusic:setLooping(true)
            ashMapMusic:setVolume(0.05)
        end
        
        if not ashMapMusic:isPlaying() then
            ashMapMusic:play()
        end
        currentMusicTrack = "ashMap"
    -- Handle whisperMap exclusive music
    elseif cleanMapName == "whisperMap" and currentMusicTrack ~= "whisperMap" then
        if gameMusic then gameMusic:stop() end
        if houseMusic then houseMusic:stop() end
        if ashMapMusic then ashMapMusic:stop() end
        if not whisperMapMusic then
            if love.filesystem.getInfo("assets/sounds/music/whispermap-music.mp3") then
                local ok, src = pcall(love.audio.newSource, "assets/sounds/music/whispermap-music.mp3", "stream")
                if ok and src then
                    whisperMapMusic = src
                    whisperMapMusic:setLooping(true)
                    whisperMapMusic:setVolume(0.05)
                else
                    print("Warning: Failed to load whispermap-music.mp3")
                end
            else
                print("Warning: Missing whispermap-music.mp3")
            end
        end
        if whisperMapMusic then whisperMapMusic:play() end
        currentMusicTrack = "whisperMap"
    -- Switch music if needed for indoor maps
    elseif isIndoor and currentMusicTrack ~= "house" then
        if gameMusic then gameMusic:stop() end
        if ashMapMusic then ashMapMusic:stop() end
        if whisperMapMusic then whisperMapMusic:stop() end
        if not houseMusic then
            houseMusic = love.audio.newSource("assets/sounds/music/house-music.mp3", "stream")
            houseMusic:setLooping(true)
            houseMusic:setVolume(0.06)
        end
        houseMusic:play()
        currentMusicTrack = "house"
    -- Switch music for general outdoor maps
    elseif not isIndoor and cleanMapName ~= "ashMap" and cleanMapName ~= "whisperMap" and currentMusicTrack ~= "game" then
        if houseMusic then houseMusic:stop() end
        if ashMapMusic then ashMapMusic:stop() end
        if whisperMapMusic then whisperMapMusic:stop() end
        if not gameMusic then
            if love.filesystem.getInfo("assets/sounds/music/game-start.mp3") then
                local ok, src = pcall(love.audio.newSource, "assets/sounds/music/game-start.mp3", "stream")
                if ok and src then
                    gameMusic = src
                    gameMusic:setLooping(true)
                    gameMusic:setVolume(0.05)
                else
                    print("Warning: Failed to load game-start.mp3")
                end
            else
                print("Warning: Missing game-start.mp3")
            end
        end
        if gameMusic then gameMusic:play() end
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
    
    -- Ending routes state tracking
    self.hasTriggeredScene13 = false
    self.routeNPCsSpawned = false
    self.currentDialogueRoute = nil
    self.endingScreen = nil
    self.showingEnding = false
    
    -- Create player collider in the current world
    local world = self.mapManager:getWorld()
    self.player.collider = world:newBSGRectangleCollider(self.player.x, self.player.y, 37, 30, 10)
    self.player.collider:setFixedRotation(true)
    
    -- Initialize enemy manager
    self.enemyManager = EnemyManager:new()
    self.enemyManager:init()
    self.enemyManager:spawnEnemiesForMap(self.mapManager.currentMap, world, self.mapManager.currentMapObject)
    
    -- Initialize NPC manager
    self.npcManager = NPCManager:new()
    self.npcManager:init()
    self.npcManager:spawnNPCsForMap(self.mapManager.currentMap, self.mapManager:getWorld())
    
    -- Initialize item manager
    self.itemManager = ItemManager:new()
    self.itemManager:init()
    self.itemManager:spawnItemsForMap(self.mapManager.currentMap, self.mapManager:getWorld())
    
    -- Initialize inventory UI
    self.inventoryUI = InventoryUI:new()
    self.inventoryUI:init()
    
    -- Initialize signage manager
    self.signageManager = SignageManager:new()
    self.signageManager:init()
    self.signageManager:loadSignsForMap(self.mapManager.currentMap, self.mapManager.currentMapObject)
    
    -- Initialize story manager
    self.storyManager = StoryManager:new()
    self.storyManager:init()
    
    -- Initialize global inventory if not exists
    if not _G.inventory then
        _G.inventory = {}
    end
    
    -- Cache font for UI prompts
    self.uiFont = love.graphics.newFont("assets/fonts/VT323-Regular.ttf", 24)
    
    -- Load objective box sprite (optional)
    local success, result = pcall(love.graphics.newImage, "assets/graphics/dialogue box/objective-box-sprite.png")
    if success then
        self.objectiveBoxSprite = result
    else
        print("Warning: objective-box-sprite.png not found, using fallback display")
        self.objectiveBoxSprite = nil
    end
    
    -- Load game-over sound effect
    self.gameOverSound = love.audio.newSource("assets/sounds/sfx/game-over.mp3", "static")
    self.gameOverSound:setVolume(0.3)
    
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
    if ashMapMusic then
        ashMapMusic:stop()
        ashMapMusic:release()
        ashMapMusic = nil
    end
    if whisperMapMusic then
        whisperMapMusic:stop()
        whisperMapMusic:release()
        whisperMapMusic = nil
    end
    
    -- Start with appropriate music for starting map (houseMap is indoor)
    currentMusicTrack = nil
    self:switchMusic(self.mapManager.currentMap)
end

function Game:enter()
    self:init()
    
    -- Start tutorial dialogue immediately
    self.storyManager:startTutorial()
    
    -- Trigger fade-out transition when entering the game (screen starts black and fades to reveal room)
    local transition = getTransition()
    transition:fadeOut(0.5, function()
        -- Allow movement after fade completes
        self.isTransitioning = false
    end)
end

function Game:update(dt)
    -- Handle ending screen
    if self.showingEnding and self.endingScreen then
        self.endingScreen:update(dt)
        return
    end
    
    -- Don't update player during transition
    if self.isTransitioning then
        return
    end
    
    -- Update story manager (handles dialogue)
    self.storyManager:update(dt)
    
    -- Update signage if active
    if self.signageManager:isActive() then
        self.signageManager:update(dt)
        return -- Don't update other things while showing sign
    end
    
    -- Don't update player if showing story dialogue
    if self.storyManager:isActive() then
        return
    end
    
    self.player:update(dt)
    self.mapManager:update(dt)
    
    -- Update enemies with player position
    self.enemyManager:update(dt, self.player.x, self.player.y)
    
    -- Update NPCs (pass player collider for pushing)
    self.npcManager:update(dt, self.player.collider)
    
    -- Update items (animations and collision)
    self.itemManager:update(dt, self.player.collider)
    
    self.player.x = self.player.collider:getX() - 19
    self.player.y = self.player.collider:getY() - 35
    
    -- Check for collision with NPCs and block player movement
    local collidedNPC = self.npcManager:checkPlayerCollision(self.player.x, self.player.y, 36, 54)
    if collidedNPC then
        -- Push player back from NPC (using NPC hitbox dimensions: 24x52 with offset 6,1)
        local npcHitboxX = collidedNPC.x + 6
        local npcHitboxY = collidedNPC.y + 1
        local npcHitboxW = 24
        local npcHitboxH = 52
        
        -- Calculate overlap and push player away
        local playerCenterX = self.player.x + 18
        local playerCenterY = self.player.y + 27
        local npcCenterX = npcHitboxX + npcHitboxW / 2
        local npcCenterY = npcHitboxY + npcHitboxH / 2
        
        local dx = playerCenterX - npcCenterX
        local dy = playerCenterY - npcCenterY
        local dist = math.sqrt(dx * dx + dy * dy)
        
        if dist > 0 then
            -- Push player away from NPC
            local pushDistance = 2
            local pushX = (dx / dist) * pushDistance
            local pushY = (dy / dist) * pushDistance
            self.player.collider:setPosition(
                self.player.collider:getX() + pushX,
                self.player.collider:getY() + pushY
            )
        end
    end
    
    -- Check for collision with enemies (using sprite dimensions)
    local collidedEnemy = self.enemyManager:checkPlayerCollision(self.player.x, self.player.y, 36, 54)
    if collidedEnemy then
        self:handlePlayerDeath(collidedEnemy)
    end
    
    -- Check if in whisperMap and collected Whisper Weed to trigger scene10
    if self.mapManager:getCurrentMap() == 'whisperMap' then
        if _G.inventory and _G.inventory.whisperweed == true then
            -- Check if scene10 hasn't been triggered yet
            if not self.storyManager:isSceneCompleted("scene10") then
                -- Trigger scene10 dialogue
                print("DEBUG: Whisper Weed collected in whisperMap - Triggering scene10")
                self.storyManager:playScene("scene10", function()
                    -- After scene10 completes, advance to obj16 (Go to the Ash Lands)
                    if self.storyManager.currentObjective == "obj15" then
                        table.insert(self.storyManager.completedObjectives, "obj15")
                        self.storyManager.currentObjective = "obj16"
                        print("DEBUG: Advanced to obj16 - Go to the Ash Lands")
                    end
                end)
            end
        end
    end
    
    -- Check if in ashMap and collected 10 ashberries to trigger scene12
    if self.mapManager:getCurrentMap() == 'ashMap' then
        if _G.inventory and (_G.inventory.ashberry or 0) >= 10 then
            -- Check if scene12 hasn't been triggered yet
            if not self.storyManager:isSceneCompleted("scene12") then
                -- Trigger scene12 dialogue
                print("DEBUG: 10 Ashberries collected in ashMap - Triggering scene12")
                self.storyManager:playScene("scene12", function()
                    -- After scene12 completes, advance to obj18 (Go to the Hill with the Thousand Turns)
                    if self.storyManager.currentObjective == "obj17" then
                        table.insert(self.storyManager.completedObjectives, "obj17")
                        self.storyManager.currentObjective = "obj18"
                        print("DEBUG: Advanced to obj18 - Go to the Hill with the Thousand Turns")
                    end
                end)
            end
        end
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
    -- Handle ending screen
    if self.showingEnding and self.endingScreen then
        self.endingScreen:draw()
        return
    end
    
    -- Handle camera for outdoor maps
    if self.mapManager:isOutdoorMap() then
        -- Check if we're in maze map for darkness effect
        local isMazeMap = self.mapManager:getCurrentMap() == "mazeMap"
        
        if isMazeMap then
            -- Render everything to canvas first
            love.graphics.setCanvas(self.mapManager.darknessCanvas)
            love.graphics.clear()
        end
        
        cam:attach()
        self.mapManager:draw()
        self.enemyManager:draw()
        self.npcManager:draw()

        love.graphics.push()
        love.graphics.scale(1, 1)
        self.player:draw()
        love.graphics.pop()
        
        -- Draw items (before fog/above layers)
        self.itemManager:draw()

        -- Draw layers that should appear above the player (fog, overhangs, etc.)
        self.mapManager:drawAbovePlayer()

        cam:detach()
        
        if isMazeMap and self.mapManager.darknessFadeAmount > 0.01 then
            -- Apply darkness shader only if darkness is still visible
            love.graphics.setCanvas()
            
            -- Calculate player center position in screen coordinates
            -- Player sprite is 12x18 scaled by 3 = 36x54, so center is at +18, +27
            local playerCenterX = self.player.x + 18
            local playerCenterY = self.player.y + 27
            local screenX = playerCenterX - cam.x + love.graphics.getWidth() / 2
            local screenY = playerCenterY - cam.y + love.graphics.getHeight() / 2
            
            -- Calculate expand radius: as darkness fades (1.0 -> 0.0), light expands (1.0 -> 10.0)
            local fadeProgress = 1.0 - self.mapManager.darknessFadeAmount -- 0.0 -> 1.0
            local expandRadius = 1.0 + (fadeProgress * 9.0) -- 1.0 -> 10.0 (exponential expansion)
            
            -- Set shader parameters (3 tiles = 16 * 3 = 48 pixels per tile at scale 3 = 144 pixels radius)
            self.mapManager.darknessShader:send("playerPos", {screenX, screenY})
            self.mapManager.darknessShader:send("lightRadius", 144) -- 3 tiles radius
            self.mapManager.darknessShader:send("darknessFade", self.mapManager.darknessFadeAmount)
            self.mapManager.darknessShader:send("expandRadius", expandRadius)
            
            -- Draw the canvas with shader applied
            love.graphics.setShader(self.mapManager.darknessShader)
            love.graphics.draw(self.mapManager.darknessCanvas, 0, 0)
            love.graphics.setShader()
        elseif isMazeMap then
            -- If darkness is faded out, just draw the canvas normally
            love.graphics.setCanvas()
            love.graphics.draw(self.mapManager.darknessCanvas, 0, 0)
        end
    else
        -- Indoor maps don't use camera
        self.mapManager:draw()
        self.enemyManager:draw()
        self.npcManager:draw()
        self.itemManager:draw()
        
        love.graphics.push()
        love.graphics.scale(1, 1)
        self.player:draw()
        love.graphics.pop()
    end
    
    -- Draw inventory UI (always visible, regardless of indoor/outdoor)
    self.inventoryUI:draw()
    
    -- Draw item collection notifications (always visible, regardless of indoor/outdoor)
    self.itemManager:drawNotification()
    
    -- Show interaction prompt when near a portal
    local portal = self:checkPortalInteraction()
    if portal then
        self:drawInteractionPrompt("Press E to enter")
    end
    
    -- Check if near an NPC and show interaction prompt
    local nearbyNPC = self.npcManager:checkPlayerInteraction(self.player.x, self.player.y)
    if nearbyNPC then
        self:drawNPCInteractionPrompt(nearbyNPC)
    end
    
    -- Check if near Milkfish and show interaction prompt
    if self.mapManager:getCurrentMap() == 'mazeMap' and self.mapManager.darknessActive then
        local playerX = self.player.collider:getX()
        local playerY = self.player.collider:getY()
        if self.mapManager:checkMilkfishInteraction(playerX, playerY) then
            self:drawMilkfishInteractionPrompt()
        end
    end
    
    -- Check if near a sign and show interaction prompt
    if not self.signageManager:isActive() then
        local playerX = self.player.collider:getX()
        local playerY = self.player.collider:getY()
        local nearbySign = self.signageManager:checkSignInteraction(playerX, playerY)
        if nearbySign then
            self:drawSignInteractionPrompt()
        end
    end
    
    -- Check if near an objective item and show interaction prompt
    if not self.storyManager:isActive() and not self.signageManager:isActive() then
        local playerX = self.player.collider:getX()
        local playerY = self.player.collider:getY()
        local nearbyItem = self.mapManager:checkObjectiveItemInteraction(playerX, playerY)
        if nearbyItem then
            self:drawObjectiveItemPrompt(nearbyItem)
        end
    end
    
    -- Draw signage overlay if active (should be on top of everything)
    self.signageManager:draw()
    
    -- Draw story dialogue (should be on top of signage)
    self.storyManager:draw()
    
    -- Draw current objective in upper right corner
    if not self.storyManager:isActive() and not self.signageManager:isActive() then
        local screenWidth = love.graphics.getWidth()
        local objectiveText = self.storyManager:getCurrentObjectiveText()
        
        if self.objectiveBoxSprite then
            local spriteWidth = self.objectiveBoxSprite:getWidth()
            local spriteHeight = self.objectiveBoxSprite:getHeight()
            local boxX = screenWidth - spriteWidth - 20
            local boxY = 20
            
            -- Draw objective box sprite
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(self.objectiveBoxSprite, boxX, boxY)
            
            -- Draw objective text
            love.graphics.setFont(self.uiFont)
            love.graphics.setColor(0, 0, 0, 1)
            local textX = boxX + 20
            local textY = boxY + 15
            local textWidth = spriteWidth - 40
            love.graphics.printf("Objective:", textX, textY, textWidth, "left")
            love.graphics.printf(objectiveText, textX, textY + 25, textWidth, "left")
            love.graphics.setColor(1, 1, 1, 1)
        else
            -- Fallback: simple box in upper right corner
            local boxWidth = 300
            local boxHeight = 80
            local boxX = screenWidth - boxWidth - 20
            local boxY = 20
            
            love.graphics.setColor(0, 0, 0, 0.7)
            love.graphics.rectangle("fill", boxX, boxY, boxWidth, boxHeight)
            
            love.graphics.setFont(self.uiFont)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.printf("Objective:", boxX + 10, boxY + 10, boxWidth - 20, "left")
            love.graphics.printf(objectiveText, boxX + 10, boxY + 35, boxWidth - 20, "left")
        end
    end
end

function Game:keypressed(key)
    -- Handle ending screen input
    if self.showingEnding and self.endingScreen then
        self.endingScreen:keypressed(key)
        return
    end
    
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
    
    if key == 'space' then
        -- If showing a sign, close it with space
        if self.signageManager:isActive() then
            self.signageManager:closeSign()
            return
        end
        -- If showing story dialogue, advance it
        if self.storyManager:isActive() then
            self.storyManager:nextDialogue()
            return
        end
        -- Test: Remove last enemy
        self.enemyManager:removeLastEnemy()
    elseif key == 'e' or key == 'E' then
        -- Check for Milkfish interaction first (in maze map)
        if self.mapManager:getCurrentMap() == 'mazeMap' then
            local playerX = self.player.collider:getX()
            local playerY = self.player.collider:getY()
            if self.mapManager:checkMilkfishInteraction(playerX, playerY) then
                self.mapManager:activateMilkfish(self.itemManager)
                return
            end
        end
        
        -- Check if near an objective item
        local playerX = self.player.collider:getX()
        local playerY = self.player.collider:getY()
        local nearbyItem = self.mapManager:checkObjectiveItemInteraction(playerX, playerY)
        if nearbyItem and not nearbyItem.collected then
            -- If objective item has targetMap, treat it as a portal
            if nearbyItem.targetMap then
                -- Set pending dialogue and transport to new map
                self.storyManager:handleObjectiveItem(nearbyItem.itemType, self.mapManager, true)
                self:handleMapTransition(nearbyItem.targetMap, nearbyItem.spawnX, nearbyItem.spawnY)
            else
                -- No targetMap, trigger dialogue immediately
                self.storyManager:handleObjectiveItem(nearbyItem.itemType, self.mapManager, false)
            end
            return
        end
        
        -- Check if near a sign
        local nearbySign = self.signageManager:checkSignInteraction(playerX, playerY)
        if nearbySign and nearbySign.text and nearbySign.text ~= "" then
            self.signageManager:showSign(nearbySign.text)
            return
        end
        
        -- Check if near an NPC
        local nearbyNPC = self.npcManager:checkPlayerInteraction(self.player.x, self.player.y)
        if nearbyNPC then
            self:triggerNPCDialogue(nearbyNPC)
            return
        end
        
        -- Otherwise check for portal interaction
        self:interact()
    end
end

function Game:mousepressed(x, y, button)
    -- Handle ending screen input
    if self.showingEnding and self.endingScreen then
        self.endingScreen:mousepressed(x, y, button)
        return
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
    self:drawTextWithShadow("Press E to interact", 20)
end

function Game:handleMapTransition(targetMap, spawnX, spawnY)
    -- Prevent interaction during transition
    if self.isTransitioning then return end
    
    self.isTransitioning = true
    local transition = getTransition()
    -- Fade to black first, then load the map and fade out
    transition:fadeIn(0.5, function()
        -- Load the target map while screen is black
        self.mapManager:loadMap(targetMap)
        
        -- Switch music based on new map
        self:switchMusic(targetMap)
        
        -- Recreate player collider in the new world
        self.mapManager:recreatePlayerCollider(self.player)
        
        -- Position player at spawn location if provided
        if spawnX and spawnY then
            -- Spawn coordinates are for the player sprite, but collider needs offset adjustment
            self.player.collider:setPosition(spawnX + 19, spawnY + 35)
            self.player.x = spawnX
            self.player.y = spawnY
            
            -- Track whisperMap entry point
            local cleanTargetMap = targetMap:gsub('.*/', ''):gsub('%.lua$', '')
            if cleanTargetMap == 'whisperMap' then
                self.whisperMapEntryX = spawnX
                self.whisperMapEntryY = spawnY
                print("DEBUG: Entered whisperMap at " .. spawnX .. ", " .. spawnY)
            end
            
            -- Set respawn position when entering frontyardMap
            if targetMap == 'frontyardMap' or targetMap == 'maps/frontyardMap' or targetMap == 'maps/frontyardMap.lua' then
                self.initialPlayerX = spawnX
                self.initialPlayerY = spawnY
            end
            print(string.format("Player spawned at: x=%.2f, y=%.2f (window: %dx%d)", 
                spawnX, spawnY, 
                love.graphics.getWidth(), love.graphics.getHeight()))
        else
            -- No spawn specified, use first portal spawn or map default
            local firstSpawnX, firstSpawnY = self.mapManager:getFirstSpawnPoint()
            if firstSpawnX and firstSpawnY then
                self.player.collider:setPosition(firstSpawnX + 19, firstSpawnY + 35)
                self.player.x = firstSpawnX
                self.player.y = firstSpawnY
                
                -- Track whisperMap entry point
                local cleanTargetMap = targetMap:gsub('.*/', ''):gsub('%.lua$', '')
                if cleanTargetMap == 'whisperMap' then
                    self.whisperMapEntryX = firstSpawnX
                    self.whisperMapEntryY = firstSpawnY
                    print("DEBUG: Entered whisperMap at " .. firstSpawnX .. ", " .. firstSpawnY)
                end
            end
        end
        
        -- Spawn enemies for the new map
        self.enemyManager:spawnEnemiesForMap(targetMap, self.mapManager:getWorld(), self.mapManager.currentMapObject)
        
        -- Spawn NPCs for the new map
        self.npcManager:spawnNPCsForMap(targetMap, self.mapManager:getWorld())
        
        -- Spawn items for the new map
        self.itemManager:spawnItemsForMap(targetMap, self.mapManager:getWorld())
        
        -- Load signs for the new map
        self.signageManager:loadSignsForMap(self.mapManager.currentMap, self.mapManager.currentMapObject)
        
        -- Load objective items for the new map
        self.mapManager:loadObjectiveItems()
        
        -- Check if there's a pending objective dialogue to trigger
        self.storyManager:checkPendingDialogue()
        
        -- Check for special map transitions that trigger objectives
        local cleanTargetMap = targetMap:gsub('.*/', ''):gsub('%.lua$', '')
        print("DEBUG: Map transition to: " .. cleanTargetMap .. " | Current objective: " .. tostring(self.storyManager.currentObjective))
        
        -- Trigger obj10 when entering intersectionMap (Town Square)
        if cleanTargetMap:lower() == 'intersectionmap' then
            print("DEBUG: Detected intersectionMap entry")
            if self.storyManager.currentObjective == "obj9" then
                -- Advance to obj10 (Talk to Mr. Andy)
                table.insert(self.storyManager.completedObjectives, "obj9")
                self.storyManager.currentObjective = "obj10"
                print("DEBUG: Entered Town Square - Advanced to obj10")
            else
                print("DEBUG: Current objective is not obj9, it's: " .. tostring(self.storyManager.currentObjective))
            end
            
            -- Check if returning after collecting 10 ashberries and scene13 not triggered
            if not self.hasTriggeredScene13 and _G.inventory and (_G.inventory.ashberry or 0) >= 10 then
                print("DEBUG: Triggering scene13 - Final stretch")
                self.hasTriggeredScene13 = true
                self.storyManager:playScene("scene13", function()
                    print("DEBUG: scene13 completed, spawning route NPCs")
                    -- After scene13, spawn dad and mistress NPCs
                    self:spawnRouteNPCs()
                end)
            end
        end
        
        -- Trigger scene9 dialogue when entering whisperMap (Whisper Willows)
        if cleanTargetMap:lower() == 'whispermap' then
            print("DEBUG: Detected whisperMap entry")
            -- Check if scene9 hasn't been played yet
            if not self.storyManager:isSceneCompleted("scene9") then
                print("DEBUG: Triggering scene9 dialogue")
                self.storyManager:playScene("scene9")
            else
                print("DEBUG: scene9 already completed")
            end
        end
        
        -- Trigger scene11 dialogue when entering ashMap with whisper weed collected
        if cleanTargetMap:lower() == 'ashmap' then
            print("DEBUG: Detected ashMap entry")
            -- Check if player has whisper weed and scene11 hasn't been played yet
            if _G.inventory and _G.inventory.whisperweed == true then
                if not self.storyManager:isSceneCompleted("scene11") then
                    print("DEBUG: Triggering scene11 dialogue")
                    self.storyManager:playScene("scene11", function()
                        -- After scene11 completes, advance to obj17 (Find the Ashroot Bulb)
                        if self.storyManager.currentObjective == "obj16" then
                            table.insert(self.storyManager.completedObjectives, "obj16")
                            self.storyManager.currentObjective = "obj17"
                            print("DEBUG: Advanced to obj17 - Find the Ashroot Bulb")
                        end
                    end)
                else
                    print("DEBUG: scene11 already completed")
                end
            else
                print("DEBUG: Whisper weed not collected yet")
            end
        end
        
        -- Then fade out to reveal the new room
        transition:fadeOut(0.5)
        self.isTransitioning = false
    end)
end

function Game:interact()
    -- Prevent interaction during transition
    if self.isTransitioning then return end
    
    local portal = self:checkPortalInteraction()
    
    if portal and portal.targetMap then
        self:handleMapTransition(portal.targetMap, portal.spawnX, portal.spawnY)
    end
end

function Game:triggerNPCDialogue(npc)
    -- Use StoryManager to handle NPC dialogue
    self.storyManager:playNPCDialogue(npc.dialogueKey)
end

function Game:drawNPCInteractionPrompt(npc)
    love.graphics.setFont(self.uiFont)
    self:drawTextWithShadow("Press E to talk to " .. npc.name, 50)
end

function Game:drawMilkfishInteractionPrompt()
    love.graphics.setFont(self.uiFont)
    self:drawTextWithShadow("Press E to get milkfish", 50)
end

function Game:drawSignInteractionPrompt()
    love.graphics.setFont(self.uiFont)
    self:drawTextWithShadow("Press E to read sign", 50)
end

function Game:drawObjectiveItemPrompt(item)
    love.graphics.setFont(self.uiFont)
    
    -- Normalize itemType to lowercase for case-insensitive matching
    local normalizedItemType = item.itemType:lower()
    
    -- If item has targetMap, show "Press E to enter"
    if item.targetMap then
        local itemNames = {
            duckroom = "Ducky's Room",
            duckyroom = "Ducky's Room",
            parentroom = "Parent's Room",
            momroom = "Mom's Room"
        }
        local roomName = itemNames[normalizedItemType] or "Room"
        self:drawTextWithShadow("Press E to enter " .. roomName, 50)
    else
        -- No targetMap, show interaction prompt
        local itemNames = {
            sink = "Check the Sink",
            pictureframe = "Pick up Picture Frame",
            food = "Get Food",
            lake = "Go to the Lake",
            journal = "Read the Journal"
        }
        local promptText = itemNames[normalizedItemType] or "Interact"
        self:drawTextWithShadow("Press E to " .. promptText, 50)
    end
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
    
    -- Play game-over sound effect
    if self.gameOverSound then
        self.gameOverSound:play()
    end
    
    -- Stop player movement sounds
    if self.player.walkingSound then
        self.player.walkingSound:stop()
    end
    if self.player.sprintSound then
        self.player.sprintSound:stop()
    end
    
    -- Get respawn position
    local respawnX, respawnY
    local currentMap = self.mapManager.currentMap
    
    print("DEBUG: Current map name: '" .. tostring(currentMap) .. "'")
    
    if currentMap == 'ashMap' then
        -- Use specific respawn point for ashMap
        print("DEBUG: Using ashMap respawn point")
        respawnX = 6
        respawnY = 1200
    elseif currentMap == 'whisperMap' and self.whisperMapEntryX and self.whisperMapEntryY then
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
        
        -- Ensure music is at correct volume after respawn
        self:switchMusic(currentMap)
        
        -- Fade back out to reveal the scene from respawn position
        transition:circularFadeOut(1.0, nil, respawnScreenX, respawnScreenY)
        self.isTransitioning = false
    end, caughtScreenX, caughtScreenY)
end

function Game:spawnRouteNPCs()
    if self.routeNPCsSpawned then return end
    
    print("DEBUG: Spawning dad and mistress NPCs at 2832, 1152")
    
    local world = self.mapManager:getWorld()
    local NPC = require('src.entities.NPC')
    
    -- Spawn Dad NPC
    -- NPC:new(x, y, spritePath, dialogueKey, name, movementType, moveDistance, moveSpeed, facingDirection, spriteFrame, world)
    local dadNPC = NPC:new(
        2832,
        1152,
        "assets/graphics/characters/dad-duckie-sprite-sheet.png",
        "father_route",
        "Father",
        0, -- movementType: stationary
        0, -- moveDistance
        0, -- moveSpeed
        "down", -- facingDirection
        {1, 1}, -- spriteFrame
        world -- world (last parameter)
    )
    table.insert(self.npcManager.npcs, dadNPC)
    
    -- Spawn Mistress NPC
    local mistressNPC = NPC:new(
        2832 + 60, -- Slightly offset from dad
        1152,
        "assets/graphics/characters/mistress-duckie-sprite-sheet.png",
        "mistress_route",
        "Mistress",
        0, -- movementType: stationary
        0, -- moveDistance
        0, -- moveSpeed
        "down", -- facingDirection
        {1, 1}, -- spriteFrame
        world -- world (last parameter)
    )
    table.insert(self.npcManager.npcs, mistressNPC)
    
    self.routeNPCsSpawned = true
    
    -- Trigger DialogueRoute1 scene1
    print("DEBUG: Starting DialogueRoute1 scene1")
    self:startDialogueRoute(DialogueRoute1, "scene1")
end

function Game:startDialogueRoute(routeModule, sceneKey)
    print("DEBUG: Starting dialogue route for " .. sceneKey)
    
    self.storyManager.isShowingDialogue = true
    
    self.storyManager.dialogueManager:startDialogueRoute(
        routeModule,
        sceneKey,
        function()
            -- On dialogue complete
            print("DEBUG: Dialogue route " .. sceneKey .. " completed")
            self.storyManager.isShowingDialogue = false
        end,
        function(choice)
            -- On choice made
            print("DEBUG: Choice made: " .. choice)
            self:handleRouteChoice(routeModule, sceneKey, choice)
        end
    )
end

function Game:handleRouteChoice(routeModule, sceneKey, choice)
    -- Route 1, Scene 1: ((Go with Dad)) or ((Find the last Ingredient))
    if routeModule == DialogueRoute1 and sceneKey == "scene1" then
        if choice == 1 then
            -- Go with Dad - Trigger Route1 Scene2, then Ending 1
            print("DEBUG: Choice 1 - Go with Dad")
            self:startDialogueRoute(DialogueRoute1, "scene2")
            -- After scene2, show ending 1
            self.storyManager.dialogueManager.onComplete = function()
                self:showEnding(1, "ENDING 1: LEAVING HOME")
            end
        else
            -- Find the last Ingredient - Trigger Route2 Scene1
            print("DEBUG: Choice 2 - Find the last Ingredient")
            self:startDialogueRoute(DialogueRoute2, "scene1")
        end
    -- Route 2, Scene 1: ((Trust Father's Words)) or ((Ignore Him))
    elseif routeModule == DialogueRoute2 and sceneKey == "scene1" then
        if choice == 1 then
            -- Trust Father's Words - Trigger Route2 Scene2, continue to end
            print("DEBUG: Choice 1 - Trust Father's Words")
            self:startDialogueRoute(DialogueRoute2, "scene2")
            -- Continue through all scenes in Route2
            self:continueRoute2Journey()
        else
            -- Ignore Him - Trigger Route3 Scene1, continue to end
            print("DEBUG: Choice 2 - Ignore Him")
            self:startDialogueRoute(DialogueRoute3, "scene1")
            -- Continue through all scenes in Route3
            self:continueRoute3Journey()
        end
    end
end

function Game:continueRoute2Journey()
    -- After scene2, continue the Route2 story sequence
    -- scene3 -> breadScene -> scene4 -> scene5 -> scene6 -> scene7 (Ending 2)
    local sceneSequence = {"scene3", "breadScene", "scene4", "scene5", "scene6", "scene7"}
    local currentIndex = 1
    
    local function playNextScene()
        if currentIndex <= #sceneSequence then
            local nextScene = sceneSequence[currentIndex]
            currentIndex = currentIndex + 1
            
            self.storyManager.dialogueManager:startDialogueRoute(
                DialogueRoute2,
                nextScene,
                function()
                    if nextScene == "scene7" then
                        -- Show Ending 2
                        self:showEnding(2, "ENDING 2: THE FALSE CURE")
                    else
                        playNextScene()
                    end
                end,
                nil
            )
        end
    end
    
    -- Start the sequence after scene2 completes
    self.storyManager.dialogueManager.onComplete = playNextScene
end

function Game:continueRoute3Journey()
    -- Continue through Route3 scenes: scene2 -> scene3 -> scene4 -> scene5 (Ending 3)
    local sceneSequence = {"scene2", "scene3", "scene4", "scene5"}
    local currentIndex = 1
    
    local function playNextScene()
        if currentIndex <= #sceneSequence then
            local nextScene = sceneSequence[currentIndex]
            currentIndex = currentIndex + 1
            
            self.storyManager.dialogueManager:startDialogueRoute(
                DialogueRoute3,
                nextScene,
                function()
                    if nextScene == "scene5" then
                        -- Show Ending 3
                        self:showEnding(3, "ENDING 3: THE TRUTH TOO LATE")
                    else
                        playNextScene()
                    end
                end,
                nil
            )
        end
    end
    
    -- Start the sequence after scene1 completes
    self.storyManager.dialogueManager.onComplete = playNextScene
end

function Game:showEnding(endingNumber, endingTitle)
    print("DEBUG: Showing ending " .. endingNumber .. ": " .. endingTitle)
    
    -- Stop all music
    if gameMusic then gameMusic:stop() end
    if houseMusic then houseMusic:stop() end
    if ashMapMusic then ashMapMusic:stop() end
    if whisperMapMusic then whisperMapMusic:stop() end
    
    -- Create and show ending screen
    self.endingScreen = EndingScreen:new()
    self.endingScreen:enter(endingNumber, endingTitle)
    self.showingEnding = true
    self.storyManager.isShowingDialogue = false
end

return Game

