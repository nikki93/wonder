local CS_VERSION = '1e53007f1b30ca59b1e8049f6f56504583e8ed76'
cs = require('https://raw.githubusercontent.com/expo/share.lua/' .. CS_VERSION .. '/cs.lua')
bump = require 'https://raw.githubusercontent.com/kikito/bump.lua/ca27d8cc1a374ba6a8e3ce0c38fe1c7375cd8fa4/bump.lua'
serpent = require 'https://raw.githubusercontent.com/pkulchenko/serpent/522a6239f25997b101c585c0daf6a15b7e37fad9/src/serpent.lua'
moonshine = require 'https://raw.githubusercontent.com/nikki93/moonshine/9e04869e3ceaa76c42a69c52a954ea7f6af0469c/init.lua'


-- `love.graphics.stacked([arg], func)` calls `func` between `love.graphics.push([arg])` and
-- `love.graphics.pop()` while being resilient to errors
function love.graphics.stacked(argOrFunc, funcOrNil)
    love.graphics.push(funcOrNil and argOrFunc)
    local succeeded, err = pcall(funcOrNil or argOrFunc)
    love.graphics.pop()
    if not succeeded then
        error(err, 0)
    end
end


local common = {}

common.NUM_LEVELS = 1

common.PLAYER_W, common.PLAYER_H = 38, 90

common.ASSETS_DIR = '/Users/nikki/Development/ghost/wonder/assets'

function common.loadBg(level)
    return love.graphics.newImage('assets/bg-' .. level .. '.png')
end

function common.loadBlocks(level)
    local blocks = {}
    local ok, str = pcall(network.fetch, portal.basePath .. '/assets/blocks-' .. level .. '.lua')
    if ok then
        local ok, res = serpent.load(str)
        if ok then
            blocks = res
        end
    end
    return blocks
end

function common.writeBlocks(level, blocks)
    local file = io.open(common.ASSETS_DIR .. '/blocks-' .. level .. '.lua', 'w')
    file:write(serpent.block(blocks))
    file:close()
end

return common
