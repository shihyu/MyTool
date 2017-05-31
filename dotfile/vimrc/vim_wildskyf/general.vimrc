" ========================================
" =============== General ================
" ========================================

syntax on                         " syntax highlight

set autoindent                    " Use autoindenting
set autoread                      " Automatically re-read the file if it has changed
set backspace=indent,eol,start    " allow backspacing over everything in insert mode
set background=dark
set colorcolumn=80
set confirm                       " if confict, ask me
" set cursorline                    " display current cursor (line)
" set cursorcolumn                  " display current cursor (column)
set display+=lastline
set encoding=utf-8
set fo+=mB                        " for asia text
set hlsearch                      " hightlight search result
set history=999                   " number of history of command
set hidden                        " make buffer could hold a modified file
set incsearch                     " display search result realtime
set ignorecase smartcase          " case-insensitive
set laststatus=2                  " open status bar
set linebreak                     " don't split a vocabulary
" set mouse=a                     " enable the mouse
set number                        " display line number
set ruler                         " right-bottom detail
set scrolloff=2                   " scroll with extra line
set showcmd                       " Show the current command at the bottom
set showmatch                     " highlight matched brackets
set showtabline=2                 " always show tabline
set shortmess=I                   " Don't show the startup message
set smartindent                   " Use smarter defaults
set smarttab                      " Use smarter defaults
set splitbelow
set splitright
set title                         " change the terminal's title
set textwidth=78
" set t_Co=256
set visualbell                    " don't beep
set noerrorbells                  " don't beep
set undolevels=1000               " use many muchos levels of undo
set wildmenu                      " Enhanced mode for command-line completion
set whichwrap=b,s,<,>,[,]         " back to the last line
set wrap                          " new line when too many char


let &colorcolumn="80,".join(range(100,999),",")

" Tab
set autoindent
set copyindent
set smartindent
set expandtab                     " Expand TABs to spaces
set shiftwidth=2                  " Indents will have a width of 4
set softtabstop=2                 " Sets the number of columns for a TAB
set tabstop=2                     " The width of a TAB is set to 4.
                                  " Still it is a \t. It is just that
                                  " Vim will interpret it to be having
                                  " a width of 4.

set wildignore=*.o,*.obj,*~,*.pyc
set wildignore+=.env
set wildignore+=.env[0-9]+
set wildignore+=.git,.gitkeep
set wildignore+=.tmp
set wildignore+=.coverage
set wildignore+=*DS_Store*
set wildignore+=.sass-cache/
set wildignore+=__pycache__/
set wildignore+=vendor/rails/**
set wildignore+=vendor/cache/**
set wildignore+=*.gem
set wildignore+=log/**
set wildignore+=tmp/**
set wildignore+=.tox/**
set wildignore+=.idea/**
set wildignore+=*.egg,*.egg-info
set wildignore+=*.png,*.jpg,*.gif
set wildignore+=*.so,*.swp,*.zip,*/.Trash/**,*.pdf,*.dmg,*/Library/**,*/.rbenv/**
set wildignore+=*/.nx/**,*.app


" set statusline=@\ %t\%r%h%w\ [%{&fileencoding},%Y]\ %m%=\ [Pos=%l,%v,%p%%]\ [LINE=%L]

set laststatus=2
set statusline=%4*%<\ %1*[%F]
set statusline+=%4*\ %5*[%{&encoding}, " encoding
set statusline+=%{&fileformat}%{\"\".((exists(\"+bomb\")\ &&\ &bomb)?\",BOM\":\"\").\"\"}]%m
set statusline+=%4*%=\ %6*%y%4*\ %3*%l%4*,\ %3*%c%4*\ \<\ %2*%P%4*\ \>
highlight User1 ctermfg=red
highlight User2 term=underline cterm=underline ctermfg=green
highlight User3 term=underline cterm=underline ctermfg=yellow
highlight User4 term=underline cterm=underline ctermfg=white
highlight User5 ctermfg=cyan
highlight User6 ctermfg=white
