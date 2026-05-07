-- ~/.config/nvim/init.lua — terminal, no plugins, single-file editing focus

local opt = vim.opt
local g = vim.g

-- --- core ---
opt.fileencodings = 'utf-8,gbk,gb18030,big5,latin1'

-- --- display ---
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.showmatch = true
opt.scrolloff = 5
opt.sidescrolloff = 8
opt.linebreak = true
opt.list = true
opt.listchars = { tab = '» ', trail = '·', nbsp = '␣', extends = '›', precedes = '‹' }
opt.fillchars = { vert = '│', fold = '·' }
opt.termguicolors = true
opt.background = 'dark'
pcall(vim.cmd.colorscheme, 'habamax')

-- --- editing ---
opt.smartindent = true
opt.expandtab = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4
opt.shiftround = true
opt.whichwrap:append('<,>,h,l,[,]')
opt.joinspaces = false
opt.virtualedit = 'block'
opt.clipboard = 'unnamedplus'

-- --- search ---
opt.ignorecase = true
opt.smartcase = true

-- --- files ---
opt.swapfile = false
opt.backup = false
opt.writebackup = false
opt.undofile = true
opt.history = 1000
opt.updatetime = 300

-- --- wildmenu / completion ---
opt.wildmode = { 'longest:full', 'full' }
opt.wildignore:append({ '*.o', '*.obj', '*.pyc', '*.class', '*.swp', '*.bak', '.git', 'node_modules' })
opt.completeopt = { 'menuone', 'longest' }
opt.shortmess:append('c')

-- --- netrw (built-in file browser) ---
g.netrw_banner = 0
g.netrw_liststyle = 3
g.netrw_winsize = 25
g.netrw_browse_split = 0
g.netrw_altv = 1

-- --- autocmds ---
local aug = vim.api.nvim_create_augroup
local au = vim.api.nvim_create_autocmd

au('FileType', {
  group = aug('ftIndent', { clear = true }),
  pattern = { 'yaml', 'yml', 'json', 'toml', 'sh', 'bash', 'zsh', 'fish', 'vim', 'lua', 'html', 'css' },
  callback = function()
    vim.bo.tabstop = 2
    vim.bo.shiftwidth = 2
    vim.bo.softtabstop = 2
  end,
})

au('BufReadPost', {
  group = aug('lastPos', { clear = true }),
  callback = function()
    local line = vim.fn.line([['"]])
    if line > 1 and line <= vim.fn.line('$') then
      vim.cmd('normal! g`"')
    end
  end,
})

-- --- keymaps ---
g.mapleader = ' '
g.maplocalleader = ','

local map = vim.keymap.set
map('i', 'jk', '<Esc>')
map('n', '<leader>w', '<cmd>w<cr>')
map('n', '<leader>q', '<cmd>q<cr>')
map('n', '<leader>x', '<cmd>x<cr>')
map('n', '<C-l>', '<cmd>nohlsearch<cr><C-l>', { silent = true })
map('n', '<leader>e', '<cmd>Lexplore<cr>')
map('n', '<leader>b', ':ls<cr>:b<space>')
map('n', '[b', '<cmd>bprevious<cr>')
map('n', ']b', '<cmd>bnext<cr>')
map('n', '<C-h>', '<C-w>h')
map('n', '<C-j>', '<C-w>j')
map('n', '<C-k>', '<C-w>k')
map('v', '<', '<gv')
map('v', '>', '>gv')
map('n', '<leader>rv', '<cmd>source $MYVIMRC<cr>')
