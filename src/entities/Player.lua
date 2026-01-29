Player = {}

function Player:new()
    local anim8 = require('lib.anim8')
    local sprite = love.graphics.newImage('assets/graphics/characters/Duckie-sprite-sheet.png')
    local grid = anim8.newGrid(12, 18, sprite:getWidth(), sprite:getHeight())    

    local animations = {
        down = anim8.newAnimation(grid('1-4', 1), 0.2),   
        left = anim8.newAnimation(grid('1-4', 2), 0.2),   
        right = anim8.newAnimation(grid('1-4', 3), 0.2),   
        up = anim8.newAnimation(grid('1-4', 4), 0.2)      
    }
    
    -- Load walking and sprint sounds
    local walkingSound = love.audio.newSource('assets/sounds/sfx/walking-sound.mp3', 'stream')
    walkingSound:setLooping(true)
    walkingSound:setVolume(0.1)
    
    local sprintSound = love.audio.newSource('assets/sounds/sfx/sprint-sound.mp3', 'stream')
    sprintSound:setLooping(true)
    sprintSound:setVolume(0.1)
    
    local self = {
        x = 482,
        y = 354,
        -- original speed is 800
        speed = 200,
        sprintSpeed = 1100,
        sprite = sprite,
        grid = grid,
        animations = animations,
        currentAnim = 'down',  
        anim8 = anim8,
        isSprinting = false,
        afterimages = {},
        afterimageTimer = 0,
        afterimageInterval = 0.05, -- Create afterimage every 0.05 seconds
        walkingSound = walkingSound,
        sprintSound = sprintSound,
        isWalking = false,
    }
    
    return setmetatable(self, { __index = Player })
end

function Player:update(dt)
    local isMoving = false
    local vx = 0
    local vy = 0
    
    -- Check if sprinting (holding shift)
    self.isSprinting = love.keyboard.isDown('lshift') or love.keyboard.isDown('rshift')
    local currentSpeed = self.isSprinting and self.sprintSpeed or self.speed
    
    -- Priority-based movement: vertical takes priority over horizontal
    if love.keyboard.isDown('w') or love.keyboard.isDown('up') then
        vy = currentSpeed * dt * -1
        self.currentAnim = 'up'
        isMoving = true
    end
    if love.keyboard.isDown('s') or love.keyboard.isDown('down') then
        vy = currentSpeed * dt 
        self.currentAnim = 'down'
        isMoving = true
    end
    if love.keyboard.isDown('a') or love.keyboard.isDown('left') then
        vx = currentSpeed * dt * -1
        self.currentAnim = 'left'
        isMoving = true
    end
    if love.keyboard.isDown('d') or love.keyboard.isDown('right') then
        vx = currentSpeed * dt 
        self.currentAnim = 'right'
        isMoving = true
    end
    
    -- Normalize diagonal movement (Pythagorean theorem)
    if vx ~= 0 and vy ~= 0 then
        local length = math.sqrt(vx * vx + vy * vy)
        vx = vx / length * currentSpeed * dt
        vy = vy / length * currentSpeed * dt
    end
    
    self.collider:setLinearVelocity(vx * 60, vy * 60)

    if isMoving then
        self.animations[self.currentAnim]:update(dt)
        
        -- Handle movement sounds (walking vs sprinting)
        if not self.isWalking then
            -- Start playing the appropriate sound
            if self.isSprinting then
                self.sprintSound:play()
            else
                self.walkingSound:play()
            end
            self.isWalking = true
        else
            -- Switch between walking and sprint sounds
            if self.isSprinting and not self.sprintSound:isPlaying() then
                self.walkingSound:stop()
                self.sprintSound:play()
            elseif not self.isSprinting and not self.walkingSound:isPlaying() then
                self.sprintSound:stop()
                self.walkingSound:play()
            end
        end
        
        -- Create afterimages when sprinting
        if self.isSprinting then
            self.afterimageTimer = self.afterimageTimer + dt
            if self.afterimageTimer >= self.afterimageInterval then
                self:createAfterimage()
                self.afterimageTimer = 0
            end
        end
    else
        self.animations[self.currentAnim]:gotoFrame(2)
        
        -- Stop all movement sounds when not moving
        if self.isWalking then
            self.walkingSound:stop()
            self.sprintSound:stop()
            self.isWalking = false
        end
    end
    
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

function Player:createAfterimage()
    table.insert(self.afterimages, {
        x = self.x,
        y = self.y,
        life = 0.3, -- Afterimage lasts 0.3 seconds
        alpha = 1
    })
end

function Player:draw()
    -- Draw afterimages first (behind player)
    for _, afterimage in ipairs(self.afterimages) do
        love.graphics.setColor(1, 1, 1, afterimage.alpha * 0.5)
        self.animations[self.currentAnim]:draw(self.sprite, afterimage.x, afterimage.y, nil, 3)
    end
    
    -- Reset color and draw player
    love.graphics.setColor(1, 1, 1, 1)
    self.animations[self.currentAnim]:draw(self.sprite, self.x, self.y, nil, 3)
end

return Player