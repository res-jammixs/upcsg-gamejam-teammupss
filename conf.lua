function love.conf(t)
    t.window.title = 'Featherless'
    t.window.width = 1024
    t.window.height = 768
    t.console = true
    
    -- Ensure consistent rendering across different devices
    t.window.resizable = false  -- Prevent window resizing which can cause misalignment
    t.window.highdpi = true     -- Support high DPI displays properly
    t.window.usedpiscale = true -- Use DPI-aware scaling (LÖVE 11.3+)
end