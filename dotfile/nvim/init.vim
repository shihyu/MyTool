" ============================================================================
" Neovim Configuration - Clean & Organized
" Author: Jason-Yao
" Description: A well-structured Neovim configuration for development
" ============================================================================

" ============================================================================
" BASIC SETTINGS
" ============================================================================

" Compatibility and core settings
set nocompatible
filetype off

" Language and encoding
language messages zh_TW.utf-8
set fencs=utf-8,gbk,big5,euc-jp,utf-16le
set fenc=utf-8 enc=utf-8

" Editor behavior
syntax on
filetype plugin indent on
set expandtab                   " Use spaces instead of tabs
set shiftwidth=4               " Number of spaces for autoindent
set tabstop=4                  " Number of spaces per tab
set softtabstop=4              " Backspace removes this many spaces
set autoindent                 " Auto indent new lines
set smartindent                " Smart indentation
set number                     " Show line numbers
set ruler                      " Show cursor position
set showcmd                    " Show command in status line
set hidden                     " Allow hidden buffers
set history=1000               " Command history size
set nomore                     " Don't pause for long messages
set nobackup                   " Don't create backup files
set noswapfile                 " Don't create swap files
set hlsearch                   " Highlight search results
set incsearch                  " Incremental search
set viminfo+=h                 " Don't highlight when loading viminfo
set nocp                       " No compatible mode
set t_Co=256                   " 256 colors
set backspace=indent,eol,start " Backspace behavior
set whichwrap+=<,>,[,]        " Cursor movement wrapping
set nofoldenable               " Disable folding by default
set mouse=                     " Disable mouse
set helplang=Cn               " Help language
set t_ti= t_te=               " Terminal settings

" Visual enhancements
set cursorline                 " Highlight current line
set signcolumn=yes            " Always show sign column
set updatetime=300            " Faster completion
set shortmess+=c              " Don't show completion messages
set tabpagemax=1000           " Maximum number of tabs

" Status line configuration
set laststatus=2
set statusline=[%n]\ %<%f\ %([%1*%M%*%R%Y]%)\ \ \ [%{Tlist_Get_Tagname_By_Line()}]\ %=%-19(\LINE\ [%l/%L]\ COL\ [%02c%03V]%)\ %P\ [%{&encoding}]

" ============================================================================
" PLUGIN MANAGEMENT
" ============================================================================

call plug#begin('~/.config/nvim/plugged')

" AI and Code Completion
Plug 'github/copilot.vim'
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" File Management & Navigation
Plug 'scrooloose/nerdtree'
Plug 'junegunn/fzf'
Plug 'vim-scripts/FuzzyFinder'

" Code Analysis & Tags
Plug 'majutsushi/tagbar'
Plug 'vim-scripts/taglist.vim'
Plug 'vim-scripts/cscope_macros.vim'

" Development Tools
Plug 'airblade/vim-gitgutter'              " Git integration
Plug 'terryma/vim-multiple-cursors'        " Multiple cursors
Plug 'tpope/vim-surround'                  " Surrounding text objects
Plug 'Raimondi/delimitMate'               " Auto-closing brackets
Plug 'Lokaltog/vim-easymotion'            " Easy text navigation
Plug 'kshenoy/vim-signature'              " Mark management

" Language Support
Plug 'sudar/vim-arduino-syntax'           " Arduino syntax
Plug 'maksimr/vim-jsbeautify'             " JavaScript beautifier

" Visual Enhancements
Plug 'luochen1990/rainbow'                " Rainbow parentheses
Plug 'vim-scripts/tir_black'              " Color scheme
Plug 'vim-scripts/Wombat'                 " Color scheme
Plug 'tomasr/molokai'                     " Color scheme

" Utilities
Plug 'vim-scripts/L9'                     " Vim script library
Plug 'drmingdrmer/xptemplate'             " Template system
Plug 'othree/eregex.vim'                  " Enhanced regex
Plug 'thinca/vim-logcat'                  " Android logcat
Plug 'vim-scripts/Quich-Filter'           " Text filtering
Plug 'bootleq/vim-tabline'                " Enhanced tabline
Plug 'vim-scripts/sessionman.vim'         " Session management
Plug 'chusiang/vim-sdcv'                  " Dictionary
Plug 'MattesGroeger/vim-bookmarks'        " Bookmark management
Plug 'mhinz/vim-startify'                 " Start screen
Plug 'vim-scripts/CCTree'                 " Call tree

call plug#end()

" ============================================================================
" COLOR SCHEME & APPEARANCE
" ============================================================================

" Color scheme
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
" KEY MAPPINGS
" ============================================================================

" --- Basic Mappings ---
imap jj <ESC>                              " Quick escape
imap <F1> <C-R>="[OOOOOOO]"<CR>          " Insert marker
imap <F2> <C-R>=strftime("%F %T")<CR>     " Insert timestamp

" --- Tab Management ---
nmap tl :tabnext<CR>                       " Next tab
nmap th :tabprev<CR>                       " Previous tab
nmap tn :tabnew<CR>                        " New tab
nmap td :tabclose<CR>                      " Close tab

" --- Indentation ---
nmap <tab> V>                              " Indent line
nmap <s-tab> V<                            " Unindent line
vmap <tab> >gv                             " Indent selection
vmap <s-tab> <gv                           " Unindent selection

" --- Text Selection & Manipulation ---
nmap <C-a> ggVG                            " Select all
nnoremap ,p :set paste!<BAR>set paste?<CR> " Toggle paste mode
nnoremap <F11> :%s/[ \t\r]\+$//g<CR>      " Remove trailing whitespace
noremap <leader>m :%s/\r//g<CR>            " Remove Windows line endings
noremap <leader><space> :%s/\s\+$//g<CR>  " Remove trailing spaces

" --- Navigation ---
nnoremap gb <C-o>                          " Go back
nnoremap qq <C-o>                          " Go back (alternative)
map <c-b> :tprevious<CR>                   " Previous tag
map <c-n> :tnext<CR>                       " Next tag

" --- Clipboard Operations ---
if has('clipboard')
    " Use system clipboard if available
    vmap <C-c> "+y
    nmap <C-c> "+yy
    imap <C-v> <ESC>"+pa
else
    " Fallback to external commands
    vmap <C-c> :w !xclip -selection clipboard<CR><CR>
    nmap <C-c> :.w !xclip -selection clipboard<CR><CR>
    nmap <C-v> :r !xclip -selection clipboard -o<CR>
    imap <C-v> <ESC>:r !xclip -selection clipboard -o<CR>a
endif

" --- Quick Filter ---
nmap <space>l :call FilteringNew().addToParameter('alt', @/).run()<CR>
nmap <space>F :call FilteringNew().parseQuery(input('>'), '<Bar>').run()<CR>
nmap <space>g :call FilteringGetForSource().return()<CR>
nmap <space>s :call ShowTrailingWhitespace()<CR>

" ============================================================================
" PLUGIN CONFIGURATIONS
" ============================================================================

" --- NERDTree ---
nnoremap <leader>p :NERDTreeToggle<CR>
nnoremap <silent> <F3> :NERDTree<CR>

" --- FuzzyFinder ---
nnoremap <leader>ff :FufFile<CR>
nnoremap <leader>fb :FufBuffer<CR>

" --- Tagbar ---
nmap <silent> <F12> :TagbarToggle<CR>

" --- GitGutter ---
let g:gitgutter_sign_added = '✚'
let g:gitgutter_sign_modified = '➡'
let g:gitgutter_sign_removed = '✘'
let g:gitgutter_sign_removed_first_line = '^^'
let g:gitgutter_sign_modified_removed = 'ww'
let g:gitgutter_max_signs = 50000

" --- Rainbow Parentheses ---
let g:rainbow_active = 1
let g:rainbow_conf = {
\   'guifgs': ['darkorange3', 'seagreen3', 'royalblue3', 'firebrick'],
\   'ctermfgs': ['lightyellow', 'lightcyan','lightblue', 'lightmagenta'],
\   'operators': '_,_',
\   'parentheses': ['start=/(/ end=/)/ fold', 'start=/\[/ end=/\]/ fold', 'start=/{/ end=/}/ fold'],
\   'separately': {
\       '*': {},
\       'vim': {
\           'parentheses': ['start=/(/ end=/)/', 'start=/\[/ end=/\]/', 'start=/{/ end=/}/ fold'],
\       },
\       'html': {
\           'parentheses': ['start=/\v\<((area|base|br|col|embed|hr|img|input|keygen|link|menuitem|meta|param|source|track|wbr)[ >])@!\z([-_:a-zA-Z0-9]+)(\s+[-_:a-zA-Z0-9]+(\=("[^"]*"|'."'".'[^'."'".']*'."'".'|[^ '."'".'"><=`]*))?)*\>/ end=#</\z1># fold'],
\       },
\       'css': 0,
\   }
\}

" --- Bookmarks ---
let g:bookmark_sign = '⚑'

" --- EasyMotion & Regex ---
let g:eregex_default_enable = 0
nnoremap ,/ :M/
nnoremap ,? :M?

" --- Vim-signature (Marks) ---
nmap <C-j> ']                              " Next mark
nmap <C-k> '[                              " Previous mark
nmap <C-.> ]`                              " Next mark (by position)
nmap <C-,> [`                              " Previous mark (by position)

" ============================================================================
" COC CONFIGURATION
" ============================================================================

" Node.js path for CoC
let g:coc_node_path = expand("$HOME/.mybin/node-v24.4.1-linux-x64/bin/node")

" --- Tab Completion ---
inoremap <silent><expr> <TAB>
      \ coc#pum#visible() ? coc#pum#next(1) :
      \ CheckBackspace() ? "\<Tab>" :
      \ coc#refresh()
inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"

function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" --- Completion & Documentation ---
inoremap <silent><expr> <c-space> coc#refresh()
inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"

nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

" --- Navigation ---
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
nmap <silent> tt <Plug>(coc-definition)

" --- Refactoring ---
nmap <leader>rn <Plug>(coc-rename)
nmap <leader>ac <Plug>(coc-codeaction)
nmap <leader>qf <Plug>(coc-fix-current)

" --- Commands ---
command! -nargs=0 Format :call CocAction('format')
command! -nargs=? Fold :call CocAction('fold', <f-args>)
command! -nargs=0 OR :call CocAction('runCommand', 'editor.action.organizeImport')

" --- Auto Commands ---
autocmd CursorHold * silent call CocActionAsync('highlight')

" ============================================================================
" DEVELOPMENT FUNCTIONS
" ============================================================================

" --- Code Formatting ---
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

" --- Compilation ---
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

" --- Execution ---
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

" --- Header/Source Switching ---
nmap ,s :call SwitchSourceHeader()<CR>
function! SwitchSourceHeader()
    if (expand("%:e") == "cpp")
        find %:t:r.h
    else
        find %:t:r.cpp
    endif
endfunction

" --- Utility Functions ---
function! ShowTrailingWhitespace()
    highlight WhitespaceEOL ctermbg=red guibg=red
    match WhitespaceEOL /\s\+$/
endfunction

" ============================================================================
" TAGLIST CONFIGURATION
" ============================================================================

let Tlist_Close_On_Select = 1              " Close on selection
let Tlist_Exit_OnlyWindow = 1              " Exit if only window
let Tlist_Show_Menu = 1                    " Show menu in GUI
let Tlist_Show_One_File = 1                " Show one file only
let Tlist_GainFocus_On_ToggleOpen = 1      " Focus on toggle
let Tlist_Highlight_Tag_On_BufEnter = 1    " Highlight current tag
let Tlist_Process_File_Always = 1          " Always process files
let Tlist_Use_Right_Window = 1             " Use right window
let Tlist_Display_Prototype = 1            " Display prototypes

map <F7> <ESC>:wincmd p<CR>               " Switch window

" Auto update tags
au! CursorHold *.[ch] nested exe "TlistUpdate"
au! CursorHold *.cpp nested exe "TlistUpdate"
au! CursorHold *.java nested exe "TlistUpdate"

" ============================================================================
" CTAGS CONFIGURATION
" ============================================================================

map <Leader>rt :!ctags --extra=+f -R *<CR><CR>

" ============================================================================
" FZF CONFIGURATION
" ============================================================================

let g:fzf_tmux_height = '20%'
let g:fzf_tmux_width = '20%'

" --- Buffer Management ---
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
" AUTO COMMANDS
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
" UTILITY COMMANDS
" ============================================================================

" Change directory to current file
cmap cd. lcd %:p:h

" Z command for quick directory navigation (requires fasd)
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
" QUICK REFERENCE
" ============================================================================
"
" Key Mappings Quick Reference:
" =============================
" jj                    -> Escape to normal mode
" <space>l              -> Show search results window
" <space>s              -> Show trailing whitespace
" <F3>                  -> Open NERDTree
" <F7>                  -> Switch between windows
" <F8>                  -> Format source code
" <F11>                 -> Remove trailing whitespace
" <F12>                 -> Toggle Tagbar
" <Leader>p             -> Toggle NERDTree
" <Leader>ff            -> FuzzyFinder files
" <Leader>fb            -> FuzzyFinder buffers
" <C-x><C-x>           -> Compile current file
" <C-r><C-r>           -> Run current file
" tt                    -> Go to definition (CoC)
" gd                    -> Go to definition (CoC)
" gr                    -> Show references (CoC)
" K                     -> Show documentation
" ,s                    -> Switch between header/source
" tl/th/tn/td          -> Tab navigation
"
" ============================================================================
