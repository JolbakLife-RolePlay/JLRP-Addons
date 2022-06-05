fx_version 'cerulean'
use_fxv2_oal 'yes'
game 'gta5'
lua54 'yes'

name 'JLRP-Addons'
author 'Mahan#8183'
description 'JolbakLifeRP Addon Account & Addon Inventory & DataStore'

version '1.0'

server_scripts {
	'@JLRP-Framework/imports.lua',
	'@oxmysql/lib/MySQL.lua',
	'server/classes/*.lua',
	'server/main.lua'
}

dependency 'JLRP-Framework'
