if not vim.fn.executable('newf') then return end
-- Auto pipe newf -o file to the buffer if file doesn't exists.
local newf_group = vim.api.nvim_create_augroup('NewfGroup', {clear = true})
vim.api.nvim_create_autocmd('BufNewFile', {
	group = newf_group,
	callback = function()
		local file = vim.fn.expand('<afile>')
		if file == '' or vim.o.buftype ~= '' then return end

		local result = vim.system(
			{"newf", "-o", file},
			{ text = true }
		):wait()
		if result.code ~= 0 then return end
		local lines = vim.split(result.stdout, "\n", {
			plain = true,
			trimempty = true,
		})
		vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
		vim.bo.modified = false
	end
})
