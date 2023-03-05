function Admin(source,skip,identifiers,groups)
    if not Config.ScenesOnlyByAdmin then
        return true
    end
    if HasFullPerms(source) then
        return true
    end
    local AdminIdentifiers = AdminIdentifiers
    if identifiers and #identifiers > 0 then
        AdminIdentifiers = identifiers
    end
    local Groups = Groups
    if groups and #groups > 0 then
        Groups = groups
    end
    if GetResourceState('es_extended')=='started' and not skip then
        if not Main then
            Main = exports['es_extended']:getSharedObject()
        end
        local xPlayer = Main.GetPlayerFromId(source)
        local gr = xPlayer.group:lower()
        for i=1,#Groups do
            if Groups[i]:lower()==gr then
                return true
            end
        end
        if skip then
            return Admin(source,true,identifiers,groups)
        end
        return false
    else
        for i=1,#Groups do
            if IsPlayerAceAllowed(source,Groups[i]:lower()) then
                return true
            end
        end
        for _,identifier in ipairs(GetPlayerIdentifiers(source))do
            for i=1,#AdminIdentifiers do
                if AdminIdentifiers[i] and tostring(AdminIdentifiers[i])~='' then
                    if identifier:find(AdminIdentifiers[i]) then
                        return true
                    end
                end
            end
        end
        return false
    end
    return false
end

function HasFullPerms(source)
    for _,identifier in ipairs(GetPlayerIdentifiers(source))do
        for i=1,#MaxAdminIdentifiers do
            if MaxAdminIdentifiers[i] and tostring(MaxAdminIdentifiers[i])~='' then
                if identifier:find(MaxAdminIdentifiers[i]) then
                    return true
                end
            end
        end
    end
    return false
end