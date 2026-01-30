local MapManager = {}

camera = require 'lib/camera'
local sti = require 'lib/sti'
local wf = require 'lib/windfield'

cam = camera()

function MapManager:new()
    local self = {
        currentMap = 'zoomedHouseMap', --original zoomedHouseMap
        currentMapObject = nil,
        world = nil,
        portals = {},
        walls = {},
        -- Classify maps as indoor or outdoor
        indoorMaps = {
            "zoomedHouseMap",
            "houseMap",
            "zoomedDuckroomMap",
            "duckyroomMap",
            "parentroomMap"
        },
        outdoorMaps = {
            "frontyardMap",
            "intersectionMap",
            "ashMap", 
            "whisperMap"
        }
        ,
        -- Fog animation state (pixels)
        fogOffsetX = 0,
        fogOffsetY = 0,
        fogAnimTime = 0,
        fogAmplitudeX = 3, -- pixels
        fogAmplitudeY = 2, -- pixels
        fogSpeed = 0.8
    }
    return setmetatable(self, { __index = MapManager })
end

function MapManager:init()
    self:loadMap('zoomedHouseMap') --original zoomedHouseMap
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
    -- Find index of Fog2 (if present) so we can draw it above the player
    self.fogStartIndex = nil
    if self.currentMapObject.layers then
        for i, layer in ipairs(self.currentMapObject.layers) do
            if layer and layer.name == "Fog2" then
                self.fogStartIndex = i
                break
            end
        end
    end
    
    -- Load walls
    self:loadWalls()
    
    -- Load portals
    self:loadPortals()
end

function MapManager:loadWalls()
    self.walls = {}
    
    if self.currentMapObject.layers and self.currentMapObject.layers["Walls"] and self.currentMapObject.layers["Walls"].objects then
        -- Use scale 5 for outdoor maps, 3 for indoor maps
        local scale = self:isOutdoorMap() and 3 or 3
       
        for i, obj in pairs(self.currentMapObject.layers["Walls"].objects) do
            local wallX = (obj.x * scale) 
            local wallY = (obj.y * scale) 
            local wallW = obj.width * scale
            local wallH = obj.height * scale

            -- Skip walls with invalid dimensions (too small or zero)
            if wallW > 0.1 and wallH > 0.1 then
                local wall = self.world:newRectangleCollider(wallX, wallY, wallW, wallH)
                wall:setType('static')
                table.insert(self.walls, wall)
            end
        end
    end
end
  
function MapManager:loadPortals()
    self.portals = {}
    
    if self.currentMapObject.layers and self.currentMapObject.layers["Portals"] and self.currentMapObject.layers["Portals"].objects then
        -- Use scale 5 for outdoor maps, 3 for indoor maps
        local scale = self:isOutdoorMap() and 3 or 3
        
        
        for i, obj in pairs(self.currentMapObject.layers["Portals"].objects) do
            local portalX = (obj.x * scale)
            local portalY = (obj.y * scale) 
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

function MapManager:getFirstSpawnPoint()
    -- Returns the first portal's spawn point, or nil if no portals with spawn exist
    for i, portal in ipairs(self.portals) do
        if portal.spawnX and portal.spawnY then
            return portal.spawnX, portal.spawnY
        end
    end
    return nil, nil
end

function MapManager:update(dt)
    if self.world then
        self.world:update(dt)
    end
    -- Update fog animation time and offsets
    self.fogAnimTime = (self.fogAnimTime or 0) + dt
    local s = self.fogSpeed or 0.8
    local ax = self.fogAmplitudeX or 3
    local ay = self.fogAmplitudeY or 2
    self.fogOffsetX = math.sin(self.fogAnimTime * s * 1.2) * ax
    self.fogOffsetY = math.cos(self.fogAnimTime * s * 0.9) * ay
end

function MapManager:isOutdoorMap()
    for _, mapName in ipairs(self.outdoorMaps) do
        if self.currentMap == mapName then
            return true
        end
    end
    return false
end

function MapManager:draw()  
    if self.currentMapObject then
        if self:isOutdoorMap() then
                -- Outdoor maps: draw each tile layer in the map's defined order
                love.graphics.push()
                love.graphics.scale(3, 3)

                -- Iterate the map's layers in their stored order and draw tile layers
                -- Stop before the Fog2 layer so we can render it after the player.
                for i, layer in ipairs(self.currentMapObject.layers) do
                    if layer and layer.type == "tilelayer" then
                        if self.fogStartIndex and i >= self.fogStartIndex then
                            break
                        end
                        self.currentMapObject:drawLayer(layer)
                    end
                end

                love.graphics.pop()
        else
            -- Indoor maps: draw normally with fixed offset
            self.currentMapObject:draw(0, 0, 3, 3)
        end
    end
end

-- Draw any layers that should appear above the player (e.g., Fog2)
function MapManager:drawAbovePlayer()
    if not self.currentMapObject then return end
    if not self:isOutdoorMap() then return end

    love.graphics.push()
    love.graphics.scale(3, 3)

    -- Apply a small translation to animate fog (offsets are in pixels; divide by scale)
    local dx = (self.fogOffsetX or 0) / 3
    local dy = (self.fogOffsetY or 0) / 3
    if dx ~= 0 or dy ~= 0 then
        love.graphics.translate(dx, dy)
    end

    local draw = false
    for i, layer in ipairs(self.currentMapObject.layers) do
        if layer and layer.type == "tilelayer" then
            if self.fogStartIndex and i >= self.fogStartIndex then
                draw = true
            end
            if draw then
                self.currentMapObject:drawLayer(layer)
            end
        end
    end

    love.graphics.pop()
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
