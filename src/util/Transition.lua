local Transition = {}

function Transition:new()
    local self = {
        isActive = false,
        duration = 0,
        elapsed = 0,
        callback = nil,
        direction = "in" -- "in" for fade in (black appears), "out" for fade out (black disappears)
    }
    
    return setmetatable(self, { __index = Transition })
end

function Transition:fadeIn(duration, callback)
    self.isActive = true
    self.duration = duration or 0.5
    self.elapsed = 0
    self.callback = callback
    self.direction = "in"
end

function Transition:fadeOut(duration, callback)
    self.isActive = true
    self.duration = duration or 0.5
    self.elapsed = 0
    self.callback = callback
    self.direction = "out"
end

function Transition:update(dt)
    if self.isActive then
        self.elapsed = self.elapsed + dt
        
        if self.elapsed >= self.duration then
            self.isActive = false
            self.elapsed = self.duration
            
            if self.callback then
                self.callback()
            end
        end
    end
end

function Transition:getAlpha()
    if not self.isActive and self.direction == "out" then
        return 0
    end
    
    local alpha = self.elapsed / self.duration
    
    if self.direction == "out" then
        alpha = 1 - alpha
    end
    
    return math.min(1, math.max(0, alpha))
end

function Transition:draw()
    if self.isActive or (self.direction == "out" and self.elapsed < self.duration) then
        local alpha = self:getAlpha()
        love.graphics.setColor(0, 0, 0, alpha)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setColor(1, 1, 1, 1)
    end
end

return Transition
