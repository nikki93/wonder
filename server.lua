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
        }
        local player = share.players[id]
        world:add(player, player.x, player.y, 72, 126)
        world:move(player, player.x, player.y + 1000)
        player.x, player.y = world:getRect(player)
    end
end

function server.update(dt)
    for id, player in pairs(share.players) do
        if homes[id].controls then
            if homes[id].controls.up then
                player.y = player.y - 400 * dt
            end
            if homes[id].controls.down then
                player.y = player.y + 400 * dt
            end
            if homes[id].controls.left then
                player.x = player.x - 400 * dt
            end
            if homes[id].controls.right then
                player.x = player.x + 400 * dt
            end
        end
    end
end
