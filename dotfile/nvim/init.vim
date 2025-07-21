" ============================================================================
" Neovim Configuration - Refactored and Organized
" Author: Jason-Yao
" ============================================================================

" ============================================================================
" Basic Settings
" ============================================================================
set nocompatible
filetype off

" Language and encoding
language messages zh_TW.utf-8
set fencs=utf-8,gbk,big5,euc-jp,utf-16le
set fenc=utf-8 enc=utf-8

" Clipboard configuration
if has('unnamedplus')
    set clipboard=unnamedplus  " Use system clipboard
else
    set clipboard=unnamed      " Fallback
endif

" Basic editor settings
syntax on
filetype plugin indent on
set expandtab
set shiftwidth=4
set tabstop=4
set softtabstop=4
set autoindent
set smartindent
set number
set ruler
set showcmd
set hidden
set history=1000
set nomore
set nobackup
set noswapfile
set hlsearch
set incsearch
set viminfo+=h
set nocp
set t_Co=256
set backspace=indent,eol,start
set whichwrap+=<,>,[,]
set nofoldenable
set mouse=
set helplang=Cn
set t_ti= t_te=

" Status line configuration
set laststatus=2
set statusline=[%n]\ %<%f\ %([%1*%M%*%R%Y]%)\ \ \ [%{Tlist_Get_Tagname_By_Line()}]\ %=%-19(\LINE\ [%l/%L]\ COL\ [%02c%03V]%)\ %P\ [%{&encoding}]

" Tab settings
set tabpagemax=1000

" Visual enhancements
set cursorline
set signcolumn=yes
set updatetime=300
set shortmess+=c

" ============================================================================
" Plugin Management
" ============================================================================
call plug#begin('~/.config/nvim/plugged')

" AI and completion
Plug 'github/copilot.vim'
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" File management and navigation
Plug 'scrooloose/nerdtree'
Plug 'junegunn/fzf'
Plug 'vim-scripts/FuzzyFinder'

" Development tools
Plug 'majutsushi/tagbar'
Plug 'vim-scripts/taglist.vim'
Plug 'luochen1990/rainbow'
Plug 'airblade/vim-gitgutter'
Plug 'terryma/vim-multiple-cursors'
Plug 'tpope/vim-surround'
Plug 'Raimondi/delimitMate'

" Language support
Plug 'sudar/vim-arduino-syntax'
Plug 'maksimr/vim-jsbeautify'

" Utilities
Plug 'vim-scripts/L9'
Plug 'vim-scripts/cscope_macros.vim'
Plug 'drmingdrmer/xptemplate'
Plug 'Lokaltog/vim-easymotion'
Plug 'othree/eregex.vim'
Plug 'thinca/vim-logcat'
Plug 'kshenoy/vim-signature'
Plug 'vim-scripts/Quich-Filter'
Plug 'bootleq/vim-tabline'
Plug 'vim-scripts/sessionman.vim'
Plug 'chusiang/vim-sdcv'
Plug 'MattesGroeger/vim-bookmarks'
Plug 'mhinz/vim-startify'

" Color schemes
Plug 'vim-scripts/tir_black'
Plug 'vim-scripts/Wombat'
Plug 'tomasr/molokai'
Plug 'vim-scripts/CCTree'

call plug#end()

" ============================================================================
" Color Scheme and Appearance
" ============================================================================
colors tir_black
colorscheme molokai
set notermguicolors

" Custom highlighting
hi cursorcolumn cterm=bold ctermbg=237 ctermfg=none term=bold
hi cursorline cterm=bold ctermbg=237 ctermfg=none term=bold
hi TabLineSel ctermfg=yellow ctermbg=darkblue cterm=bold
hi StatusLine ctermfg=yellow ctermbg=darkblue cterm=bold
hi LineNr ctermfg=yellow
hi Visual cterm=reverse ctermbg=none ctermfg=none guibg=none guifg=none
hi EasyMotionTarget ctermbg=none ctermfg=red
hi EasyMotionShade ctermbg=none ctermfg=blue
hi BookmarkSign ctermbg=NONE ctermfg=160

" Disable cursor blinking
set gcr=a:block-blinkon0

" ============================================================================
" Key Mappings
" ============================================================================

" Basic mappings
imap jj <ESC>
imap <F1> <C-R>="[OOOOOOO]"<CR>
imap <F2> <C-R>=strftime("%F %T")<CR>
imap <C-F11> <C-R>=strftime("%x %X")<BAR><CR>. owen_wen@htc.com.<ESC>

" Tab management
nmap tl :tabnext<CR>
nmap th :tabprev<CR>
nmap tn :tabnew<CR>
nmap td :tabclose<CR>

" Indentation
nmap <tab> V>
nmap <s-tab> V<
vmap <tab> >gv
vmap <s-tab> <gv

" File operations
nmap <C-a> ggVG
nnoremap ,p :set paste!<BAR>set paste?<CR>

" Clipboard operations - with fallback support
if has('clipboard')
    " Use system clipboard if available
    vmap <C-c> "+y
    nmap <C-c> "+yy
    imap <C-v> <ESC>"+pa
    nmap <C-v> "+p
    vmap <C-v> "+p
else
    " Fallback to external commands
    vmap <C-c> :w !xclip -selection clipboard<CR><CR>
    nmap <C-c> :.w !xclip -selection clipboard<CR><CR>
    nmap <C-v> :r !xclip -selection clipboard -o<CR>
    imap <C-v> <ESC>:r !xclip -selection clipboard -o<CR>a
endif

" Text manipulation
nnoremap <F11> :%s/[ \t\r]\+$//g<CR>
noremap <leader>m :%s/\r//g<CR>
noremap <leader><space> :%s/\s\+$//g<CR>

" Navigation
nnoremap gb <C-o>
nnoremap qq <C-o>
map <c-b> :tprevious<CR>
map <c-n> :tnext<CR>

" ============================================================================
" Plugin Configurations
" ============================================================================

" NERDTree
nnoremap <leader>p :NERDTreeToggle<CR>
nnoremap <silent> <F3> :NERDTree<CR>

" FuzzyFinder
nnoremap <leader>ff :FufFile<CR>
nnoremap <leader>fb :FufBuffer<CR>

" Tagbar
nmap <silent> <F12> :TagbarToggle<CR>

" GitGutter
let g:gitgutter_sign_added = '✚'
let g:gitgutter_sign_modified = '➡'
let g:gitgutter_sign_removed = '✘'
let g:gitgutter_sign_removed_first_line = '^^'
let g:gitgutter_sign_modified_removed = 'ww'
let g:gitgutter_max_signs = 50000

" Rainbow parentheses
let g:rainbow_active = 1
let g:rainbow_conf = {
\   'guifgs': ['darkorange3', 'seagreen3', 'royalblue3', 'firebrick'],
\   'ctermfgs': ['lightyellow', 'lightcyan','lightblue', 'lightmagenta'],
\   'operators': '_,_',
\   'parentheses': ['start=/(/ end=/)/ fold', 'start=/\[/ end=/\]/ fold', 'start=/{/ end=/}/ fold'],
\}

" Bookmarks
let g:bookmark_sign = '⚑'

" EasyMotion
let g:eregex_default_enable = 0
nnoremap ,/ :M/
nnoremap ,? :M?

" Vim-signature
nmap <C-j> ']
nmap <C-k> '[
nmap <C-.> ]`
nmap <C-,> [`

" ============================================================================
" CoC Configuration
" ============================================================================
let g:coc_node_path = expand("$HOME/.mybin/node-v24.4.1-linux-x64/bin/node")

" Tab completion
inoremap <silent><expr> <TAB>
      \ coc#pum#visible() ? coc#pum#next(1) :
      \ CheckBackspace() ? "\<Tab>" :
      \ coc#refresh()
inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"

function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Trigger completion
inoremap <silent><expr> <c-space> coc#refresh()
inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"

" Navigation
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
nmap <silent> tt <Plug>(coc-definition)

" Documentation
nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

" Refactoring
nmap <leader>rn <Plug>(coc-rename)
nmap <leader>ac <Plug>(coc-codeaction)
nmap <leader>qf <Plug>(coc-fix-current)

" Commands
command! -nargs=0 Format :call CocAction('format')
command! -nargs=? Fold :call CocAction('fold', <f-args>)
command! -nargs=0 OR :call CocAction('runCommand', 'editor.action.organizeImport')

" Auto commands
autocmd CursorHold * silent call CocActionAsync('highlight')

" ============================================================================
" Development Functions
" ============================================================================

" Code formatting
nmap <F8> :call FormartSrc()<CR>
function! FormartSrc()
    exec "w"
    if &filetype == 'c'
        exec "!astyle %"
    elseif &filetype == 'cpp' || &filetype == 'hpp'
        exec "!astyle %"
    elseif &filetype == 'rust'
        exec "!rustfmt --edition 2024 %"
    elseif &filetype == 'go'
        exec "!gofmt -l -w %"
    elseif &filetype == 'python' || &filetype == 'py'
        exec "!black % > /dev/null 2>&1"
    elseif &filetype == 'perl'
        exec "!astyle --style=gnu --suffix=none %"
    elseif &filetype == 'java'
        exec "!astyle --style=java --suffix=none %"
    elseif &filetype == 'jsp'
        exec "!astyle --style=gnu --suffix=none %"
    elseif &filetype == 'xml'
        exec "!astyle --style=gnu --suffix=none %"
    endif
    exec "e! %"
endfunction

" Compile function
nmap <C-x><C-x> :call Compile_gcc()<CR>
function! Compile_gcc()
    if &filetype=="c"
        set autochdir
        execute "w"
        execute "!gcc -Wall -pedantic -g -O0 -std=gnu99 % -o %:r -lm -pthread"
    elseif &filetype=="cpp"
        set autochdir
        execute "w"
        execute "!g++ -Wall -Wextra -g -std=c++17 -pthread % -o %:r"
    elseif &filetype=="rust"
        set autochdir
        execute "w"
        execute "!rustc -C debuginfo=2 --edition 2024 %:r.rs"
    elseif &filetype=="go"
        set autochdir
        execute "w"
        execute "!go build %:r.go"
    elseif &filetype=="java"
        set autochdir
        execute "w"
        execute "!javac %:r.java"
    elseif &filetype=="kotlin"
        set autochdir
        execute "w"
        execute '!kotlinc %:t -include-runtime -d %:r.jar'
    endif
endfunction

" Run function
nmap <C-r><C-r> :call Run_gcc()<CR>
function! Run_gcc()
    if &filetype=="c" || &filetype=="cpp" || &filetype=="rust" || &filetype=="go"
        set autochdir
        execute "! ./%:r"
    elseif &filetype=="python"
        set autochdir
        execute "w !python"
    elseif &filetype=="php"
        set autochdir
        execute "w !php"
    elseif &filetype=="java"
        set autochdir
        execute "w !java %:r"
    elseif &filetype=="kotlin"
        set autochdir
        execute "w"
        execute '!kotlin %:r.jar'
    endif
endfunction

" Switch between header and source
nmap ,s :call SwitchSourceHeader()<CR>
function! SwitchSourceHeader()
    if (expand("%:e") == "cpp")
        find %:t:r.h
    else
        find %:t:r.cpp
    endif
endfunction

" Show trailing whitespace
nmap <space>s :call ShowTrailingWhitespace()<CR>
function! ShowTrailingWhitespace()
    highlight WhitespaceEOL ctermbg=red guibg=red
    match WhitespaceEOL /\s\+$/
endfunction

" ============================================================================
" TagList Configuration
" ============================================================================
let Tlist_Close_On_Select = 1
let Tlist_Exit_OnlyWindow = 1
let Tlist_Show_Menu = 1
let Tlist_Show_One_File = 1
let Tlist_GainFocus_On_ToggleOpen = 1
let Tlist_Highlight_Tag_On_BufEnter = 1
let Tlist_Process_File_Always = 1
let Tlist_Use_Right_Window = 1
let Tlist_Display_Prototype = 1

map <F7> <ESC>:wincmd p<CR>

" Auto update
au! CursorHold *.[ch] nested exe "TlistUpdate"
au! CursorHold *.cpp nested exe "TlistUpdate"
au! CursorHold *.java nested exe "TlistUpdate"

" ============================================================================
" CTags Configuration
" ============================================================================
map <Leader>rt :!ctags --extra=+f -R *<CR><CR>

" ============================================================================
" FZF Configuration
" ============================================================================
let g:fzf_tmux_height = '20%'
let g:fzf_tmux_width = '20%'

" Buffer list
function! BufList()
  redir => ls
  silent ls
  redir END
  return split(ls, '\n')
endfunction

function! BufOpen(e)
  execute 'buffer '. matchstr(a:e, '^[ 0-9]*')
endfunction

nnoremap <silent> <Leader>] :call fzf#run({
      \   'source':      reverse(BufList()),
      \   'sink':        function('BufOpen'),
      \   'options':     '+m',
      \   'tmux_width': '20%'
      \ })<CR>

nnoremap <silent> <Leader>o :call fzf#run({
      \   'sink':       'tabe',
      \   'options':     '-m',
      \   'tmux_width': '40%'
      \ })<CR>

" ============================================================================
" Auto Commands
" ============================================================================

" Preserve last editing position
if has("autocmd")
   autocmd BufRead *.txt set tw=78
   autocmd BufReadPost *
      \ if line("'\"") > 0 && line ("'\"") <= line("$") |
      \   exe "normal g'\"" |
      \ endif
endif

" Rust single file configuration
augroup RustSingleFile
  autocmd!
  autocmd BufRead,BufNewFile *.rs 
    \ if !filereadable(expand('%:p:h') . '/Cargo.toml') && 
    \    !filereadable(expand('%:p:h') . '/../Cargo.toml') |
    \   let b:coc_enabled = 0 |
    \ endif
augroup END

" ============================================================================
" Utility Commands
" ============================================================================

" Change directory to current file
cmap cd. lcd %:p:h

" Z command for quick directory navigation
command! -nargs=* Z :call Z(<f-args>)
function! Z(...)
  let cmd = 'fasd -d -e printf'
  for arg in a:000
    let cmd = cmd . ' ' . arg
  endfor
  let path = system(cmd)
  if isdirectory(path)
    echo path
    exec 'cd ' . path
  endif
endfunction

" ============================================================================
" Legacy and Commented Configurations
" ============================================================================
" Note: Many legacy configurations have been commented out or removed
" for clarity. Uncomment and adapt as needed for specific use cases.

" End of configuration
