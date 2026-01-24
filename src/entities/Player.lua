Player = {}

local playerSprite = love.graphics.newImage('assets/graphics/characters/Duckie-sprite-sheet.png')
local anim8 = require('lib.anim8')
local grid = anim8.newGrid(12, 18, playerSprite:getWidth(), playerSprite:getHeight())

function Player:new(x, y)
    local animations = {
        down = anim8.newAnimation(grid('1-4', 1), 0.2),   
        left = anim8.newAnimation(grid('1-4', 2), 0.2),   
        right = anim8.newAnimation(grid('1-4', 3), 0.2),   
        up = anim8.newAnimation(grid('1-4', 4), 0.2)      
    }
    
    local self = {
        x = x or 482,
        y = y or 354,
        speed = 200,
        sprite = playerSprite,
        animations = animations,
        currentAnim = 'down',
        
        -- Sprint effects
        isSprinting = false,
        sprintSpeed = 1.5,
        
        -- After-image effect
        afterImages = {},
        afterImageTimer = 0,
        afterImageInterval = 0.05,
    }
    
    return setmetatable(self, { __index = Player })
end

function Player:update(dt)
    local isMoving = false
    local speed = self.speed
    
    -- Check if sprinting
    self.isSprinting = love.keyboard.isDown('lshift') or love.keyboard.isDown('rshift')
    
    if self.isSprinting then
        speed = speed * self.sprintSpeed
    end
    
    -- Store previous position for after-images
    local prevX, prevY = self.x, self.y
    
    -- Movement
    if love.keyboard.isDown('w') or love.keyboard.isDown('up') then
        self.y = self.y - speed * dt
        self.currentAnim = 'up'
        isMoving = true
    end
    if love.keyboard.isDown('s') or love.keyboard.isDown('down') then
        self.y = self.y + speed * dt
        self.currentAnim = 'down'
        isMoving = true
    end
    if love.keyboard.isDown('a') or love.keyboard.isDown('left') then
        self.x = self.x - speed * dt
        self.currentAnim = 'left'
        isMoving = true
    end
    if love.keyboard.isDown('d') or love.keyboard.isDown('right') then
        self.x = self.x + speed * dt
        self.currentAnim = 'right'
        isMoving = true
    end
    
    -- Animation
    if isMoving then
        -- Speed up animation when sprinting
        local animSpeed = self.isSprinting and 1.5 or 1.0
        self.animations[self.currentAnim]:update(dt * animSpeed)
    else
        self.animations[self.currentAnim]:gotoFrame(2)
    end
    
    -- Sprint effects
    if isMoving and self.isSprinting then
        -- After-image effect
        self.afterImageTimer = self.afterImageTimer + dt
        if self.afterImageTimer >= self.afterImageInterval then
            table.insert(self.afterImages, {
                x = prevX,
                y = prevY,
                anim = self.currentAnim,
                frame = self.animations[self.currentAnim].position,
                alpha = 0.5,
                lifetime = 0
            })
            self.afterImageTimer = 0
        end
    end
    
    -- Update after-images
    for i = #self.afterImages, 1, -1 do
        local img = self.afterImages[i]
        img.lifetime = img.lifetime + dt
        img.alpha = img.alpha - dt * 2  -- Fade out
        
        if img.alpha <= 0 then
            table.remove(self.afterImages, i)
        end
    end
end

function Player:draw()
    -- Draw after-images (motion blur/mirage)
    for _, img in ipairs(self.afterImages) do
        love.graphics.setColor(1, 1, 1, img.alpha * 0.5)
        self.animations[img.anim]:draw(self.sprite, img.x, img.y, nil, 10)
    end
    
    love.graphics.setColor(1, 1, 1, 1)
    self.animations[self.currentAnim]:draw(self.sprite, self.x, self.y, nil, 10)
end

return Player