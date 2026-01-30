Enemy = {}

function Enemy:new(x, y, movementType)
    local anim8 = require('lib.anim8')
    local sprite = love.graphics.newImage('assets/graphics/enemies/owl-sprite-sheet.png')
    sprite:setFilter('nearest', 'nearest')
    
    local gridLeft = anim8.newGrid(74, 62, sprite:getWidth(), sprite:getHeight(), 8, 1)    
    local gridRight = anim8.newGrid(78, 62, sprite:getWidth(), sprite:getHeight(), 1, 3)    

    -- Use provided movementType or randomly choose: 1 = horizontal, 2 = vertical
    movementType = movementType or love.math.random(1, 2)
    local direction = love.math.random(0, 1) == 1 and 1 or -1
    
    -- For up/down movement, randomly choose left or right sprite
    local upDownRow = love.math.random(0, 1) == 1 and 1 or 3
    local gridUpDown = upDownRow == 1 and gridLeft or gridRight
    
    local animations = {
        left = anim8.newAnimation(gridLeft('1-4', 1), 0.2),   
        right = anim8.newAnimation(gridRight('1-4', 3), 0.2),   
        up = anim8.newAnimation(gridUpDown('1-4', upDownRow), 0.2),
        down = anim8.newAnimation(gridUpDown('1-4', upDownRow), 0.2)
    }
    
    local self = {
        x = x,
        y = y,
        speed = 100,

        chaseSpeed = 250,
        removed = false,
        movementType = movementType, -- 1 = horizontal, 2 = vertical
        direction = direction, -- 1 or -1
        moveDistance = 150, -- How far to move before turning around
        startX = x,
        startY = y,
        sprite = sprite,
        animations = animations,
        currentAnim = movementType == 1 and (direction == 1 and 'right' or 'left') or 'down',
        anim8 = anim8,
        detectionRadius = 200,
        isChasing = false
    }
    
    return setmetatable(self, { __index = Enemy })
end

function Enemy:update(dt, playerX, playerY)
    if self.removed then return end
    
    -- Check if player is in detection range
    local distToPlayer = math.sqrt((playerX - self.x)^2 + (playerY - self.y)^2)
    self.isChasing = distToPlayer <= self.detectionRadius
    
    local currentSpeed = self.isChasing and self.chaseSpeed or self.speed
    local vx = 0
    local vy = 0
    
    if self.isChasing then
        -- Chase player and face their direction
        local dx = playerX - self.x
        local dy = playerY - self.y
        local angle = math.atan2(dy, dx)
        
        vx = math.cos(angle) * currentSpeed
        vy = math.sin(angle) * currentSpeed
        
        -- Face the player's direction
        if math.abs(dx) > math.abs(dy) then
            -- Horizontal movement is dominant
            if dx > 0 then
                self.currentAnim = 'right'
            else
                self.currentAnim = 'left'
            end
        else
            -- Vertical movement is dominant
            if dy > 0 then
                self.currentAnim = 'down'
            else
                self.currentAnim = 'up'
            end
        end
    else
        -- Patrol behavior
        if self.movementType == 1 then
            -- Move horizontally (left and right)
            vx = self.speed * self.direction
            
            -- Update animation based on direction
            self.currentAnim = self.direction == 1 and 'right' or 'left'
        else
            -- Move vertically (up and down)
            vy = self.speed * self.direction
            
            -- Update animation based on direction
            self.currentAnim = self.direction == 1 and 'down' or 'up'
        end
    end
    
    -- Apply velocity directly to position
    self.x = self.x + vx * dt
    self.y = self.y + vy * dt
    
    -- Check patrol bounds AFTER moving
    if not self.isChasing then
        if self.movementType == 1 then
            -- Check if moved too far horizontally from start position
            if math.abs(self.x - self.startX) >= self.moveDistance then
                self.direction = self.direction * -1
            end
        else
            -- Check if moved too far vertically from start position
            if math.abs(self.y - self.startY) >= self.moveDistance then
                self.direction = self.direction * -1
            end
        end
    end
    
    -- Update animation
    self.animations[self.currentAnim]:update(dt)
end

function Enemy:draw()
    if self.removed then return end
    
    love.graphics.setColor(1, 1, 1, 1)
    self.animations[self.currentAnim]:draw(self.sprite, self.x, self.y, nil, 1)
    
    -- Draw hitbox (collision box)
    love.graphics.setColor(0, 1, 0, 0.5)
    love.graphics.rectangle("line", self.x, self.y, 74, 62)
    
    -- Draw detection circle
    love.graphics.setColor(1, 0, 0, 0.3)
    love.graphics.circle("line", self.x + 36, self.y + 40, self.detectionRadius)
    
    love.graphics.setColor(1, 1, 1, 1)
end

function Enemy:remove()
    self.removed = true
end

function Enemy:checkCollision(playerX, playerY, playerWidth, playerHeight)
    -- Simple AABB collision detection (sprite is 72x80)
    local enemyWidth = 74 
    local enemyHeight = 62
    
    return self.x < playerX + playerWidth and
           self.x + enemyWidth > playerX and
           self.y < playerY + playerHeight and
           self.y + enemyHeight > playerY
end

return Enemy
