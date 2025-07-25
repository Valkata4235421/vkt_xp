local showUI = false

RegisterNetEvent('vkt_xp:client:showUI', function(data)
    if type(data) ~= "table" then return end

    local categories = {}
    for category, info in pairs(Config.Categories) do
        local playerData = data[category] or { xp = 0, level = 1 }
        categories[category] = {
            label = info.label,
            xp = playerData.xp,
            level = playerData.level,
            maxXP = info.xpStart + (playerData.level * info.xpFactor * info.xpStart)
        }
    end

    SendNUIMessage({
        action = 'showUI',
        categories = categories
    })

    SetNuiFocus(true, true)
    showUI = true
end)

RegisterNUICallback('closeUI', function(_, cb)
    SetNuiFocus(false, false)
    showUI = false
    cb('ok')
end)

RegisterCommand('xp', function()
    TriggerServerEvent('vkt_xp:server:getAllPlayerXP')
end, false)

RegisterNetEvent('vkt_xp:client:receiveAllXP', function(data)
    TriggerEvent('vkt_xp:client:showUI', data)
end)

exports('GetXP', function(categoryName)
    return exports['vkt_xp']:GetPlayerXPData(-1, categoryName)
end)

exports('GetLevel', function(categoryName)
    local data = exports['vkt_xp']:GetXP(categoryName)
    return data and data.level or 1
end)