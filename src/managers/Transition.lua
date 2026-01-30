local Transition = {}

function Transition:new()
    local self = {
        isActive = false,
        duration = 0,
        elapsed = 0,
        callback = nil,
        direction = "in", -- "in" for fade in (black appears), "out" for fade out (black disappears)
        transitionType = "fade", -- "fade" or "circular"
        centerX = nil,
        centerY = nil
    }
    
    return setmetatable(self, { __index = Transition })
end

function Transition:fadeIn(duration, callback)
    self.isActive = true
    self.duration = duration or 0.5
    self.elapsed = 0
    self.callback = callback
    self.direction = "in"
    self.transitionType = "fade"
end

function Transition:fadeOut(duration, callback)
    self.isActive = true
    self.duration = duration or 0.5
    self.elapsed = 0
    self.callback = callback
    self.direction = "out"
    self.transitionType = "fade"
end

function Transition:circularFadeIn(duration, callback, centerX, centerY)
    self.isActive = true
    self.duration = duration or 1.0
    self.elapsed = 0
    self.callback = callback
    self.direction = "in"
    self.transitionType = "circular"
    self.centerX = centerX
    self.centerY = centerY
end

function Transition:circularFadeOut(duration, callback, centerX, centerY)
    self.isActive = true
    self.duration = duration or 1.0
    self.elapsed = 0
    self.callback = callback
    self.direction = "out"
    self.transitionType = "circular"
    self.centerX = centerX
    self.centerY = centerY
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
        if self.transitionType == "fade" then
            -- Normal fade transition
            local alpha = self:getAlpha()
            love.graphics.setColor(0, 0, 0, alpha)
            love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
            love.graphics.setColor(1, 1, 1, 1)
        elseif self.transitionType == "circular" then
            -- Circular transition
            local progress = self.elapsed / self.duration
            
            local screenWidth = love.graphics.getWidth()
            local screenHeight = love.graphics.getHeight()
            
            -- Use provided center or default to screen center
            local centerX = self.centerX or (screenWidth / 2)
            local centerY = self.centerY or (screenHeight / 2)
            
            -- Calculate max radius to cover entire screen from center point
            local maxRadius = math.sqrt(math.max(
                centerX^2 + centerY^2,
                (screenWidth - centerX)^2 + centerY^2,
                centerX^2 + (screenHeight - centerY)^2,
                (screenWidth - centerX)^2 + (screenHeight - centerY)^2
            ))
            
            -- For fade IN: starts full screen (maxRadius), shrinks to 0 (black closes in towards center)
            -- For fade OUT: starts at 0, grows to maxRadius (black reveals from center outward)
            local currentRadius
            if self.direction == "in" then
                currentRadius = maxRadius * (1 - progress)  -- Shrinks from full to 0
            else
                currentRadius = maxRadius * progress  -- Grows from 0 to full
            end
            
            -- Use stencil to create circular mask (visible area)
            love.graphics.stencil(function()
                love.graphics.circle("fill", centerX, centerY, currentRadius)
            end, "replace", 1)
            
            -- Draw black everywhere except the stenciled circle
            love.graphics.setStencilTest("equal", 0)
            love.graphics.setColor(0, 0, 0, 1)
            love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
            love.graphics.setStencilTest()
            love.graphics.setColor(1, 1, 1, 1)
        end
    end
end

return Transition
