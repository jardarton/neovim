-- Run with: nvim --headless -u NONE -i NONE -l tests/clipboard.lua
package.path = "./lua/?.lua;" .. package.path

local original = {
	herdr = vim.env.HERDR_ENV,
	wayland = vim.env.WAYLAND_DISPLAY,
	display = vim.env.DISPLAY,
}
local copies = {}
package.loaded["vim.ui.clipboard.osc52"] = {
	copy = function(reg)
		assert(reg == "+")
		return function(lines)
			table.insert(copies, vim.deepcopy(lines))
		end
	end,
}

local function reset()
	pcall(vim.api.nvim_del_augroup_by_name, "vimmer_herdr_clipboard")
	vim.opt.clipboard = ""
end

local function check(herdr, wayland, display, mirrored)
	reset()
	vim.env.HERDR_ENV = herdr
	vim.env.WAYLAND_DISPLAY = wayland
	vim.env.DISPLAY = display
	require("config.clipboard").setup()
	assert(vim.deep_equal(vim.opt.clipboard:get(), mirrored and {} or { "unnamedplus" }))
	local before = #copies
	vim.api.nvim_buf_set_lines(0, 0, -1, false, { "hello", "world" })
	vim.cmd("normal! gg yy")
	assert(#copies == before + (mirrored and 1 or 0))
	if mirrored then
		assert(vim.deep_equal(copies[#copies], { "hello" }))
		vim.cmd('normal! "ayy')
		vim.cmd("normal! dd")
		assert(#copies == before + 1, "named yanks and deletes must not mirror")
		vim.cmd("normal! p")
		assert(vim.api.nvim_buf_get_lines(0, 1, 2, false)[1] == "hello", "local paste must work")
	end
end

if vim.uv.os_uname().sysname == "Linux" then
	check("1", nil, nil, true)
	check("1", "wayland-0", nil, false)
	check("1", nil, ":0", false)
end
check(nil, nil, nil, false)
check("0", nil, nil, false)

reset()
vim.env.HERDR_ENV = original.herdr
vim.env.WAYLAND_DISPLAY = original.wayland
vim.env.DISPLAY = original.display
print("clipboard tests passed")
