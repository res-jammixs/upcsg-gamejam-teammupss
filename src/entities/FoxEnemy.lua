FoxEnemy = {}

-- Owl body hitbox (using owl sprite as placeholder)
local HITBOX = {
    offsetX = 1,
    offsetY = 0,
    width   = 85,
    height  = 74
}

function FoxEnemy:new(x, y, patrolWidth, patrolHeight, movementAxis, facingDirection, world, map, chaseAreaWidth, chaseAreaHeight)
    local anim8 = require('lib.anim8')
    local sprite = love.graphics.newImage('assets/graphics/enemies/fox-sprite-sheet.png')
    sprite:setFilter('nearest', 'nearest')
    
    -- Load fox sound
    local foxSound = love.audio.newSource('assets/sounds/sfx/fox-sound.mp3', 'static')
    foxSound:setVolume(0.3)
    foxSound:setLooping(true)
    
    -- Use exact same grid coordinates as BirdEnemy
    local gridLeft = anim8.newGrid(74, 62, sprite:getWidth(), sprite:getHeight(), 8, 1)    
    local gridRight = anim8.newGrid(78, 62, sprite:getWidth(), sprite:getHeight(), 1, 3)    
    
    local animations = {
        left = anim8.newAnimation(gridLeft('1-4', 1), 0.2),   
        right = anim8.newAnimation(gridRight('1-4', 3), 0.2)
    }
    
    -- movementAxis: 'horizontal' or 'vertical'
    -- facingDirection: 'left' or 'right' (only needed for vertical movement, since no top-down sprites)
    -- For horizontal movement, facing is determined automatically by movement direction
    
    -- Determine initial animation
    local initialAnim = 'right' -- Start facing right for horizontal (starts at left edge, moves right)
    if movementAxis == 'vertical' then
        initialAnim = 'right' -- Vertical starts at top moving down (progress 0, direction 1)
    end
    
    -- For horizontal, start at left edge and move right
    local initialPatrolDirection = 1
    local initialPatrolProgress = 0 -- Start at left edge (0)
    if movementAxis == 'vertical' then
        initialPatrolProgress = 0 -- Start at top edge
    end
    
    local self = {
        x = x,
        y = y,
        speed = 100,
        chaseSpeed = 200,
        returnSpeed = 100,
        removed = false,
        
        -- Rectangular patrol
        patrolWidth = patrolWidth or 200,
        patrolHeight = patrolHeight or 200,
        movementAxis = movementAxis or 'horizontal', -- 'horizontal' or 'vertical'
        facingDirection = facingDirection, -- 'left' or 'right' for sprite (only used for vertical movement)
        patrolProgress = initialPatrolProgress, -- 0 to 1, position along patrol path
        patrolDirection = initialPatrolDirection, -- 1 = forward, -1 = backward
        
        -- Spawn and area limits
        spawnX = x,
        spawnY = y,
        chaseAreaWidth = chaseAreaWidth or 400,
        chaseAreaHeight = chaseAreaHeight or 250,
    }
    
    -- Calculate initial position at patrol edge
    if movementAxis == 'horizontal' then
        self.x = x - (patrolWidth or 200) / 2 -- Start at left edge
    else
        self.y = y - (patrolHeight or 200) / 2 -- Start at top edge
    end
    
    self.sprite = sprite
    self.animations = animations
    self.currentAnim = initialAnim
    self.anim8 = anim8
    
    -- AI states
    self.detectionWidth = patrolWidth
    self.detectionHeight = patrolHeight
    self.detectionRadius = 200
    self.catchRadius = 50 -- Circular catch range radius
    self.visionConeAngle = math.pi / 2 -- 90 degree cone (45 degrees each side)
    self.state = 'patrol' -- 'patrol', 'chase', 'return'
    self.world = world -- Store world reference for collision checking
    self.map = map -- Store map reference for collision checking
    
    -- Sound
    self.foxSound = foxSound
    self.hasPlayedSound = false -- Track if sound has been played
    
    -- Debug: check if world was passed
    if not self.world then
        print("WARNING: FoxEnemy created without world reference!")
    else
        -- Test query to see if walls exist
        local testColliders = self.world:queryRectangleArea(0, 0, 1000, 1000)
        if testColliders then
            print("Fox can see", #testColliders, "colliders in world")
        else
            print("Fox world query returned nil")
        end
    end
    
    -- Animation memory for maintaining direction after chase
    self.chaseAnim = nil
    self.targetPatrolPoint = nil -- Store target return point on patrol line
    
    -- Afterimage effect during chase
    self.afterimages = {}
    self.afterimageTimer = 0
    self.afterimageInterval = 0.05
    
    return setmetatable(self, { __index = FoxEnemy })
end

function FoxEnemy:getPatrolPosition(progress)
    -- Returns x, y based on progress (0 to 1) along the patrol path
    if self.movementAxis == 'horizontal' then
        -- Move left and right
        local halfWidth = self.patrolWidth / 2
        return self.spawnX + (progress - 0.5) * self.patrolWidth, self.spawnY
    else
        -- Move up and down
        local halfHeight = self.patrolHeight / 2
        return self.spawnX, self.spawnY + (progress - 0.5) * self.patrolHeight
    end
end

function FoxEnemy:findNearestPointOnPatrolLine()
    -- Find the closest point on the patrol line to current position
    if self.movementAxis == 'horizontal' then
        -- Clamp x position to patrol line bounds
        local leftEdge = self.spawnX - self.patrolWidth / 2
        local rightEdge = self.spawnX + self.patrolWidth / 2
        local clampedX = math.max(leftEdge, math.min(rightEdge, self.x))
        
        -- Calculate progress (0 to 1) along the patrol line
        local progress = (clampedX - leftEdge) / self.patrolWidth
        
        return clampedX, self.spawnY, progress
    else
        -- Clamp y position to patrol line bounds
        local topEdge = self.spawnY - self.patrolHeight / 2
        local bottomEdge = self.spawnY + self.patrolHeight / 2
        local clampedY = math.max(topEdge, math.min(bottomEdge, self.y))
        
        -- Calculate progress (0 to 1) along the patrol line
        local progress = (clampedY - topEdge) / self.patrolHeight
        
        return self.spawnX, clampedY, progress
    end
end

function FoxEnemy:isPlayerInVisionCone(playerX, playerY)
    -- Player hitbox (from Player.lua HITBOX constant)
    local playerHitboxWidth = 39
    local playerHitboxHeight = 51
    local playerLeft = playerX - 19
    local playerRight = playerX + 20
    local playerTop = playerY - 35
    local playerBottom = playerY + 16
    
    -- Cone origin
    local centerX = self.x + 36
    local centerY = self.y + 40
    
    -- Vision cone direction based on current animation
    local facingAngle
    if self.currentAnim == 'right' then
        facingAngle = 0 -- Facing right (0 degrees)
    else
        facingAngle = math.pi -- Facing left (180 degrees)
    end
    
    -- Cone edges
    local coneStart = facingAngle - self.visionConeAngle / 2
    local coneEnd = facingAngle + self.visionConeAngle / 2
    
    -- Check if any corner of player hitbox is inside the cone
    local corners = {
        {playerLeft, playerTop},
        {playerRight, playerTop},
        {playerLeft, playerBottom},
        {playerRight, playerBottom}
    }
    
    for _, corner in ipairs(corners) do
        local dx = corner[1] - centerX
        local dy = corner[2] - centerY
        local dist = math.sqrt(dx * dx + dy * dy)
        
        -- Check if within detection radius
        if dist <= self.detectionRadius then
            local angleToCorner = math.atan2(dy, dx)
            
            -- Normalize angles
            local normalizedStart = coneStart
            local normalizedEnd = coneEnd
            local normalizedAngle = angleToCorner
            
            -- Handle angle wrapping
            while normalizedStart < -math.pi do normalizedStart = normalizedStart + 2 * math.pi end
            while normalizedStart > math.pi do normalizedStart = normalizedStart - 2 * math.pi end
            while normalizedEnd < -math.pi do normalizedEnd = normalizedEnd + 2 * math.pi end
            while normalizedEnd > math.pi do normalizedEnd = normalizedEnd - 2 * math.pi end
            while normalizedAngle < -math.pi do normalizedAngle = normalizedAngle + 2 * math.pi end
            while normalizedAngle > math.pi do normalizedAngle = normalizedAngle - 2 * math.pi end
            
            -- Check if angle is within cone
            if normalizedStart <= normalizedEnd then
                if normalizedAngle >= normalizedStart and normalizedAngle <= normalizedEnd then
                    return true
                end
            else
                -- Cone wraps around -pi/pi boundary
                if normalizedAngle >= normalizedStart or normalizedAngle <= normalizedEnd then
                    return true
                end
            end
        end
    end
    
    return false
end

function FoxEnemy:update(dt, playerX, playerY)
    if self.removed then return end
    
    -- Check distance from spawn point (using ellipse)
    local dx = self.x - self.spawnX
    local dy = self.y - self.spawnY
    -- Ellipse equation: (dx/radiusX)^2 + (dy/radiusY)^2 <= 1
    local radiusX = self.chaseAreaWidth / 2
    local radiusY = self.chaseAreaHeight / 2
    local normalizedDist = (dx / radiusX)^2 + (dy / radiusY)^2
    local outOfChaseArea = normalizedDist > 1
    
    -- Check distance to player
    local distToPlayer = math.sqrt((playerX - self.x)^2 + (playerY - self.y)^2)
    
    local vx = 0
    local vy = 0
    
    -- State machine
    if self.state == 'patrol' then
        -- Check if player is in vision cone
        if self:isPlayerInVisionCone(playerX, playerY) then
            self.state = 'chase'
            self.chaseAnim = nil
            
            -- Play fox sound when detecting player
            if self.foxSound and not self.foxSound:isPlaying() then
                self.foxSound:play()
            end
        else
            -- Move along patrol path
            local moveSpeed = self.speed / (self.movementAxis == 'horizontal' and self.patrolWidth or self.patrolHeight)
            self.patrolProgress = self.patrolProgress + (moveSpeed * self.patrolDirection * dt)
            
            -- Reverse direction at ends
            if self.patrolProgress >= 1 then
                self.patrolProgress = 1
                self.patrolDirection = -1
            elseif self.patrolProgress <= 0 then
                self.patrolProgress = 0
                self.patrolDirection = 1
            end
            
            -- Get target position
            local targetX, targetY = self:getPatrolPosition(self.patrolProgress)
            
            -- Move towards target position
            local dx = targetX - self.x
            local dy = targetY - self.y
            local dist = math.sqrt(dx * dx + dy * dy)
            
            if dist > 1 then
                vx = (dx / dist) * self.speed
                vy = (dy / dist) * self.speed
            end
            
            -- Update facing animation during patrol
            if self.movementAxis == 'horizontal' then
                -- For horizontal movement, face the direction of movement
                if self.patrolDirection > 0 then
                    self.currentAnim = 'right' -- Moving right
                else
                    self.currentAnim = 'left' -- Moving left
                end
            else
                -- For vertical movement: up = left, down = right
                if self.patrolDirection > 0 then
                    self.currentAnim = 'right' -- Moving down
                else
                    self.currentAnim = 'left' -- Moving up
                end
            end
        end
        
    elseif self.state == 'chase' then
        -- Check if out of chase area (rectangular boundary)
        if outOfChaseArea then
            self.state = 'return'
            self.chaseAnim = self.currentAnim
        elseif distToPlayer > self.detectionRadius * 1.5 then
            -- Lost player, return to patrol
            self.state = 'return'
            self.chaseAnim = self.currentAnim
            -- Stop fox sound when losing player
            if self.foxSound and self.foxSound:isPlaying() then
                self.foxSound:stop()
            end
        else
            -- Chase player
            local dx = playerX - self.x
            local dy = playerY - self.y
            local dist = math.sqrt(dx * dx + dy * dy)
            
            if dist > 1 then
                vx = (dx / dist) * self.chaseSpeed
                vy = (dy / dist) * self.chaseSpeed
            end
            
            -- Check for collision with walls using world colliders
            if self.world then
                local nextX = self.x + vx * dt
                local nextY = self.y + vy * dt
                
                -- Check collisions at the next position using world:queryRectangleArea
                local hbX = nextX + HITBOX.offsetX
                local hbY = nextY + HITBOX.offsetY
                local hbW = HITBOX.width
                local hbH = HITBOX.height
                
                -- Query for colliders in the next position area
                local colliders = self.world:queryRectangleArea(hbX, hbY, hbX + hbW, hbY + hbH)
                
                local hasCollision = false
                if colliders then
                    for _, collider in ipairs(colliders) do
                        -- Check if it's a wall (static collider, not the player or enemy)
                        if collider:getType() == 'static' then
                            hasCollision = true
                            print("Fox detected collision with wall at", nextX, nextY)
                            break
                        end
                    end
                end
                
                -- If collision detected, return to original spawn
                if hasCollision then
                    self.state = 'return'
                    self.chaseAnim = self.currentAnim
                    -- Set target to original spawn instead of nearest patrol point
                    self.targetPatrolPoint = {
                        x = self.spawnX - (self.movementAxis == 'horizontal' and self.patrolWidth / 2 or 0),
                        y = self.spawnY - (self.movementAxis == 'vertical' and self.patrolHeight / 2 or 0),
                        progress = 0
                    }
                    vx = 0
                    vy = 0
                end
            end
            
            -- Face the player direction
            -- For both horizontal and vertical: face left if player is to the left, right if to the right
            if dx > 0 then
                self.currentAnim = 'right'
            else
                self.currentAnim = 'left'
            end
            
            -- Create afterimages during chase
            self.afterimageTimer = self.afterimageTimer + dt
            if self.afterimageTimer >= self.afterimageInterval then
                self:createAfterimage()
                self.afterimageTimer = 0
            end
        end
        
    elseif self.state == 'return' then
        -- Return to nearest point on patrol line
        if not self.targetPatrolPoint then
            local pointX, pointY, progress = self:findNearestPointOnPatrolLine()
            self.targetPatrolPoint = {
                x = pointX,
                y = pointY,
                progress = progress
            }
        end
        
        local dx = self.targetPatrolPoint.x - self.x
        local dy = self.targetPatrolPoint.y - self.y
        local dist = math.sqrt(dx * dx + dy * dy)
        
        if dist < 10 then
            -- Reached target point on patrol line, resume patrol from this position
            self.x = self.targetPatrolPoint.x
            self.y = self.targetPatrolPoint.y
            self.state = 'patrol'
            -- Stop fox sound when returning to patrol
            if self.foxSound and self.foxSound:isPlaying() then
                self.foxSound:stop()
            end
            self.patrolProgress = self.targetPatrolPoint.progress
            -- Determine which direction to continue patrolling based on where we are on the line
            -- If we're closer to the left/top edge, move forward; if closer to right/bottom, move backward
            if self.targetPatrolPoint.progress < 0.5 then
                self.patrolDirection = 1 -- Move forward (right/down)
            else
                self.patrolDirection = -1 -- Move backward (left/up)
            end
            self.targetPatrolPoint = nil
            self.chaseAnim = nil
            self.returnDirection = nil
        else
            -- Move towards target point on patrol line
            vx = (dx / dist) * self.returnSpeed
            vy = (dy / dist) * self.returnSpeed
            
            -- Animate based on movement axis
            if self.movementAxis == 'horizontal' then
                -- Horizontal: face direction of movement
                if dx > 0 then
                    self.currentAnim = 'right'
                else
                    self.currentAnim = 'left'
                end
            else
                -- Vertical: use opposite of chase direction and maintain it
                if self.chaseAnim then
                    -- Use opposite of chase animation
                    self.currentAnim = (self.chaseAnim == 'left') and 'right' or 'left'
                else
                    -- Fallback: face based on horizontal return direction
                    if dx > 0 then
                        self.currentAnim = 'right'
                    else
                        self.currentAnim = 'left'
                    end
                end
            end
        end
    end
    
    -- Apply velocity to position
    self.x = self.x + vx * dt
    self.y = self.y + vy * dt
    
    -- Update animation
    self.animations[self.currentAnim]:update(dt)
    
    -- Update afterimages
    for i = #self.afterimages, 1, -1 do
        local afterimage = self.afterimages[i]
        afterimage.life = afterimage.life - dt
        afterimage.alpha = afterimage.life / 0.3
        
        if afterimage.life <= 0 then
            table.remove(self.afterimages, i)
        end
    end
end

function FoxEnemy:createAfterimage()
    table.insert(self.afterimages, {
        x = self.x,
        y = self.y,
        life = 0.3,
        alpha = 1,
        anim = self.currentAnim
    })
end

function FoxEnemy:draw()
    if self.removed then return end
    
    -- Draw afterimages first
    for _, afterimage in ipairs(self.afterimages) do
        love.graphics.setColor(1, 1, 1, afterimage.alpha * 0.5)
        self.animations[afterimage.anim]:draw(self.sprite, afterimage.x, afterimage.y, nil, 1.2)
    end
    
    -- Reset color and draw enemy
    love.graphics.setColor(1, 1, 1, 1)
    self.animations[self.currentAnim]:draw(self.sprite, self.x, self.y, nil, 1.2)

    -- Debug: Draw fox hitbox (74x62 like owl)
    love.graphics.setColor(1, 1, 0, 0.5)
    love.graphics.rectangle("line", self.x + HITBOX.offsetX, self.y + HITBOX.offsetY, HITBOX.width, HITBOX.height)
    love.graphics.setColor(1, 1, 1, 1)

    -- Debug: Draw spawn point and chase area (ellipse)
    love.graphics.setColor(0, 0, 1, 0.2)
    local centerX = self.spawnX + 36
    local centerY = self.spawnY + 40
    love.graphics.ellipse("line", centerX, centerY, self.chaseAreaWidth / 2, self.chaseAreaHeight / 2)
    
    -- Debug: Draw patrol path (line)
    love.graphics.setColor(0, 1, 1, 0.5)
    if self.movementAxis == 'horizontal' then
        local y = self.spawnY + 40
        love.graphics.line(
            self.spawnX - self.patrolWidth / 2 + 36, y,
            self.spawnX + self.patrolWidth / 2 + 36, y
        )
    else
        local x = self.spawnX + 36
        love.graphics.line(
            x, self.spawnY - self.patrolHeight / 2 + 40,
            x, self.spawnY + self.patrolHeight / 2 + 40
        )
    end
    
    -- Debug: Draw vision cone
    love.graphics.setColor(1, 0, 0, 0.3)
    local detectionCenterX = self.x + 36
    local detectionCenterY = self.y + 40
    
    -- Vision cone direction based on current animation
    local facingAngle
    if self.currentAnim == 'right' then
        facingAngle = 0
    else
        facingAngle = math.pi
    end
    
    -- Draw cone
    local coneStart = facingAngle - self.visionConeAngle / 2
    local coneEnd = facingAngle + self.visionConeAngle / 2
    local segments = 20
    
    love.graphics.polygon("line", 
        detectionCenterX, detectionCenterY,
        detectionCenterX + math.cos(coneStart) * self.detectionRadius, detectionCenterY + math.sin(coneStart) * self.detectionRadius,
        detectionCenterX + math.cos(coneEnd) * self.detectionRadius, detectionCenterY + math.sin(coneEnd) * self.detectionRadius
    )
    
    -- Draw arc
    for i = 0, segments do
        local angle = coneStart + (coneEnd - coneStart) * (i / segments)
        local x1 = detectionCenterX + math.cos(angle) * self.detectionRadius
        local y1 = detectionCenterY + math.sin(angle) * self.detectionRadius
        if i > 0 then
            local prevAngle = coneStart + (coneEnd - coneStart) * ((i-1) / segments)
            local x0 = detectionCenterX + math.cos(prevAngle) * self.detectionRadius
            local y0 = detectionCenterY + math.sin(prevAngle) * self.detectionRadius
            love.graphics.line(x0, y0, x1, y1)
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function FoxEnemy:remove()
    self.removed = true
end

function FoxEnemy:checkCollision(playerX, playerY, playerWidth, playerHeight)
    -- Use rectangular AABB collision (same as BirdEnemy)
    local hbX = self.x + HITBOX.offsetX
    local hbY = self.y + HITBOX.offsetY
    local hbW = HITBOX.width
    local hbH = HITBOX.height

    return hbX < playerX + playerWidth and
           hbX + hbW > playerX and
           hbY < playerY + playerHeight and
           hbY + hbH > playerY
end

return FoxEnemy
