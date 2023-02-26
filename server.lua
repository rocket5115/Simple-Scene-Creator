local files = {}
local allow = {}
local resource = GetCurrentResourceName()

RegisterCommand('allowscene', function(source)
    allow[source] = not allow[source]
    TriggerClientEvent('Scene_creator:allow',source,allow[source])
end)

RegisterNetEvent('Scene_creator:create_session', function(arg)
    local src = source
    if files[src]or not allow[src] then
        return
    else
        local file = ('UNSC'..(arg or math.random(99999))..'.txt')
        SaveResourceFile(resource, './projects/'..file,'[]',-1)
        files[src] = file
        TriggerClientEvent('Scene_creator:createdscene', src, file)
    end
end)

RegisterNetEvent('Scene_creator:save_session', function(data,compressed)
    local src = source
    if not files[src]or not allow[src] then
        return
    else
        SaveResourceFile(resource,'./projects/'..files[src],data,-1)
    end
end)

RegisterNetEvent('Scene_creator:load_session', function(id)
    local src = source
    if not allow[src] then
        return
    end
    local proj = LoadResourceFile(resource,'./projects/UNSC'..id..'.txt')
    if proj then
        files[src]='UNSC'..id..'.txt'
        TriggerClientEvent('Scene_creator:load_session', src, proj)
    else
        TriggerClientEvent('Scene_creator:load_session', src, false)
    end
end)

RegisterNetEvent('Scene_creator:unload', function()
    local src = source
    if not allow[src] then
        return
    end
    if files[src] then
        files[src]=nil
    end
end)

RegisterNetEvent('Scene_creator:save_template', function(data)
    local src = source
    if not allow[src] then
        return
    end
    if files[src] then
        local f = files[src]:gsub('UNSC','UNSCTEMP')
        SaveResourceFile(resource,'./projects/'..f,data,-1)
    end
end)

RegisterNetEvent('Scene_creator:load_template', function(id)
    local src = source
    if not allow[src] then
        return
    end
    local proj = LoadResourceFile(resource,'./projects/UNSCTEMP'..id..'.txt')
    if proj then
        TriggerClientEvent('Scene_creator:load_template', src, proj)
    end
end)