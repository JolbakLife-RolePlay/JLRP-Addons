--Addon Account
local AccountsIndex, Accounts, SharedAccounts = {}, {}, {}

local OX_INVENTORY = exports['ox_inventory']

AddEventHandler('onResourceStart', function(resourceName)
	if resourceName == GetCurrentResourceName() then
		local accounts = MySQL.query.await('SELECT * FROM addon_account LEFT JOIN addon_account_data ON addon_account.name = addon_account_data.account_name UNION SELECT * FROM addon_account RIGHT JOIN addon_account_data ON addon_account.name = addon_account_data.account_name')

		local newAccounts = {}
		for i = 1, #accounts do
			local account = accounts[i]
			if account.shared == 0 then
				if not Accounts[account.name] then
					AccountsIndex[#AccountsIndex + 1] = account.name
					Accounts[account.name] = {}
				end
				Accounts[account.name][#Accounts[account.name] + 1] = CreateAddonAccount(account.name, account.owner, account.money)
			else
				if account.money then
					SharedAccounts[account.name] = CreateAddonAccount(account.name, nil, account.money)
				else
					newAccounts[#newAccounts + 1] = {account.name, 0}
				end
			end
		end

		if next(newAccounts) then
			MySQL.prepare('INSERT INTO addon_account_data (account_name, money) VALUES (?, ?)', newAccounts)
			for i = 1, #newAccounts do
				local newAccount = newAccounts[i]
				SharedAccounts[newAccount[1]] = CreateAddonAccount(newAccount[1], nil, 0)
			end
		end
	end
end)

function GetAccount(name, owner)
	for i=1, #Accounts[name], 1 do
		if Accounts[name][i].owner == owner then
			return Accounts[name][i]
		end
	end
end

function GetSharedAccount(name)
	return SharedAccounts[name]
end

AddEventHandler('JLRP-Addons-Account:getAccount', function(name, owner, cb)
	cb(GetAccount(name, owner))
end)

AddEventHandler('JLRP-Addons-Account:getSharedAccount', function(name, cb)
	cb(GetSharedAccount(name))
end)

--Addon Inventory
Items = {}
local InventoriesIndex, Inventories, SharedInventories = {}, {}, {}

if Framework.GetConfig().OxInventory then
	AddEventHandler('onServerResourceStart', function(resourceName)
		if resourceName == 'ox_inventory' or resourceName == GetCurrentResourceName() then
			local stashes = MySQL.query.await('SELECT * FROM addon_inventory')

			for i = 1, #stashes do
				local stash = stashes[i]
				local jobStash = stash.name:find('society') and string.sub(stash.name, 9)
				OX_INVENTORY:RegisterStash(stash.name, stash.label, 1000, 10000000, stash.shared == 0 and true or false, jobStash)
			end
		end
	end)

	return
end

MySQL.ready(function()
	--local items = MySQL.query.await('SELECT * FROM items')
	local items = OX_INVENTORY:Items()

	for i=1, #items, 1 do
		Items[items[i].name] = items[i].label
	end

	local result = MySQL.query.await('SELECT * FROM addon_inventory')

	for i=1, #result, 1 do
		local name   = result[i].name
		local label  = result[i].label
		local shared = result[i].shared

		local result2 = MySQL.query.await('SELECT * FROM addon_inventory_items WHERE inventory_name = ?', { name })

		if shared == 0 then

			table.insert(InventoriesIndex, name)

			Inventories[name] = {}
			local items       = {}

			for j=1, #result2, 1 do
				local itemName  = result2[j].name
				local itemCount = result2[j].count
				local itemOwner = result2[j].owner

				if items[itemOwner] == nil then
					items[itemOwner] = {}
				end

				table.insert(items[itemOwner], {
					name  = itemName,
					count = itemCount,
					label = Items[itemName]
				})
			end

			for k,v in pairs(items) do
				local addonInventory = CreateAddonInventory(name, k, v)
				table.insert(Inventories[name], addonInventory)
			end

		else
			local items = {}

			for j=1, #result2, 1 do
				table.insert(items, {
					name  = result2[j].name,
					count = result2[j].count,
					label = Items[result2[j].name]
				})
			end

			local addonInventory    = CreateAddonInventory(name, nil, items)
			SharedInventories[name] = addonInventory
		end
	end
end)

function GetInventory(name, owner)
	for i=1, #Inventories[name], 1 do
		if Inventories[name][i].owner == owner then
			return Inventories[name][i]
		end
	end
end

function GetSharedInventory(name)
	return SharedInventories[name]
end

AddEventHandler('JLRP-Addons:getInventory', function(name, owner, cb)
	cb(GetInventory(name, owner))
end)

AddEventHandler('JLRP-Addons:getSharedInventory', function(name, cb)
	cb(GetSharedInventory(name))
end)

--DataStore
local DataStores, DataStoresIndex, SharedDataStores = {}, {}, {}

AddEventHandler('onResourceStart', function(resourceName)
	if resourceName == GetCurrentResourceName() then
		local dataStore = MySQL.query.await('SELECT * FROM datastore_data LEFT JOIN datastore ON datastore_data.name = datastore.name UNION SELECT * FROM datastore_data RIGHT JOIN datastore ON datastore_data.name = datastore.name')

		local newData = {}
		for i = 1, #dataStore do
			local data = dataStore[i]
			if data.shared == 0 then
				if not DataStores[data.name] then
					DataStoresIndex[#DataStoresIndex + 1] = data.name
					DataStores[data.name] = {}
				end
				DataStores[data.name][#DataStores[data.name] + 1] = CreateDataStore(data.name, data.owner, json.decode(data.data))
			else
				if data.data then
					SharedDataStores[data.name] = CreateDataStore(data.name, nil, json.decode(data.data))
				else
					newData[#newData + 1] = {data.name, '\'{}\''}
				end
			end
		end

		if next(newData) then
			MySQL.prepare('INSERT INTO datastore_data (name, data) VALUES (?, ?)', newData)
			for i = 1, #newData do
				local new = newData[i]
				SharedDataStores[new[1]] = CreateDataStore(new[1], nil, {})
			end
		end
	end
end)

function GetDataStore(name, owner)
	for i=1, #DataStores[name], 1 do
		if DataStores[name][i].owner == owner then
			return DataStores[name][i]
		end
	end
end

function GetDataStoreOwners(name)
	local citizenids = {}

	for i=1, #DataStores[name], 1 do
		table.insert(citizenids, DataStores[name][i].owner)
	end

	return citizenids
end

function GetSharedDataStore(name)
	return SharedDataStores[name]
end

AddEventHandler('JLRP-Addons-Datastore:getDataStore', function(name, owner, cb)
	cb(GetDataStore(name, owner))
end)

AddEventHandler('JLRP-Addons-Datastore:getDataStoreOwners', function(name, cb)
	cb(GetDataStoreOwners(name))
end)

AddEventHandler('JLRP-Addons-Datastore:getSharedDataStore', function(name, cb)
	cb(GetSharedDataStore(name))
end)

--Addon Account & Addon Inventory & DataStore
AddEventHandler('JLRP-Framework:playerLoaded', function(playerId, xPlayer)
	--Addon Account
	local addonAccounts = {}

	for i=1, #AccountsIndex, 1 do
		local name    = AccountsIndex[i]
		local account = GetAccount(name, xPlayer.citizenid)

		if account == nil then
			MySQL.insert('INSERT INTO addon_account_data (account_name, money, owner) VALUES (?, ?, ?)', {name, 0, xPlayer.citizenid})

			account = CreateAddonAccount(name, xPlayer.citizenid, 0)
			Accounts[name][#Accounts[name] + 1] = account
		end

		addonAccounts[#addonAccounts + 1] = account
	end

	xPlayer.set('addonAccounts', addonAccounts)
	
	--Addon Inventory
	local addonInventories = {}

	for i=1, #InventoriesIndex, 1 do
		local name      = InventoriesIndex[i]
		local inventory = GetInventory(name, xPlayer.citizenid)

		if inventory == nil then
			inventory = CreateAddonInventory(name, xPlayer.citizenid, {})
			table.insert(Inventories[name], inventory)
		end

		table.insert(addonInventories, inventory)
	end

	xPlayer.set('addonInventories', addonInventories)
	
	--DataStore
	for i = 1, #DataStoresIndex, 1 do
		local name = DataStoresIndex[i]
		local dataStore = GetDataStore(name, xPlayer.citizenid)

		if not dataStore then
			MySQL.insert('INSERT INTO datastore_data (name, owner, data) VALUES (?, ?, ?)', {name, xPlayer.citizenid, '{}'})

			DataStores[name][#DataStores[name] + 1] = CreateDataStore(name, xPlayer.citizenid, {})
		end
	end
end)
