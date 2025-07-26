fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'VKT Development'
description 'Standalone XP and Level System'
version '1.0.1'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'server.lua'
}

ui_page 'nui/ui.html'

files {
    'nui/*.*'
}
