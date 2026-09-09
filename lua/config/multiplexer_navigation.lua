local M = {}

local directions = {
	left = { wincmd = "h", tmux = "Left" },
	down = { wincmd = "j", tmux = "Down" },
	up = { wincmd = "k", tmux = "Up" },
	right = { wincmd = "l", tmux = "Right" },
}

local function herdr_binary()
	local herdr = vim.env.HERDR_BIN_PATH
	return herdr and herdr ~= "" and herdr or "herdr"
end

local function sidebar_pane(herdr)
	local workspace = vim.env.HERDR_WORKSPACE_ID
	local tab = vim.env.HERDR_TAB_ID
	if not workspace or workspace == "" or not tab or tab == "" then
		return nil
	end

	local result = vim.system({ herdr, "pane", "list", "--workspace", workspace }, { text = true }):wait()
	if result.code ~= 0 then
		return nil
	end

	local ok, response = pcall(vim.json.decode, result.stdout)
	if not ok then
		return nil
	end

	for _, pane in ipairs(vim.tbl_get(response, "result", "panes") or {}) do
		if pane.tab_id == tab and pane.label == "nvim sidebar" then
			return pane.pane_id
		end
	end
end

function M.navigate(direction)
	local spec = directions[direction]
	if not spec then
		return
	end

	local previous_win = vim.api.nvim_get_current_win()
	vim.cmd("wincmd " .. spec.wincmd)
	if vim.api.nvim_get_current_win() ~= previous_win then
		return
	end

	if vim.env.HERDR_ENV == "1" then
		local herdr = herdr_binary()
		-- herdr-nvim's persistent daemon inherits the pane that launched it,
		-- not the current sidebar pane. Resolve the sidebar from the live tab
		-- instead of focusing relative to that stale (or unrelated) pane ID.
		local is_sidebar = vim.env.HERDR_PLUGIN_ID == "chmarax.herdr-nvim"
			and vim.env.HERDR_PLUGIN_ENTRYPOINT_ID == "sidebar"
		local pane = is_sidebar and sidebar_pane(herdr) or vim.env.HERDR_PANE_ID
		if not pane or pane == "" then
			vim.notify("could not resolve the current Herdr pane", vim.log.levels.WARN)
			return
		end

		local result = vim.system({ herdr, "pane", "focus", "--direction", direction, "--pane", pane }, {
			text = true,
		}):wait()
		if result.code ~= 0 then
			vim.notify(
				("herdr pane focus failed: %s"):format(result.stderr ~= "" and result.stderr or result.stdout),
				vim.log.levels.WARN
			)
		end
		return
	end

	if vim.env.TMUX and vim.env.TMUX ~= "" then
		pcall(vim.cmd, "TmuxNavigate" .. spec.tmux)
	end
end

return M
