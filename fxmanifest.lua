fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name "ls_framework"
description "This ressource is framework of Lore Santos RP fivem server"
author "SpaceTube_"
version "1.0.1"

shared_scripts {
	'shared/*.lua'
}

client_scripts {
	'client/*.lua'
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'server/config.lua',
	'server/*.lua'
}
