local WhisperWeed = {}

function WhisperWeed:new(id, x, y, world)
    local self = {
        id = id,
        type = "whisperweed",
        x = x,
        y = y,
        sprite = nil,
        scale = 1, -- 32x32 sprite
        hitboxRadius = 30,
        bobOffset = 0,
        bobSpeed = 2,
        bobTime = love.math.random() * math.pi * 2,
        canStack = false, -- Whisper-weed is single pickup (quest item)
        removed = false
    }
    
    -- Load whisper-weed sprite (32x32)
    local success, sprite = pcall(love.graphics.newImage, 'assets/graphics/items/whisper-weed.png')
    if success then
        sprite:setFilter('nearest', 'nearest')
        self.sprite = sprite
    else
        print("Warning: Could not load whisper-weed.png")
    end
    
    return setmetatable(self, { __index = WhisperWeed })
end

function WhisperWeed:update(dt, playerCollider)
    -- Bobbing animation only
    self.bobTime = self.bobTime + dt * self.bobSpeed
    self.bobOffset = math.sin(self.bobTime) * 5
end

function WhisperWeed:checkCollision(playerX, playerY)
    -- Player hitbox: width=37, height=51, offsetX=-19, offsetY=-35
    local playerHitboxX = playerX - 19
    local playerHitboxY = playerY - 35
    local playerHitboxW = 37
    local playerHitboxH = 51
    
    -- Calculate center of player hitbox
    local playerCenterX = playerHitboxX + playerHitboxW / 2
    local playerCenterY = playerHitboxY + playerHitboxH / 2
    
    -- Use current Y position with bobbing offset
    local itemY = self.y + self.bobOffset
    
    local dx = playerCenterX - self.x
    local dy = playerCenterY - itemY
    local distance = math.sqrt(dx * dx + dy * dy)
    
    return distance < self.hitboxRadius
end

function WhisperWeed:draw()
    if self.sprite and not self.removed then
        local drawY = self.y + self.bobOffset
        
        -- Draw interaction hitbox (circle) - cyan
        love.graphics.setColor(0, 1, 1, 0.3)
        love.graphics.circle("line", self.x, drawY, self.hitboxRadius)
        
        -- Draw sprite
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(
            self.sprite,
            self.x,
            drawY,
            0,
            self.scale,
            self.scale,
            self.sprite:getWidth() / 2,
            self.sprite:getHeight() / 2
        )
    end
end

function WhisperWeed:collect()
    self.removed = true
end

function WhisperWeed:destroy()
    -- No collider to destroy
end

return WhisperWeed