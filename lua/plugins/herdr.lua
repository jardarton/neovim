local nix = require("config.nix")

return {
	{
		"ChmaraX/herdr-nvim",
		name = "herdr-nvim",
		main = "herdr-nvim",
		enabled = nix.enableForCategory("ai", true)
			and nix.getCatOrDefault("opts.agentIntegration", "herdr") == "herdr",
		opts = { prefix = "<leader>e" },
	},
}
