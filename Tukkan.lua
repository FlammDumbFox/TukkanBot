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

function getPercentage(levelTable, player)
    local charExp = player["charExperience"]
    local charLevel = tonumber(player["charLevel"])
    local totalExpToThisLevel = levelTable[charLevel]["exp_total"]
    local totalExpToNextLevel = levelTable[charLevel]["exp_toNext"]

    local percentage = math.floor((10000 * ((charExp - totalExpToThisLevel) / totalExpToNextLevel))) / 100
    local ps = tostring(percentage).."%"
    return ps
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

    for i = 1, tonumber(n) do
        local player = {}
        player["charName"] = f:read()
        player["charRank"] = f:read()
        player["charLevel"] = f:read()
        player["charExperience"] = f:read()
        local p = getPercentage(levelTable, player)
        print("% = "..p)

        message.channel:send{
            embed = {
                title = "Rank #"..player["charRank"]..": "..player["charName"],
                fields = {
                    { name = "Nível: ", value = player["charLevel"], inline = true},
                    { name = "EXP: ", value = player["charExperience"], inline = true},
                    { name = "Porcentagem: ", value = p, inline = true}
                },
                color = discordia.Color.fromRGB(114, 100, 185).value
            }
        }
    end
    f:close()
end

function printLadderWithLimit(message, levelTable, limit)
    local f = io.open("ladder/update_now.txt", "r")
    local n = f:read()

    if limit > tonumber(n) then
        message:reply("Tentando quebrar meu bot, é, parça? n deve ser menor ou igual a "..n.."!")
        return
    end

    for i = 1, limit do
        local player = {}
        player["charName"] = f:read()
        player["charRank"] = f:read()
        player["charLevel"] = f:read()
        player["charExperience"] = f:read()

        message.channel:send{
            embed = {
                title = "Rank #"..player["charRank"]..": "..player["charName"],
                fields = {
                    { name = "Nível: ", value = player["charLevel"], inline = true},
                    { name = "EXP: ", value = player["charExperience"], inline = true},
                    { name = "Porcentagem: ", value = getPercentage(levelTable, player), inline = true}
                },
                color = discordia.Color.fromRGB(114, 100, 185).value
            }
        }
    end
    f:close()
end

function getLadder(message)
    local file_now = io.open("ladder/update_now.txt", "w+")
    coroutine.wrap(
        function()
            local link = "https://api.pathofexile.com/ladders/Akira+is+Dead+Inside+(PL1111)"
            -- local link = "http://api.pathofexile.com/ladders/Standard"
            local result, body = coro.request("GET", link)
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
    message:reply("Peguei as informações da ladder, ou assim eu acho! owo")
end

function isNil(a)
    if a == nil then
        return true
    else
        return false
    end
end

-- Command handler
client:on("messageCreate", function(message)
    if message.author.bot == false then
        local content = message.content
        local member = message.member
        local memberId = message.member.id

        local tokens = commandTokenize(content)

        if tokens[1]:lower() == "tukkan" then
            if isNil(tokens[2]) or tokens[2]:lower() == "help" or tokens[2]:lower() == "ajuda" then
                message.channel:send("Usagem:\n- `tukkan <get|fetch>` -> Puxa a ladder pela API\n- `tukkan <show|display> [n]` -> Mostra a ladder. Caso o argumento n exista, apenas os n primeiros ranks serão mostrados\n\n\n(dica: não escreva owo/rawr/uwu)")
            elseif tokens[2]:lower() == "ping" then
                message:reply("rawr owo")
            elseif tokens[2]:lower() == "get" or tokens[2]:lower() == "fetch" then
                getLadder(message)
            elseif tokens[2]:lower() == "show" or tokens[2]:lower() == "display" then
                if isNil(tokens[3]) then
                    printLadder(message, getLevelsFromFile())
                else
                    local num = tonumber(tokens[3])
                    if isNil(num) then
                        message:reply("Erro: argumento DEVE ser um número!")
                    else
                        printLadderWithLimit(message, getLevelsFromFile(), num)
                    end
                end
            else
                message.channel:send("Usagem:\n- `tukkan <get|fetch>` -> Puxa a ladder pela API\n- `tukkan <show|display> [n]` -> Mostra a ladder. Caso o argumento n exista, apenas os n primeiros ranks serão mostrados\n\n\n(dica: não escreva owo/rawr/uwu)")
            end
        elseif tokens[1]:lower() == "owo" or tokens[1]:lower() == "rawr" or tokens[1]:lower() == "uwu" then
            message:reply("rawr owo")
        end
    end
end
)


file = io.open("botToken/token.txt", "r")
client:run("Bot "..file:read())
file:close()