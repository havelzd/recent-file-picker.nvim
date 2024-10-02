local M = {}

-- @Return buffer if buffer with name exists, nil otherwise
function M.find_buffer_by_name(name)
	for buffer = 1, vim.fn.bufnr("$") do
		if vim.fn.bufname(buffer) == name then
			return buffer
		end
	end
	return nil
end

return M
