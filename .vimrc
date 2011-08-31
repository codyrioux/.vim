" Use pathogen to easily modify the runtime path to include all plugins under
" the ~/.vim/bundle directory
filetype off
call pathogen#helptags()
call pathogen#runtime_append_all_bundles()

set tabstop=2
set shiftwidth=2 " number of spaces used for autoindenting
set ai
set nu				" show line numbers
set nowrap			" don't wrap lines
set cursorline
set cursorcolumn
set nocompatible
set expandtab " Convert tabs to spaces 
filetype on
filetype plugin on
filetype indent on
syntax on


" Quickly edit/reload the vimrc file
nmap <silent> <leader>ev :e $MYVIMRC<CR>
nmap <silent> <leader>sv :so $MYVIMRC<CR>

" Command-T related hotkeys
noremap <leader>o <Esc>:CommandT<CR>
noremap <leader>O <Esc>:CommandTFlush<CR>
noremap <leader>m <Esc>:CommandTBuffer<CR>

" Tagbar related hotkeys
let g:tagbar_usearrows = 1
nnoremap <leader>l :TagbarToggle<CR>

" Opening a new buffer hides the currently open buffer
set hidden

set foldmethod=indent
set foldlevel=99

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

" add a 'paste mode' that disables all autoindenting to paste large blobs of
" text
set pastetoggle=<F2>

" gVim specific settings
set guifont=ProFontX
colorscheme Tomorrow-Night-Bright
set transparency=15
syn on
set spell
set go-=T

" Clear the search highlighting
nmap <silent> <leader>/ :let @/=""<CR>
map <leader>td <Plug>TaskList
