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
        objectiveItems = {},
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
            "whisperMap",
            "mazeMap"
        }
        ,
        -- Fog animation state (pixels)
        fogOffsetX = 0,
        fogOffsetY = 0,
        fogAnimTime = 0,
        fogAmplitudeX = 3, -- pixels
        fogAmplitudeY = 2, -- pixels
        fogSpeed = 0.8,
        -- Darkness shader for maze map
        darknessShader = nil,
        darknessCanvas = nil,
        -- Darkness fade state
        darknessActive = true,
        darknessFadeAmount = 1.0, -- 1.0 = full darkness, 0.0 = no darkness
        darknessFading = false,
        darknessFadeTime = 0,
        darknessFadeDuration = 3.0,
        -- Milkfish object
        milkfishObject = nil
    }
    return setmetatable(self, { __index = MapManager })
end

function MapManager:init()
    -- Create darkness shader for maze map
    self.darknessShader = love.graphics.newShader([[
        uniform vec2 playerPos;
        uniform float lightRadius;
        uniform float darknessFade; // 1.0 = full darkness, 0.0 = no darkness
        
        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
            // Calculate distance from player position to current pixel
            float dist = distance(screen_coords, playerPos);
            
            // Create smooth transition from visible to dark
            // At 60% of radius = fully visible (alpha = 0)
            // At 100% of radius = fully dark (alpha = 1)
            float visibleRadius = lightRadius * 0.6;
            float fadeStart = visibleRadius;
            float fadeEnd = lightRadius;
            
            // Calculate darkness alpha based on distance
            float alpha = 0.0;
            if (dist > fadeStart) {
                if (dist > fadeEnd) {
                    alpha = 1.0; // Completely dark
                } else {
                    // Smooth transition between fadeStart and fadeEnd
                    float t = (dist - fadeStart) / (fadeEnd - fadeStart);
                    // Use smoothstep for even smoother transition
                    alpha = smoothstep(0.0, 1.0, t);
                }
            }
            
            // Apply darkness with fade amount
            vec4 pixel = Texel(texture, texture_coords) * color;
            return mix(pixel, vec4(0.0, 0.0, 0.0, 1.0), alpha * darknessFade);
        }
    ]])
    
    -- Create canvas for rendering with darkness effect
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    self.darknessCanvas = love.graphics.newCanvas(width, height)
    
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
    
    -- Reset darkness state for maze map
    if cleanMapName == 'mazeMap' then
        self.darknessActive = true
        self.darknessFadeAmount = 1.0
        self.darknessFading = false
        self.darknessFadeTime = 0
    end
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
    
    -- Load objective items
    self:loadObjectiveItems()
    
    -- Load Milkfish object for maze map
    self:loadMilkfish()
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

function MapManager:loadMilkfish()
    self.milkfishObject = nil
    
    if self.currentMap ~= 'mazeMap' then
        return
    end
    
    if self.currentMapObject.layers and self.currentMapObject.layers["Milkfish"] and self.currentMapObject.layers["Milkfish"].objects then
        local scale = self:isOutdoorMap() and 3 or 3
        
        for i, obj in pairs(self.currentMapObject.layers["Milkfish"].objects) do
            local objX = (obj.x * scale)
            local objY = (obj.y * scale)
            local objW = obj.width * scale
            local objH = obj.height * scale
            
            self.milkfishObject = {
                x = objX,
                y = objY,
                width = objW,
                height = objH
            }
            break -- Only load the first Milkfish object
        end
    end
end

function MapManager:checkMilkfishInteraction(playerX, playerY)
    if not self.milkfishObject or self.currentMap ~= 'mazeMap' then
        return false
    end
    
    local interactionRange = 50
    local objCenterX = self.milkfishObject.x + self.milkfishObject.width / 2
    local objCenterY = self.milkfishObject.y + self.milkfishObject.height / 2
    
    local dist = math.sqrt(
        (playerX - objCenterX) ^ 2 + 
        (playerY - objCenterY) ^ 2
    )
    
    return dist < interactionRange + (math.max(self.milkfishObject.width, self.milkfishObject.height) / 2)
end

function MapManager:activateMilkfish()
    if self.currentMap == 'mazeMap' and not self.darknessFading and self.darknessActive then
        self.darknessFading = true
        self.darknessFadeTime = 0
    end
end

function MapManager:loadObjectiveItems()
    self.objectiveItems = {}
    
    if not self.currentMapObject or not self.currentMapObject.layers then
        return
    end
    
    local portalsLayer = self.currentMapObject.layers["Portals"]
    if not portalsLayer or not portalsLayer.objects then
        return
    end
    
    local scale = self:isOutdoorMap() and 3 or 3
    
    for i, obj in pairs(portalsLayer.objects) do
        -- Check if this object has an objectiveItem property
        if obj.properties and obj.properties.objectiveItem then
            local itemX = (obj.x * scale)
            local itemY = (obj.y * scale)
            local itemW = obj.width * scale
            local itemH = obj.height * scale
            
            table.insert(self.objectiveItems, {
                x = itemX,
                y = itemY,
                width = itemW,
                height = itemH,
                itemType = obj.properties.objectiveItem,
                targetMap = obj.properties.targetMap,
                spawnX = obj.properties.spawnX,
                spawnY = obj.properties.spawnY,
                collected = false
            })
        end
    end
end

function MapManager:checkObjectiveItemInteraction(playerX, playerY)
    if #self.objectiveItems == 0 then
        return nil
    end
    
    local interactionRange = 50
    
    for i, item in ipairs(self.objectiveItems) do
        if not item.collected then
            local itemCenterX = item.x + item.width / 2
            local itemCenterY = item.y + item.height / 2
            
            local dist = math.sqrt(
                (playerX - itemCenterX) ^ 2 + 
                (playerY - itemCenterY) ^ 2
            )
            
            if dist < interactionRange + (math.max(item.width, item.height) / 2) then
                return item
            end
        end
    end
    
    return nil
end

function MapManager:collectObjectiveItem(itemType)
    for i, item in ipairs(self.objectiveItems) do
        if item.itemType == itemType and not item.collected then
            item.collected = true
            return true
        end
    end
    return false
end

function MapManager:hideLayer(layerName)
    if not self.currentMapObject or not self.currentMapObject.layers then
        return
    end
    
    local layer = self.currentMapObject.layers[layerName]
    if layer then
        layer.visible = false
    end
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
    
    -- Update darkness fade for maze map
    if self.darknessFading then
        self.darknessFadeTime = self.darknessFadeTime + dt
        local progress = math.min(self.darknessFadeTime / self.darknessFadeDuration, 1.0)
        self.darknessFadeAmount = 1.0 - progress -- Fade from 1.0 to 0.0
        
        if progress >= 1.0 then
            self.darknessFading = false
            self.darknessActive = false
            self.darknessFadeAmount = 0.0
        end
    end
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
