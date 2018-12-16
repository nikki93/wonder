local common = require 'common'


--- VARIABLES

-- Physics
local world

-- Level
local level

-- View
local viewX, viewY

-- Background
local bg

-- Solids
local solids

-- Player
local player

-- Ball
local ball


--- LOAD

function love.load()
    do -- Physics
        love.physics.setMeter(64)
        world = love.physics.newWorld(0, 32 * 64, true)
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

    local blocks
    do -- Blocks
        blocks = common.loadBlocks(level)
    end

    do -- Solids
        solids = {}
        for _, b in pairs(blocks) do
            if b.type == 'solid' then
                local solid = {}
                solid.body = love.physics.newBody(world, b.x, b.y)
                solid.shape = love.physics.newChainShape(false, unpack(b.points))
                solid.fixture = love.physics.newFixture(solid.body, solid.shape)
                table.insert(solids, solid)
            end
        end
    end

    do -- Player
        player = {}
        local x, y = 0, 0
        for _, b in pairs(blocks) do
            if b.type == 'spawn' then
                x, y = b.x, b.y
            end
        end
        player.body = love.physics.newBody(world, x, y, 'dynamic')
        player.shape = love.physics.newRectangleShape(32, 90)
        player.fixture = love.physics.newFixture(player.body, player.shape, 0)
        player.fixture:setFriction(0.4)
        player.body:setLinearDamping(2.8)
        player.body:setFixedRotation(true)
        player.jumpRequestTime = nil
        player.canDoubleJump = false
    end

    do -- Ball
        ball = {}
        local px, py = player.body:getPosition()
        ball.body = love.physics.newBody(world, px + 40, py, 'dynamic')
        ball.shape = love.physics.newCircleShape(14)
        ball.fixture = love.physics.newFixture(ball.body, ball.shape, 0)
        ball.fixture:setRestitution(0.3)
    end
end


--- DRAW

do
    local characterImg = love.graphics.newImage('assets/character-1.png')
    local characterQuad = love.graphics.newQuad(0, 0, 72, 126, characterImg:getDimensions())
    local characterFlip = 1

    function love.draw()
        do -- World
            love.graphics.stacked('all', function()
                do -- View
                    local VIEW_PADDING = 240
                    local x, y = player.body:getPosition()
                    local ww, wh = love.graphics.getDimensions()
                    viewX = math.max(x - ww + VIEW_PADDING, math.min(viewX, x - VIEW_PADDING))
                    viewY = math.max(y - wh + VIEW_PADDING, math.min(viewY, y - VIEW_PADDING))
                    love.graphics.translate(-viewX, -viewY)
                end

                do -- Background
                    love.graphics.draw(bg, 0, 0)
                end

                do -- Player
--                    love.graphics.polygon('line', player.body:getWorldPoints(player.shape:getPoints()))
                    local x, y = player.body:getPosition()
                    local vx, vy = player.body:getLinearVelocity()
                    local left, right = love.keyboard.isDown('left'), love.keyboard.isDown('right')
                    local walking = (left or right) and math.abs(vx) >= 0.01
                    if walking then
                        if left then
                            characterFlip = -1
                        elseif right then
                            characterFlip = 1
                        end
                        local frame = math.floor(10 * love.timer.getTime()) % 6
                        characterQuad:setViewport(72 * frame, 126, 72, 126)
                    else
                        local sq = 1 - math.abs(math.sin(0.7 * love.timer.getTime()))
                        sq = sq * sq
                        local frame = 5 - math.floor(4 * sq * sq * sq * sq)
                        characterQuad:setViewport(72 * frame, 0, 72, 126)
                    end
                    love.graphics.draw(characterImg, characterQuad,
                        x + 72 * (0.5 * -characterFlip + 0.5) - 36, y - 32 - 45,
                        0, characterFlip, 1)
                end

                do -- Ball
                    love.graphics.circle('fill', ball.body:getX(), ball.body:getY(), ball.shape:getRadius())
                end

                do -- Solids
--                    love.graphics.stacked('all', function()
--                        love.graphics.setLineWidth(3)
--                        for _, solid in pairs(solids) do
--                            love.graphics.line(solid.body:getWorldPoints(solid.shape:getPoints()))
--                        end
--                    end)
                end
            end)
        end

        do -- Stats
            love.graphics.print('fps: ' .. love.timer.getFPS(), 20, 20)

            if love.keyboard.isDown('left') then
                love.graphics.print('\n\nLEFT pressed', 20, 20)
            end
            if love.keyboard.isDown('right') then
                love.graphics.print('\n\n\nRIGHT pressed', 20, 20)
            end
        end
    end
end


--- UPDATE

function love.update(dt)
    do -- Player
        do -- Left / right
            local MAX_VEL, ACC = 280, 3200
            local vx, vy = player.body:getLinearVelocity()
            local newVx = vx
            local left, right = love.keyboard.isDown('left'), love.keyboard.isDown('right')
            if not (right and left) then
                if vx < MAX_VEL and right then
                    newVx = math.min(MAX_VEL, vx + ACC * dt)
                end
                if vx > -MAX_VEL and left then
                    newVx = math.max(-MAX_VEL, vx - ACC * dt)
                end
            end
            player.body:applyLinearImpulse(newVx - vx, 0)
        end

        do -- Jump
            local x, y = player.body:getPosition()

            local grounded = false
            for _, contact in pairs(player.body:getContactList()) do
                local x1, y1, x2, y2 = contact:getPositions()
                if (y1 and y1 > y) or (y2 and y2 > y) then
                    grounded = true
                    break
                end
            end
            if grounded then
                player.canDoubleJump = true
            end

            local JUMP_TIMESLOP = 0.1
            if player.jumpRequestTime
                    and love.timer.getTime() - player.jumpRequestTime < JUMP_TIMESLOP then
                local JUMP_VEL = 900
                local vx, vy = player.body:getLinearVelocity()
                if vy > -JUMP_VEL then
                    local canJump = false
                    if grounded then
                        canJump = true
                    elseif player.canDoubleJump then
                        canJump = true
                        player.canDoubleJump = false
                    end
                    if canJump then
                        player.body:applyLinearImpulse(0, -JUMP_VEL - vy)
                        player.jumpRequestTime = nil
                    end
                end
            end
        end
    end

--    do -- Moving solids
--        solids[2].body:setLinearVelocity(40 * math.sin(love.timer.getTime()), 0)
--        solids[3].body:setLinearVelocity(0, 40 * math.sin(love.timer.getTime()))
--        solids[4].body:setLinearVelocity(40 * math.sin(love.timer.getTime()), 0)
--    end

    do -- Physics
        world:update(dt)
    end
end


--- KEYBOARD

function love.keypressed(key)
    do -- Player
        if key == 'up' then -- Jump
            player.jumpRequestTime = love.timer.getTime()
        end
    end
end