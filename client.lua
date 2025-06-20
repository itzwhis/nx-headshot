local lastHeadshotTime = 0
local debugMode = true -- Set to false in production

-- Verify screenshot resource on start
CreateThread(function()
    Wait(5000) -- Wait for resources to load
    if not exports['screenshot-basic'] then
        print("^1[CRITICAL] screenshot-basic resource not running!^0")
        print("^1Add to server.cfg:^0 ensure screenshot-basic")
    else
        print("^2[STATUS] screenshot-basic ready^0")
    end
end)

-- Enhanced screenshot capture
local function TakeHeadshotScreenshot()
    local promise = promise.new()
    
    if not exports['screenshot-basic'] then
        promise:resolve(nil)
        return Citizen.Await(promise)
    end

    exports['screenshot-basic']:requestScreenshotUpload(
        Config.Webhooks.Screenshots, 
        'files[]', 
        function(data)
            local result = json.decode(data)
            
            if result and result.attachments and result.attachments[1] then
                if debugMode then
                    print("^2[SCREENSHOT] Success:^0", result.attachments[1].url)
                end
                promise:resolve(result.attachments[1].proxy_url) -- Use proxy_url
            else
                print("^1[SCREENSHOT FAILED] Response:^0", data)
                promise:resolve(nil)
            end
        end
    )
    
    return Citizen.Await(promise)
end

-- Headshot detection
AddEventHandler('game:playerDied', function(killerId, deathData)
    if killerId == PlayerId() or killerId == -1 then return end
    
    local isHeadshot = false
    for _, bone in ipairs(Config.HeadshotBones or {31086, 12844}) do
        if deathData.hitbone == bone then
            isHeadshot = true
            break
        end
    end
    
    if isHeadshot and GetGameTimer() - lastHeadshotTime > (Config.Cooldown or 30000) then
        lastHeadshotTime = GetGameTimer()
        
        Citizen.SetTimeout(1000, function() -- 1s delay for death anim
            local screenshotUrl = TakeHeadshotScreenshot()
            
            if not screenshotUrl and debugMode then
                print("^3[FALLBACK] Using default image^0")
            end
            
            TriggerServerEvent('nx-headshot:logHeadshot', 
                GetPlayerServerId(killerId),
                GetPlayerServerId(PlayerId()),
                screenshotUrl
            )
        end)
    end
end)

-- Test command
RegisterCommand('tesths', function()
    -- First take screenshot
    exports['screenshot-basic']:requestScreenshotUpload(
        Config.Webhooks.Screenshots,
        'files[]',
        function(data)
            local result = json.decode(data)
            if result and result.attachments then
                -- Get the PROXY URL (important for Discord embeds)
                local screenshotUrl = result.attachments[1].proxy_url
                
                -- Send BOTH to the TEXT webhook
                TriggerServerEvent('nx-headshot:logHeadshot', 
                    GetPlayerServerId(PlayerId()),
                    GetPlayerServerId(PlayerId()),
                    screenshotUrl -- Send URL to text webhook
                )
            else
                print("^1Screenshot failed^0")
            end
        end
    )
end, false)