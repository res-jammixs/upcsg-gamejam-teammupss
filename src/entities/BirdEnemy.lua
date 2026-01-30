BirdEnemy = {}

-- Owl body hitbox (ignores wings)
local HITBOX = {
    offsetX = 0,
    offsetY = 0,
    width   = 95,
    height  = 78
}

function BirdEnemy:new(x, y, patrolRadius, allPatrolPoints, clockwise)
    local anim8 = require('lib.anim8')
    local sprite = love.graphics.newImage('assets/graphics/enemies/owl-sprite-sheet.png')
    sprite:setFilter('nearest', 'nearest')
    
    -- Load owl sound
    local owlSound = love.audio.newSource('assets/sounds/sfx/owl-sound.mp3', 'static')
    owlSound:setVolume(0.3)
    owlSound:setLooping(true)
    
    local gridLeft = anim8.newGrid(74, 62, sprite:getWidth(), sprite:getHeight(), 8, 1)    
    local gridRight = anim8.newGrid(78, 62, sprite:getWidth(), sprite:getHeight(), 1, 3)    
    
    local animations = {
        left = anim8.newAnimation(gridLeft('1-4', 1), 0.2),   
        right = anim8.newAnimation(gridRight('1-4', 3), 0.2)
    }
    
    -- Determine patrol direction: clockwise (negative) or counter-clockwise (positive)
    local patrolSpeedValue = (clockwise == false) and 0.5 or -0.5
    
    -- Start at a random angle on the circle to avoid all owls starting at the same position
    local startAngle = math.random() * 2 * math.pi
    local startRadius = patrolRadius or 150
    local startX = x + math.cos(startAngle) * startRadius
    local startY = y + math.sin(startAngle) * startRadius
    
    local self = {
        x = startX,
        y = startY,
        speed = 100,
        chaseSpeed = 200, -- Original balanced chase speed
        returnSpeed = 100,
        removed = false,
        
        -- Circular patrol
        patrolRadius = startRadius,
        patrolAngle = startAngle, -- Start at top of circle
        initialPatrolAngle = startAngle, -- Store initial angle for respawn
        patrolSpeed = patrolSpeedValue, -- Radians per second for patrol rotation
        
        -- Spawn and area limits
        spawnX = x,
        spawnY = y,
        chaseAreaRadius = 300,
        
        -- All patrol points (cyan circles) in the map
        allPatrolPoints = allPatrolPoints or {{x = x, y = y, radius = patrolRadius}},
        targetPatrolPoint = nil,
        
        sprite = sprite,
        animations = animations,
        currentAnim = 'right',
        anim8 = anim8,
        
        -- Sound
        owlSound = owlSound,
        hasPlayedSound = false, -- Track if sound has been played this chase
        
        -- AI states
        detectionRadius = 200,
        visionConeAngle = math.pi / 2, -- 90 degree cone (45 degrees each side)
        state = 'patrol', -- 'patrol', 'chase', 'return'
        
        -- Animation memory for maintaining direction after chase
        chaseAnim = nil, -- Stores the animation used during chase
        
        -- Afterimage effect during chase (matches player settings)
        afterimages = {},
        afterimageTimer = 0,
        afterimageInterval = 0.05, -- Create afterimage every 0.05 seconds
    }
    
    return setmetatable(self, { __index = BirdEnemy })
end

function BirdEnemy:findNearestPatrolPoint()
    local nearestPoint = self.allPatrolPoints[1]
    local nearestDist = math.huge
    
    for _, point in ipairs(self.allPatrolPoints) do
        local dist = math.sqrt((self.x - point.x)^2 + (self.y - point.y)^2)
        if dist < nearestDist then
            nearestDist = dist
            nearestPoint = point
        end
    end
    
    return nearestPoint
end

function BirdEnemy:findNearestPointOnCircle(centerX, centerY, radius)
    -- Calculate angle from center to current position
    local dx = self.x - centerX
    local dy = self.y - centerY
    local angle = math.atan2(dy, dx)
    
    -- Calculate the point on the circle at that angle
    local pointX = centerX + math.cos(angle) * radius
    local pointY = centerY + math.sin(angle) * radius
    
    return pointX, pointY, angle
end

function BirdEnemy:isPlayerInVisionCone(playerX, playerY)
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
    
    -- Vision cone direction based on patrol direction
    -- Clockwise (negative speed): tangent is patrolAngle - π/2
    -- Counter-clockwise (positive speed): tangent is patrolAngle + π/2
    local facingAngle
    if self.patrolSpeed < 0 then
        facingAngle = self.patrolAngle - math.pi / 2  -- Clockwise
    else
        facingAngle = self.patrolAngle + math.pi / 2  -- Counter-clockwise
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

function BirdEnemy:update(dt, playerX, playerY)
    if self.removed then return end
    
    -- Check distance from spawn point
    local distFromSpawn = math.sqrt((self.x - self.spawnX)^2 + (self.y - self.spawnY)^2)
    
    -- Check distance to player
    local distToPlayer = math.sqrt((playerX - self.x)^2 + (playerY - self.y)^2)
    
    local vx = 0
    local vy = 0
    
    -- State machine
    if self.state == 'patrol' then
        -- Check if player is in vision cone
        if self:isPlayerInVisionCone(playerX, playerY) then
            self.state = 'chase'
            self.chaseAnim = nil -- Reset chase animation memory
            
            -- Play owl sound when detecting player
            if self.owlSound and not self.owlSound:isPlaying() then
                self.owlSound:play()
            end
        else
            -- Circular patrol movement
            self.patrolAngle = self.patrolAngle + self.patrolSpeed * dt
            if self.patrolAngle > 2 * math.pi then
                self.patrolAngle = self.patrolAngle - 2 * math.pi
            end
            
            -- Calculate target position on circle
            local targetX = self.spawnX + math.cos(self.patrolAngle) * self.patrolRadius
            local targetY = self.spawnY + math.sin(self.patrolAngle) * self.patrolRadius
            
            -- Move towards target position
            local dx = targetX - self.x
            local dy = targetY - self.y
            local dist = math.sqrt(dx * dx + dy * dy)
            
            if dist > 1 then
                vx = (dx / dist) * self.speed
                vy = (dy / dist) * self.speed
            end
            
            -- Update animation based on circular position only if no chase animation memory
            if not self.chaseAnim then
                self:updateCircularAnimation()
            else
                -- Use the chase animation until we cross the diagonal boundary
                self.currentAnim = self.chaseAnim
                
                -- Check if we've crossed to the opposite diagonal half
                local expectedAnim = self:getCircularAnimation()
                if expectedAnim ~= self.chaseAnim then
                    -- Crossed boundary, reverse animation
                    self.chaseAnim = nil
                    self:updateCircularAnimation()
                end
            end
        end
        
    elseif self.state == 'chase' then
        -- Check if out of chase area
        if distFromSpawn > self.chaseAreaRadius then
            self.state = 'return'
            -- Stop owl sound when leaving chase area
            if self.owlSound and self.owlSound:isPlaying() then
                self.owlSound:stop()
            end
            self.chaseAnim = self.currentAnim -- Remember the animation from chase
            local nearestPatrol = self:findNearestPatrolPoint()
            local pointX, pointY, angle = self:findNearestPointOnCircle(nearestPatrol.x, nearestPatrol.y, nearestPatrol.radius)
            self.targetPatrolPoint = {
                center = nearestPatrol,
                x = pointX,
                y = pointY,
                angle = angle
            }
        elseif distToPlayer > self.detectionRadius * 1.5 then
            -- Lost player, return to patrol
            self.state = 'return'
            -- Stop owl sound when losing player
            if self.owlSound and self.owlSound:isPlaying() then
                self.owlSound:stop()
            end
            self.chaseAnim = self.currentAnim -- Remember the animation from chase
            local nearestPatrol = self:findNearestPatrolPoint()
            local pointX, pointY, angle = self:findNearestPointOnCircle(nearestPatrol.x, nearestPatrol.y, nearestPatrol.radius)
            self.targetPatrolPoint = {
                center = nearestPatrol,
                x = pointX,
                y = pointY,
                angle = angle
            }
        else
            -- Chase player
            local dx = playerX - self.x
            local dy = playerY - self.y
            local dist = math.sqrt(dx * dx + dy * dy)
            
            if dist > 1 then
                vx = (dx / dist) * self.chaseSpeed
                vy = (dy / dist) * self.chaseSpeed
            end
            
            -- Face the player direction
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
        -- Return to nearest point on patrol circle
        if not self.targetPatrolPoint then
            local nearestPatrol = self:findNearestPatrolPoint()
            local pointX, pointY, angle = self:findNearestPointOnCircle(nearestPatrol.x, nearestPatrol.y, nearestPatrol.radius)
            self.targetPatrolPoint = {
                center = nearestPatrol,
                x = pointX,
                y = pointY,
                angle = angle
            }
        end
        
        local dx = self.targetPatrolPoint.x - self.x
        local dy = self.targetPatrolPoint.y - self.y
        local dist = math.sqrt(dx * dx + dy * dy)
        
        if dist < 10 then
            -- Reached target point on patrol circle, resume patrol from this angle
            self.spawnX = self.targetPatrolPoint.center.x
            self.spawnY = self.targetPatrolPoint.center.y
            self.patrolRadius = self.targetPatrolPoint.center.radius
            self.x = self.targetPatrolPoint.x
            self.y = self.targetPatrolPoint.y
            self.state = 'patrol'
            -- Continue patrol from the angle where we rejoined the circle
            self.patrolAngle = self.targetPatrolPoint.angle
            -- Keep the chase animation memory so it continues with the same direction
            self.targetPatrolPoint = nil
        else
            -- Move towards target point on circle
            vx = (dx / dist) * self.returnSpeed
            vy = (dy / dist) * self.returnSpeed
            
            -- Animate based on the direction it's moving back
            if dx > 0 then
                self.currentAnim = 'right'
                self.chaseAnim = 'right' -- Update chase memory
            else
                self.currentAnim = 'left'
                self.chaseAnim = 'left' -- Update chase memory
            end
        end
    end
    
    -- Apply velocity to position
    self.x = self.x + vx * dt
    self.y = self.y + vy * dt
    
    -- Update animation
    self.animations[self.currentAnim]:update(dt)
    
    -- Update afterimages (fade out over time)
    for i = #self.afterimages, 1, -1 do
        local afterimage = self.afterimages[i]
        afterimage.life = afterimage.life - dt
        afterimage.alpha = afterimage.life / 0.3 -- Fade based on remaining life
        
        if afterimage.life <= 0 then
            table.remove(self.afterimages, i)
        end
    end
end

function BirdEnemy:createAfterimage()
    table.insert(self.afterimages, {
        x = self.x,
        y = self.y,
        life = 0.3, -- Afterimage lasts 0.3 seconds
        alpha = 1,
        anim = self.currentAnim -- Store current animation
    })
end

function BirdEnemy:getCircularAnimation()
    -- Returns what the animation should be based on vision cone direction
    -- Vision cone faces tangent to circle
    local facingAngle
    if self.patrolSpeed < 0 then
        facingAngle = self.patrolAngle - math.pi / 2  -- Clockwise
    else
        facingAngle = self.patrolAngle + math.pi / 2  -- Counter-clockwise
    end
    
    -- Normalize to 0 to 2*pi
    local normalizedAngle = facingAngle
    while normalizedAngle < 0 do
        normalizedAngle = normalizedAngle + 2 * math.pi
    end
    while normalizedAngle >= 2 * math.pi do
        normalizedAngle = normalizedAngle - 2 * math.pi
    end
    
    -- Left animation when facing left (90° to 270°)
    -- Right animation when facing right (270° to 90°)
    if normalizedAngle >= math.pi / 2 and normalizedAngle < 3 * math.pi / 2 then
        return 'left'
    else
        return 'right'
    end
end

function BirdEnemy:updateCircularAnimation()
    -- Determine animation based on vision cone facing direction
    -- Vision cone faces tangent to circle
    local facingAngle
    if self.patrolSpeed < 0 then
        facingAngle = self.patrolAngle - math.pi / 2  -- Clockwise
    else
        facingAngle = self.patrolAngle + math.pi / 2  -- Counter-clockwise
    end
    
    -- Normalize angle to 0 to 2*pi range
    local normalizedAngle = facingAngle
    while normalizedAngle < 0 do
        normalizedAngle = normalizedAngle + 2 * math.pi
    end
    while normalizedAngle >= 2 * math.pi do
        normalizedAngle = normalizedAngle - 2 * math.pi
    end
    
    -- Face left when vision cone points left (90° to 270°)
    -- Face right when vision cone points right (270° to 90°)
    if normalizedAngle >= math.pi / 2 and normalizedAngle < 3 * math.pi / 2 then
        self.currentAnim = 'left'
    else
        self.currentAnim = 'right'
    end
end

function BirdEnemy:draw()
    if self.removed then return end
    
    -- Draw afterimages first (behind owl)
    for _, afterimage in ipairs(self.afterimages) do
        love.graphics.setColor(1, 1, 1, afterimage.alpha * 0.5)
        self.animations[afterimage.anim]:draw(self.sprite, afterimage.x, afterimage.y, nil, 1.2)
    end
    
    -- Reset color and draw owl
    love.graphics.setColor(1, 1, 1, 1)
    self.animations[self.currentAnim]:draw(self.sprite, self.x, self.y, nil,  1.2)
end

function BirdEnemy:remove()
    self.removed = true
end

function BirdEnemy:checkCollision(playerX, playerY, playerWidth, playerHeight)
    local hbX = self.x + HITBOX.offsetX
    local hbY = self.y + HITBOX.offsetY
    local hbW = HITBOX.width
    local hbH = HITBOX.height

    return hbX < playerX + playerWidth and
           hbX + hbW > playerX and
           hbY < playerY + playerHeight and
           hbY + hbH > playerY
end

return BirdEnemy
