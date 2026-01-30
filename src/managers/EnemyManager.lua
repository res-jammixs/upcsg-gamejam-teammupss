local BirdEnemy = require('src.entities.BirdEnemy')

EnemyManager = {}

function EnemyManager:new()
    local self = {
        enemies = {},
        world = nil, -- Will be set when spawning
        spawnLocations = {
            whisperMap = {
                birds = {
                    {x = 47 * 16 * 3, y = 11 * 16 * 3, patrolRadius = 150, clockwise = true},  
                    {x = 25 * 16 * 3, y = 8 * 16 * 3, patrolRadius = 150, clockwise = false}, 
                    {x = 8 * 16 * 3, y = 18 * 16 * 3, patrolRadius = 180, clockwise = true}, 
                    {x = 21 * 16 * 3, y = 32 * 16 * 3, patrolRadius = 180, clockwise = false}, 
                    {x = 42 * 16 * 3, y = 33 * 16 * 3, patrolRadius = 180, clockwise = true}
                }
            }
        }
    }
    
    return setmetatable(self, { __index = EnemyManager })
end

function EnemyManager:init()
    -- Initialize empty, enemies will be spawned per map
end

function EnemyManager:spawnBirdEnemy(x, y, patrolRadius, allPatrolPoints, clockwise)
    local enemy = BirdEnemy:new(x, y, patrolRadius, allPatrolPoints, clockwise)
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
        -- Spawn bird enemies
        if self.spawnLocations[cleanMapName].birds then
            local allPatrolPoints = {}
            
            -- Collect all patrol points for this map
            for _, loc in ipairs(self.spawnLocations[cleanMapName].birds) do
                table.insert(allPatrolPoints, {x = loc.x, y = loc.y, radius = loc.patrolRadius})
            end
            
            -- Spawn each bird with knowledge of all patrol points
            for _, loc in ipairs(self.spawnLocations[cleanMapName].birds) do
                self:spawnBirdEnemy(loc.x, loc.y, loc.patrolRadius, allPatrolPoints, loc.clockwise)
            end
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
        if enemy.spawnX and enemy.spawnY then
            enemy.x = enemy.spawnX
            enemy.y = enemy.spawnY
            enemy.state = 'patrol'
            enemy.patrolAngle = 0
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
