local InventoryUI = {}

function InventoryUI:new()
    local self = {
        icons = {},
        font = nil,
        padding = 10,
        iconSize = 32,
        -- Item display order
        itemOrder = {"ashberry", "milkfish", "whisperweed"}
    }
    
    return setmetatable(self, { __index = InventoryUI })
end

function InventoryUI:init()
    -- Load item icons
    local ashSuccess, ashSprite = pcall(love.graphics.newImage, 'assets/graphics/items/ash-berry.png')
    if ashSuccess then
        ashSprite:setFilter('nearest', 'nearest')
        self.icons.ashberry = ashSprite
    end
    
    local milkSuccess, milkSprite = pcall(love.graphics.newImage, 'assets/graphics/items/milkfish.png')
    if milkSuccess then
        milkSprite:setFilter('nearest', 'nearest')
        self.icons.milkfish = milkSprite
    else
        print("Warning: Could not load milkfish icon, using ash-berry as fallback")
        self.icons.milkfish = self.icons.ashberry
    end
    
    local weedSuccess, weedSprite = pcall(love.graphics.newImage, 'assets/graphics/items/whisper-weed.png')
    if weedSuccess then
        weedSprite:setFilter('nearest', 'nearest')
        self.icons.whisperweed = weedSprite
    else
        print("Warning: Could not load whisper-weed icon, using ash-berry as fallback")
        self.icons.whisperweed = self.icons.ashberry
    end
    
    -- Create font for item count
    self.font = love.graphics.newFont(20)
end

function InventoryUI:draw()
    if not _G.inventory then return end
    
    -- Draw HORIZONTALLY at TOP
    local x = 20
    local y = 20
    
    love.graphics.setFont(self.font)
    
    -- Draw each item type in defined order (horizontally)
    local offset = 0
    for _, itemType in ipairs(self.itemOrder) do
        local value = _G.inventory[itemType]
        
        -- Only draw if item exists in inventory
        if value then
            local icon = self.icons[itemType]
            if icon then
                -- Scale based on item type (ashberry is 16x16, others are 32x32)
                local iconScale = (itemType == "ashberry") and 2 or 1
                
                -- Draw icon
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.draw(icon, x + offset, y, 0, iconScale, iconScale)
                
                -- Draw count/indicator text with shadow
                if type(value) == "number" then
                    -- Ash-berry count (stackable items) with larger font
                    local largeFont = love.graphics.newFont(24)
                    love.graphics.setFont(largeFont)
                    
                    love.graphics.setColor(0, 0, 0, 0.7)
                    love.graphics.print("x" .. value, x + offset + 42, y + 6)
                    
                    love.graphics.setColor(1, 1, 1, 1)
                    love.graphics.print("x" .. value, x + offset + 40, y + 4)
                    
                    love.graphics.setFont(self.font)
                else
                    -- Quest items (single pickup) - show "x1" instead of checkmark
                    local largeFont = love.graphics.newFont(24)
                    love.graphics.setFont(largeFont)
                    
                    love.graphics.setColor(0, 0, 0, 0.7)
                    love.graphics.print("x1", x + offset + 42, y + 6)
                    
                    love.graphics.setColor(1, 1, 1, 1)
                    love.graphics.print("x1", x + offset + 40, y + 4)
                    
                    love.graphics.setFont(self.font)
                end
                
                offset = offset + 100 -- Horizontal spacing
            end
        end
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

return InventoryUI
