-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {
	{
    'jakewvincent/mkdnflow.nvim',
    event = 'BufRead',
    filetypes = { 'markdown' },
    config = function()
      require('mkdnflow').setup {
        perspective = {
          priority = 'root',
          fallback = 'current',
          root_tell = 'index.md',
          nvim_wd_wheel = false,
          update = false,
        },
        links = {
          style = 'markdown',
          name_is_source = false,
          conceal = false,
          context = 0,
          implicit_extension = nil,
          transform_implicit = false,
          transform_explicit = function(text)
            return text
          end,
          create_on_follow_failure = true,
        },
      }
      vim.api.nvim_create_autocmd('BufLeave', { pattern = '*.md', command = 'silent! wall' })
    end,
  },
  {
    'MeanderingProgrammer/render-markdown.nvim',
    ft = { 'markdown', 'md', 'rmd' },
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.icons' }, -- if you use standalone mini plugins
    opts = {},
  },
  {
    'akinsho/toggleterm.nvim',
    event = 'VeryLazy',
    opts = {
      open_mapping = [[<C-\>]],
    },
  },
  {
    'mistweaverco/kulala.nvim',
    keys = {
      { '<leader>Rs', desc = 'Send request' },
      { '<leader>Ra', desc = 'Send all requests' },
      { '<leader>Rb', desc = 'Open scratchpad' },
    },
    ft = { 'http', 'rest' },
    opts = {
      global_keymaps = false,
      global_keymaps_prefix = '<leader>R',
      kulala_keymaps_prefix = '',
      lsp = {
        enable = true,
        keymaps = false,
        formatter = true,
      },
    },
  },
  {
	'sindrets/diffview.nvim',
opts = {},
  },
  -- ========================================================================
  -- smart-splits.nvim — Neovim-aware pane navigation & resizing
  -- ========================================================================
  --
  -- Problem:
  --   The default WezTerm multiplexer integration (`multiplexer_integration
  --   = 'wezterm'`) spawns 6 synchronous `wezterm cli` subprocesses every
  --   time you navigate from a Neovim edge split to an adjacent WezTerm
  --   pane. On Windows, each subprocess takes ~300-500ms, totalling 2-3s
  --   of delay per cross-pane move. The reverse direction (WezTerm ->
  --   Neovim) is unaffected because WezTerm handles it natively.
  --
  -- Solution:
  --   Bypass the CLI entirely using WezTerm user variables (OSC 1337
  --   escape sequences). When Neovim detects it's at an edge, it writes
  --   a user variable to stderr — just bytes on a pipe, essentially
  --   instant. WezTerm picks this up via a `user-var-changed` event
  --   handler (defined in .wezterm.lua) and calls `ActivatePaneDirection`
  --   natively. Zero subprocesses, zero delay.
  --
  -- Architecture:
  --   1. `multiplexer_integration = false`
  --      Disables the built-in mux backend so no CLI calls are made.
  --
  --   2. `at_edge = function(ctx) ... end`
  --      Called when the cursor is at Neovim's outermost split and the
  --      user presses Ctrl+hjkl toward a WezTerm pane. Emits the user
  --      variable `SMART_SPLITS_MOVE=<direction>` via OSC 1337, then
  --      clears it after 50ms so the same direction can be re-triggered
  --      (WezTerm only fires `user-var-changed` on value *change*).
  --
  --   3. `config = function(_, opts) ... end`
  --      - Calls `setup(opts)` to apply our settings.
  --      - Clears `require('smart-splits.mux').__mux` to bust a stale
  --        cache: the plugin's own `plugin/smart-splits.lua` runs before
  --        lazy.nvim calls this config function, and during that early
  --        init it auto-detects WezTerm and caches the mux backend.
  --        Without clearing, `M.get()` would still return the cached
  --        wezterm module and make CLI calls despite our setting.
  --      - Manually sets the `IS_NVIM` WezTerm user variable (normally
  --        done by the mux backend's `on_init`). This lets WezTerm's
  --        smart-splits plugin know when to forward keypresses to Neovim
  --        vs. handle them as native pane navigation.
  --      - Registers autocmds to clear/re-set `IS_NVIM` on
  --        VimLeavePre, VimSuspend, and VimResume.
  --
  --   4. WezTerm side (.wezterm.lua)
  --      A `user-var-changed` event handler listens for
  --      `SMART_SPLITS_MOVE`, title-cases the direction value, and calls
  --      `ActivatePaneDirection`. See .wezterm.lua for details.
  --
  -- Keybindings:
  --   Ctrl+h/j/k/l      Move focus between Neovim splits / WezTerm panes
  --   Alt+h/j/k/l       Resize splits / panes
  --   <leader><leader>+h/j/k/l  Swap buffers between Neovim windows
  -- ========================================================================
  {
    'mrjones2014/smart-splits.nvim',
    -- Do not lazy load so the IS_NVIM user var is set for WezTerm
    lazy = false,
    opts = {
      multiplexer_integration = false,
      at_edge = function(ctx)
        local dir = ctx.direction
        local b64 = vim.base64.encode(dir)
        local escape = string.format('\027]1337;SetUserVar=SMART_SPLITS_MOVE=%s\007', b64)
        vim.fn.chansend(vim.v.stderr, escape)
        -- Clear after 50ms so the same direction can be re-triggered
        -- (WezTerm only fires user-var-changed on value *change*).
        vim.defer_fn(function()
          local clear = '\027]1337;SetUserVar=SMART_SPLITS_MOVE=\007'
          vim.fn.chansend(vim.v.stderr, clear)
        end, 50)
      end,
    },
    config = function(_, opts)
      require('smart-splits').setup(opts)
      -- Bust the stale mux cache (see header comment for details).
      require('smart-splits.mux').__mux = nil
      -- Manually manage the IS_NVIM user var since the mux backend's
      -- on_init/on_exit no longer runs.
      local function set_is_nvim(val)
        local b64 = vim.base64.encode(val)
        local escape = string.format('\027]1337;SetUserVar=IS_NVIM=%s\007', b64)
        vim.fn.chansend(vim.v.stderr, escape)
      end
      set_is_nvim('true')
      local augroup = vim.api.nvim_create_augroup('SmartSplitsIsNvim', { clear = true })
      vim.api.nvim_create_autocmd({ 'VimLeavePre' }, {
        group = augroup,
        callback = function() set_is_nvim('false') end,
      })
      vim.api.nvim_create_autocmd({ 'VimSuspend' }, {
        group = augroup,
        callback = function() set_is_nvim('false') end,
      })
      vim.api.nvim_create_autocmd({ 'VimResume' }, {
        group = augroup,
        callback = function() set_is_nvim('true') end,
      })
    end,
    keys = {
      -- Moving between splits (Neovim + WezTerm panes)
      { '<C-h>', function() require('smart-splits').move_cursor_left() end,  desc = 'Move cursor left' },
      { '<C-j>', function() require('smart-splits').move_cursor_down() end,  desc = 'Move cursor down' },
      { '<C-k>', function() require('smart-splits').move_cursor_up() end,    desc = 'Move cursor up' },
      { '<C-l>', function() require('smart-splits').move_cursor_right() end, desc = 'Move cursor right' },
      -- Resizing splits
      { '<A-h>', function() require('smart-splits').resize_left() end,  desc = 'Resize left' },
      { '<A-j>', function() require('smart-splits').resize_down() end,  desc = 'Resize down' },
      { '<A-k>', function() require('smart-splits').resize_up() end,    desc = 'Resize up' },
      { '<A-l>', function() require('smart-splits').resize_right() end, desc = 'Resize right' },
      -- Swapping buffers between windows
      { '<leader><leader>h', function() require('smart-splits').swap_buf_left() end,  desc = 'Swap buffer left' },
      { '<leader><leader>j', function() require('smart-splits').swap_buf_down() end,  desc = 'Swap buffer down' },
      { '<leader><leader>k', function() require('smart-splits').swap_buf_up() end,    desc = 'Swap buffer up' },
      { '<leader><leader>l', function() require('smart-splits').swap_buf_right() end, desc = 'Swap buffer right' },
    },
  },
  {
    'iamcco/markdown-preview.nvim',
    cmd = { 'MarkdownPreviewToggle', 'MarkdownPreview', 'MarkdownPreviewStop' },
    keys = {
      { '<leader>mp', '<cmd>MarkdownPreviewToggle<CR>', ft = 'markdown', desc = '[M]arkdown [P]review toggle' },
    },
    ft = { 'markdown' },
    build = function(plugin)
      -- Add the plugin to runtimepath so autoload functions are available
      vim.opt.rtp:append(plugin.dir)
      vim.fn['mkdp#util#install']()
    end,
  },
}
