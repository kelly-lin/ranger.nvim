local M = {}

---Configurable user options.
local opts = {
	tmp_filepath = vim.fn.stdpath("cache") .. "/ranger_selected_file",
	replace_netrw = true,
	disable_netrw = true,
}

---Opens all files in `filepath` in buffers.
---@param filepath string
local function open_files(filepath)
	local selected_files = vim.fn.readfile(filepath)
	for _, file in ipairs(selected_files) do
		vim.cmd.edit(file)
	end
end

---Builds the ranger command.
---@param select_current_file boolean open ranger with the current buffer file selected.
local function build_cmd(select_current_file)
	local result = "ranger --choosefiles=" .. opts.tmp_filepath
	if select_current_file then
		result = result .. " --selectfile=" .. vim.fn.expand("%")
	end
	return result
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
	local cmd = build_cmd(select_current_file)

	local buf = vim.api.nvim_create_buf(false, true)
	local last_win = vim.api.nvim_get_current_win()
	vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = vim.o.columns,
		height = vim.o.lines - vim.o.cmdheight,
		row = 0,
		col = 0,
	})
	vim.api.nvim_set_hl(0, "NormalFloat", { bg = "" })

	vim.fn.termopen(cmd, {
		on_exit = function()
			vim.api.nvim_win_close(0, true)
			vim.api.nvim_set_current_win(last_win)
			if vim.fn.filereadable(opts.tmp_filepath) == 1 then
				open_files(opts.tmp_filepath)
				vim.fn.delete(opts.tmp_filepath)
			end
		end,
	})
	vim.cmd.startinsert()
end

---Optional setup to configure ranger.nvim.
---@param user_opts table|nil Configurable options: - tmp_filepath (string): location of temporary file.
function M.setup(user_opts)
	if user_opts then
		opts = vim.tbl_deep_extend("force", opts, user_opts)
	end
	if opts.replace_netrw then
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
	if opts.disable_netrw then
		vim.g.loaded_netrw = 1
		vim.g.loaded_netrwPlugin = 1
	end
end

return M

