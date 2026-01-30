local Enemy = require('src.entities.Enemy')

EnemyManager = {}

function EnemyManager:new()
    local self = {
        enemies = {},
        world = nil, -- Will be set when spawning
        spawnLocations = {
            -- frontyardMap is 64x48 tiles (16x16) with scale 3 = 3072x2304 pixels
            -- Walls are scaled too, so coordinates need to be * 3
            -- House walls are roughly at x: 377-692 * 3 = 1131-2076, y: 118-328 * 3 = 354-984
            -- Safe spawn areas (open yard, away from walls)
            frontyardMap = {
                {x = 300 * 3, y = 400 * 3},   -- Left side of yard (900, 1200)
                {x = 200 * 3, y = 300 * 3},   -- Upper left area (600, 900)
                {x = 250 * 3, y = 500 * 3},   -- Lower left area (750, 1500)
            }
        }
    }
    
    return setmetatable(self, { __index = EnemyManager })
end

function EnemyManager:init()
    -- Initialize empty, enemies will be spawned per map
end

function EnemyManager:spawnEnemy(x, y)
    local enemy = Enemy:new(x, y)
    enemy.initialX = x
    enemy.initialY = y
    table.insert(self.enemies, enemy)
    return enemy
end

function EnemyManager:spawnEnemiesForMap(mapName, world)
    -- Store world reference
    self.world = world
    
    -- Clear existing enemies (and their colliders)
    self:clearAllEnemies()
    
    -- Clean up the map name
    local cleanMapName = mapName
    if mapName:find('/') then
        cleanMapName = mapName:gsub('.*/', '')
    end
    if cleanMapName:find('%.lua$') then
        cleanMapName = cleanMapName:gsub('%.lua$', '')
    end
    
    -- Spawn enemies for specific maps
    if self.spawnLocations[cleanMapName] then
        for _, loc in ipairs(self.spawnLocations[cleanMapName]) do
            self:spawnEnemy(loc.x, loc.y)
        end
    end
end

function EnemyManager:update(dt, playerX, playerY)
    -- Update all enemies (iterate backwards to safely remove)
    for i = #self.enemies, 1, -1 do
        local enemy = self.enemies[i]
        if not enemy.removed then
            enemy:update(dt, playerX, playerY)
        else
            table.remove(self.enemies, i)
        end
    end
end

function EnemyManager:resetAllToInitialPositions()
    -- Reset all enemies to their initial spawn positions
    for _, enemy in ipairs(self.enemies) do
        if enemy.initialX and enemy.initialY then
            enemy.x = enemy.initialX
            enemy.y = enemy.initialY
            enemy.startX = enemy.initialX
            enemy.startY = enemy.initialY
            enemy.isChasing = false
            -- Reset patrol direction (randomize again)
            enemy.direction = (love.math.random() < 0.5) and 1 or -1
        end
    end
end

function EnemyManager:draw()
    -- Draw all enemies
    for i = 1, #self.enemies do
        local enemy = self.enemies[i]
        if not enemy.removed then
            enemy:draw()
        end
    end
end

function EnemyManager:clearAllEnemies()
    self.enemies = {}
end

function EnemyManager:removeLastEnemy()
    if #self.enemies > 0 then
        self.enemies[#self.enemies]:remove()
    end
end

function EnemyManager:getEnemyCount()
    local count = 0
    for i = 1, #self.enemies do
        if not self.enemies[i].removed then
            count = count + 1
        end
    end
    return count
end

function EnemyManager:checkPlayerCollision(playerX, playerY, playerWidth, playerHeight)
    for i = 1, #self.enemies do
        local enemy = self.enemies[i]
        if not enemy.removed and enemy:checkCollision(playerX, playerY, playerWidth, playerHeight) then
            return enemy
        end
    end
    return nil
end

return EnemyManager
