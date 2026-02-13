vim.opt.linebreak = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true
vim.cmd.highlight 'Normal guibg=transparent'

vim.cmd [[ autocmd BufNewFile,BufRead *.bicep set filetype=bicep ]]

vim.filetype.add {
  pattern = {
    ['openapi.*%.ya?ml'] = 'yaml.openapi',
    ['openapi.*%.json'] = 'json.openapi',
    ['http'] = 'http',
  },
}

-- Autowrite Markdown Documents!!!
vim.api.nvim_create_autocmd('FileType', { pattern = 'markdown', command = 'set awa' })

-- vim: ts=2 sts=2 sw=2 et
