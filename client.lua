local common = require 'common'


local client = cs.client

client.enabled = true
--client.useCastleServer()
--client.start('207.254.45.246:22122') -- A remote server I test on
client.start('127.0.0.1:22122') -- Local server
--client.start('10.0.1.36:22122') -- LAN IP

local share = client.share
local home = client.home

local bgs = {}
for i = 1, common.NUM_LEVELS do
    bgs[i] = common.loadBg(i)
end

local viewX, viewY = 0, 0

local characterImg
local characterQuad

function client.load()
    characterImg = love.graphics.newImage('assets/character-1.png')
    characterQuad = love.graphics.newQuad(0, 0, 72, 126, characterImg:getDimensions())
end

function client.connect()
    home.controls = { left = false, right = false, up = false, down = false }
end

function client.draw()
    if client.connected then
        love.graphics.stacked('all', function()
            do
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
            end

            love.graphics.draw(bgs[share.level])

--            for _, b in ipairs(share.blocks) do
--                love.graphics.stacked('all', function()
--                    if b.type ==  'solid' then
--                        love.graphics.setColor(0, 0, 1)
--                    elseif b.type == 'spawn' then
--                        love.graphics.setColor(1, 1, 0)
--                    end
--                    love.graphics.rectangle('fill', b.x, b.y, b.w, b.h)
--                end)
--            end

            for clientId, player in pairs(share.players) do
                if player.vx == 0 then
                    local sq = 1 - math.abs(math.sin(0.7 * love.timer.getTime() + clientId * 0.64))
                    sq = sq * sq
                    characterQuad:setViewport(72 * (5 - math.floor(4 * sq * sq * sq * sq)), 0, 72, 126)
                else
                    characterQuad:setViewport(72 * (math.floor(10 * love.timer.getTime()) % 6), 126, 72, 126)
                end
                love.graphics.draw(characterImg, characterQuad,
                    player.x - 16 + 72 * (0.5 * -player.flip + 0.5), player.y - 29,
                    0, player.flip, 1)
            end
        end)
    end
end

function love.keypressed(key)
    if client.connected then
        if key == 'up' then
            client.send('jump')
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
        if key == 'left' then
            home.controls.left = false
        end
        if key == 'right' then
            home.controls.right = false
        end
    end
end
