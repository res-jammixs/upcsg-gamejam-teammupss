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
    
    local self = {
        x = 482,
        y = 354,
        speed = 200,
        sprite = sprite,
        grid = grid,
        animations = animations,
        currentAnim = 'down',  
        anim8 = anim8, 
    }
    
    return setmetatable(self, { __index = Player })
end

function Player:update(dt)
    local isMoving = false

    local vx = 0; 
    local vy = 0; 
    
    if love.keyboard.isDown('w') or love.keyboard.isDown('up') then
        vy = self.speed * dt * -1
        self.currentAnim = 'up'
        isMoving = true
    end
    if love.keyboard.isDown('s') or love.keyboard.isDown('down') then
        vy = self.speed * dt 
        self.currentAnim = 'down'
        isMoving = true
    end
    if love.keyboard.isDown('a') or love.keyboard.isDown('left') then
        vx = self.speed * dt * -1
        self.currentAnim = 'left'
        isMoving = true
    end
    if love.keyboard.isDown('d') or love.keyboard.isDown('right') then
        vx = self.speed * dt 
        self.currentAnim = 'right'
        isMoving = true
    end
    
    self.collider:setLinearVelocity(vx * 60, vy * 60)

    if isMoving then
        self.animations[self.currentAnim]:update(dt)
    else
        self.animations[self.currentAnim]:gotoFrame(2)
    end
end

function Player:draw()
    self.animations[self.currentAnim]:draw(self.sprite, self.x, self.y, nil, 3)
end

return Player