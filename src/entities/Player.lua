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
        anim8 = anim8  
    }
    
    return setmetatable(self, { __index = Player })
end

function Player:update(dt)
    local isMoving = false
    
    if love.keyboard.isDown('w') or love.keyboard.isDown('up') then
        self.y = self.y - self.speed * dt
        self.currentAnim = 'up'
        isMoving = true
    end
    if love.keyboard.isDown('s') or love.keyboard.isDown('down') then
        self.y = self.y + self.speed * dt
        self.currentAnim = 'down'
        isMoving = true
    end
    if love.keyboard.isDown('a') or love.keyboard.isDown('left') then
        self.x = self.x - self.speed * dt
        self.currentAnim = 'left'
        isMoving = true
    end
    if love.keyboard.isDown('d') or love.keyboard.isDown('right') then
        self.x = self.x + self.speed * dt
        self.currentAnim = 'right'
        isMoving = true
    end
    
    if isMoving then
        self.animations[self.currentAnim]:update(dt)
    else
        self.animations[self.currentAnim]:gotoFrame(2)
    end
end

function Player:draw()
    self.animations[self.currentAnim]:draw(self.sprite, self.x, self.y, nil, 10)
end

return Player