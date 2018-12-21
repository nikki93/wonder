local common = require 'common'


local isMobile = love.system.getOS() == 'iOS' or love.system.getOS() == 'Android'


--- CLIENT

local client = cs.client

if USE_CASTLE_CONFIG then
    client.useCastleConfig()
else
    client.enabled = true
    client.start('127.0.0.1:22122')
end

local share = client.share
local home = client.home


--- LOCALS

-- View
local viewX, viewY

-- Backgrounds
local bgImgs

-- Character
local characterImg
local characterQuad


--- LOAD

function client.load()
    do -- View
        viewX, viewY = 0, 0
    end

    do -- Backgrounds
        bgImgs = {}
        for i = 1, common.NUM_LEVELS do
            bgImgs[i] = common.loadBg(i)
        end
    end

    do -- Character
        characterImg = love.graphics.newImage('assets/character-1.png')
        characterQuad = love.graphics.newQuad(0, 0, 72, 126, characterImg:getDimensions())
    end
end


--- CONNECT

function client.connect()
    do -- Walk
        home.walk = { left = false, right = false }
    end
end


--- DRAW

function client.draw()
    if client.connected then -- Connected
        love.graphics.stacked('all', function()
            do -- View
                local VIEW_PAD = 240
                local player = share.players[client.id]
                local ww, wh = love.graphics.getDimensions()
                viewX = math.max(player.x - ww + VIEW_PAD, math.min(viewX, player.x - VIEW_PAD))
                viewY = math.max(player.y - wh + VIEW_PAD, math.min(viewY, player.y - VIEW_PAD))
                love.graphics.translate(-viewX, -viewY)
            end

            do -- Background
                love.graphics.draw(bgImgs[share.level])
            end

            do -- Players
                for clientId, player in pairs(share.players) do
                    -- love.graphics.polygon('line', player.body:getWorldPoints(player.shape:getPoints()))
                    if player.walking then -- Walking
                        local frame = math.floor(10 * love.timer.getTime()) % 6
                        characterQuad:setViewport(72 * frame, 126, 72, 126)
                    else -- Idle
                        local sq = 1 - math.abs(math.sin(0.7 * love.timer.getTime()))
                        sq = sq * sq
                        local frame = 5 - math.floor(4 * sq * sq * sq * sq)
                        characterQuad:setViewport(72 * frame, 0, 72, 126)
                    end
                    love.graphics.draw(characterImg, characterQuad,
                        player.x + 72 * (0.5 * -player.flip + 0.5) - 36,
                        player.y - 32 - 45,
                        0, player.flip, 1)
                end
            end

            do -- Balls
                for ballId, ball in pairs(share.balls) do
                    love.graphics.circle('fill', ball.x, ball.y, ball.radius)
                end
            end

--            do -- Solids
--                love.graphics.stacked('all', function()
--                    love.graphics.setLineWidth(3)
--                    for _, solid in pairs(share.solids) do
--                        love.graphics.stacked(function()
--                            love.graphics.translate(solid.x, solid.y)
--                            love.graphics.line(solid.points)
--                        end)
--                    end
--                end)
--            end
        end)
    end

    if not client.connected then -- Not connected
        love.graphics.print('not connected', 20, 20)
    end
end


--- MOUSE / TOUCH

function client.mousepressed(x, y, button)
    do -- Player
        if isMobile then
            if y >= 0.5 * love.graphics.getHeight() then -- Walk
                if x < 0.5 * love.graphics.getWidth() then
                    home.walk.left = true
                else
                    home.walk.right = true
                end
            else -- Jump
                client.send('jump')
            end
        end
    end
end

function client.mousereleased(x, y, button)
    do -- Player
        if isMobile then
            if y >= 0.5 * love.graphics.getHeight() then -- Walk
                if x < 0.5 * love.graphics.getWidth() then
                    home.walk.left = false
                else
                    home.walk.right = false
                end
            end
        end
    end
end


--- KEYBOARD

function client.keypressed(key)
    do -- Player
        do -- Walk
            if key == 'left' then
                home.walk.left = true
            end
            if key == 'right' then
                home.walk.right = true
            end
        end
        do -- Jump
            if key == 'up' then
                client.send('jump')
            end
        end
    end
end

function client.keyreleased(key)
    do -- Player
        do -- Walk
            if key == 'left' then
                home.walk.left = false
            end
            if key == 'right' then
                home.walk.right = false
            end
        end
    end
end
