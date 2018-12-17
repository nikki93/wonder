local common = require 'common'


--- SERVER

local server = cs.server

server.maxClients = 6
if USE_CASTLE_CONFIG then
    server.useCastleConfig()
else
    server.enabled = true
    server.start('22122')
end

local share = server.share
local homes = server.homes


--- LOCALS

-- World
local world

-- Blocks
local blocks


--- LOAD

function server.load()
    do -- Physics
        love.physics.setMeter(64)
        world = love.physics.newWorld(0, 32 * 64, true)
    end

    do -- Level
        share.level = 1
    end

    do -- Blocks
        blocks = common.loadBlocks(share.level)
    end

    do -- Solids
        share.solids = {}
        for blockId, b in pairs(blocks) do
            if b.type == 'solid' then
                share.solids[blockId] = {}
                local solid = share.solids[blockId]
                solid.x, solid.y, solid.points = b.x, b.y, b.points
                solid.body = love.physics.newBody(world, solid.x, solid.y)
                solid.shape = love.physics.newChainShape(false, unpack(solid.points:__table()))
                solid.fixture = love.physics.newFixture(solid.body, solid.shape)
            end
        end
    end

    do -- Players
        share.players = {}
    end

    do -- Balls
        share.balls = {}
        for ballId = 1, 1 do
            share.balls[ballId] = {}
            local ball = share.balls[ballId]
            ball.radius = 14
            for _, b in pairs(blocks) do
                if b.type == 'spawn' then
                    ball.x, ball.y = b.x + 40, b.y + ballId * 30
                end
            end
            ball.body = love.physics.newBody(world, ball.x, ball.y, 'dynamic')
            ball.shape = love.physics.newCircleShape(ball.radius)
            ball.fixture = love.physics.newFixture(ball.body, ball.shape, 0)
            ball.fixture:setRestitution(0.3)
        end
    end
end


--- CONNECT

function server.connect(clientId)
    do -- Player
        share.players[clientId] = {}
        local player = share.players[clientId]
        player.x, player.y = 0, 0
        for _, b in pairs(blocks) do
            if b.type == 'spawn' then
                player.x, player.y = b.x, b.y
            end
        end
        player.body = love.physics.newBody(world, player.x, player.y, 'dynamic')
        player.shape = love.physics.newRectangleShape(32, 90)
        player.fixture = love.physics.newFixture(player.body, player.shape, 0)
        player.fixture:setFriction(0.4)
        player.body:setLinearDamping(2.8)
        player.body:setFixedRotation(true)
        player.jumpRequestTime = nil
        player.canDoubleJump = false
        player.flip = 1
    end
end


--- DISCONNECT

function server.disconnect(clientId)
    do -- Player
        share.players[clientId] = nil
    end
end


--- RECEIVE

function server.receive(clientId, msg)
    do -- Player
        local player = share.players[clientId]
        do -- Jump
            if msg == 'jump' then
                player.jumpRequestTime = love.timer.getTime()
            end
        end
    end
end


--- UPDATE

function server.update(dt)
    do -- Player -> Physics
        for clientId, player in pairs(share.players) do
            do -- Walk
                local walk = homes[clientId].walk
                if walk then
                    local MAX_VEL, ACC = 280, 3200
                    local vx, vy = player.body:getLinearVelocity()
                    local newVx = vx
                    if not (walk.right and walk.left) then
                        if vx < MAX_VEL and walk.right then
                            newVx = math.min(MAX_VEL, vx + ACC * dt)
                        end
                        if vx > -MAX_VEL and walk.left then
                            newVx = math.max(-MAX_VEL, vx - ACC * dt)
                        end
                    end
                    player.body:applyLinearImpulse(newVx - vx, 0)
                end
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
    end

--     do -- Moving solids
--         solids[2].body:setLinearVelocity(40 * math.sin(love.timer.getTime()), 0)
--         solids[3].body:setLinearVelocity(0, 40 * math.sin(love.timer.getTime()))
--         solids[4].body:setLinearVelocity(40 * math.sin(love.timer.getTime()), 0)
--     end

    do -- Physics
        world:update(dt)
    end

    do -- Players <- Physics
        for clientId, player in pairs(share.players) do
            do -- Position
                player.x, player.y = player.body:getPosition()
            end

            do -- Walking, flip
                local walk = homes[clientId].walk
                if walk then
                    local vx, vy = player.body:getLinearVelocity()
                    player.walking = math.abs(vx) >= 0.01 and (walk.left or walk.right)
                            and not (walk.left and walk.right)
                else
                    player.walking = false
                end
                if player.walking then
                    if walk.left then
                        player.flip = -1
                    end
                    if walk.right then
                        player.flip = 1
                    end
                end
            end
        end
    end

    do -- Balls <- Physics
        for ballId, ball in pairs(share.balls) do
            do -- Position
                ball.x, ball.y = ball.body:getPosition()
            end
        end
    end
end
