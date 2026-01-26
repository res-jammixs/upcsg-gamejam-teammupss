local MapManager = {}

local sti = require 'lib/sti'
local wf = require 'lib/windfield'

function MapManager:new()
    local self = {
        currentMap = 'houseMap',
        currentMapObject = nil,
        world = nil,
        portals = {},
        walls = {}
    }
    return setmetatable(self, { __index = MapManager })
end

function MapManager:init()
    self:loadMap('houseMap')
end

function MapManager:loadMap(mapName)
    -- Clean up current world and colliders properly
    if self.world then
        self.world:destroy()
        self.world = nil
    end
    
    -- Extract just the map name (remove path and extension if included)
    local cleanMapName = mapName
    if mapName:find('/') then
        cleanMapName = mapName:gsub('.*/', '')
    end
    if cleanMapName:find('%.lua$') then
        cleanMapName = cleanMapName:gsub('%.lua$', '')
    end
    
    -- Load the new map
    self.currentMap = cleanMapName
    self.currentMapObject = sti('maps/' .. cleanMapName .. '.lua')
    self.world = wf.newWorld(0, 0)
    
    -- Load walls
    self:loadWalls()
    
    -- Load portals
    self:loadPortals()
end

function MapManager:loadWalls()
    self.walls = {}
    
    if self.currentMapObject.layers and self.currentMapObject.layers["Walls"] and self.currentMapObject.layers["Walls"].objects then
        local scale = 3
        local offsetX = -1037
        local offsetY = -750
        
        for i, obj in pairs(self.currentMapObject.layers["Walls"].objects) do
            local wallX = (obj.x * scale) + offsetX
            local wallY = (obj.y * scale) + offsetY
            local wallW = obj.width * scale
            local wallH = obj.height * scale

            local wall = self.world:newRectangleCollider(wallX, wallY, wallW, wallH)
            wall:setType('static')

            table.insert(self.walls, wall)
        end
    end
end

function MapManager:loadPortals()
    self.portals = {}
    
    if self.currentMapObject.layers and self.currentMapObject.layers["Portals"] and self.currentMapObject.layers["Portals"].objects then
        local scale = 3
        local offsetX = -1037
        local offsetY = -750
        
        for i, obj in pairs(self.currentMapObject.layers["Portals"].objects) do
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

function MapManager:checkPortalInteraction(playerX, playerY)
    for i, portal in ipairs(self.portals) do
        local interactionRange = 20
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

function MapManager:update(dt)
    if self.world then
        self.world:update(dt)
    end
end

function MapManager:draw()
    if self.currentMapObject then
        self.currentMapObject:draw(-345, -250, 3, 3)
    end
end

function MapManager:recreatePlayerCollider(player)
    if self.world and player then
        player.collider = self.world:newBSGRectangleCollider(player.x, player.y, 37, 30, 10)
        player.collider:setFixedRotation(true)
    end
end

function MapManager:getWorld()
    return self.world
end

function MapManager:getCurrentMap()
    return self.currentMap
end

return MapManager
