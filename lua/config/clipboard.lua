local M = {}

function M.setup()
	-- In a headless Herdr pane, clipboard reads cannot reliably return from the
	-- viewer. Keep unnamed registers local and forward only ordinary yanks.
	local headless_herdr = vim.env.HERDR_ENV == "1"
		and vim.uv.os_uname().sysname == "Linux"
		and not vim.env.WAYLAND_DISPLAY
		and not vim.env.DISPLAY
	if not headless_herdr then
		vim.opt.clipboard = "unnamedplus"
		return
	end

	vim.opt.clipboard = ""
	local copy = require("vim.ui.clipboard.osc52").copy("+")
	vim.api.nvim_create_autocmd("TextYankPost", {
		group = vim.api.nvim_create_augroup("vimmer_herdr_clipboard", { clear = true }),
		desc = "Mirror unnamed yanks to the Herdr viewer clipboard",
		callback = function()
			local event = vim.v.event
			if event.operator == "y" and event.regname == "" then
				copy(event.regcontents)
			end
		end,
	})
end

return M
