" leader
let g:mapleader = "\<Space>"
let g:maplocalleader = ','

" syntax
syntax on

" history : how many lines of history VIM has to remember
set history=2000
set pyxversion=3

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

" fold
set foldmethod=syntax
set nofoldenable


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
set wildignore=*.o,*~,*.pyc,*.class,*.lo

" others
set backspace=indent,eol,start  " make that backspace key work the way it should
set whichwrap+=<,>,h,l

" keymap
noremap <C-j> <C-W>j
noremap <C-k> <C-W>k
noremap <C-h> <C-W>h
noremap <C-l> <C-W>l
noremap <C-v> <C-W>v
noremap <C-s> <C-W>s

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
" Plug 'vim-airline/vim-airline'
" Shorthand notation; fetches https://github.com/junegunn/vim-easy-align
" Plug 'junegunn/vim-easy-align'

" Plug 'easymotion/vim-easymotion'

" Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
" Plug 'morhetz/gruvbox'
" Plug 'mhinz/vim-startify'
" Plug 'dhruvasagar/vim-table-mode'
" Plug 'NLKNguyen/papercolor-theme'


" let g:deoplete#enable_at_startup = 1

" Plug 'pearofducks/ansible-vim'
" Plug 'aserebryakov/vim-todo-lists'
" Plug 'liuchengxu/vim-clap'
" Plug 'zimbatm/haproxy.vim'
" Plug 'zivyangll/git-blame.vim'

" Plug 'SirVer/ultisnips'

" Plug 'junegunn/goyo.vim'

" Plug 'ludovicchabant/vim-gutentags'
" Plug 'skywind3000/gutentags_plus'

" Plug 'liuchengxu/vista.vim'
" Plug 'ryanoasis/vim-devicons'

" Plug 'hotoo/pangu.vim'

" Plug 'aklt/plantuml-syntax'

" Plug 'plasticboy/vim-markdown'
" Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app && yarn install'  }

" Plug 'preservim/nerdcommenter'
" Plug '~/toy/vim/plantuml-vim'
call plug#end()

" plugin cfg
" color 
" colorscheme PaperColor

" NERDTree
" map <leader>1 :NERDTreeToggle<CR>
" map <leader>2 :NERDTreeFind<CR>

" git blame
" noremap <leader>gb :<C-u>call gitblame#echo()<CR>

" Clap
" noremap ; :Clap<CR>
" noremap <leader>p :Clap files<cr>
" noremap <leader>e :Clap files<cr>
" noremap <C-e> :Clap history<CR>

" gui
" toggle file tree
" noremap <D-1> :NERDTreeToggle<CR>
" find anchor for current file
" noremap <D-2> :NERDTreeFind<CR>
" toggle taglist 
" noremap <D-3> :Vista!!<CR>
" noremap <D-p> :Clap files<CR>

" alt 映射问题: 输入方式为：按下 Crtl+v后在按下 Alt+key（你想设置的键）
" alt + h
noremap ˙ :tabprevious<CR>
" alt + l
noremap ¬ :tabnext<CR>


set guifont=SauceCodePro\ Nerd\ Font:h14

" table mode
" let g:table_mode_motion_up_map = '<S-CR>'
" let g:table_mode_motion_down_map = '<CR>'
" let g:table_mode_corner = '|'

" noremap <Leader>tt :TableModeToggle<CR>

" noremap <Leader>z za<CR>

" easy motion
" let g:EasyMotion_do_mapping = 0 " Disable default mappings
" Jump to anywhere you want with minimal keystrokes, with just one key binding.
" `s{char}{label}`
" nmap f <Plug>(easymotion-overwin-f2)

" map  / <Plug>(easymotion-sn)
" omap / <Plug>(easymotion-tn)

" let g:EasyMotion_smartcase = 1
" map J <Plug>(easymotion-bd-jk)
" map K <Plug>(easymotion-bd-jk)

" vimrc
" noremap <leader>q <esc>:wq!<cr>
" noremap <leader>w <esc>:w!<cr>

" noremap <leader>ev :vsplit $HOME/.vim/main.vim<cr>
" noremap <leader>sv :source $MYVIMRC<cr>


" enable gtags module
" let g:gutentags_modules = ['ctags', 'gtags_cscope']
" config project root markers.
" let g:gutentags_project_root = ['.root']
" generate datebases in my cache directory, prevent gtags files polluting my project
" let g:gutentags_cache_dir = expand('~/.cache/tags')
" change focus to quickfix window after search (optional).
" let g:gutentags_plus_switch = 1

" preview
" let g:mkdp_open_to_the_world = 1
