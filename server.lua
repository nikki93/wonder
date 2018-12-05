local common = require 'common'


local server = cs.server

server.enabled = true
--server.useCastleServer()
server.start('22122')

local share = server.share
local homes = server.homes

function server.load()
    share.level = 1
    share.blocks = common.loadBlocks(share.level)
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
            x = spawn.x,
            y = spawn.y,
        }
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
