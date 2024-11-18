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
---@field enable_cmds boolean set commands
---@field replace_netrw boolean
---@field keybinds Keybinds
---@field ui UI

---@class UI
---@field border string (see ':h nvim_open_win')
---@field height number from 0 to 1 (0 = 0% of screen and 1 = 100% of screen)
---@field width number from 0 to 1 (0 = 0% of screen and 1 = 100% of screen)
---@field x number from 0 to 1 (0 = left most of screen and 1 = right most of
---screen)
---@field y number from 0 to 1 (0 = top most of screen and 1 = bottom most of
---screen)
local opts = {
	enable_cmds = false,
	replace_netrw = false,
	keybinds = {
		["ov"] = M.OPEN_MODE.vsplit,
		["oh"] = M.OPEN_MODE.split,
		["ot"] = M.OPEN_MODE.tabedit,
		["or"] = M.OPEN_MODE.rifle,
	},
	ui = {
		border = "none",
		height = 1,
		width = 1,
		x = 0.5,
		y = 0.5,
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
---
---
local function get_absolute_argument()
	-- Access the first argument passed to Neovim
	local arg = vim.fn.argv(0) -- 0 is the index for the first argument

	-- Get the absolute path of the argument
	local absolute_path = vim.fn.fnamemodify(arg, ":p")

	-- Print the absolute path
	-- print("Absolute path of the argument: " .. absolute_path)

	return absolute_path
end
---
---
---
local function build_ranger_cmd(select_current_file)
	local selected_file = ""
	if vim.fn.expand("%") then
		selected_file = "'" .. vim.fn.expand("%") .. "'"
	end
	local selectfile_flag = select_current_file and " --selectfile=" .. selected_file or ""
	if select_current_file then
		return string.format(
			"ranger --choosefiles=%s %s %s",
			SELECTED_FILEPATH,
			selectfile_flag,
			create_ranger_cmd_flags(create_cmd_values(opts.keybinds))
		)
	else
		vim.api.nvim_buf_delete(1, { force = true })
		return string.format(
			"ranger  --choosefiles=%s %s %s",
			SELECTED_FILEPATH,
			create_ranger_cmd_flags(create_cmd_values(opts.keybinds)),
			get_absolute_argument()
		)
	end
end

---Open a window for ranger to run in.
local function open_win()
	local buf = vim.api.nvim_create_buf(false, true)
	local win_height = math.ceil(vim.o.lines * opts.ui.height)
	local win_width = math.ceil(vim.o.columns * opts.ui.width)
	local row = math.ceil((vim.o.lines - win_height) * opts.ui.y - 1)
	local col = math.ceil((vim.o.columns - win_width) * opts.ui.x)
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = win_width,
		height = win_height,
		border = opts.ui.border,
		row = row,
		col = col,
		style = "minimal",
	})
	vim.api.nvim_win_set_option(win, "winhl", "NormalFloat:Normal")
	vim.api.nvim_buf_set_option(buf, "filetype", "ranger")
end

---Clean up temporary files used to communicate between ranger and the plugin.
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
	if opts.enable_cmds then
		vim.cmd('command! Ranger lua require("ranger-nvim").open(true)')
	end
end

return M
