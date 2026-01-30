local Ashberry = require('src.entities.items.Ashberry')
local Milkfish = require('src.entities.items.Milkfish')
local WhisperWeed = require('src.entities.items.WhisperWeed')

local ItemManager = {}

function ItemManager:new()
    print("=== ITEM MANAGER INITIALIZED ===")
    local self = {
        items = {},
        collectedItems = {}, -- Persists across maps (tracks by ID)
        completionTriggered = false, -- Track if completion message shown
        
        -- Simple notification system (matches game.lua UI style)
        notification = {
            active = false,
            text = "",
            timer = 0,
            duration = 3, -- Show for 3 seconds
            font = nil
        },
        
        -- Define item spawn locations for each map
        spawnLocations = {
            ashMap = {
                -- 10 ash-berries for quest requirement
                {id = "ashberry_ash_01", class = Ashberry, x = 360, y = 28},
                {id = "ashberry_ash_02", class = Ashberry, x = 172, y = 2230},
                {id = "ashberry_ash_03", class = Ashberry, x = 1028, y = 2230},
                {id = "ashberry_ash_04", class = Ashberry, x = 920, y = 28},
                {id = "ashberry_ash_05", class = Ashberry, x = 1464, y = 28},
                {id = "ashberry_ash_06", class = Ashberry, x = 1970, y = 2245},
                {id = "ashberry_ash_07", class = Ashberry, x = 2850, y = 1095},
                {id = "ashberry_ash_08", class = Ashberry, x = 2775, y = 42 * 16 * 3},
                {id = "ashberry_ash_10", class = Ashberry, x = 1170, y = 1550},
                {id = "ashberry_ash_10", class = Ashberry, x = 38 * 16 * 3, y = 19 * 16 * 3},

            },
            whisperMap = {
                -- Quest items
                {id = "whisperweed_whisper_01", class = WhisperWeed, x = 58 * 16 * 3, y = 39 * 16 * 3},
            },
            mazeMap = {
                {id = "milkfish_maze_01", class = Milkfish, x = 32 * 16 * 3, y = 40 * 16 * 3},
            }
        }
    }
    
    return setmetatable(self, { __index = ItemManager })
end

function ItemManager:init()
    print("ItemManager:init() called - loading notification font")
    -- Load font for notifications (same as game.lua UI)
    local success, font = pcall(love.graphics.newFont, "assets/fonts/VT323-Regular.ttf", 24)
    if success then
        self.notification.font = font
        print("Successfully loaded notification font")
    else
        self.notification.font = love.graphics.newFont(24)
        print("Failed to load custom font, using default")
    end
end

function ItemManager:spawnItemsForMap(mapName, world)
    print("=== SPAWNING ITEMS FOR MAP: " .. mapName .. " ===")
    
    -- Clear current items
    self:clearAllItems()
    print("Cleared existing items")
    
    -- Clean up the map name
    local cleanMapName = mapName
    if mapName:find('/') then
        cleanMapName = cleanMapName:gsub('.*/', '')
    end
    if cleanMapName:find('%.lua$') then
        cleanMapName = cleanMapName:gsub('%.lua$', '')
    end
    print("Cleaned map name: " .. cleanMapName)
    
    -- Get spawn data for this map
    local spawnData = self.spawnLocations[cleanMapName]
    if not spawnData then
        print("No spawn data found for map: " .. cleanMapName)
        return
    end
    print("Found spawn data with " .. #spawnData .. " potential items")
    
    -- Spawn items that haven't been collected
    for _, data in ipairs(spawnData) do
        if not self.collectedItems[data.id] then
            print("Spawning item: " .. data.id .. " at (" .. data.x .. ", " .. data.y .. ")")
            local item = data.class:new(data.id, data.x, data.y)
            table.insert(self.items, item)
        else
            print("Skipping already collected item: " .. data.id)
        end
    end
    
    print("Spawned " .. #self.items .. " items for " .. cleanMapName)
    print("=== SPAWNING COMPLETE ===")
    print("")
end

function ItemManager:update(dt, playerCollider)
    -- Update items
    for i = #self.items, 1, -1 do
        local item = self.items[i]
        item:update(dt)
        
        -- Auto-collect if player collides (except Milkfish, which requires interaction)
        if playerCollider and item.type ~= "milkfish" then
            local playerX, playerY = playerCollider:getPosition()
            if item:checkCollision(playerX, playerY) then
                print("Item collision detected: " .. item.id .. " at position (" .. item.x .. ", " .. item.y .. ")")
                self:collectItem(item, i)
            end
        end
    end
    
    -- Update notification timer
    if self.notification.active then
        self.notification.timer = self.notification.timer + dt
        if self.notification.timer >= self.notification.duration then
            self.notification.active = false
        end
    end
end

function ItemManager:showNotification(text)
    self.notification.active = true
    self.notification.text = text
    self.notification.timer = 0
end

function ItemManager:checkNearbyItem(playerX, playerY)
    -- Check if player is near any item
    for _, item in ipairs(self.items) do
        if item:checkCollision(playerX, playerY) then
            return item
        end
    end
    return nil
end

function ItemManager:collectNearbyItem(playerX, playerY)
    -- Find and collect the nearest item
    for i = #self.items, 1, -1 do
        local item = self.items[i]
        
        if item:checkCollision(playerX, playerY) then
            self:collectItem(item, i)
            return true
        end
    end
    return false
end

function ItemManager:collectItem(item, index)
    print("=== ITEM COLLECTION START ===")
    print("Collecting item: " .. item.id .. " (type: " .. item.type .. ")")
    
    -- Mark as collected (persists across maps)
    self.collectedItems[item.id] = true
    print("Marked as collected in collectedItems table")
    
    -- Add to global inventory
    if not _G.inventory then
        _G.inventory = {}
        print("Created new global inventory table")
    end
    
    -- Only stack ash-berries, others are single pickup
    if item.canStack then
        local oldCount = _G.inventory[item.type] or 0
        _G.inventory[item.type] = oldCount + 1
        print("Stacked item - Old count: " .. oldCount .. ", New count: " .. _G.inventory[item.type])
    else
        -- Single pickup items stored as boolean
        _G.inventory[item.type] = true
        print("Single pickup item - Set to true in inventory")
    end
    
    -- Mark item as collected
    item:collect()
    print("Called item:collect() method")
    
    -- TODO: Play sound effect
    -- local collectSound = love.audio.newSource('assets/sounds/sfx/collect.wav', 'static')
    -- collectSound:play()
    
    -- Remove from active items
    table.remove(self.items, index)
    print("Removed item from active items list (was at index " .. index .. ")")
    
    -- Show notification based on item type
    if item.type == "ashberry" then
        local count = _G.inventory[item.type]
        if count == 10 then
            self:showNotification("Collected 10 Ash-berries! Quest item complete!")
            print("NOTIFICATION: Collected 10 Ash-berries! Quest item complete!")
        else
            self:showNotification("Collected Ash-berry (" .. count .. "/10)")
            print("NOTIFICATION: Collected Ash-berry (" .. count .. "/10)")
        end
        print("Collected: " .. item.id .. " | Total ashberries: " .. count)
    elseif item.type == "milkfish" then
        self:showNotification("Collected Milkfish! Quest item obtained!")
        print("NOTIFICATION: Collected Milkfish! Quest item obtained!")
        print("Collected: " .. item.id .. " | Milkfish (quest item)")
    elseif item.type == "whisperweed" then
        self:showNotification("Collected Whisper-weed! Quest item obtained!")
        print("NOTIFICATION: Collected Whisper-weed! Quest item obtained!")
        print("Collected: " .. item.id .. " | Whisper-weed (quest item)")
    end
    
    print("=== ITEM COLLECTION END ===")
    print("")
    
    -- Check for quest completion
    self:checkQuestCompletion()
end

function ItemManager:checkQuestCompletion()
    if self.completionTriggered then
        return false
    end
    
    if not _G.inventory then
        return false
    end
    
    -- Check if player has all required items
    local hasAshberries = (_G.inventory.ashberry or 0) >= 10
    local hasMilkfish = _G.inventory.milkfish == true
    local hasWhisperweed = _G.inventory.whisperweed == true
    
    if hasAshberries and hasMilkfish and hasWhisperweed then
        self.completionTriggered = true
        self:showNotification("QUEST COMPLETE! All items collected!")
        print("===========================================")
        print("QUEST COMPLETE!")
        print("You have collected:")
        print("  ✓ 10 Ash-berries")
        print("  ✓ Milkfish")
        print("  ✓ Whisper-weed")
        print("===========================================")
        return true
    end
    
    return false
end

function ItemManager:hasCompletedQuest()
    return self.completionTriggered
end

-- Simple text shadow helper (same as game.lua)
function ItemManager:drawTextWithShadow(text, y)
    local screenWidth = love.graphics.getWidth()
    
    -- Draw shadow
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.printf(text, 0, y + 2, screenWidth, "center")
    
    -- Draw main text
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(text, 0, y, screenWidth, "center")
end

function ItemManager:draw()
    -- Draw items (scaled with game world)
    for _, item in ipairs(self.items) do
        item:draw()
    end
end

function ItemManager:drawNotification()
    -- Draw notification OUTSIDE camera (fixed screen position, top-center)
    -- This should be called AFTER cam:detach() in game.lua
    if self.notification.active then
        love.graphics.setFont(self.notification.font)
        self:drawTextWithShadow(self.notification.text, 50) -- Below inventory (which is at y=20)
    end
end

function ItemManager:clearAllItems()
    -- Destroy all item colliders before clearing
    for _, item in ipairs(self.items) do
        if item.destroy then
            item:destroy()
        end
    end
    self.items = {}
end

function ItemManager:reset()
    -- Call this when returning to main menu
    self.collectedItems = {}
    self.items = {}
    self.completionTriggered = false
    self.notification.active = false
    if _G.inventory then
        _G.inventory = {}
    end
    print("ItemManager: Reset all collected items and inventory")
end

function ItemManager:getItemCount()
    return #self.items
end

return ItemManager