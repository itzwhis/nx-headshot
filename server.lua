local QBCore = exports['qb-core']:GetCoreObject()

-- Get formatted player info
local function GetPlayerInfo(source)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return "Unknown Player" end
    return string.format("%s %s (ID: %d)", 
        player.PlayerData.charinfo.firstname,
        player.PlayerData.charinfo.lastname,
        source
    )
end

-- Main webhook handler
RegisterNetEvent('nx-headshot:logHeadshot', function(killerId, victimId, screenshotUrl)
    -- Ensure proper Discord CDN URL
    if screenshotUrl then
        screenshotUrl = string.gsub(screenshotUrl, "media.discordapp.net", "cdn.discordapp.com")
    end

    local payload = {
        username = "Headshot Logger",
        avatar_url = "https://i.imgur.com/xJl5XpB.png",
        embeds = {{
            title = "🔫 HEADSHOT DETECTED",
            description = string.format(
                "**Killer:** %s\n**Victim:** %s",
                GetPlayerInfo(killerId),
                GetPlayerInfo(victimId)
            ),
            color = 16711680,
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            image = { url = screenshotUrl or "https://i.imgur.com/xJl5XpB.png" },
            footer = {
                text = "Server Time: "..os.date("%Y-%m-%d %H:%M:%S")
            }
        }}
    }

    PerformHttpRequest(Config.Webhooks.Logs, function(err, text, headers)
        if Config.Debug then
            print("^4[WEBHOOK STATUS]^0 Code:", err)
            if err ~= 200 then
                print("Response:", text)
            end
        end
    end, 'POST', json.encode(payload), { 
        ['Content-Type'] = 'application/json',
        ['User-Agent'] = 'FiveM-Headshot-Logger'
    })
end)

-- Debug command
RegisterCommand('testwebhook', function(source)
    local src = source or 1
    print("^5[TEST] Sending test webhook^0")
    TriggerEvent('nx-headshot:logHeadshot', src, src, "https://i.imgur.com/xJl5XpB.png")
end, true)