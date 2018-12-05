local common = require 'common'


local server = cs.server

server.enabled = true
--server.useCastleServer()
server.start('22122')

local share = server.share
local homes = server.homes

local world = bump.newWorld(72)

function server.load()
    share.level = 1

    share.blocks = common.loadBlocks(share.level)
    for bid, b in pairs(share.blocks) do
        if b.type == 'solid' then
            b.id = bid
            world:add(b, b.x, b.y, b.w, b.h)
        end
    end

    share.players = {}
end

function server.connect(id)
    local spawn
    for _, b in pairs(share.blocks) do
        if b.type == 'spawn' then
            spawn = b
        end
    end
    if spawn then
        share.players[id] = {
            id = id,
            x = spawn.x,
            y = spawn.y,
            vx = 0,
            vy = 0,
        }
        local player = share.players[id]
        world:add(player, player.x, player.y, common.PLAYER_W, common.PLAYER_H)
        player.x, player.y = world:move(player, player.x, player.y + 1000)
    end
end

function server.receive(id, msg, ...)
    if msg == 'jump' then
        local player = share.players[id]
        if player then
            local _, nHits = world:queryRect(
                player.x, player.y + common.PLAYER_H,
                common.PLAYER_W, 1)
            if nHits > 0 then
                player.vy = -500
            end
        end
    end
end

function server.update(dt)
    for id, player in pairs(share.players) do
        player.vx = 0

        local controls = homes[id].controls
        if controls then
            if not (controls.left and controls.right) then
                if controls.left then
                    player.vx = -200
                end
                if controls.right then
                    player.vx = 200
                end
            end
        end

        player.vy = math.min(player.vy + 1200 * dt, 40000)
        local newX, newY = world:move(player, player.x + player.vx * dt, player.y + player.vy * dt)
        player.vx, player.vy = (newX - player.x) / dt, (newY - player.y) / dt
        player.x, player.y = newX, newY
    end
end
