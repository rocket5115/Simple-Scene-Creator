local identifiers = {
    --'steam:xxx',
    --'xxx'
    --'steam:110000xxx'
}

local groups = {
    'god','admin','mod','superadmin','_dev','best','owner'
}

function Admin(source)
    if not Config.ScenesOnlyByAdmin then
        return true
    end
    if GetResourceState('es_extended')=='started' then
        if not Main then
            Main = exports['es_extended']:getSharedObject()
        end
        local xPlayer = Main.GetPlayerFromId(source)
        local gr = xPlayer.group:lower()
        for i=1,#groups do
            if groups[i]:lower()==gr then
                return true
            end
        end
        return false
    else
        if not Main then
            Main = true
        end
        for i=1,#groups do
            if IsPlayerAceAllowed(source,groups) then
                return true
            end
        end
        for _,identifier in ipairs(GetPlayerIdentifiers(source))do
            for i=1,#identifiers do
                if identifiers[i] and tostring(identifiers[i])~='' then
                    if identifier:find(identifiers[i]) then
                        return true
                    end
                end
            end
        end
        return false
    end
    return false
end