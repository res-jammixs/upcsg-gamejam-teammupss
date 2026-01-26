Game = {}

function Game:init()
    self.player = require('src.entities.Player'):new()

    sti = require 'lib/sti'
    self.currentMap = 'houseMap'
    houseMap = sti('maps/houseMap.lua')
    
    wf =  require'lib/windfield'
    houseWorld = wf.newWorld(0, 0)

    self.player.collider = houseWorld:newBSGRectangleCollider(self.player.x, self.player.y, 37, 30, 10)
    self.player.collider:setFixedRotation(true)
    
    local scale = 3
    local offsetX = -1037
    local offsetY = -750

    walls = {}
    if houseMap.layers and houseMap.layers["Walls"] and houseMap.layers["Walls"].objects then
        for i, obj in pairs(houseMap.layers["Walls"].objects) do
            local wallX = (obj.x * scale) + offsetX
            local wallY = (obj.y * scale) + offsetY
            local wallW = obj.width * scale
            local wallH = obj.height * scale

            local houseWall = houseWorld:newRectangleCollider(wallX, wallY, wallW, wallH)
            houseWall:setType('static')

            table.insert(walls, houseWall)
        end
    end

    -- Load portals from Portals layer
    self.portals = {}
    if houseMap.layers and houseMap.layers["Portals"] and houseMap.layers["Portals"].objects then
        for i, obj in pairs(houseMap.layers["Portals"].objects) do
            local portalX = (obj.x * scale) + offsetX
            local portalY = (obj.y * scale) + offsetY
            local portalW = obj.width * scale
            local portalH = obj.height * scale
            
            local targetMap = nil
            if obj.properties and obj.properties.targetMap then
                targetMap = obj.properties.targetMap:gsub('\n', '')
            end
            
            local spawnX = nil
            local spawnY = nil
            if obj.properties and obj.properties.spawnX then
                if type(obj.properties.spawnX) == "string" then
                    spawnX = tonumber(obj.properties.spawnX:gsub('\n', ''))
                else
                    spawnX = tonumber(obj.properties.spawnX)
                end
            end
            if obj.properties and obj.properties.spawnY then
                if type(obj.properties.spawnY) == "string" then
                    spawnY = tonumber(obj.properties.spawnY:gsub('\n', ''))
                else
                    spawnY = tonumber(obj.properties.spawnY)
                end
            end
            
            table.insert(self.portals, {
                x = portalX,
                y = portalY,
                width = portalW,
                height = portalH,
                targetMap = targetMap,
                spawnX = spawnX,
                spawnY = spawnY
            })
        end
    end
end

function Game:enter()
    self:init()
end

function Game:update(dt)
    self.player:update(dt)

    houseWorld:update(dt)

    self.player.x = self.player.collider:getX()-19
    self.player.y = self.player.collider:getY()-35
end

function Game:draw()
    houseMap:draw(-345, -250, 3, 3)

    love.graphics.push()
    love.graphics.scale(1, 1)
    self.player:draw()
    
    -- Show interaction prompt when near a portal
    local portal = self:checkPortalInteraction()
    if portal then
        love.graphics.setFont(love.graphics.newFont(16))
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf("Press F to interact", self.player.x - 60, self.player.y - 50, 120, "center")
    end
    
    love.graphics.pop()
end

function Game:keypressed(key)
    if key == 'f' or key == 'F' then
        self:interact()
    end
end

function Game:loadMap(mapName)
    -- Store player position before destroying
    local playerX = self.player.x
    local playerY = self.player.y
    
    -- Clean up current world and colliders properly
    if houseWorld then
        -- Destroy player collider first
        if self.player.collider then
            self.player.collider:destroy()
            self.player.collider = nil
        end
        -- Then destroy the world
        houseWorld:destroy()
        houseWorld = nil
    end
    
    self.currentMap = mapName
    houseMap = sti(mapName)
    houseWorld = wf.newWorld(0, 0)
    
    -- Create new collider in new world
    self.player.collider = houseWorld:newBSGRectangleCollider(playerX, playerY, 37, 30, 10)
    self.player.collider:setFixedRotation(true)
    
    local scale = 3
    local offsetX = -1037
    local offsetY = -750

    walls = {}
    if houseMap.layers and houseMap.layers["Walls"] and houseMap.layers["Walls"].objects then
        for i, obj in pairs(houseMap.layers["Walls"].objects) do
            local wallX = (obj.x * scale) + offsetX
            local wallY = (obj.y * scale) + offsetY
            local wallW = obj.width * scale
            local wallH = obj.height * scale

            local houseWall = houseWorld:newRectangleCollider(wallX, wallY, wallW, wallH)
            houseWall:setType('static')

            table.insert(walls, houseWall)
        end
    end

    -- Load portals from Portals layer
    self.portals = {}
    if houseMap.layers and houseMap.layers["Portals"] and houseMap.layers["Portals"].objects then
        for i, obj in pairs(houseMap.layers["Portals"].objects) do
            local portalX = (obj.x * scale) + offsetX
            local portalY = (obj.y * scale) + offsetY
            local portalW = obj.width * scale
            local portalH = obj.height * scale
            
            local targetMap = nil
            if obj.properties and obj.properties.targetMap then
                targetMap = obj.properties.targetMap:gsub('\n', '')
            end
            
            local spawnX = nil
            local spawnY = nil
            if obj.properties and obj.properties.spawnX then
                if type(obj.properties.spawnX) == "string" then
                    spawnX = tonumber(obj.properties.spawnX:gsub('\n', ''))
                else
                    spawnX = tonumber(obj.properties.spawnX)
                end
            end
            if obj.properties and obj.properties.spawnY then
                if type(obj.properties.spawnY) == "string" then
                    spawnY = tonumber(obj.properties.spawnY:gsub('\n', ''))
                else
                    spawnY = tonumber(obj.properties.spawnY)
                end
            end
            
            table.insert(self.portals, {
                x = portalX,
                y = portalY,
                width = portalW,
                height = portalH,
                targetMap = targetMap,
                spawnX = spawnX,
                spawnY = spawnY
            })
        end
    end
end

function Game:checkPortalInteraction()
    -- Check if player is near any portal
    local playerX = self.player.collider:getX()
    local playerY = self.player.collider:getY()
    
    for i, portal in ipairs(self.portals) do
        -- Check if player is within interaction range (slightly larger than portal)
        local interactionRange = 50
        local portalCenterX = portal.x + portal.width / 2
        local portalCenterY = portal.y + portal.height / 2
        
        local dist = math.sqrt(
            (playerX - portalCenterX) ^ 2 + 
            (playerY - portalCenterY) ^ 2
        )
        
        if dist < interactionRange + (math.max(portal.width, portal.height) / 2) then
            return portal
        end
    end
    return nil
end

function Game:interact()
    local portal = self:checkPortalInteraction()
    
    if portal then
        print("Interacting with portal! Target: " .. tostring(portal.targetMap))
        
        if portal.targetMap then
            -- Load the target map
            self:loadMap(portal.targetMap)
            
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
        end
    else
        print("No portal nearby to interact with!")
    end
end

return Game