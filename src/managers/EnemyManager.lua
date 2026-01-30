local BirdEnemy = require('src.entities.BirdEnemy')
local FoxEnemy = require('src.entities.FoxEnemy')

EnemyManager = {}

function EnemyManager:new()
    local self = {
        enemies = {},
        world = nil, -- Will be set when spawning
        map = nil, -- Will be set when spawning
        spawnLocations = {
            whisperMap = {
                birds = { -- 8 31
                    {x = 47 * 16 * 3, y = 11 * 16 * 3, patrolRadius = 180, clockwise = true},  
                    {x = 25 * 16 * 3, y = 8 * 16 * 3, patrolRadius = 180, clockwise = false}, 
                    {x = 20 * 16 * 3, y = 22 * 16 * 3, patrolRadius = 180, clockwise = true}, 
                    {x = 7 * 16 * 3, y = 17 * 16 * 3, patrolRadius = 180, clockwise = false}, 
                    {x = 42 * 16 * 3, y = 33 * 16 * 3, patrolRadius = 180, clockwise = true},
                    {x = 35 * 16 * 3, y = 23 * 16 * 3, patrolRadius = 180, clockwise = false},
                    {x = 8 * 16 * 3, y = 31 * 16 * 3, patrolRadius = 180, clockwise = true}, 
                    {x = 30 * 16 * 3, y = 44 * 16 * 3, patrolRadius = 180, clockwise = false},
                    {x = 37 * 16 * 3, y = 2 * 16 * 3, patrolRadius = 180, clockwise = true},
                    {x = 19 * 16 * 3, y = 34 * 16 * 3, patrolRadius = 180, clockwise = false}
                }
            },
            ashMap = {
                foxes = {
                    {x = 9 * 16 * 3, y = 19 * 16 * 3, patrolWidth = 250, patrolHeight = 50, movementAxis = 'horizontal', chaseAreaWidth = 400, chaseAreaHeight = 300},
                    {x = 24 * 16 * 3, y = 4 * 16 * 3, patrolWidth = 50, patrolHeight = 250, movementAxis = 'vertical', chaseAreaWidth = 250, chaseAreaHeight = 350},
                    {x = 11 * 16 * 3, y = 41 * 16 * 3, patrolWidth = 200, patrolHeight = 50, movementAxis = 'horizontal', chaseAreaWidth = 300, chaseAreaHeight = 200},
                    {x = 32 * 16 * 3, y = 17 * 16 * 3, patrolWidth = 50, patrolHeight = 250, movementAxis = 'vertical', chaseAreaWidth = 200, chaseAreaHeight = 500},
                    {x = 37 * 16 * 3, y = 44 * 16 * 3, patrolWidth = 50, patrolHeight = 200, movementAxis = 'vertical', chaseAreaWidth = 200, chaseAreaHeight = 300},
                    {x = 44 * 16 * 3, y = 22 * 16 * 3, patrolWidth = 250, patrolHeight = 50, movementAxis = 'horizontal', chaseAreaWidth = 600, chaseAreaHeight = 300},
                    {x = 50 * 16 * 3, y = 34 * 16 * 3, patrolWidth = 50, patrolHeight = 250, movementAxis = 'vertical', chaseAreaWidth = 250, chaseAreaHeight = 350},
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

function EnemyManager:spawnFoxEnemy(x, y, patrolWidth, patrolHeight, movementAxis, facingDirection, chaseAreaWidth, chaseAreaHeight)
    local enemy = FoxEnemy:new(x, y, patrolWidth, patrolHeight, movementAxis, facingDirection, self.world, self.map, chaseAreaWidth, chaseAreaHeight)
    enemy.initialX = x
    enemy.initialY = y
    table.insert(self.enemies, enemy)
    return enemy
end

function EnemyManager:spawnEnemiesForMap(mapName, world, map)
    -- Store world and map references
    self.world = world
    self.map = map
    
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
        
        -- Spawn fox enemies
        if self.spawnLocations[cleanMapName].foxes then
            for _, loc in ipairs(self.spawnLocations[cleanMapName].foxes) do
                self:spawnFoxEnemy(loc.x, loc.y, loc.patrolWidth, loc.patrolHeight, loc.movementAxis, loc.facingDirection, loc.chaseAreaWidth, loc.chaseAreaHeight)
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
            -- For bird enemies, calculate the position on the circle using initial angle
            if enemy.initialPatrolAngle and enemy.patrolRadius then
                enemy.patrolAngle = enemy.initialPatrolAngle
                enemy.x = enemy.spawnX + math.cos(enemy.initialPatrolAngle) * enemy.patrolRadius
                enemy.y = enemy.spawnY + math.sin(enemy.initialPatrolAngle) * enemy.patrolRadius
            else
                -- For other enemies (foxes), reset to spawn position directly
                enemy.x = enemy.spawnX
                enemy.y = enemy.spawnY
            end
            
            enemy.state = 'patrol'
            
            -- Stop enemy sounds if playing
            if enemy.owlSound and enemy.owlSound:isPlaying() then
                enemy.owlSound:stop()
            end
            if enemy.foxSound and enemy.foxSound:isPlaying() then
                enemy.foxSound:stop()
            end
            
            -- Reset fox-specific properties
            if enemy.patrolProgress then
                enemy.patrolProgress = 0.5
                enemy.patrolDirection = 1
            end
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
