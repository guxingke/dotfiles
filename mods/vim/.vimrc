" ~/.vimrc — terminal, no plugins, single-file editing focus

" --- core ---
set nocompatible
set encoding=utf-8
set fileencodings=utf-8,gbk,gb18030,big5,latin1
syntax on
filetype plugin indent on

" --- display ---
set number
set relativenumber
set cursorline
set ruler
set showcmd
set showmatch
set laststatus=2
set scrolloff=5
set sidescrolloff=8
set wrap
set linebreak
set display=lastline
set list
set listchars=tab:»\ ,trail:·,nbsp:␣,extends:›,precedes:‹
set fillchars=vert:│,fold:·

" 24-bit color only when the terminal advertises it
if has('termguicolors') && ($COLORTERM ==# 'truecolor' || $COLORTERM ==# '24bit')
  set termguicolors
endif
set background=dark
silent! colorscheme habamax

" --- editing ---
set autoindent
set smartindent
set expandtab
set tabstop=4
set shiftwidth=4
set softtabstop=4
set shiftround
set backspace=indent,eol,start
set whichwrap+=<,>,h,l,[,]
set nojoinspaces
set virtualedit=block
set mouse=a
if has('clipboard')
  set clipboard^=unnamed,unnamedplus
endif

" config files: 2-space indent
augroup ftIndent
  autocmd!
  autocmd FileType yaml,yml,json,toml,sh,bash,zsh,fish,vim,lua,html,css setlocal tabstop=2 shiftwidth=2 softtabstop=2
augroup END

" --- search ---
set incsearch
set hlsearch
set ignorecase
set smartcase
set wrapscan

" --- files ---
set hidden
set autoread
set noswapfile
set nobackup
set nowritebackup
set undofile
if !isdirectory($HOME . '/.vim/undo')
  silent! call mkdir($HOME . '/.vim/undo', 'p', 0700)
endif
set undodir=~/.vim/undo
set history=1000
set updatetime=300

" jump back to last cursor position
augroup lastPos
  autocmd!
  autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe 'normal! g`"' | endif
augroup END

" --- completion / wildmenu ---
set wildmenu
set wildmode=longest:full,full
set wildignore+=*.o,*.obj,*.pyc,*.class,*.swp,*.bak,.git,node_modules
set completeopt=menuone,longest
set shortmess+=c

" --- netrw (built-in file browser) ---
let g:netrw_banner = 0
let g:netrw_liststyle = 3
let g:netrw_winsize = 25
let g:netrw_browse_split = 0
let g:netrw_altv = 1

" --- keymaps ---
let mapleader = ' '
let maplocalleader = ','

" quick escape
inoremap jk <Esc>

" save / quit
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>x :x<CR>

" clear search highlight
nnoremap <silent> <Esc> :nohlsearch<CR>

" file browser
nnoremap <leader>e :Lexplore<CR>

" buffer navigation
nnoremap <leader>b :ls<CR>:b<Space>
nnoremap [b :bprevious<CR>
nnoremap ]b :bnext<CR>

" window navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" keep selection after indent
vnoremap < <gv
vnoremap > >gv

" toggle paste mode for safe pasting in terminals without bracketed-paste
set pastetoggle=<F2>

" reload this file
nnoremap <leader>rv :source $MYVIMRC<CR>
