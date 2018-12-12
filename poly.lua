local world

local floors
local ball

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

    do -- Ball
        ball = {}
        ball.body = love.physics.newBody(world, 80, 0, 'dynamic')
        ball.shape = love.physics.newCircleShape(20)
        ball.fixture = love.physics.newFixture(ball.body, ball.shape, 0)
        ball.fixture:setFriction(0.1)
        ball.body:setLinearDamping(2.8)
        ball.maxVx = nil
        ball.jumpRequestTime = nil
        ball.canDoubleJump = false
    end
end

function love.draw()
    do -- World
        do -- Ball
            love.graphics.circle('line', ball.body:getX(), ball.body:getY(), ball.shape:getRadius())
        end

        do -- Floors
            for _, floor in pairs(floors) do
                love.graphics.line(floor.body:getWorldPoints(floor.shape:getPoints()))
            end
        end
    end

    do -- Stats
        love.graphics.print('fps: ' .. love.timer.getFPS(), 20, 20)
        love.graphics.print('\nmax x vel: ' .. (ball.maxVx or 0), 20, 20)

        if love.keyboard.isDown('left') then
            love.graphics.print('\n\n\nLEFT pressed', 20, 20)
        end
        if love.keyboard.isDown('right') then
            love.graphics.print('\n\n\n\nRIGHT pressed', 20, 20)
        end
    end
end

function love.update(dt)
    do -- Ball pre-physics
        do -- Left / right
            local MAX_VEL, ACC = 280, 3200
            local vx, vy = ball.body:getLinearVelocity()
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
            ball.body:applyLinearImpulse(newVx - vx, 0)
        end

        do -- Jump
            local x, y = ball.body:getPosition()

            local grounded = false
            for _, contact in pairs(ball.body:getContactList()) do
                local x1, y1, x2, y2 = contact:getPositions()
                if (y1 and y1 > y) or (y2 and y2 > y) then
                    grounded = true
                    break
                end
            end
            if grounded then
                ball.canDoubleJump = true
            end

            local JUMP_TIMESLOP = 0.1
            if ball.jumpRequestTime
                    and love.timer.getTime() - ball.jumpRequestTime < JUMP_TIMESLOP then
                local JUMP_VEL = 900
                local vx, vy = ball.body:getLinearVelocity()
                if vy > -JUMP_VEL then
                    local canJump = false
                    if grounded then
                        canJump = true
                    elseif ball.canDoubleJump then
                        canJump = true
                        ball.canDoubleJump = false
                    end
                    if canJump then
                        ball.body:applyLinearImpulse(0, -JUMP_VEL - vy)
                        ball.jumpRequestTime = nil
                    end
                end
            end
        end
    end

    do -- Physics
        world:update(dt)
    end

    do -- Ball post-physics
        do -- Check max. X velocity
            local vx, vy = ball.body:getLinearVelocity()
            if not ball.maxVx or ball.maxVx < vx then
                ball.maxVx = vx
            end
        end
    end
end

function love.keypressed(key)
    do
        if key == 'up' then
            ball.jumpRequestTime = love.timer.getTime()
        end
    end
end