Game = {}

function Game:init()
    self.player = require('src.entities.Player'):new()
end

function Game:enter()
    self:init()
end

function Game:update(dt)
    self.player:update(dt)
end

function Game:draw()
    love.graphics.clear(0.50, 0.87, 0.68)
    self.player:draw()
end

return Game