local discordia = require("discordia")
local coro = require("coro-http")
local json = require("json")
local client = discordia.Client()

--  Split a string into many tokens
function commandTokenize(commandString)
    q = {}
    for token in string.gmatch(commandString, "[^%s]+") do
        q[#q + 1] = token
    end
    return q
end

-- Gets a Chuck Norris joke. Dumb, I know, but I wanted to work on some JSON gimmicks
function getChuckNorris(message)
    coroutine.wrap(
        function()
            local link = "https://api.chucknorris.io/jokes/random"
            local result, body = coro.request("GET", link)
            body = json.parse(body)
            message:reply("<@!"..message.member.id.."> "..body["value"])
        end
    )()
end


client:on("messageCreate", function(message)
    local content = message.content
    local member = message.member
    local memberId = message.member.id

    local tokens = commandTokenize(content)
    if tokens[1]:lower() == "tukkan" then
        if tokens[2]:lower() == "ping" then
            message:reply("Fuck off!!")
        elseif tokens[2]:lower() == "norris" or tokens[2]:lower() == "chuck" then
            getChuckNorris(message)
        end
    end
end
)


file = io.open("botToken/token.txt", "r")
client:run("Bot "..file:read())
file:close()