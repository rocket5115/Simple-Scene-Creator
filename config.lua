Config = {}
Config.Language = "en"
Config.ScenesOnlyByAdmin = true
Config.AutoEnable = false
Config.Groups = {
    'god','admin','mod','superadmin','_dev','best','owner'
}
Config.AdminAllow = function(source)
    if GetResourceState('es_extended')=='started' then
        if not Main then
            Main = exports['es_extended']:getSharedObject()
        end
        local xPlayer = Main.GetPlayerFromId(source)
        local gr = xPlayer.group:lower()
        for i=1,#Config.Groups do
            if Config.Groups[i]:lower()==gr then
                return true
            end
        end
        return false
    else
        if not Main then
            Main = true
        end
        for i=1,#Config.Groups do
            if IsPlayerAceAllowed(source,Config.Groups[i]) then
                return true
            end
        end
        return false
    end
    return false
end

--- Controlled By NUI
Config.SaveDefault = false --Save Any Major Change in physical JSON format
Config.SaveSpace = false --Compress JSON files in order to save space