cmd_aliases = {
	data = {}
}

local function run_command(name, args)
	if not args or args == "" then
		return false, "You need a command."
	end
	local found, _, commandname, params = args:find("^([^%s]+)%s(.+)$")
	if not found then
		commandname = args
	end

	local command = minetest.chatcommands[commandname]
	if not command then
		return false, "Not a valid command."
	end
	if not minetest.check_player_privs(name, command.privs) then
		return false, "Your privileges are insufficient."
	end

	minetest.log("action", name.." runs " .. args .. " (from alias)")
	return command.func(name, (params or ""))
end

function cmd_aliases.get_player(name)
	return cmd_aliases.data[name] or {}
end

function cmd_aliases.get_player_or_nil(name)
	return cmd_aliases.data[name]
end

minetest.register_chatcommand("alias", {
	func = function(name, params)
		local alias_name, cmd = string.match(params,"^([%a%d_]+) (.+)")
		if alias_name and cmd then
			local aliases = cmd_aliases.get_player(name)
			aliases[alias_name] = cmd
			minetest.chat_send_player(name, "Alias " .. alias_name .. " set to " .. cmd)
			cmd_aliases.data[name] = aliases
		end
	end
})

minetest.register_on_chat_message(function(name, message)
	if message:sub(1, 1) == "/" then
		local aliases = cmd_aliases.get_player_or_nil(name)
		if not aliases then
			return
		end

		local alias_name, params = string.match(message,"^%/([%a%d_]+) (.+)")
		if not alias_name then
			alias_name = message:sub(2, #message)
		end

		local alias = aliases[alias_name]
		if alias then
			if params then
				local ret, msg = run_command(name, alias .. " " .. params)
				if ret then
					if msg then
						minetest.chat_send_player(name, msg)
					end
				end
			else
				local ret, msg = run_command(name, alias)
				if ret then
					if msg then
						minetest.chat_send_player(name, msg)
					end
				end
			end
			return true
		end
	end
end)
