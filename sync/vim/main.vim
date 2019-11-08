" leader
let g:mapleader = "\<Space>"
let g:maplocalleader = ','

" syntax
syntax on

" history : how many lines of history VIM has to remember
set history=2000

" filetype
filetype on
" Enable filetype plugins
filetype plugin on
filetype indent on

" base set nocompatible                " don't bother with vi compatibility
set hidden
set autoread                    " reload files when changed on disk, i.e. via `git checkout`
set shortmess=atI

set magic                       " For regular expressions turn magic on
set title                       " change the terminal's title
set nobackup                    " do not keep a backup file
set noswapfile                  " do not keep a swap file

set novisualbell                " turn off visual bell
set noerrorbells                " don't beep
set visualbell t_vb=            " turn off error beep/flash
set t_vb=
set tm=500

" show location
set cursorcolumn
set cursorline

" movement
set scrolloff=7                 " keep 3 lines when scrolling

" show
set ruler                       " show the current row and column
set number                      " show line numbers
set nowrap
set showcmd                     " display incomplete commands
set showmode                    " display current modes
set showmatch                   " jump to matches when entering parentheses
set matchtime=2                 " tenths of a second to show the matching parenthesis


" search
set hlsearch                    " highlight searches
set incsearch                   " do incremental searching, search as you type
set ignorecase                  " ignore case when searching
set smartcase                   " no ignorecase if Uppercase char present


" tab
set expandtab                   " expand tabs to spaces
set smarttab
set shiftround

" indent
set autoindent smartindent shiftround
set shiftwidth=2
set tabstop=2
set softtabstop=2                " insert mode tab and backspace use 2 spaces


" encoding
set encoding=utf-8
set fileencodings=ucs-bom,utf-8,cp936,gb18030,big5,euc-jp,euc-kr,latin1
set termencoding=utf-8
set ffs=unix,dos,mac
set formatoptions+=m
set formatoptions+=B

set completeopt=longest,menu
set wildmenu                           " show a navigable menu for tab completion"
set wildmode=longest,list,full
set wildignore=*.o,*~,*.pyc,*.class

" others
set backspace=indent,eol,start  " make that backspace key work the way it should
set whichwrap+=<,>,h,l

" keymap
noremap <C-j> <C-W>j
noremap <C-k> <C-W>k
noremap <C-h> <C-W>h
noremap <C-l> <C-W>l

" Shift+H goto head of the line, Shift+L goto end of the line
nnoremap H ^
nnoremap L $

" command mode, ctrl-a to head， ctrl-e to tail
cnoremap <C-j> <t_kd>
cnoremap <C-k> <t_ku>
cnoremap <C-a> <Home>

" path
set path+=**
"noremap ; :Rg<CR>

" clipboard
set clipboard=unnamed

call plug#begin('~/.vim/plugged')
Plug 'vim-airline/vim-airline'
" Shorthand notation; fetches https://github.com/junegunn/vim-easy-align
Plug 'junegunn/vim-easy-align'
Plug 'scrooloose/nerdcommenter'
Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
Plug 'morhetz/gruvbox'
" Plug '/usr/local/opt/fzf'
" Plug 'junegunn/fzf.vim'
Plug 'mhinz/vim-startify'
Plug 'dhruvasagar/vim-table-mode'
Plug 'NLKNguyen/papercolor-theme'

if has('nvim')
  Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
else
  Plug 'Shougo/deoplete.nvim'
  Plug 'roxma/nvim-yarp'
  Plug 'roxma/vim-hug-neovim-rpc'
  Plug 'tbodt/deoplete-tabnine', { 'do': './install.sh' }
endif

let g:deoplete#enable_at_startup = 1

Plug 'pearofducks/ansible-vim'
Plug 'aserebryakov/vim-todo-lists'
Plug 'liuchengxu/vim-clap'
Plug 'zimbatm/haproxy.vim'
call plug#end()

" plugin cfg
" color 
colorscheme PaperColor

" NERDTree
map <leader>1 :NERDTreeToggle<CR>
map <leader>2 :NERDTreeFind<CR>

" Clap
noremap ; :Clap<CR>
noremap <C-p> :Clap files<CR>
noremap <C-e> :Clap history<CR>

" FZF
"nnoremap <silent> <C-p> :Files<CR>
"nmap <C-e> :Buffers<CR>
"let g:fzf_action = { 'ctrl-e': 'edit' }

" nvim
if has("nvim")
  set guicursor=
endif

" gui
noremap <D-1> :NERDTreeToggle<CR>
noremap <D-2> :NERDTreeFind<CR>

" alt 映射问题: 输入方式为：按下 Crtl+v后在按下 Alt+key（你想设置的键）
" alt + h
noremap ˙ :tabprevious<CR>
" alt + l
noremap ¬ :tabnext<CR>


set guifont=Source\ Code\ Pro:h14

" table mode
let g:table_mode_motion_up_map = '<S-CR>'
let g:table_mode_motion_down_map = '<CR>'
let g:table_mode_corner = '|'

noremap <leader>tt :TableModeToggle<cr>

" vimrc
noremap <leader>q <esc>:wq!<cr>
noremap <leader>w <esc>:w!<cr>

noremap <leader>ev :vsplit $HOME/.vim/main.vim<cr>
noremap <leader>sv :source $MYVIMRC<cr>
