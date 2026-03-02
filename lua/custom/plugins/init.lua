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
