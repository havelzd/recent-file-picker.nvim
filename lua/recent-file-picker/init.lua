local utils = require("recent-file-picker.utils")
local M = {}
local time = 0

local buffer_access_times = {}
local bufnr_name = "rfp"
local width = math.ceil(vim.o.columns * 0.8)
local height = math.ceil(vim.o.lines * 0.8)
local win_opts = {
	relative = "editor",
	width = width,
	height = height,
	col = math.ceil((vim.o.columns - width) / 2),
	row = math.ceil((vim.o.lines - height) / 2),
	anchor = "NW",
	style = "minimal",
	border = "rounded",
}

function M.setup(opts)
	opts = opts or {}
	M.setup_autocommands()
end

M.buffer_access_times = buffer_access_times

--[[
-- Setup autocommands to track buffer access times on BufEnter event
    ]]
function M.setup_autocommands()
	local group = vim.api.nvim_create_augroup("MyPluginCleanup", { clear = true })
	-- Initialize buffer access times tracking
	vim.api.nvim_create_autocmd("BufEnter", {
		group = group,
		pattern = "*",
		callback = function()
			local buf = vim.api.nvim_get_current_buf()
			-- check if bufid is valid
			if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "" and vim.bo[buf].buflisted then
				buffer_access_times[vim.api.nvim_get_current_buf()] = time
				time = time + 1
			end
		end,
	})
end

--[[
-- Open a floating window to display the list of recent files
    ]]
function M.open_float_window()
	local bufnr = utils.find_buffer_by_name(bufnr_name)
	if not bufnr then
		bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_name(bufnr, bufnr_name)
	end
	local win = vim.api.nvim_open_win(bufnr, true, win_opts)
	vim.api.nvim_win_set_option(win, "cursorline", true) -- Highlight the current line
	M.float_win = win

	return bufnr, win
end

--[[
-- Jump to the buffer selected in the floating window
    ]]
function M.jump_to_buffer()
	local line = vim.api.nvim_get_current_line()
	local lineNumber = vim.api.nvim_win_get_cursor(0)[1]
	if lineNumber <= 1 then
		return
	end

	local bufnr = line:match("^(%d+):") -- Extract buffer number from line
	local win_to_open = nil
	if not bufnr then
		error("Failed get bufnr")
		return
	end
	bufnr = tonumber(bufnr)

	-- Check if the buffer is already open in any window, if not, open it in a new window
	local windows = vim.api.nvim_list_wins()
	for _, win in ipairs(windows) do
		if vim.api.nvim_win_get_buf(win) == bufnr then
			win_to_open = win
			break
		end
	end
	if not win_to_open then
		win_to_open = M.current_win
	end

	-- set buffer and redraw
	vim.api.nvim_win_set_buf(win_to_open, bufnr)
	vim.api.nvim_command("redraw") -- Force redraw of the UI
	-- Close the floating window
	vim.api.nvim_win_close(M.float_win, true)
end

--[[
-- Create lines to display in the floating window
    ]]
local function createLines(buffers)
	local lines = {}
	table.insert(lines, "RFP - press 'q' to quit")

	for _, buf in ipairs(buffers) do
		table.insert(lines, string.format("%d: %s", buf.bufnr, buf.name))
	end
	return lines
end

--[[
-- List all the buffers in a floating window
    ]]
function M.list_buffers()
	M.current_win = vim.api.nvim_get_current_win()

	local bufnr, win = M.open_float_window()
	vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
	local buffers = {}
	for buffer_number, _ in pairs(M.buffer_access_times) do
		if vim.api.nvim_buf_is_loaded(buffer_number) then
			table.insert(buffers, {
				bufnr = buffer_number,
				time = M.buffer_access_times[buffer_number],
				name = vim.api.nvim_buf_get_name(buffer_number),
			})
		end
	end
	table.sort(buffers, function(a, b)
		return a.time < b.time
	end)

	local lines = createLines(buffers)

	local cursor_line = 0
	-- (#lines > 1 and 2 or 1)
	if #lines > 1 then
		cursor_line = #lines - 1
	end
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
	vim.api.nvim_win_set_cursor(win, { cursor_line, 0 })
	vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
	-- Set key mappings for each line
	vim.api.nvim_buf_set_keymap(
		bufnr,
		"n",
		"<CR>",
		'<cmd>lua require("recent-file-picker").jump_to_buffer()<CR>',
		{ noremap = true, silent = true }
	)
	vim.api.nvim_buf_set_keymap(bufnr, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
end

--[[
-- Cleanup function to be called when the plugin is closed
    ]]
function M.cleanup()
	M.opened = false
end

return M
