local world

local floors
local player

function love.load()
    do -- Physics
        love.physics.setMeter(64)
        world = love.physics.newWorld(0, 32 * 64, true)
    end

    do -- Floors
        floors = {}

        do
            floors[1] = {}
            floors[1].body = love.physics.newBody(world, 20, 20)
            floors[1].shape = love.physics.newChainShape(false, 0, 200, 200, 200, 400, 200)
            floors[1].fixture = love.physics.newFixture(floors[1].body, floors[1].shape)
        end

        do
            floors[2] = {}
            floors[2].body = love.physics.newBody(world, 400, 300)
            floors[2].shape = love.physics.newChainShape(false, 0, 200, 200, 200, 400, 120)
            floors[2].fixture = love.physics.newFixture(floors[2].body, floors[2].shape)
        end

        do
            floors[3] = {}
            floors[3].body = love.physics.newBody(world, 200, 500)
            floors[3].shape = love.physics.newChainShape(false, 0, 200, 200, 200, 400, 180)
            floors[3].fixture = love.physics.newFixture(floors[3].body, floors[3].shape)
        end

        do
            floors[4] = {}
            floors[4].body = love.physics.newBody(world, -100, 450)
            floors[4].shape = love.physics.newChainShape(false, 0, 200, 200, 200, 400, 180)
            floors[4].fixture = love.physics.newFixture(floors[4].body, floors[4].shape)
        end
    end

    do -- Player
        player = {}
        player.body = love.physics.newBody(world, 80, 0, 'dynamic')
        player.shape = love.physics.newRectangleShape(32, 90)
        player.fixture = love.physics.newFixture(player.body, player.shape, 0)
        player.fixture:setFriction(0.4)
        player.body:setLinearDamping(2.8)
        player.body:setFixedRotation(true)
        player.jumpRequestTime = nil
        player.canDoubleJump = false
    end
end

local characterImg
local characterQuad
characterImg = love.graphics.newImage('assets/character-1.png')
characterQuad = love.graphics.newQuad(0, 0, 72, 126, characterImg:getDimensions())
local characterFlip = 1

function love.draw()
    do -- World
        do -- Player
--            love.graphics.polygon('line', player.body:getWorldPoints(player.shape:getPoints()))
            local x, y = player.body:getPosition()
            local vx, vy = player.body:getLinearVelocity()
            local walking = (love.keyboard.isDown('left') or love.keyboard.isDown('right')) and
                    math.abs(vx) >= 0.01
            if walking then
                if vx < -0.01 then
                    characterFlip = -1
                elseif vx > 0.01 then
                    characterFlip = 1
                end
                characterQuad:setViewport(72 * (math.floor(10 * love.timer.getTime()) % 6), 126, 72, 126)
            else
                local sq = 1 - math.abs(math.sin(0.7 * love.timer.getTime()))
                sq = sq * sq
                characterQuad:setViewport(72 * (5 - math.floor(4 * sq * sq * sq * sq)), 0, 72, 126)
            end
            love.graphics.draw(characterImg, characterQuad,
                x + 72 * (0.5 * -characterFlip + 0.5) - 36, y - 32 - 45,
                0, characterFlip, 1)
        end

        do -- Floors
            for _, floor in pairs(floors) do
                love.graphics.line(floor.body:getWorldPoints(floor.shape:getPoints()))
            end
        end
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

    do -- Physics
        world:update(dt)
    end
end

function love.keypressed(key)
    do -- Player
        if key == 'up' then -- Jump
            player.jumpRequestTime = love.timer.getTime()
        end
    end
end