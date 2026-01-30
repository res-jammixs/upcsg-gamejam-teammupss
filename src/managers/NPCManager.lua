local NPC = require('src.entities.NPC')

NPCManager = {}

function NPCManager:new()
    local self = {
        npcs = {},
        world = nil, -- Will be set when spawning
        -- Define NPC spawn locations for each map
        spawnLocations = {
            intersectionMap = {
                {
                    x = 400, 
                    y = 600, 
                    sprite = "assets/graphics/characters/npc.png",
                    dialogueKey = "beakynpc",
                    name = "Beaky",
                    movementType = 1, -- 1 = horizontal (left-right)
                    moveDistance = 150,
                    moveSpeed = 50
                },
                {
                    x = 1500, 
                    y = 500, 
                    sprite = "assets/graphics/characters/flappy.png",
                    dialogueKey = "flappynpc",
                    name = "Flappy",
                    movementType = 0, -- 0 = stationary (idle)
                    moveDistance = 0,
                    moveSpeed = 0,
                    facingDirection = nil,
                    spriteFrame = {"1-4", 1} -- Animate all 4 frames in first row
                },
                {
                    x = 1600, 
                    y = 1000, 
                    sprite = "assets/graphics/characters/Mr.Feather.png",
                    dialogueKey = "mrfeathernpc",
                    name = "Mr. Feather",
                    movementType = 1, -- 1 = horizontal (left-right)
                    moveDistance = 200,
                    moveSpeed = 40                },
                {
                    x = 2000, 
                    y = 1450, 
                    sprite = "assets/graphics/characters/npc.png",
                    dialogueKey = "waddlenc",
                    name = "Waddle",
                    movementType = 1, -- 1 = horizontal (left-right)
                    moveDistance = 180,
                    moveSpeed = 45                }
            },
            -- Add more maps and NPCs here
            -- frontyardMap = {
            --     {x = 500, y = 400, sprite = "path/to/sprite.png", dialogueKey = "neighbor", name = "Neighbor"}
            -- }
        }
    }
    
    return setmetatable(self, { __index = NPCManager })
end

function NPCManager:init()
    -- Initialize empty, NPCs will be spawned per map
end

function NPCManager:spawnNPCsForMap(mapName, world)
    -- Store world reference
    self.world = world
    
    -- Clear existing NPCs (and their colliders)
    self:clearAllNPCs()
    
    -- Clean up the map name
    local cleanMapName = mapName
    if mapName:find('/') then
        cleanMapName = mapName:gsub('.*/', '')
    end
    if cleanMapName:find('%.lua$') then
        cleanMapName = cleanMapName:gsub('%.lua$', '')
    end
    
    -- Spawn NPCs for this map
    if self.spawnLocations[cleanMapName] then
        for _, npcData in ipairs(self.spawnLocations[cleanMapName]) do
            local npc = NPC:new(
                npcData.x,
                npcData.y,
                npcData.sprite,
                npcData.dialogueKey,
                npcData.name,
                npcData.movementType,
                npcData.moveDistance,
                npcData.moveSpeed,
                npcData.facingDirection,
                npcData.spriteFrame,
                world
            )
            table.insert(self.npcs, npc)
        end
    end
end

function NPCManager:update(dt, playerCollider)
    -- Update all NPCs, passing player collider for collision detection
    for _, npc in ipairs(self.npcs) do
        npc:update(dt, playerCollider)
    end
end

function NPCManager:draw()
    -- Draw all NPCs
    for _, npc in ipairs(self.npcs) do
        npc:draw()
    end
end

function NPCManager:checkPlayerInteraction(playerX, playerY)
    -- Check if player is near any NPC
    for _, npc in ipairs(self.npcs) do
        if npc:checkPlayerInteraction(playerX, playerY) then
            return npc
        end
    end
    return nil
end

function NPCManager:getNPCCount()
    return #self.npcs
end

function NPCManager:clearAllNPCs()
    -- Destroy all NPC colliders before clearing
    for _, npc in ipairs(self.npcs) do
        npc:destroy()
    end
    self.npcs = {}
end

return NPCManager
