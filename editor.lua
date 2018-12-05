local common = require 'common'


local LEVEL = 1


local bg = common.loadBg(LEVEL)


local viewX, viewY = 0, 0

local blocks = common.loadBlocks(LEVEL)
local newBlock

local mode = 'solid'


function love.update(dt)
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

function love.draw()
    love.graphics.stacked('all', function()
        love.graphics.translate(-viewX, -viewY)

        love.graphics.draw(bg, 0, 0)

        for _, b in ipairs(blocks) do
            if b.type ==  'solid' then
                love.graphics.setColor(0, 0, 1)
            elseif b.type == 'spawn' then
                love.graphics.setColor(1, 1, 0)
            end
            love.graphics.rectangle('fill', b.x, b.y, b.w, b.h)
        end
        if newBlock then
            love.graphics.setColor(1, 0, 0)
            love.graphics.rectangle('fill', newBlock.x, newBlock.y, newBlock.w, newBlock.h)
        end
    end)

    love.graphics.stacked('all', function()
        love.graphics.translate(20, 20)

        local font = love.graphics.getFont()
        local w, h = font:getWidth(mode), font:getHeight()

        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle('fill', -5, -5, w + 10, h + 10)
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle('line', -5, -5, w + 10, h + 10)
        love.graphics.print(mode, 0, 0)
    end)
end

function love.mousepressed(mx, my)
    local x, y = mx + viewX, my + viewY

    if mode == 'solid' or mode == 'spawn' then
        newBlock = { type = mode, x = x, y = y, w = 0, h = 0 }
    end

    if mode == 'remove' then
        for i = #blocks, 1, -1 do
            local b = blocks[i]
            if b.x <= x and b.x + b.w >= x and b.y <= y and b.y + b.h >= y then
                table.remove(blocks, i)
            end
        end
    end
end

function love.mousemoved(mx, my)
    local x, y = mx + viewX, my + viewY
    if newBlock then
        newBlock.w, newBlock.h = x - newBlock.x, y - newBlock.y
    end
end

function love.mousereleased()
    if newBlock then
        if newBlock.w > 8 and newBlock.h > 8 then
            if newBlock.type == 'spawn' then
                for i, b in pairs(blocks) do
                    if b.type == 'spawn' then
                        table.remove(blocks, i)
                    end
                end
            end
            table.insert(blocks, newBlock)
        end
        newBlock = nil
    end
end

function love.keypressed(key)
    if key == '1' then
        mode = 'solid'
    end
    if key == '2' then
        mode = 'remove'
    end
    if key == '3' then
        mode = 'spawn'
    end

    if key == '0' then
        common.writeBlocks(LEVEL, blocks)
    end
end
