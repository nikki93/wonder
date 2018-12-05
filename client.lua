local common = require 'common'


local client = cs.client

client.enabled = true
--client.useCastleServer()
--client.start('207.254.45.246:22122') -- A remote server I test on
client.start('127.0.0.1:22122') -- Local server

local share = client.share
local home = client.home

local bgs = {}
for i = 1, common.NUM_LEVELS do
    bgs[i] = common.loadBg(i)
end

local viewX, viewY = 0, 0

local characterImg = love.graphics.newImage('./assets/character-1.png')
local characterQuad = love.graphics.newQuad(0, 0, 72, 126, characterImg:getDimensions())

function client.connect()
    home.controls = { left = false, right = false, up = false, down = false }
end

function client.draw()
    if client.connected then
        love.graphics.stacked('all', function()
            local player = share.players[client.id]

            local ww, wh = love.graphics.getDimensions()
            if player.x - 240 < viewX then
                viewX = player.x - 240
            end
            if player.x + 240 > viewX + ww then
                viewX = player.x + 240 - ww
            end
            if player.y - 240 < viewY then
                viewY = player.y - 240
            end
            if player.y + 240 > viewY + wh then
                viewY = player.y + 240 - wh
            end
            love.graphics.translate(-viewX, -viewY)

            love.graphics.draw(bgs[share.level])

            for _, b in ipairs(share.blocks) do
                love.graphics.stacked('all', function()
                    if b.type ==  'solid' then
                        love.graphics.setColor(0, 0, 1)
                    elseif b.type == 'spawn' then
                        love.graphics.setColor(1, 1, 0)
                    end
                    love.graphics.rectangle('fill', b.x, b.y, b.w, b.h)
                end)
            end

            characterQuad:setViewport(72 * (math.floor(6 * love.timer.getTime()) % 1), 0, 72, 126)
            love.graphics.draw(characterImg, characterQuad, player.x, player.y)
        end)
    end
end

function love.keypressed(key)
    if client.connected then
        if key == 'up' then
            home.controls.up = true
        end
        if key == 'down' then
            home.controls.down = true
        end
        if key == 'left' then
            home.controls.left = true
        end
        if key == 'right' then
            home.controls.right = true
        end
    end
end

function love.keyreleased(key)
    if client.connected then
        if key == 'up' then
            home.controls.up = false
        end
        if key == 'down' then
            home.controls.down = false
        end
        if key == 'left' then
            home.controls.left = false
        end
        if key == 'right' then
            home.controls.right = false
        end
    end
end
