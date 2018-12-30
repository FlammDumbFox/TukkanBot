-- Requirements for the bot itself to work

local discordia = require("discordia")
local coro = require("coro-http")
local json = require("json")
local client = discordia.Client()

--  Commands and utilities
function commandTokenize(commandString)
    q = {}
    for token in string.gmatch(commandString, "[^%s]+") do
        q[#q + 1] = token
    end
    return q
end

function getLevelsFromFile()
    local l = {}
    local tokens = {}
    local f = io.open("ladder/exp_table.txt", "r")

    for i = 1, 100 do
        local finput = f:read()
        local q = {}
        tokens = commandTokenize(finput)

        q["level"] = tokens[1]
        q["exp_total"] = tokens[2]
        q["exp_toNext"]= tokens[3]
        table.insert(l, q)
    end
    return l
end

function getPercentage(levelTable, playerLevel, playerExp)
    print("Player level: "..playerLevel.."\n")
    print("Total EXP for this level: "..levelTable[tonumber(playerLevel)]["exp_total"].."\n")

    local percentage = math.floor((10000 * ((playerExp - levelTable[tonumber(playerLevel)]["exp_total"]) / levelTable[tonumber(playerLevel)]["exp_toNext"]))) / 100
    local ps = tostring(percentage)
    return percentage.."%"
end

function doesFileExist(name)
    local f = io.open(name, "r")
    if f ~= nil then
        io.close(f)
        return true
    else
        return false
    end
end

function writel(f, s)
    f:write(s)
    f:write("\n")
end


function printLadder(message, levelTable)
    local f = io.open("ladder/update_now.txt", "r")
    local n = f:read()

    for i = 1, 100 do
        print(i.." - "..levelTable[i]["level"]..": "..levelTable[i]["exp_total"])
    end


    for i = 1, tonumber(n) do
        local charName = f:read()
        local charRank = f:read()
        local charLevel = f:read()
        local charExperience = f:read()
        message.channel:send{
            embed = {
                title = "Rank #"..charRank..": "..charName,
                fields = {
                    { name = "Nível: ", value = charLevel, inline = true},
                    { name = "EXP: ", value = charExperience, inline = true},
                    { name = "Porcentagem: ", value = getPercentage(levelTable, charLevel, charExperience), inline = true}
                },
                color = discordia.Color.fromRGB(114, 100, 185).value
            }
        }
    end
end

function getLadder(message)
    local file_now = io.open("ladder/update_now.txt", "w+")
    coroutine.wrap(
        function()
            local link = "https://api.pathofexile.com/ladders/Akira+is+Dead+Inside+(PL1111)"
            -- local link = "http://api.pathofexile.com/ladders/Standard"
            local result, body = coro.request("GET", link)
            print(body)
            body = json.decode(body)
            -- writel(file_now, body["total"])
            file_now:write(body["total"].."\n")
            for i = 1, body["total"] do
                local charName = body["entries"][i]["character"]["name"]
                local charRank = body["entries"][i]["rank"]
                local charLevel = body["entries"][i]["character"]["level"]
                local charExperience = body["entries"][i]["character"]["experience"]

                writel(file_now, charName)
                writel(file_now, charRank)
                writel(file_now, charLevel)
                writel(file_now, charExperience)
            end
            file_now:close()
        end 
    )()
    message:reply("Peguei as informações da ladder, ou assim eu acho!")
end

    

-- Command aliases
    pingAliases = {"ping", "pong", "acorda", "fdp"}

-- Command handler

client:on("messageCreate", function(message)
    if message.author.bot == false then
        local content = message.content
        local member = message.member
        local memberId = message.member.id

        local tokens = commandTokenize(content)
        if tokens[1]:lower() == "tukkan" then
            if tokens[2]:lower() == "ping" then
                message:reply("Fuck off!!")
            elseif tokens[2]:lower() == "norris" or tokens[2]:lower() == "chuck" then
                message:reply(getChuckNorris())
            elseif tokens[2]:lower() == "ladder" then
                if tokens[3]:lower() == "get" or tokens[3]:lower() == "fetch" then
                    getLadder(message)
                elseif tokens[3]:lower() == "show" or tokens[3]:lower() == "display" then
                    printLadder(message, getLevelsFromFile())
                end
            end
        end
    end
end
)


file = io.open("botToken/token.txt", "r")
client:run("Bot "..file:read())
file:close()