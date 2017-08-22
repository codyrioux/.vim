set nocp
filetype on
filetype plugin on
filetype indent on
syntax on

call plug#begin('~/.vim/plugged')

" Color Schmes
Plug 'altercation/vim-colors-solarized'
Plug 'tomasr/molokai'
Plug 'tpope/vim-vividchalk'

" Developer Tools Integration
Plug 'tfnico/vim-gradle'
Plug 'Shougo/vimproc.vim', {'do' : 'make'} | Plug 'idanarye/vim-vebugger'
Plug 'christoomey/vim-tmux-navigator'

" Utilities
Plug 'ctrlpvim/ctrlp.vim'
Plug 'scrooloose/nerdtree'
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'
Plug 'vim-scripts/paredit.vim'
Plug 'oblitum/rainbow'
Plug 'vim-airline/vim-airline'
Plug 'justinmk/vim-sneak'
Plug 'ervandew/supertab'
Plug 'vimwiki/vimwiki'
Plug 'skywind3000/asyncrun.vim'
Plug 'mileszs/ack.vim'

" Java Related
Plug 'artur-shaik/vim-javacomplete2'

" Clojre Related
Plug 'tpope/vim-classpath'
Plug 'guns/vim-clojure-static' | Plug 'tpope/vim-fireplace'

call plug#end()

set tabstop=2
set shiftwidth=2 " number of spaces used for autoindenting
set ai
set nu				" show line numbers
set nowrap			" don't wrap lines
set cursorline
set cursorcolumn
set nocompatible
set expandtab " Convert tabs to spaces 
set backspace=indent,eol,start " allow backspacing over everything in insert mode
set autoindent " always have autoindenting on
set copyindent " copy the previous indentation on autoindenting
set shiftround " use multiple of shiftwidth when indenting with '<' key
set showmatch  " show matching parenthesis
set ignorecase " ignore case when searching
set smartcase  " ignore case if search pattern is all lowercase, case-sensitive otherwise
set smarttab   " insert tabs on the start of a line according to shiftwidth, not tab stop
set hlsearch   " highlight search terms
set incsearch  " show search matches as you type
set history=1000	" remember commands and search history
set undolevels=1000 " many levels of undo
set wildignore=*.swp,*.bak,*.pyc,*.class " ignore file extensions when completing names by pressing Tab
set title			" change the terminal's title
set noerrorbells	" don't beep
set hidden " Opening a new buffer hides the currently open buffer
set foldmethod=indent
set foldlevel=99
set statusline=%F%m%r%h%w\ [FORMAT=%{&ff}]\ [ENC=%{strlen(&fenc)?&fenc:'none'}]\ [TYPE=%Y]\ [POS=%04l,%04v][%p%%]\ [LEN=%L]
set laststatus=2
set visualbell

"""""""""""""""""""""
" Custom Keybindings
"""""""""""""""""""""

let mapleader = "\<Space>"

" Clear the search highlighting
nmap <silent> <leader>/ :let @/=""<CR>

" add a 'paste mode' that disables all autoindenting to paste large blobs of
" text
set pastetoggle=<F2>

"""""""""""""""""""""""""
" File Specific
" Configuration Settings
"""""""""""""""""""""""""
" Python (tab width 2 chars, no wrapping)
autocmd FileType python set textwidth=160
autocmd FileType python set shiftwidth=4
autocmd FileType python set tabstop=4
autocmd FileType python set expandtab
autocmd FileType python set softtabstop=4
autocmd FileType python set shiftround
autocmd FileType python set autoindent


" HTML (tab width 2 chars, no wrapping)
autocmd FileType html set sw=2
autocmd FileType html set ts=2
autocmd FileType html set sts=2
autocmd FileType html set textwidth=0

" CSS (tab width 2 chars, wrap at 79th char)
autocmd FileType css set sw=2
autocmd FileType css set ts=2
autocmd FileType css set sts=2
autocmd FileType css set textwidth=79

"JavaScript (tab width 2 chars, wrap at 79th)
autocmd FileType javascript set sw=4
autocmd FileType javascript set ts=4
autocmd FileType javascript set sts=4
autocmd FileType javascript set textwidth=79

" gradle settings
autocmd FileType groovy :compiler gradlew
autocmd FileType scala :compiler gradlew
autocmd FileType java :compiler gradlew
autocmd FileType clojure :compiler gradlew

""""""""""""""""""""""
" Conditional Settings
""""""""""""""""""""""

" gVim specific settings
if (has('gui_running'))
	syn on
	set spell
	set go-=T
else
	set t_Co=256
endif

" MacVim Specific Settings
if has("gui_macvim")
  set transparency=0
  set guifont=ProFontX
endif

set directory=~/.vim/swp//,/tmp//

" CtrlP.vim Mappings
let g:ctrlp_map = '<c-p>'
let g:ctrlp_cmd = 'CtrlP'
let g:ctrlp_working_path_mode = 'ra'
let g:ctrlp_user_command = ['.git/', 'git --git-dir=%s/.git ls-files -oc --exclude-standard']

" rainbow_parenthesis settings
let g:rbpt_colorpairs = [
    \ ['brown',       'RoyalBlue3'],
    \ ['Darkblue',    'SeaGreen3'],
    \ ['darkgray',    'DarkOrchid3'],
    \ ['darkgreen',   'firebrick3'],
    \ ['darkcyan',    'RoyalBlue3'],
    \ ['darkred',     'SeaGreen3'],
    \ ['darkmagenta', 'DarkOrchid3'],
    \ ['brown',       'firebrick3'],
    \ ['gray',        'RoyalBlue3'],
    \ ['black',       'SeaGreen3'],
    \ ['darkmagenta', 'DarkOrchid3'],
    \ ['Darkblue',    'firebrick3'],
    \ ['darkgreen',   'RoyalBlue3'],
    \ ['darkcyan',    'SeaGreen3'],
    \ ['darkred',     'DarkOrchid3'],
    \ ['red',         'firebrick3'],
    \ ]


let g:rainbow_active = 1

" vim-sneak replaces f
nmap f <Plug>Sneak_s
nmap F <Plug>Sneak_S
xmap f <Plug>Sneak_s
xmap F <Plug>Sneak_S
omap f <Plug>Sneak_s
omap F <Plug>Sneak_S

" vim-clojure-static settings
let g:clojure_maxlines = 100
let g:clojure_fuzzy_inent = 1
let g:clojure_fuzzy_indent_patterns = "with.*,def.*,let.*"
let g:clojure_align_multiline_strings = 1

" Color Scheme
let g:solarized_termcolors=256
syntax enable
set background=dark
colorscheme solarized

" vim-airline settings
set ttimeoutlen=50

set viminfo='100,n$HOME/.vim/files/info/viminfo

" Relative Line Numbers
set relativenumber
autocmd InsertEnter * :set norelativenumber
autocmd InsertLeave * :set relativenumber

" Simpler split navigation
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

set splitbelow
set splitright

" Java
autocmd FileType java setlocal omnifunc=javacomplete#Complete

nmap <F7> <Plug>(JavaComplete-Imports-RemoveUnused)
imap <F7> <Plug>(JavaComplete-Imports-RemoveUnused)

let g:JavaComplete_GradleExecutable = './gradlew'
let g:SuperTabDefaultCompletionType = "context"
let g:vimfiler_as_default_explorer = 1
