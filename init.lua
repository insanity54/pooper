if minetest.get_current_modname() ~= "pooper" then
   error("mod directory must be named 'pooper'");
end


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

-- Spawn stool at player location
local defecate = function(amount, player)
	minetest.sound_play("poop_defecate", {pos=minetest.get_player_by_name(player):get_pos(), gain = 1.0, max_hear_distance = 10,})
	minetest.add_item(minetest.get_player_by_name(player):get_pos(), "pooper:poop_turd")
end


minetest.register_craftitem("pooper:laxative", {
	description = "Laxative",
	inventory_image = "laxative.png",
	stack_max = 1,
	on_use = function(itemstack, user, pointed_thing)
		--replace_with_item = "vessels:glass_bottle"
		minetest.do_item_eat(0, "vessels:glass_bottle", itemstack, user, pointed_thing)
		minetest.chat_send_player(user:get_player_name(), "You suddenly feel unwell...")
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
