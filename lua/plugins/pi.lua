local nix = require("config.nix")

return {
	{
		"pi",
		enabled = nix.enableForCategory("ai", true)
			and nix.getCatOrDefault("opts.agentIntegration", "herdr") == "pi",
		dependencies = { { "folke/snacks.nvim", opts = { input = {}, picker = {} } } },
		config = function()
			require("pi").setup()
		end,
	},
}
