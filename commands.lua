RegisterNetEvent('Scene_creator:'..Config.Commands.AllowScene.name, function()
    if not allow[source]then
        allow[source] = Admin(source,nil,Config.Commands.AllowScene?.Permissions?.Identifiers,Config.Commands.AllowScene?.Permissions?.Groups)
    else
        allow[source] = false
    end
    TriggerClientEvent('Scene_creator:allow',source,allow[source])
end)

RegisterNetEvent('Scene_creator:'..Config.Commands.ShowAdmin.name, function()
    if Admin(source,nil,Config.Commands.ShowAdmin?.Permissions?.Identifiers,Config.Commands.ShowAdmin?.Permissions?.Groups) then
        TriggerClientEvent('Scene_creator:openAdmin',source)
    end
end)

RegisterNetEvent('Scene_creator:'..Config.Commands.SaveTemplate.name, function()
    if Admin(source,nil,Config.Commands.ShowAdmin?.Permissions?.Identifiers,Config.Commands.ShowAdmin?.Permissions?.Groups) then
        TriggerClientEvent('Scene_creator:saveTemplate',source)
    end
end)

RegisterNetEvent('Scene_creator:'..Config.Commands.DeleteAll.name, function()
    if Admin(source,nil,Config.Commands.DeleteAll?.Permissions?.Identifiers,Config.Commands.DeleteAll?.Permissions?.Groups) then
        TriggerClientEvent('Scene_creator:sceneDeleteAll',source)
    end
end)

--Server Console Commands

RegisterCommand('removescenebucket', function(source,args)
    if source == 0 then
        DeleteScene(args[1])
    end
end)

RegisterCommand('setscenebucket', function(source,args)
    if source==0 then
        SetSceneBucket(args[1],args[2])
    end
end)

RegisterCommand('loadscenebucket', function(source,args)
    if source==0 then
        LoadSceneBucket(args[1])
    end
end)