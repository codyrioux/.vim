" Use pathogen to easily modify the runtime path to include all plugins under
" the ~/.vim/bundle directory
filetype off
call pathogen#infect()

let isWindowsHost = has('win32') || has('win16')

filetype on
filetype plugin on
filetype indent on
syntax on

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

"""""""""""""""""""""
" Custom Keybindings
"""""""""""""""""""""

" Clear the search highlighting
nmap <silent> <leader>/ :let @/=""<CR>

" Use space bar for folding
nnoremap <silent> <Space> @=(foldlevel('.')?'za':'l')<CR>
vnoremap <Space> zf

" add a 'paste mode' that disables all autoindenting to paste large blobs of
" text
set pastetoggle=<F2>

"""""""""""""""""""""""""
" File Specific
" Configuration Settings
"""""""""""""""""""""""""

" HTML (tab width 2 chars, no wrapping)
autocmd FileType html set sw=2
autocmd FileType html set ts=2
autocmd FileType html set sts=2
autocmd FileType html set textwidth=0

" CSS (tab width 2 chars, wrap at 79th char)
autocmd FileType css set sw=2
autocmd FileType css set ts=2
autocmd FileType css set sts=2
autocmd FileTYpe css set textwidth=79

"JavaScript (tab width 4 chars, wrap at 79th)
autocmd FileType javascript set sw=4
autocmd FileType javascript set ts=4
autocmd FileType javascript set sts=4
autocmd FileType javascript set textwidth=79

" Autocompletion
autocmd FileType javascript set omnifunc=javascriptcomplete#CompleteJS
autocmd FileType html set omnifunc=htmlcomplete#CompleteTags
autocmd FileType css set omnifunc=csscomplete#CompleteCSS

" Quickly edit/reload the vimrc file
nmap <silent> <leader>ev :e $MYVIMRC<CR>
nmap <silent> <leader>sv :so $MYVIMRC<CR>

colorscheme herald

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
  set transparency=15
  "set guifont=ProFontX
  set guifont=SourceCodePro-Regular
endif

if isWindowsHost
	set directory=$USERPROFILE\\vimfiles\\swp//,.,C:\temp//
else
	set directory=~/.vim/swp//,.,/tmp//
endif
" Set erlang man path on my mac
let g:erlang_man_path='/usr/local/share/man'

" CtrlP.vim Mappings
let g:ctrlp_map = '<c-p>'
let g:ctrlp_cmd = 'CtrlPMixed'

" VimClojure Settings
let vimclojure#HighlightBuiltins=1
let vimclojure#ParenRainbow=1
let vimclojure#WantNailgun=1

" Numbers.vim Settings
" nnoremap <F3> :NumbersToggle<CR>
