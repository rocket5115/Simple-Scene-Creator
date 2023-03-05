fx_version 'cerulean'

game 'gta5'

lua54 'yes'

shared_scripts {
    'config.lua',
}

client_scripts {
    'nui.lua',
    'translation.lua',
    'translations/*.lua',
    'client.lua'
}

server_scripts {
    'serverconfig.lua',
    'admin.lua',
    'server.lua',
    'commands.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/styles.css',
    'html/template.css',
    'html/script.js'
}