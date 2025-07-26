local cooldowns = {}
local locks = {}
local LOCK_TIMEOUT = 10

local function NormalizeCategory(cat)
    return string.lower(cat or ""):gsub("%s+", "")
end

local function GetIdentifier(src)
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if string.match(id, "license:") then
            return id
        end
    end
    return nil
end

local function IsCooldownReady(src)
    local resource = GetInvokingResource() or "unknown"
    local now = os.time()

    cooldowns[src] = cooldowns[src] or {}
    local lastTime = cooldowns[src][resource] or 0

    if now - lastTime >= 2 then
        cooldowns[src][resource] = now
        return true
    end
    return false
end

local function IsValidCategory(cat)
    local normalized = NormalizeCategory(cat)
    return type(normalized) == "string" and Config.Categories[normalized] ~= nil
end

local function AcquireLock(src, category)
    locks[src] = locks[src] or {}

    local now = os.time()
    for cat, lockInfo in pairs(locks[src]) do
        if now - lockInfo.timestamp > LOCK_TIMEOUT then
            locks[src][cat] = nil
        end
    end

    if locks[src][category] then
        return false
    end

    locks[src][category] = { locked = true, timestamp = now }
    return true
end

local function ReleaseLock(src, category)
    if locks[src] then
        locks[src][category] = nil
    end
end

RegisterNetEvent('vkt_xp:server:initPlayerXP', function()
    local src = source
    local identifier = GetIdentifier(src)
    if not identifier then return end

    for category, _ in pairs(Config.Categories) do
        local normCategory = NormalizeCategory(category)
        MySQL.Async.fetchAll('SELECT xp, level FROM vkt_xp WHERE identifier = @identifier AND category = @category', {
            ['@identifier'] = identifier,
            ['@category'] = normCategory
        }, function(result)
            if not result[1] then
                MySQL.Async.execute('INSERT INTO vkt_xp (identifier, category, xp, level) VALUES (@identifier, @category, 0, 1)', {
                    ['@identifier'] = identifier,
                    ['@category'] = normCategory
                })
            end
        end)
    end

    TriggerClientEvent('vkt_xp:client:initComplete', src)
end)

RegisterNetEvent('vkt_xp:server:getAllPlayerXP', function()
    local src = source
    local identifier = GetIdentifier(src)
    if not identifier then return end

    MySQL.Async.fetchAll('SELECT category, xp, level FROM vkt_xp WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    }, function(result)
        local data = {}
        for _, row in ipairs(result) do
            data[row.category] = { xp = row.xp, level = row.level }
        end
        TriggerClientEvent('vkt_xp:client:showUI', src, data)
    end)
end)

exports('AddPlayerXP', function(source, categoryName, xpToAdd)
    local normCategory = NormalizeCategory(categoryName)
    if not IsValidCategory(normCategory) or type(xpToAdd) ~= "number" or xpToAdd <= 0 then return end
    if not IsCooldownReady(source) then return end
    if not AcquireLock(source, normCategory) then return end

    local identifier = GetIdentifier(source)
    if not identifier then 
        ReleaseLock(source, normCategory)
        return 
    end

    local categoryData = Config.Categories[normCategory]

    MySQL.Async.fetchAll('SELECT xp, level FROM vkt_xp WHERE identifier = @identifier AND category = @category', {
        ['@identifier'] = identifier,
        ['@category'] = normCategory
    }, function(result)
        local xp = xpToAdd
        local level = 1

        if result[1] then
            xp = result[1].xp + xpToAdd
            level = result[1].level
        end

        local neededXP = categoryData.xpStart + level * categoryData.xpFactor * categoryData.xpStart

        -- Level up only if below maxLevel
        while xp >= neededXP and level < categoryData.maxLevel do
            xp = xp - neededXP
            level = level + 1
            TriggerClientEvent('chat:addMessage', source, { args = { '^2[vkt_xp]', ('Leveled up %s to level %d!'):format(categoryData.label, level) } })
            neededXP = categoryData.xpStart + level * categoryData.xpFactor * categoryData.xpStart
        end

        -- If at maxLevel, allow XP overflow only if enabled
        if level == categoryData.maxLevel and not Config.AllowOverMaxLevel then
            local maxNeededXP = categoryData.xpStart + categoryData.maxLevel * categoryData.xpFactor * categoryData.xpStart
            if xp > maxNeededXP then
                xp = maxNeededXP
            end
        end

        -- Always cap level at maxLevel (to prevent level 6 and above)
        if level > categoryData.maxLevel then
            level = categoryData.maxLevel
        end

        if result[1] then
            MySQL.Async.execute('UPDATE vkt_xp SET xp = @xp, level = @level WHERE identifier = @identifier AND category = @category', {
                ['@xp'] = xp,
                ['@level'] = level,
                ['@identifier'] = identifier,
                ['@category'] = normCategory
            }, function()
                ReleaseLock(source, normCategory)
                TriggerEvent('vkt_xp:server:getAllPlayerXP', source)
            end)
        else
            MySQL.Async.execute('INSERT INTO vkt_xp (identifier, category, xp, level) VALUES (@identifier, @category, @xp, @level)', {
                ['@identifier'] = identifier,
                ['@category'] = normCategory,
                ['@xp'] = xp,
                ['@level'] = level
            }, function()
                ReleaseLock(source, normCategory)
                TriggerEvent('vkt_xp:server:getAllPlayerXP', source)
            end)
        end
    end)
end)

exports('GetPlayerXPData', function(source, categoryName)
    local identifier = GetIdentifier(source)
    local normCategory = NormalizeCategory(categoryName)
    if not identifier or not IsValidCategory(normCategory) then return { xp = 0, level = 1 } end

    local data = MySQL.Sync.fetchAll('SELECT xp, level FROM vkt_xp WHERE identifier = @identifier AND category = @category', {
        ['@identifier'] = identifier,
        ['@category'] = normCategory
    })
    if data[1] then
        return { xp = data[1].xp, level = data[1].level }
    end
    return { xp = 0, level = 1 }
end)

exports('InitPlayerXP', function(source)
    TriggerEvent('vkt_xp:server:initPlayerXP', source)
end)

AddEventHandler('playerDropped', function(reason)
    local src = source
    cooldowns[src] = nil
    locks[src] = nil
end)
