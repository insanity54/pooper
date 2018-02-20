if minetest.get_current_modname() ~= "pooper" then
   error("mod directory must be named 'pooper'");
end

dofile(minetest.get_modpath("pooper") .. "/keybind.lua")

minetest.register_node("pooper:poop_pile", {
	description = "Pile of Feces",
	tiles = {"poop_pile.png"},
	groups = {crumbly = 3, soil = 1, falling_node = 1},
	drop = "pooper:poop_turd" .. " 4",
	sounds = default.node_sound_dirt_defaults(),
})

minetest.register_craftitem("pooper:poop_turd", {
	description = "Feces",
	inventory_image = "poop_turd.png",
	on_use = minetest.item_eat(1)
})

minetest.register_craftitem("pooper:digestive_agent", {
	description = "Raw Digestive Agent",
	inventory_image = "raw_digestive_agent.png",
	stack_max = 1,
	on_use = minetest.item_eat(0, "vessels:glass_bottle")
})

minetest.register_craft({
	output = "pooper:poop_pile",
	recipe = {
		{"", "pooper:poop_turd", ""},
		{"pooper:poop_turd", "pooper:poop_turd", "pooper:poop_turd"}
	}
})

minetest.register_craft({
	output = "pooper:digestive_agent",
	recipe = {
		{"flowers:waterlily"},
		{"flowers:mushroom_red"},
		{"vessels:glass_bottle"}
	}
})

minetest.register_craft({
	type = "cooking",
	cooktime = 15,
	output = "pooper:laxative",
	recipe = "pooper:digestive_agent"
})

MIN_TIME_BETWEEN_PLAYER_POOP = 3600
FOOD_FILLS_BOWELS_BY = 600

-- Spawn stool at player location
local defecate = function(amount, player)
	if amount <= MIN_TIME_BETWEEN_PLAYER_POOP then
		minetest.chat_send_player(player, "Your bowels are empty!")
	else
		minetest.sound_play("poop_defecate", {pos=minetest.get_player_by_name(player):getpos(), gain = 1.0, max_hear_distance = 10,})
		minetest.add_item(minetest.get_player_by_name(player):getpos(), "pooper:poop_turd")
	end
end

local player_bowels = {}
local bowel_variance = {}

minetest.register_globalstep(function(dtime)
	for _, user in pairs(minetest.get_connected_players()) do
		local player = user:get_player_name()
		-- Sets initial bowel level when first iterating over this loop
		if player_bowels[player] == nil then
			player_bowels[player] = math.random(1, MIN_TIME_BETWEEN_PLAYER_POOP - 1)
		end
		if bowel_variance[player] == nil then
			bowel_variance[player] = math.random(800, 2000)
		end
		player_bowels[player] = player_bowels[player] + 1 --dtime
		-- Defecate at least every X seconds
		if player_bowels[player] >= MIN_TIME_BETWEEN_PLAYER_POOP + bowel_variance[player] then
			defecate(player_bowels[player], player)
			player_bowels[player] = 0
			bowel_variance[player] = math.random(800, 2000)
		end
		-- Gut growls to notify player of readiness to defecate
		if player_bowels[player] == MIN_TIME_BETWEEN_PLAYER_POOP then
			minetest.sound_play("poop_rumble", {pos=minetest.get_player_by_name(player):getpos(), gain = 1.0, max_hear_distance = 10,})
		end
	end
end)

-- Empty bowels when manual defecate is called
get_bowel_level = function(who)
	local player = who
	local snapshot = player_bowels[player]
	-- Check whether bowels have filled sufficiently or not
	if player_bowels[player] > MIN_TIME_BETWEEN_PLAYER_POOP then
		player_bowels[player] = 0
	end
	return snapshot
end

-- Manually defecate when sneak key is pressed
minetest.register_on_key_press(function(player, key)
	local pooper = player:get_player_name()
	if key == "aux1" then
		defecate(get_bowel_level(pooper), pooper)
	end
end)

-- Eating food item increases bowel level
minetest.register_on_item_eat(function(hp_change, replace_with_item, itemstack, user, pointed_thing)
	minetest.after(5, function()
		local player = user:get_player_name()
		player_bowels[player] = player_bowels[player] + FOOD_FILLS_BOWELS_BY
	end)
end)

minetest.register_abm(
	{nodenames = {"pooper:poop_pile"},
	interval = 2.0,
	chance = 1,
	-- Suffocate players within a 5 node radius of "poop_pile"
	action = function(pos)
	local objects = minetest.get_objects_inside_radius(pos, 5)
	-- Poll players for names to pass to set_breath()
	for i, obj in ipairs(objects) do
		if (obj:is_player()) then
			local depletion = minetest.get_player_by_name(obj:get_player_name()):get_breath() - 1
			if minetest.get_player_by_name(obj:get_player_name()):get_breath() > 1 then
				minetest.get_player_by_name(obj:get_player_name()):set_breath(depletion)
			else
				local health_initial = minetest.get_player_by_name(obj:get_player_name()):get_hp()
				local health_drain = health_initial - 0.5
				if health_drain > 2 then
					minetest.get_player_by_name(obj:get_player_name()):set_hp(health_drain)
				end
			end
		end
	end
end,
})

-- Clear player bowels on death
minetest.register_on_dieplayer(function(player)
	-- Such a low number to minimize likelihood of idle dead players pooping
	player_bowels[player:get_player_name()] = -90000
end)

-- Clear player bowels on respawn
minetest.register_on_respawnplayer(function(player)
	player_bowels[player:get_player_name()] = 0
end)

minetest.register_craftitem("pooper:laxative", {
	description = "Laxative",
	inventory_image = "laxative.png",
	stack_max = 1,
	on_use = function(itemstack, user, pointed_thing)
		--replace_with_item = "vessels:glass_bottle"
		minetest.do_item_eat(0, "vessels:glass_bottle", itemstack, user, pointed_thing)
		minetest.chat_send_player(user:get_player_name(), "You suddenly do not feel well...")
		minetest.sound_play("poop_rumble")
		for q = 1, 5 do
			minetest.after(math.random(4,8), function()
				defecate(999999, user:get_player_name())
			end)
		end
		itemstack:take_item()
			return "vessels:glass_bottle"
	end
})
