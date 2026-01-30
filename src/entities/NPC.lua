NPC = {}

function NPC:new(x, y, spritePath, dialogueKey, name, movementType, moveDistance, moveSpeed, facingDirection, spriteFrame, world)
    local anim8 = require('lib.anim8')
    
    local self = {
        x = x,
        y = y,
        width = 36,  -- Default NPC width
        height = 54, -- Default NPC height
        sprite = nil,
        dialogueKey = dialogueKey or "testDialogue",
        name = name or "NPC",
        scale = 3, -- Sprite scale to match game scale
        interactionRadius = 60, -- How close player needs to be to interact
        animations = nil,
        currentAnim = facingDirection or 'down', -- Set facing direction (down=row1, left=row2, right=row3, up=row4)
        anim8 = anim8,
        animTimer = 0,
        animSpeed = 0.2,
        spriteFrame = spriteFrame, -- {column, row} for specific frame
        -- Movement properties
        movementType = movementType or 0, -- 0 = stationary, 1 = horizontal
        moveDistance = moveDistance or 150,
        moveSpeed = moveSpeed or 50,
        startX = x,
        startY = y,
        direction = 1, -- 1 = right/down, -1 = left/up
        -- Collision
        collider = nil
    }
    
    -- Load sprite if provided
    if spritePath then
        local success, result = pcall(love.graphics.newImage, spritePath)
        if success then
            self.sprite = result
            self.sprite:setFilter('nearest', 'nearest')
            
            -- Create animation grid (assuming same format as Duckie: 12x18 sprite frames)
            local grid = anim8.newGrid(12, 18, self.sprite:getWidth(), self.sprite:getHeight())
            
            -- If specific frame is provided, use only that frame
            if self.spriteFrame then
                local col, row = self.spriteFrame[1], self.spriteFrame[2]
                -- If col is a string like "1-4", animate the range; otherwise use single frame
                if type(col) == "string" then
                    self.animations = {
                        custom = anim8.newAnimation(grid(col, row), self.animSpeed)
                    }
                else
                    self.animations = {
                        custom = anim8.newAnimation(grid(col, row), self.animSpeed)
                    }
                end
                self.currentAnim = 'custom'
            else
                -- Create animations for all directions
                self.animations = {
                    down = anim8.newAnimation(grid('1-4', 1), self.animSpeed),   
                    left = anim8.newAnimation(grid('1-4', 2), self.animSpeed),   
                    right = anim8.newAnimation(grid('1-4', 3), self.animSpeed),   
                    up = anim8.newAnimation(grid('1-4', 4), self.animSpeed)
                }
            end
            
            -- Update dimensions based on sprite
            self.width = 12 * self.scale
            self.height = 18 * self.scale
        else
            print("Warning: Could not load NPC sprite: " .. spritePath)
        end
    end
    
    -- Create collider if world is provided
    if world then
        -- Create a collider similar to the player (rectangle collider)
        -- Using the sprite center as collider position
        local colliderX = self.x + (self.width / 2)
        local colliderY = self.y + (self.height / 2)
        local colliderW = self.width * 0.6
        local colliderH = self.height * 0.5
        self.collider = world:newBSGRectangleCollider(colliderX, colliderY, colliderW, colliderH, 10)
        self.collider:setFixedRotation(true)
        self.collider:setType('static') -- NPCs don't move by physics, we control their position
        
        -- Store collider dimensions for later use
        self.colliderWidth = colliderW
        self.colliderHeight = colliderH
    end
    
    return setmetatable(self, { __index = NPC })
end

function NPC:update(dt, playerCollider)
    -- Handle movement if NPC has movement type
    if self.movementType == 1 then -- Horizontal movement
        -- Move left or right
        local oldX = self.x
        self.x = self.x + (self.moveSpeed * self.direction * dt)
        
        -- Update collider position if it exists
        if self.collider then
            local colliderX = self.x + (self.width / 2)
            local colliderY = self.y + (self.height / 2)
            self.collider:setPosition(colliderX, colliderY)
        end
        
        -- Push player if they're in the way
        if playerCollider and self.collider then
            -- Check if NPC collider overlaps with player collider using AABB
            local npcX, npcY = self.collider:getPosition()
            local npcW, npcH = self.colliderWidth, self.colliderHeight
            local playerX, playerY = playerCollider:getPosition()
            -- Player collider is 37x30 (from game.lua)
            local playerW, playerH = 37, 30
            
            -- AABB collision check
            if npcX - npcW/2 < playerX + playerW/2 and
               npcX + npcW/2 > playerX - playerW/2 and
               npcY - npcH/2 < playerY + playerH/2 and
               npcY + npcH/2 > playerY - playerH/2 then
                -- Push player in the direction NPC is moving
                local pushForce = self.moveSpeed * self.direction * 1.5
                playerCollider:setPosition(playerX + pushForce * dt, playerY)
            end
        end
        
        -- Check if we've moved too far from start position
        if self.direction == 1 then
            self.currentAnim = 'right'
            if self.x >= self.startX + self.moveDistance then
                self.direction = -1
            end
        else
            self.currentAnim = 'left'
            if self.x <= self.startX - self.moveDistance then
                self.direction = 1
            end
        end
        
        -- Update animation for moving NPCs
        if self.animations then
            self.animations[self.currentAnim]:update(dt)
        end
    elseif self.spriteFrame then
        -- Stationary NPCs with custom frames should still animate
        if self.animations and self.animations[self.currentAnim] then
            self.animations[self.currentAnim]:update(dt)
        end
    end
    -- Stationary NPCs without custom frames stay idle with no animation update
end

function NPC:draw()
    if self.sprite and self.animations then
        love.graphics.setColor(1, 1, 1, 1)
        self.animations[self.currentAnim]:draw(self.sprite, self.x, self.y, nil, self.scale)
    else
        -- Draw a simple rectangle if no sprite
        love.graphics.setColor(0.3, 0.6, 0.9, 1)
        love.graphics.rectangle('fill', self.x, self.y, 36, 54)
        love.graphics.setColor(1, 1, 1, 1)
    end
end

function NPC:checkPlayerInteraction(playerX, playerY)
    -- Use exact player hitbox dimensions from Player.lua
    -- Player hitbox: width=37, height=51, offsetX=-19, offsetY=-35
    local playerHitboxX = playerX - 19
    local playerHitboxY = playerY - 35
    local playerHitboxW = 37
    local playerHitboxH = 51
    
    -- Calculate center of player hitbox
    local playerCenterX = playerHitboxX + playerHitboxW / 2
    local playerCenterY = playerHitboxY + playerHitboxH / 2
    
    -- Calculate center of NPC
    local npcCenterX = self.x + self.width / 2
    local npcCenterY = self.y + self.height / 2
    
    -- Calculate distance
    local dist = math.sqrt(
        (playerCenterX - npcCenterX) ^ 2 + 
        (playerCenterY - npcCenterY) ^ 2
    )
    
    return dist < self.interactionRadius
end

function NPC:destroy()
    -- Destroy the collider if it exists and has a valid body
    if self.collider and self.collider.body then
        self.collider:destroy()
        self.collider = nil
    end
end

return NPC
