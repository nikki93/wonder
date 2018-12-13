local common = require 'common'


--- VARIABLES

-- Settings
local ICON_RADIUS = 14

-- Mode
local mode

-- Level
local level

-- View
local viewX, viewY

-- Background
local bg

-- Blocks
local blocks
local newBlock -- Currently edited block


--- LOAD

function love.load()
    do -- Mode
        mode = 'solid'
    end

    do -- Level
        level = 1
    end

    do -- View
        viewX, viewY = 0, 0
    end

    do -- Background
        bg = common.loadBg(level)
    end

    do -- Blocks
        blocks  = common.loadBlocks(level)
    end
end


--- DRAW

function love.draw()
    do -- Level
        love.graphics.stacked('all', function()
            do -- View
                love.graphics.translate(-viewX, -viewY)
            end

            do -- Background
                love.graphics.stacked('all', function()
                    love.graphics.setColor(1, 1, 1, 0.6)
                    love.graphics.draw(bg, 0, 0)
                end)
            end

            do -- Blocks
                love.graphics.stacked('all', function()
                    love.graphics.setLineWidth(3)
                    love.graphics.setPointSize(6)
                    do -- Existing blocks
                        for _, b in ipairs(blocks) do
                            if b.type ==  'solid' then
                                love.graphics.setColor(0, 0, 1, 0.8)
                                love.graphics.stacked(function()
                                    love.graphics.translate(b.x, b.y)
                                    love.graphics.line(b.points)
                                    love.graphics.points(b.points)
                                end)
                            elseif b.type == 'spawn' then
                                love.graphics.setColor(1, 1, 0, 0.8)
                                love.graphics.circle('fill', b.x, b.y, ICON_RADIUS)
                            end
                        end
                    end
                    do -- New block
                        if newBlock then
                            love.graphics.setColor(1, 0, 0, 0.8)
                            love.graphics.stacked(function()
                                love.graphics.translate(newBlock.x, newBlock.y)
                                if #newBlock.points >= 4 then
                                    love.graphics.line(newBlock.points)
                                end
                                love.graphics.points(newBlock.points)
                            end)
                        end
                    end
                end)
            end
        end)
    end

    do -- Toolbar
        love.graphics.stacked('all', function()
            love.graphics.translate(20, 20)

            do -- Mode
                local font = love.graphics.getFont()
                local w, h = font:getWidth(mode), font:getHeight()
                love.graphics.setColor(0, 0, 0)
                love.graphics.rectangle('fill', -5, -5, w + 10, h + 10)
                love.graphics.setColor(1, 1, 1)
                love.graphics.rectangle('line', -5, -5, w + 10, h + 10)
                love.graphics.print(mode, 0, 0)
            end
        end)
    end
end


--- UPDATE

function love.update(dt)
    do -- View pan
        if love.keyboard.isDown('a') then
            viewX = viewX - 400 * dt
        end
        if love.keyboard.isDown('d') then
            viewX = viewX + 400 * dt
        end
        if love.keyboard.isDown('w') then
            viewY = viewY - 400 * dt
        end
        if love.keyboard.isDown('s') then
            viewY = viewY + 400 * dt
        end
    end
end


--- MOUSE

function love.mousepressed(mx, my)
    -- World position
    local x, y = mx + viewX, my + viewY

    do -- New block
        if mode == 'solid' then
            if not newBlock then
                newBlock = { type = 'solid', x = x, y = y, points = {} }
            end
            do -- Compute new top-left and transform existing points
                local newX, newY = math.min(x, newBlock.x), math.min(y, newBlock.y)
                for i = 1, #newBlock.points - 1, 2 do
                    newBlock.points[i] = newBlock.points[i] + newBlock.x - newX
                    newBlock.points[i + 1] = newBlock.points[i + 1] + newBlock.y - newY
                end
                newBlock.x, newBlock.y = newX, newY
            end
            table.insert(newBlock.points, x - newBlock.x)
            table.insert(newBlock.points, y - newBlock.y)
        end

        if mode == 'spawn' then
            table.insert(blocks, { type = 'spawn', x = x, y = y })
        end
    end

    do -- Remove block
        if mode == 'remove' then
            for i = #blocks, 1, -1 do
                local b = blocks[i]
                local remove = false
                if b.type == 'solid' then
                    for j = 1, #b.points - 1, 2 do -- Dumb check for every point for closeness
                        local dx, dy = b.x + b.points[j] - x, b.y + b.points[j + 1] - y
                        remove = remove or dx * dx + dy * dy < 80
                    end
                elseif b.type == 'spawn' then
                    local dx, dy = b.x - x, b.y - y
                    remove = dx * dx + dy * dy < ICON_RADIUS * ICON_RADIUS
                end
                if remove then
                    table.remove(blocks, i)
                end
            end
        end
    end
end


--- KEYBOARD

function love.keypressed(key)
    do -- Mode select
        if key == '1' then
            mode = 'solid'
        end
        if key == '2' then
            mode = 'remove'
        end
        if key == '3' then
            mode = 'spawn'
        end
    end

    do -- Save
        if key == '0' then
            common.writeBlocks(level, blocks)
        end
    end

    do -- New block finish
        if key == 'return' then
            if newBlock then
                local skip = false
                if newBlock.type == 'solid' then -- Need at least two points for a solid
                    if not (#newBlock.points >= 4) then
                        skip = true
                    end
                end
                if newBlock.type == 'spawn' then -- Need only one spawn, remove other
                    for i, b in pairs(blocks) do
                        if b.type == 'spawn' then
                            table.remove(blocks, i)
                        end
                    end
                end
                if not skip then
                    table.insert(blocks, newBlock)
                end
                newBlock = nil
            end
        end
    end
end
