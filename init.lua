-- Leader
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Basic options
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = "a"
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.cursorline = true
vim.opt.scrolloff = 8

-- Keybindings
vim.keymap.set("n", "<leader>w", "<cmd>w<cr>")
vim.keymap.set("n", "<leader>q", "<cmd>q<cr>")
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr>")

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	-- Telescope
	{ "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },

	-- Treesitter
	{ "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },

	-- LSP
	{ "neovim/nvim-lspconfig" },

	-- Completion
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
		},
	},

	{
		"stevearc/conform.nvim",
		opts = {
			formatters_by_ft = {
				lua = { "stylua" },
				cpp = { "clang-format" },
				c = { "clang-format" },
			},
			format_on_save = { timeout_ms = 500, lsp_fallback = true },
		},
	},

	{ "mg979/vim-visual-multi", branch = "master" },

	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			"nvim-tree/nvim-web-devicons",
		},
		opts = {
			window = {
				width = 30,
			},

			filesystem = {
				commands = {
					delete = function(state)
						local node = state.tree:get_node()
						local path = node.path

						vim.fn.system({ "trash", path })

						require("neo-tree.sources.manager").refresh(state.name)
					end,
				},
			},
		},
	},
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {},
	},
})
vim.diagnostic.config({
	virtual_text = true,
	signs = true,
	underline = true,
	update_in_insert = false,
	severity_sort = true,
})

vim.lsp.enable("clangd")

-- terminal
local terminal = {
	buf = nil,
	win = nil,
	previous_win = nil,
}

local function terminal_is_open()
	return terminal.win ~= nil and vim.api.nvim_win_is_valid(terminal.win)
end

local function focus_terminal()
	if not terminal_is_open() then
		-- Remember where we came from
		terminal.previous_win = vim.api.nvim_get_current_win()

		-- Create the terminal
		vim.cmd("botright split")
		vim.cmd("resize " .. math.floor(vim.o.lines * 0.3))
		vim.cmd("terminal")

		terminal.buf = vim.api.nvim_get_current_buf()
		terminal.win = vim.api.nvim_get_current_win()
	else
		-- Remember the current window before switching
		terminal.previous_win = vim.api.nvim_get_current_win()
		vim.api.nvim_set_current_win(terminal.win)
	end

	-- Enter terminal mode
	vim.cmd("startinsert")
end

local function leave_terminal()
	-- Leave terminal mode
	vim.cmd("stopinsert")

	-- Return to the window we came from
	if terminal.previous_win and vim.api.nvim_win_is_valid(terminal.previous_win) then
		vim.api.nvim_set_current_win(terminal.previous_win)
	end
end
local builtin = require("telescope.builtin")

--------------------------------------------------------
---------------  KEYMAPS   -----------------------------
--------------------------------------------------------
vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
vim.keymap.set("n", "<leader>fk", builtin.keymaps, { desc = "Find keymaps" })
vim.keymap.set("n", "<leader>fw", builtin.live_grep, { desc = "Find word" })
vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Find buffers" })
vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Find help" })
vim.keymap.set("n", "<leader>fr", builtin.oldfiles, { desc = "Find recent files" })
vim.keymap.set("n", "<leader>fd", builtin.diagnostics, { desc = "Find diagnostics" })
vim.keymap.set("n", "<leader>fc", builtin.commands, { desc = "Find commands" })

vim.keymap.set("n", "<leader>e", "<cmd>Neotree toggle<cr>", { desc = "Toggle file explorer" })

vim.keymap.set("n", "<leader>t", "<cmd>ToggleTerm<cr>", { desc = "Toggle terminal" })
vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]])
-- Terminal
vim.keymap.set("n", "<C-\\>", focus_terminal, { desc = "Focus bottom terminal" })
vim.keymap.set("t", "<C-\\>", leave_terminal, { desc = "Return from terminal" })
vim.keymap.set("t", "<Esc><Esc>", leave_terminal, { desc = "Exit terminal" })

local builtin = require("telescope.builtin")

vim.keymap.set("n", "gd", builtin.lsp_definitions, {
	desc = "Go to definition",
})

vim.keymap.set("n", "gD", builtin.lsp_declarations, {
	desc = "Go to declaration",
})

vim.keymap.set("n", "gi", builtin.lsp_implementations, {
	desc = "Go to implementation",
})

vim.keymap.set("n", "gr", builtin.lsp_references, {
	desc = "Find references",
})

vim.keymap.set("n", "gt", builtin.lsp_type_definitions, {
	desc = "Go to type definition",
})

--------------------------------------------------------
---------------  OPTIONS   -----------------------------
--------------------------------------------------------
vvim.cmd.colorscheme("catppuccin")
