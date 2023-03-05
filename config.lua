Config = {}
Config.Language = "en"
Config.ScenesOnlyByAdmin = true --Allow /allowscene to admins
Config.AutoEnable = false --Auto check for option above

Config.Commands = {
    AllowScene = {
        name = 'allowscene',
        Keys = {
            'INSERT'
        },
        --[[Permissions = {
            Identifiers = {
                'steam:'
            },
            Groups = {
                'admin'
            }
        }]]
    },
    ShowAdmin = {
        name = 'showsceneadmin',
        Keys = {
            'F11'
        },
    },
    SaveTemplate = {
        name = 'savetemplate',
        Keys = {
            'LBRACKET'
        }
    },
    DeleteAll = {
        name = 'scenedeleteall',
        Keys = {
            'LSHIFT',
            'DELETE'
        }
    }
}

--- Controlled By NUI
Config.SaveDefault = false --Save Any Major Change in physical JSON format