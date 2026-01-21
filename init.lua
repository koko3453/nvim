-- Neovim Config (requires Neovim 0.11+)
-- ==================================================
-- 1. Lazy.nvim Bootstrap
-- =====================================================
-- Lazy.nvim is a modern plugin manager for Neovim.
-- This section handles automatic installation if not already present.


-- Define the installation path for lazy.nvim in Neovim's data directory
-- Typically: ~/.local/share/nvim/lazy/lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

-- Check if lazy.nvim is already installed using the filesystem API
-- vim.uv is the newer API (Neovim 0.10+), vim.loop is the legacy fallback
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  -- Clone lazy.nvim from GitHub if not found
  -- --filter=blob:none: Shallow clone for faster download (no file history)
  -- --branch=stable: Use the stable release branch
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath,
  })  
end

-- Prepend lazy.nvim to the runtime path so Neovim can find it
vim.opt.rtp:prepend(lazypath)

-- Leader key must be set before plugins are loaded
-- The leader key acts as a prefix for custom keybindings
-- Setting it to space provides easy access for both hands
vim.g.mapleader = " "       -- Global leader key (used for most mappings)
vim.g.maplocalleader = " "  -- Local leader key (used for buffer-specific mappings)

-- Disable netrw (required for nvim-tree)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- =====================================================
-- 2. Plugin Configuration
-- =====================================================
require("lazy").setup({
  -- Colorscheme
  { "folke/tokyonight.nvim", lazy = false, priority = 1000 },

  -- Snacks.nvim: Provides the UI for Opencode
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      input = { enabled = true },
      notifier = { enabled = true },
      scope = { enabled = true },
      words = { enabled = true },
    },
  }, 

  -- UI & Tree
  { "nvim-lualine/lualine.nvim", dependencies = { "nvim-tree/nvim-web-devicons" } },
  { 
    "nvim-tree/nvim-tree.lua", 
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup()
    end,
  },
  { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },
  
  -- Nerdfont support
  { "ryanoasis/vim-devicons" },

  -- LSP Configuration (Neovim 0.11+ native API)
  {
    "neovim/nvim-lspconfig",
    config = function()
      -- Enable LSP servers using Neovim 0.11+ native API
      vim.lsp.enable('pyright')     -- Python
      vim.lsp.enable('ts_ls')       -- JavaScript/TypeScript
      vim.lsp.enable('clangd')      -- C/C++

      -- LSP Keymaps (set when LSP attaches to buffer)
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local opts = { buffer = args.buf }
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
          vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
          vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
          vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
          vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
        end,
      })
    end,
  },

  -- GitHub Copilot AI Autocomplete
  { "github/copilot.vim", event = "InsertEnter" },

  -- Autocompletion
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",  -- LSP completion source
      "hrsh7th/cmp-buffer",    -- Buffer completion source
      "hrsh7th/cmp-path",      -- Path completion source
    },
    config = function()
      local cmp = require("cmp")
      cmp.setup({
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),      -- Trigger completion
          ["<CR>"] = cmp.mapping.confirm({ select = true }), -- Confirm selection
          ["<Tab>"] = cmp.mapping.select_next_item(),  -- Next item
          ["<S-Tab>"] = cmp.mapping.select_prev_item(), -- Previous item
          ["<C-e>"] = cmp.mapping.abort(),             -- Close menu
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },  -- LSP completions (pyright, etc.)
          { name = "buffer" },   -- Words from current buffer
          { name = "path" },     -- File paths
        }),
      })
    end,
  },

 -- Treesitter (The Modern 2026 Fix)
  -- Treesitter (Legacy/Stable version)
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master", -- This pins it to the old version
    build = ":TSUpdate",
    config = function()
       require("nvim-treesitter.configs").setup({
         highlight = { enable = true },
         indent = { enable = true },
         ensure_installed = { "lua", "vim", "python", "javascript", "typescript" },
      })
    end,
  },

  -- Opencode AI Integration
  {
    "NickvanDyke/opencode.nvim",
    dependencies = { "folke/snacks.nvim" },
    lazy = false, -- Load immediately so commands are available
    opts = { 
      opencode_bin = os.getenv("HOME") .. "/.opencode/bin/opencode",
      model = "github/gpt-4o", 
      provider = { enabled = "snacks" }, -- Use Snacks for input/output
    },
    config = function(_, opts)
      -- Core configuration
      vim.g.opencode_opts = opts
      vim.o.autoread = true -- Automatically reload files changed by AI

      -- Define the :OpencodeAsk command
      vim.api.nvim_create_user_command("OpencodeAsk", function(args)
        local prompt = (args.args ~= "") and args.args or "@this: "
        require("opencode").ask(prompt, { submit = true })
      end, { nargs = "*" })

      -- Define the :OpencodeSelect command (Task menu)
      vim.api.nvim_create_user_command("OpencodeSelect", function()
        require("opencode").select()
      end, {})

      -- Keymaps
      vim.keymap.set({ "n", "v" }, "<leader>aa", ":OpencodeAsk<CR>", { desc = "Ask AI" })
      vim.keymap.set({ "n", "v" }, "<leader>as", ":OpencodeSelect<CR>", { desc = "AI Tasks" })
    end,
  },
})

-- =====================================================
-- 3. Final Polish & UI Settings
-- =====================================================
vim.cmd("colorscheme tokyonight")
require("lualine").setup()

-- Line numbers
vim.opt.number = true -- Show absolute line numbers
vim.api.nvim_set_hl(0, 'LineNr', { fg = "white"})
-- Nerdfont settings
vim.g.devicons_enable = true
vim.g.devicons_v7 = true

-- NvimTree Toggle
vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { silent = true })

-- Telescope Find Files
vim.keymap.set("n", "<leader>ff", ":Telescope find_files<CR>", { silent = true, desc = "Find Files" })

-- Keybind Help Popup
local function show_keybinds()
  local lines = {
    "                              Keybinds Cheatsheet                               ",
    "--------------------------------------------------------------------------------",
    "",
    " [Navigation]                  [Editing]                   [Search/Files]       ",
    " h j k l    Move cursor        i         Insert mode       /         Search     ",
    " w b       Word fwd/back       a         Append            n / N     Next/Prev  ",
    " 0 $       Line start/end      o O       New line below/up *         Search word",
    " gg G      File start/end      x         Delete char       <C-f>     Page down  ",
    " %         Match bracket       dd        Delete line       <C-b>     Page up    ",
    " { }       Paragraph fwd/back  yy        Yank line         <C-d/u>   Half page  ",
    " H M L     Screen top/mid/bot  p P       Paste after/before          ",
    "",
    " [Windows]                     [Visual Mode]               [Buffers/Tabs]       ",
    " C-w s     Split horizontal    v         Visual char       :bn :bp   Next/Prev  ",
    " C-w v     Split vertical      V         Visual line       :bd       Close buf  ",
    " C-w h/j/k/l  Move focus       C-v       Visual block      :ls       List bufs  ",
    " C-w H/L   Move window         y         Yank selection    gt / gT   Next/Prev  ",
    " C-w =     Equal size          d         Delete selection  :tabnew   New tab    ",
    " C-w q     Close window        >  <      Indent/Outdent              ",
    "",
    " [LSP]                         [Custom]                    [OpenCode AI]        ",
    " gd        Go to definition    <leader>ff  Find files      <leader>aa  Ask AI   ",
    " gr        References          <leader>e   File tree       <leader>as  AI Tasks ",
    " K         Hover docs          <C-s>       Save file                  ",
    " <leader>rn  Rename            <leader>hh  This help                  ",
    " <leader>ca  Code action                                              ",
    " [d / ]d   Prev/Next diag                                             ",
    "",
    " [Useful Commands]             [Macros/Registers]          [Marks]              ",
    " :w :q :wq Save/Quit           qa        Record macro a    ma        Set mark a ",
    " :e file   Open file           q         Stop recording    'a        Jump mark a",
    " u / C-r   Undo/Redo           @a        Play macro a      ''        Last pos   ",
    " .         Repeat last         \"ay      Yank to reg a     :marks    List marks ",
    " :s/x/y/g  Replace             \"ap      Paste from reg a            ",
    "",
    "                          Press q or <Esc> to close                             ",
  }

  -- Define highlight groups for categories
  local ns = vim.api.nvim_create_namespace("keybind_help")
  vim.api.nvim_set_hl(0, "KeybindTitle", { fg = "#7aa2f7", bold = true })
  vim.api.nvim_set_hl(0, "KeybindCategory", { fg = "#bb9af7", bold = true })
  vim.api.nvim_set_hl(0, "KeybindSeparator", { fg = "#565f89" })
  vim.api.nvim_set_hl(0, "KeybindFooter", { fg = "#565f89", italic = true })

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  local width = 84
  local height = #lines
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = "minimal",
    border = "rounded",
    title = " Help ",
    title_pos = "center",
  })

  -- Apply highlights
  -- Title line
  vim.api.nvim_buf_add_highlight(buf, ns, "KeybindTitle", 0, 0, -1)
  -- Separator line
  vim.api.nvim_buf_add_highlight(buf, ns, "KeybindSeparator", 1, 0, -1)
  -- Footer line
  vim.api.nvim_buf_add_highlight(buf, ns, "KeybindFooter", #lines - 1, 0, -1)

  -- Highlight all [Category] headers
  for i, line in ipairs(lines) do
    local start = 1
    while true do
      local s, e = line:find("%[[%w%s/]+%]", start)
      if not s then break end
      vim.api.nvim_buf_add_highlight(buf, ns, "KeybindCategory", i - 1, s - 1, e)
      start = e + 1
    end
  end

  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, silent = true })
  vim.keymap.set("n", "<Esc>", "<cmd>close<cr>", { buffer = buf, silent = true })
end

vim.keymap.set("n", "<leader>hh", show_keybinds, { desc = "Show Keybinds" })

-- Python Provider
vim.g.python3_host_prog = os.getenv("HOME") .. "/.venv/nvim/bin/python"

-- n = normal | i = insert | v = visual mode
vim.keymap.set("n", "<C-s>", ":w<CR>", { silent = true })
vim.keymap.set("i", "<C-s>", "<Esc>:w<CR>a", { silent = true })
vim.keymap.set("v", "<C-s>", "<Esc>:w<CR>", { silent = true })

vim.o.showtabline = 2 
vim.api.nvim_set_hl(0, "Tabline", { fg = "#ffffff" })
-- Rotating tabline messages
--
--
--
--
--
--
--
local tabline_messages = {
 "keybinds at <space> hh"
}
--
--
--
--
--
--
--
local current_message_index = 1

local function update_tabline()
  vim.o.tabline = "  " .. tabline_messages[current_message_index]
  current_message_index = current_message_index % #tabline_messages + 1
end

update_tabline() -- Set initial message
vim.fn.timer_start(30000, function()
  update_tabline()
  vim.cmd("redrawtabline")
end, { ["repeat"] = -1 }) -- -1 means repeat forever 

