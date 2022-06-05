function CreateAddonInventory(name, owner, items)
	local self = {}

	self.name  = name
	self.owner = owner
	self.items = items

	function self.addItem(name, count)
		local item = self.getItem(name)
		item.count = item.count + count
		Wait(100)
		self.saveItem(name, item.count)
	end

	function self.removeItem(name, count)
		local item = self.getItem(name)
		item.count = item.count - count

		self.saveItem(name, item.count)
	end

	function self.setItem(name, count)
		local item = self.getItem(name)
		item.count = count

		self.saveItem(name, item.count)
	end

	function self.getItem(name)
		for i=1, #self.items, 1 do
			if self.items[i].name == name then
				return self.items[i]
			end
		end

		item = {
			name  = name,
			count = 0,
			label = Items[name]
		}

		table.insert(self.items, item)

		if self.owner == nil then
			MySQL.update('INSERT INTO addon_inventory_items (inventory_name, name, count) VALUES (?, ?, ?)', { self.name, name, 0, self.owner })
		else
			MySQL.update('INSERT INTO addon_inventory_items (inventory_name, name, count, owner) VALUES (?, ?, ?, ?)', { self.name, name, 0 })
		end

		return item
	end

	function self.saveItem(name, count)
		if self.owner == nil then
			MySQL.update('UPDATE addon_inventory_items SET count = ? WHERE inventory_name = ? AND name = ?', { self.name, name, count })
		else
			MySQL.update('UPDATE addon_inventory_items SET count = ? WHERE inventory_name = ? AND name = ? AND owner = ?', { self.name, name, count, self.owner })
		end
	end

	return self
end

