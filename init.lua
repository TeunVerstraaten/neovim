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
	{ "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },

	{ "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },

	{ "neovim/nvim-lspconfig" },
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"onsails/lspkind.nvim",
			"nvim-tree/nvim-web-devicons",
		},
	},

	{
		"stevearc/conform.nvim",
		opts = {
			formatters_by_ft = {
				lua = { "stylua" },
				cpp = { "clang-format" },
				c = { "clang-format" },
				json = { "prettier" },
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
			window = { width = 30 },
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
	},

	{
		"rcarriga/nvim-dap-ui",
		dependencies = {
			"mfussenegger/nvim-dap",
			"nvim-neotest/nvim-nio",
		},
		config = function()
			local dap = require("dap")
			local dapui = require("dapui")

			dapui.setup()

			dap.listeners.after.event_initialized["dapui_config"] = function()
				dapui.open()
			end

			dap.listeners.before.event_terminated["dapui_config"] = function()
				dapui.close()
			end

			dap.listeners.before.event_exited["dapui_config"] = function()
				dapui.close()
			end
		end,
	},
	{
		"folke/flash.nvim",
		event = "VeryLazy",
		opts = {},
		keys = {
			{
				"s",
				mode = { "n", "x", "o" },
				function()
					require("flash").jump()
				end,
				desc = "Flash",
			},
			{
				"S",
				mode = { "n", "x", "o" },
				function()
					require("flash").treesitter()
				end,
				desc = "Flash Treesitter",
			},
			{
				"r",
				mode = "o",
				function()
					require("flash").remote()
				end,
				desc = "Remote Flash",
			},
			{
				"R",
				mode = { "o", "x" },
				function()
					require("flash").treesitter_search()
				end,
				desc = "Treesitter Search",
			},
			{
				"<c-s>",
				mode = { "c" },
				function()
					require("flash").toggle()
				end,
				desc = "Toggle Flash Search",
			},
		},
	},
	{ "j-hui/fidget.nvim" },
	{
		"nvim-telescope/telescope-ui-select.nvim",
		config = function()
			require("telescope").load_extension("ui-select")
		end,
	},
})

-- cppcheck
vim.api.nvim_create_user_command("Cppcheck", function()
	vim.fn.setqflist({}, "r", {
		title = "cppcheck",
		lines = vim.fn.systemlist(
			"cppcheck --project=build/compile_commands.json " .. "--enable=all"
			-- .. "--enable=warning,style,performance,portability "
			-- .. "--suppress=missingIncludeSystem"
		),
	})

	vim.cmd("copen")
end, {})

-- dap debugging
local dap = require("dap")

dap.adapters["lldb"] = {
	type = "executable",
	command = "lldb-dap",
	name = "lldb",
}

dap.configurations.cpp = {
	{
		name = "Launch",
		type = "lldb",
		request = "launch",
		program = function()
			return vim.fn.input("Path to executable: ", vim.fn.getcwd(), "file")
		end,
		cwd = "${workspaceFolder}",
		stopOnEntry = true,
		args = {},
	},
}

vim.api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		vim.highlight.on_yank({
			higroup = "Visual",
			timeout = 200,
		})
	end,
})

-- lsp

-----------------------------------------------------------
-- Completion
-----------------------------------------------------------

local cmp = require("cmp")
local lspkind = require("lspkind")

cmp.setup({
	completion = {
		completeopt = "menu,menuone,noinsert",
	},

	window = {
		completion = cmp.config.window.bordered({
			border = "rounded",
			winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None",
			scrollbar = true,
		}),

		documentation = cmp.config.window.bordered({
			border = "rounded",
			winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
		}),
	},

	formatting = {
		format = lspkind.cmp_format({
			mode = "symbol_text",
			maxwidth = 50,

			before = function(entry, vim_item)
				vim_item.menu = ({
					nvim_lsp = "[LSP]",
					buffer = "[Buffer]",
					path = "[Path]",
				})[entry.source.name]

				return vim_item
			end,
		}),
	},

	sources = cmp.config.sources({
		{ name = "nvim_lsp", priority = 100 },
	}, {
		{ name = "buffer", priority = 50 },
		{ name = "path", priority = 25 },
	}),

	sorting = {
		priority_weight = 2,
		comparators = {
			cmp.config.compare.offset,
			cmp.config.compare.exact,
			cmp.config.compare.score,
			cmp.config.compare.recently_used,
			cmp.config.compare.locality,
			cmp.config.compare.kind,
			cmp.config.compare.sort_text,
			cmp.config.compare.length,
			cmp.config.compare.order,
		},
	},

	mapping = cmp.mapping.preset.insert({
		["<C-Space>"] = cmp.mapping.complete(),

		["<CR>"] = cmp.mapping.confirm({
			select = false,
		}),

		["<Tab>"] = cmp.mapping.select_next_item(),
		["<S-Tab>"] = cmp.mapping.select_prev_item(),

		["<C-e>"] = cmp.mapping.abort(),
	}),

	experimental = {
		ghost_text = false,
	},
})

local capabilities = require("cmp_nvim_lsp").default_capabilities()

vim.diagnostic.config({
	virtual_text = true,
	signs = true,
	underline = true,
	update_in_insert = false,
	severity_sort = true,
})

vim.lsp.config("clangd", {
	cmd = {
		"clangd",
		"--background-index",
	},
	capabilities = capabilities,
})
vim.lsp.enable("clangd")

-- terminal
local terminal = { buf = nil, win = nil, previous_win = nil }

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

vim.api.nvim_create_autocmd("WinEnter", {
	callback = function()
		if vim.bo.buftype == "terminal" then
			vim.cmd("startinsert")
		end
	end,
})

--------------------------------------------------------
---------------  KEYMAPS   -----------------------------
--------------------------------------------------------
local builtin = require("telescope.builtin")

vim.keymap.set("n", "<leader>f", builtin.find_files, { desc = "Find files" })
vim.keymap.set("n", "<leader>k", builtin.keymaps, { desc = "Find keymaps" })
vim.keymap.set("n", "<leader>/", builtin.live_grep, { desc = "Find word" })
vim.keymap.set("n", "<leader>b", builtin.buffers, { desc = "Find buffers" })
vim.keymap.set("n", "<leader>h", builtin.help_tags, { desc = "Find help" })
vim.keymap.set("n", "<leader>r", builtin.oldfiles, { desc = "Find recent files" })
vim.keymap.set("n", "<leader>D", builtin.diagnostics, { desc = "Find diagnostics" })
-- vim.keymap.set("n", "<leader>fc", builtin.commands, { desc = "Find commands" })

-- Terminal
vim.keymap.set("n", "<leader>e", "<cmd>Neotree toggle<cr>", { desc = "Toggle file explorer" })
vim.keymap.set("n", "<leader>t", "<cmd>ToggleTerm<cr>", { desc = "Toggle terminal" })
vim.keymap.set("n", "<C-\\>", focus_terminal, { desc = "Focus bottom terminal" })
vim.keymap.set("t", "<C-\\>", leave_terminal, { desc = "Return from terminal" })
-- vim.keymap.set("t", "<Esc><Esc>", leave_terminal, { desc = "Exit terminal" })

-- lsp stuff
require("telescope").load_extension("ui-select")

vim.keymap.set("n", "gd", builtin.lsp_definitions, { desc = "Go to definition" })
vim.keymap.set("n", "gi", builtin.lsp_implementations, { desc = "Go to implementation" })
vim.keymap.set("n", "gr", builtin.lsp_references, { desc = "Find references" })
vim.keymap.set("n", "gt", builtin.lsp_type_definitions, { desc = "Go to type definition" })
vim.keymap.set("n", "<leader>a", vim.lsp.buf.code_action, { desc = "Code actions" })

-- debugging
vim.keymap.set("n", "<F5>", dap.continue, { desc = "Debug: Continue" })
vim.keymap.set("n", "<F10>", dap.step_over, { desc = "Debug: Step over" })
vim.keymap.set("n", "<F11>", dap.step_into, { desc = "Debug: Step into" })
vim.keymap.set("n", "<F12>", dap.step_out, { desc = "Debug: Step out" })
vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Debug: Toggle breakpoint" })
vim.keymap.set("n", "<leader>dB", function()
	dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
end, { desc = "Debug: Conditional breakpoint" })
vim.keymap.set("n", "<leader>dr", dap.repl.open, { desc = "Debug: REPL" })
vim.keymap.set("n", "<leader>dq", dap.terminate, { desc = "Debug: Quit" })

-- Don't overwrite the clipboard when deleting or changing
vim.keymap.set("n", "d", '"_d')
vim.keymap.set("n", "D", '"_D')
vim.keymap.set("n", "c", '"_c')
vim.keymap.set("n", "C", '"_C')

vim.keymap.set("v", "d", '"_d')
vim.keymap.set("v", "c", '"_c')

--------------------------------------------------------
---------------  OPTIONS   -----------------------------
--------------------------------------------------------
vim.cmd.colorscheme("catppuccin")
vim.opt.clipboard = "unnamedplus"
vim.opt.undofile = true
