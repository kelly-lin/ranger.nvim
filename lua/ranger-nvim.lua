local SELECTED_FILEPATH = vim.fn.stdpath("cache") .. "/ranger_selected_files"
local MODE_FILEPATH = vim.fn.stdpath("cache") .. "/ranger_mode"

local M = {}

---@enum OPEN_MODE
M.OPEN_MODE = {
	vsplit = "vsplit",
	split = "split",
	tabedit = "tabedit",
	rifle = "rifle",
}

---@alias Keybinds table<string, OPEN_MODE>

---Configurable user options.
---@class Options
---@field replace_netrw boolean
---@field keybinds Keybinds
local opts = {
	replace_netrw = false,
	keybinds = {
		["ov"] = M.OPEN_MODE.vsplit,
		["oh"] = M.OPEN_MODE.split,
		["ot"] = M.OPEN_MODE.tabedit,
		["os"] = M.OPEN_MODE.rifle,
	},
}

---Opens all files in `filepath` using `open`.
---@param filepath string
---@param open function
local function open_files(filepath, open)
	local selected_files = vim.fn.readfile(filepath)
	for _, file in ipairs(selected_files) do
		open(file)
	end
end

---Build the ranger command flags for keybinds.
---@param cmds table<integer,string>
local function create_ranger_cmd_flags(cmds)
	local create_ranger_cmd_flag = function(cmd)
		return string.format("--cmd='%s'", cmd)
	end

	local concat_with_space = function(target, subject)
		return string.format("%s %s", target, subject)
	end

	local result = ""
	for _, cmd in ipairs(cmds) do
		if result == "" then
			result = create_ranger_cmd_flag(cmd)
		else
			result = concat_with_space(result, create_ranger_cmd_flag(cmd))
		end
	end
	return result
end

---Creates the ranger mapping command.
---@param keybinding string
---@param mode string the mode the file(s) will be open in, e.g. vsplit, tab.
---@param mode_filepath string file where the selected mode will be output to.
---@return string ranger_mapping ranger mapping command.
local function create_map_cmd(keybinding, mode, mode_filepath)
	return string.format("map %s chain shell echo '%s' > %s; move right=1", keybinding, mode, mode_filepath)
end

---Transforms the `keybinds` into a `table<integer, string>` containing the
---ranger mapping commands.
---@param keybinds Keybinds keybinds.
---@return table<integer, string>
local function create_cmd_values(keybinds)
	local result = {}
	for keybind, mode in pairs(keybinds) do
		table.insert(result, create_map_cmd(keybind, mode, MODE_FILEPATH))
	end
	return result
end

---Builds the ranger command to be executed with open().
---@param select_current_file boolean open ranger with the current buffer file selected.
---@return string
local function build_ranger_cmd(select_current_file)
	local selectfile_flag = select_current_file and " --selectfile=" .. vim.fn.expand("%") or ""
	return string.format(
		"ranger --choosefiles=%s %s %s",
		SELECTED_FILEPATH,
		selectfile_flag,
		create_ranger_cmd_flags(create_cmd_values(opts.keybinds))
	)
end

---Open a window for ranger to run in.
local function open_win()
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = vim.o.columns,
		height = vim.o.lines - vim.o.cmdheight,
		row = 0,
		col = 0,
	})
	vim.api.nvim_set_hl(0, "NormalFloat", { bg = "" })
end

local function clean_up()
	vim.fn.delete(SELECTED_FILEPATH)
	vim.fn.delete(MODE_FILEPATH)
end

---@return function
local function get_open_func()
	local open = {
		current_win = function(filepath)
			vim.cmd.edit(filepath)
		end,
		vsplit = function(filepath)
			vim.cmd.vsplit(filepath)
		end,
		split = function(filepath)
			vim.cmd.split(filepath)
		end,
		tabedit = function(filepath)
			vim.cmd.tabedit(filepath)
		end,
		rifle = function(filepath)
			vim.fn.system({ "rifle", filepath })
		end,
	}

	if vim.fn.filereadable(MODE_FILEPATH) ~= 1 then
		return open.current_win
	end

	local mode = vim.fn.readfile(MODE_FILEPATH)[1]
	if mode == M.OPEN_MODE.vsplit then
		return open.vsplit
	elseif mode == M.OPEN_MODE.split then
		return open.split
	elseif mode == M.OPEN_MODE.tabedit then
		return open.tabedit
	elseif mode == M.OPEN_MODE.rifle then
		return open.rifle
	else
		return open.current_win
	end
end

---Opens ranger and open selected files on exit.
---@param select_current_file boolean|nil open ranger and select the current file. Defaults to true.
function M.open(select_current_file)
	if vim.fn.executable("ranger") ~= 1 then
		vim.api.nvim_err_write(
			"ranger executable not found, please check that ranger is installed and is in your path\n"
		)
		return
	end

	if select_current_file == nil then
		select_current_file = true
	end

	clean_up()

	local cmd = build_ranger_cmd(select_current_file)
	local last_win = vim.api.nvim_get_current_win()
	open_win()
	vim.fn.termopen(cmd, {
		on_exit = function()
			vim.api.nvim_win_close(0, true)
			vim.api.nvim_set_current_win(last_win)
			if vim.fn.filereadable(SELECTED_FILEPATH) == 1 then
				open_files(SELECTED_FILEPATH, get_open_func())
			end
			clean_up()
		end,
	})
	vim.cmd.startinsert()
end

---Disable and replace netrw with ranger.
local function replace_netrw()
	vim.g.loaded_netrw = 1
	vim.g.loaded_netrwPlugin = 1
	vim.api.nvim_create_autocmd("VimEnter", {
		pattern = "*",
		callback = function()
			if vim.fn.isdirectory(vim.fn.argv(0)) == 1 then
				M.open(false)
			end
			return true
		end,
	})
end

---Optional setup to configure ranger.nvim.
---@param user_opts Options Configurable options.
function M.setup(user_opts)
	if user_opts then
		opts = vim.tbl_deep_extend("force", opts, user_opts)
	end
	if opts.replace_netrw then
		replace_netrw()
	end
end

return M
