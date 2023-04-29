local M = {}

---Configurable user options.
local opts = {
	tmp_filepath = vim.fn.stdpath("cache") .. "/ranger_selected_file",
}

---Opens all files in `filepath` in buffers.
---@param filepath string
local function open_files(filepath)
	local selected_files = vim.fn.readfile(filepath)
	for _, file in ipairs(selected_files) do
		vim.cmd.edit(file)
	end
end

---Opens ranger in a new tab and will open selected files on exit.
function M.open()
	local last_tabpage = vim.api.nvim_get_current_tabpage()
	vim.cmd.tabnew()
	vim.fn.termopen("ranger --choosefiles=" .. opts.tmp_filepath, {
		on_exit = function()
			vim.api.nvim_buf_delete(0, {})
			vim.api.nvim_set_current_tabpage(last_tabpage)

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
	opts = user_opts or opts
end

return M
