set nocompatible               " be iMproved
filetype off                   " required!
call plug#begin('~/.vim/plugged')
Plug 'github/copilot.vim'
Plug 'vim-scripts/L9'
Plug 'vim-scripts/cscope_macros.vim'
Plug 'scrooloose/nerdtree'
Plug 'SirVer/ultisnips'
Plug 'drmingdrmer/xptemplate'
Plug 'vim-scripts/FuzzyFinder'
Plug 'vim-scripts/AutoComplPop'
Plug 'tpope/vim-surround'
Plug 'Lokaltog/vim-easymotion'
Plug 'vim-scripts/tir_black'
Plug 'othree/eregex.vim'
Plug 'vim-scripts/Wombat'
Plug 'tomasr/molokai'
Plug 'vim-scripts/CCTree'
Plug 'vim-scripts/taglist.vim'
Plug 'majutsushi/tagbar'
Plug 'thinca/vim-logcat'
Plug 'kshenoy/vim-signature'
Plug 'vim-scripts/Quich-Filter'
Plug 'bootleq/vim-tabline'
Plug 'Raimondi/delimitMate'
Plug 'terryma/vim-multiple-cursors'
Plug 'sudar/vim-arduino-syntax'
Plug 'vim-scripts/sessionman.vim'
Plug 'maksimr/vim-jsbeautify'
Plug 'airblade/vim-gitgutter'
Plug 'chusiang/vim-sdcv'
Plug 'MattesGroeger/vim-bookmarks'
Plug 'ludovicchabant/vim-gutentags'
Plug 'skywind3000/gutentags_plus'
Plug 'junegunn/fzf'
"Plug 'autozimu/LanguageClient-neovim', { 'branch': 'next' }
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'luochen1990/rainbow'
call plug#end()

filetype plugin indent on

"nmap <leader>U :GundoToggle<cr>
"let g:gundo_preview_bottom = 1
"let g:gundo_preview_height = 10
"let g:gundo_width = 30

cabbrev ack <c-r>=(getcmdtype()==':' && getcmdpos()==1 ? 'Ack' : 'ack')<CR>
if has ("Ack")
    copen 30
endif

" Basic Settings:
syntax on
filetype on
filetype plugin on
filetype indent on
colors tir_black
language messages zh_TW.utf-8

set fencs=utf-8,gbk,big5,euc-jp,utf-16le
"set fencs=utf-8,gbk,big5
set fenc=utf-8 enc=utf-8 tenc=utf-8
set t_ti= t_te=
set expandtab
set shiftwidth=4
set tabstop=4
set history=1000
set nomore
set laststatus=2
set statusline=%<%f\ %h%m%r%=%-14.(%l,%c%V%)\ %P>
set statusline=%4*%<\ %1*[%F]
set statusline+=%4*\ %5*[%{&encoding}, " encoding
set statusline+=%{&fileformat}%{\"\".((exists(\"+bomb\")\ &&\ &bomb)?\",BOM\":\"\").\"\"}]%m
set statusline+=%4*%=\ %6*%y%4*\ %3*%l%4*,\ %3*%c%4*\ \<\ %2*%P%4*\ \>

set ruler
set softtabstop=4
set nobackup
"set cindent
set autoindent
set smartindent
set showcmd
set helplang=Cn
set hidden
set nofoldenable
set noswapfile
set number
"set mouse=nv
set hlsearch
set incsearch
set viminfo+=h
set nocp
set t_Co=256
set backspace=indent,eol,start whichwrap+=<,>,[,]
"autocmd FileType perl set keywordprg=perldoc\ -f
"copen 25

"nmap <F8> gg :w<CR> :!astyle %<CR><CR> :edit!<CR>
nmap <F8> :call FormartSrc()<CR>
func FormartSrc()
    exec "w"
    if &filetype == 'c'
        exec "!astyle %"
    elseif &filetype == 'cpp' || &filetype == 'hpp'
        exec "!astyle %"
    elseif &filetype == 'rust'
        exec "!rustfmt %"
    elseif &filetype == 'go'
        exec "!gofmt -l -w %"
    elseif &filetype == 'perl'
        exec "!astyle --style=gnu --suffix=none %"
    elseif &filetype == 'py'||&filetype == 'python'
        exec "r !pydent % > /dev/null 2>&1"
    elseif &filetype == 'java'
        exec "!astyle --style=java --suffix=none %"
    elseif &filetype == 'jsp'
        exec "!astyle --style=gnu --suffix=none %"
    elseif &filetype == 'xml'
        exec "!astyle --style=gnu --suffix=none %"
    endif
    exec "e! %"
endfunc

"進行make的設置
"map <F8> :call Do_make()<CR>
"function Do_make()
"    set autochdir
"    set makeprg=make
"    execute "silent make"
"    execute "copen"
"endfunction

"map <F9> :call Do_makei_clean()<CR>
"function Do_makei_clean()
"    set autochdir
"    execute "silent make clean"
"endfunction

"單檔gcc compile
nmap <C-c><C-c> :call Compile_gcc()<CR>
function Compile_gcc()
    if &filetype=="c"
        set autochdir
        execute "w"
        "execute "!clang -Wall -Wextra -O2 -g  % -o %:r -lm"
        "execute "!gcc  -Wall -pedantic -g -O0 -std=gnu99 % -o %:r -lGL -lglut -lGLU -lSDL -lm -pthread"
        execute "!gcc  -Wall -pedantic -g -O0 -std=gnu99 % -o %:r -lm -pthread"
    elseif &filetype=="cpp"
        set autochdir
        execute "w"
        execute "!g++ -Wall -Wextra -g -std=c++11 -pthread % -o %:r"
        "execute "!clang++ -Wall -Wextra -O2 -g -std=c++11 % -o %:r"
        "execute "!g++  -Wall -pedantic -ansi -ggdb3 -std=c++11 -O0 % -o %:r -lGL -lglut -lGLU -lSDL -lGLEW -pthread `pkg-config --libs --cflags opencv2`"
        "execute "!g++  -Wall -pedantic -ansi -ggdb3 -std=c++11 -O0 % -o %:r -lGL -lglut -lGLU -lGLEW -pthread"
    elseif &filetype=="rust"
        set autochdir
        execute "w"
        execute "!rustc %:r.rs"
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

"單檔RUN
nmap <C-r><C-r> :call Run_gcc()<CR>
function Run_gcc()
    if &filetype=="c"
        set autochdir
        execute "! ./%:r"
    elseif &filetype=="cpp"
        set autochdir
        execute "! ./%:r"
    elseif  &filetype=="python"
        set autochdir
        execute "w !python"
    elseif  &filetype=="php"
        "sudo aptitude install php5-cli
        set autochdir
        execute "w !php"
    elseif  &filetype=="rust"
        set autochdir
        execute "! ./%:r"
    elseif  &filetype=="go"
        set autochdir
        execute "! ./%:r"
    elseif  &filetype=="java"
        set autochdir
        execute "w !java %:r"
    elseif &filetype=="kotlin"
        set autochdir
        execute "w"
        execute '!kotlin %:r.jar'
    endif
endfunction

imap <F1> <C-R>="[OOOOOOO]"<CR>
imap <F2> <C-R>=strftime("%F %T")<CR>
imap jj <ESC>
"imap ,, -><C-X><C-O>

" 刪除所有行未尾空格
nnoremap <F11> :%s/[ \t\r]\+$//g<cr>

nnoremap <leader>p  :NERDTreeToggle<CR>
nnoremap <leader>ff  :FufFile<CR>
nnoremap <leader>fb  :FufBuffer<CR>

"Remove the Windows ^M
noremap <leader>m  :%s/\r//g<CR>

"Remove the space
noremap <leader><space> :% s/\s\+$//g<CR>

"eregex.vim
let g:eregex_default_enable = 0
nnoremap ,/ :M/
nnoremap ,? :M?
"nnoremap ,/ /
"nnoremap ,? ?

nmap <tab> V>
nmap <s-tab> V<
vmap <tab> >gv
vmap <s-tab> <gv

"imap <C-h> <left>
"imap <C-j> <down>
"imap <C-k> <up>
"imap <C-l> <right>

"映射按鍵：剪切版、全選，系統有效
vmap <C-c> "+y
"vmap <C-x> "+x
"nmap <C-v> "+gP
"vmap <C-v> "+gP
nmap <C-a> ggVG

" ,p toggles paste mode
nnoremap ,p :set paste!<BAR>set paste?<CR>

" vim-logcat
nnoremap ,l :set filetype=logcat<CR>
nnoremap ,k :set filetype=<CR>

" :cd. change working directory to that of the current file
cmap cd. lcd %:p:h

function! SwitchSourceHeader()
  "update!
  if (expand ("%:e") == "cpp")
    find %:t:r.h
  else
    find %:t:r.cpp
  endif
endfunction

nmap ,s :call SwitchSourceHeader()<CR>

"nmap <F5> ^W_^W\|
"nmap <F6> ^W=
"imap <F5> <ESC>^W_^W\|a
"imap <F6> <ESC>^W=a
"nmap gF ^Wf

"setup doxygen：sudo apt-get install doxygen
map <F4>a  :DoxAuthor<CR>
map <F4>f  :Dox
map <F4>b  :DoxBlock<CR>
map <F4>l  :DoxLic<CR>
map <F4>c :odocClass<C-B>
map <F4>m :odocMember<C-B>

let g:DoxygenToolkit_authorName="Jason-Yao"
let s:licenseTag = "Copyright(C)\<enter>"
let s:licenseTag = s:licenseTag . "For free\<enter>"
let s:licenseTag = s:licenseTag . "All right reserved\<enter>"
let g:DoxygenToolkit_licenseTag = s:licenseTag
let g:DoxygenToolkit_briefTag_funcName="yes"
let g:doxygen_enhanced_color=1

let g:NeoComplCache_DisableAutoComplete = 1
"let g:SuperTabRetainCompletionType = 2
"let g:SuperTabDefaultCompletionType = "<C-X><C-U>"

noremap <C-W><C-U> :CtrlPMRU<CR>
nnoremap <C-W>u :CtrlPMRU<CR>

"let g:ctrlp_custom_ignore = '\.git$\|\.hg$\|\.svn$\|.rvm$'

"let g:ctrlp_custom_ignore = {
"    \ 'dir': '\v[\/]\.(git|hg|svn)$',
"    \ 'file': '\v\.(exe|so|dll|bak|gds)$',
"    \ 'link': 'SOME_BAD_SYMBOLIC_LINKS',
"    \ }
"let g:ctrlp_by_filename = 1 " only lookup file name
"let g:ctrlp_cache_dir = '/tmp/ctrlp/cache/'
"let g:ctrlp_working_path_mode=0
"let g:ctrlp_match_window_bottom=1
"let g:ctrlp_max_height=15
"let g:ctrlp_match_window_reversed=0
"let g:ctrlp_mruf_max=500
"let g:ctrlp_follow_symlinks=1
""let g:ctrlp_clear_cache_on_exit = 0
"let g:ctrlp_max_files = 1000000
"let g:ctrlp_user_command = 'find %s -type f | grep -P "\.h$|\.hpp$|\.c$|\.cc$|\.cpp$|\.java$"'
""let g:ctrlp_user_command = 'find %s -type f | grep -P "\.pl$|\.py$|\.lua$|\.xml$|\.sh$|\.mk$|\.h$|\.hh$|\.hpp$|\.c$|\.cc$|\.cpp$"'
"" CtrlP - open in new tab by default
"let g:ctrlp_prompt_mappings = {
"    \ 'AcceptSelection("e")': ['<c-t>', '<2-LeftMouse>'],
"    \ 'AcceptSelection("t")': ['<cr>'],
"\ }

let g:ctrlp_cmd = 'CtrlP'
map <leader>f :CtrlPMRU<CR>
let g:ctrlp_custom_ignore = {
    \ 'dir':  '\v[\/]\.(git|hg|svn|rvm)$',
    \ 'file': '\v\.(exe|so|dll|zip|tar|tar.gz|pyc)$',
    \ }
let g:ctrlp_by_filename = 1 " only lookup file name
let g:ctrlp_cache_dir = '/tmp/ctrlp/cache/'
let g:ctrlp_working_path_mode=0
let g:ctrlp_match_window_bottom=1
let g:ctrlp_follow_symlinks=1
let g:ctrlp_max_height=15
let g:ctrlp_match_window_reversed=0
let g:ctrlp_max_files = 1000000
let g:ctrlp_mruf_max=500
let g:ctrlp_follow_symlinks=1
let g:ctrlp_clear_cache_on_exit = 0
"let g:ctrlp_user_command = 'find %s -type f | grep -P "\.h$|\.hpp$|\.c$|\.cc$|\.cpp$|\.java$"'

let g:ctrlp_prompt_mappings = {
    \ 'AcceptSelection("e")': ['<c-t>', '<2-LeftMouse>'],
    \ 'AcceptSelection("t")': ['<cr>'],
\ }


if has("gdb")
    set splitright
    set previewheight=60
    "set splitright
    "set splitbelow
    set asm=0
    set gdbprg=gdb
    nmap <silent><LEADER>g :run macros/gdb_mappings.vim<cr>
    nmap <silent> <LEADER>v :bel 8 split gdb-variables<CR>
    let g:vimgdb_debug_file = ""
    run macros/gdb_mappings.vim
endif

"hi Normal ctermfg=grey ctermbg=black
"hi Visual ctermfg=green ctermbg=black
"hi Search term=reverse cterm=standout ctermfg=green  ctermbg=yellow
"hi IncSearch term=reverse cterm=standout ctermfg=green ctermbg=yellow
"hi PmenuSel ctermbg=green ctermfg=Yellow

"Preserve last editing position in VIM
"need remove ~/.viminfo
if has("autocmd")
   autocmd BufRead *.txt set tw=78
   autocmd BufReadPost *
      \ if line("'\"") > 0 && line ("'\"") <= line("$") |
      \   exe "normal g'\"" |
      \ endif
endif

colorscheme molokai
set cursorline
"set cursorcolumn
"highlight CursorLine cterm=none ctermbg=237
hi cursorcolumn cterm=bold ctermbg=237 ctermfg=none term=bold
hi cursorline cterm=bold ctermbg=237 ctermfg=none term=bold
highlight TabLineSel ctermfg=yellow ctermbg=darkblue cterm=bold
highlight StatusLine ctermfg=yellow ctermbg=darkblue cterm=bold
highlight LineNr ctermfg=yellow

" 刪除指標閃爍 , Terminator Profiles -> General 把 Cursor blink 勾選拿掉
set gcr=a:block-blinkon0

imap <C-F11> <C-R>=strftime("%x %X")<BAR><CR>. owen_wen@htc.com.<ESC> <C-R>
nnoremap <silent> <F3> :NERDTree<CR>

" Open .h if it's a cpp file, and vice versa.
function! OpenComplementFile()
  let f = expand('%')   " (1)
  let suffix = matchstr(f, '\.\a\+$')
  let pattern = suffix . "$"
  if suffix == '.h'
    let suffixes = ['.cpp', '.cc', '.mm', '.m', '.h']
    for suf in suffixes
      let target = substitute(f, pattern, suf, '')   " (2)
      if filereadable(target)
        break
      endif
    endfor
  elseif suffix == '.cpp' || suffix == '.cc' || suffix == '.m' || suffix == '.mm'
    let target = substitute(f, pattern, '.h', '')
    if !filereadable(target)
      let tmp = target
      let target = substitute(tmp, '\v(.+)\..+', 'public/\1.h', '')  " (3)
      if !filereadable(target)
        let target = substitute(tmp, '\v(.+)/(.+)\.(.+)', '\1/public/\2.h', '')
      endif
    endif
  else
    let target = ''
  endif

  if filereadable(target)
    exec 'vsplit ' target
  else
    echo "Complement file not found"
  endif
endfunction
nnoremap <silent> <F4> :call OpenComplementFile()<CR>


hi EasyMotionTarget ctermbg=none ctermfg=red
hi EasyMotionShade  ctermbg=none ctermfg=blue

"let g:agprg="<custom-ag-path-goes-here> --column"
"
"
au FileType qf call AdjustWindowHeight(3, 20)
function! AdjustWindowHeight(minheight, maxheight)
   let l = 1
   let n_lines = 0
   let w_width = winwidth(0)
   while l <= line('$')
       " number to float for division
       let l_len = strlen(getline(l)) + 0.0
       let line_width = l_len/w_width
       let n_lines += float2nr(ceil(line_width))
       let l += 1
   endw
   exe max([min([n_lines, a:maxheight]), a:minheight]) . "wincmd _"
endfunction

"將當前正在編輯但未保存的文件與已保存的做diff
func  DiffWithSaved ()
    let  ft = &filetype
     diffthis
    vnew  |  r  # |  normal!  1Gdd
     diffthis
    exe  "setlocal bt=nofile bh=wipe nobl noswf ro ft="  .  ft
endfunc
nnoremap <leader>df  :call DiffWithSaved()<CR>

"刪除行末空格
"func  DeleteTrailingWhiteSpace ()
"    normal  mZ
"     % s / \s\+$ // e
"    normal  `Z
"endfunc
"au  BufWrite  *  if  &ft  !=  'mkd'  |  call  DeleteTrailingWhiteSpace ()  |  endif

"Show_current_function_name_in_C_programs
"fun! ShowFuncName()
"  let lnum = line(".")
"  let col = col(".")
"  echohl ModeMsg
"
"
"  if &filetype=="java"
"      "java code
"      echo getline(search("\\h\\+\\s\\+\\h\\+\\s*(.*)", 'bW'))
"  else
"      " c/c++ code
"      echo getline(search("^[^ \t#/]\\{2}.*[^:]\s*$", 'bW'))
"  endif
"
"  echohl None
"  call search("\\%" . lnum . "l" . "\\%" . col . "c")
"endfun
"map F :call ShowFuncName() <CR>


" TagList options
" updatetime 加速
" set updatetime=1000
let Tlist_Close_On_Select = 1 "close taglist window once we selected something
let Tlist_Exit_OnlyWindow = 1 "if taglist window is the only window left, exit vim
let Tlist_Show_Menu = 1 "show Tags menu in gvim
let Tlist_Show_One_File = 1 "show tags of only one file
let Tlist_GainFocus_On_ToggleOpen = 1 "automatically switch to taglist window
let Tlist_Highlight_Tag_On_BufEnter = 1 "highlight current tag in taglist window
let Tlist_Process_File_Always = 1 "even without taglist window, create tags file, required for displaying tag in statusline
let Tlist_Use_Right_Window = 1 "display taglist window on the right
let Tlist_Display_Prototype = 1 "display full prototype instead of just function name
"set statusline=[%{&encoding}]\ [%n]\ %<%f\ %([%1*%M%*%R%Y]%)\ \ \ [%{Tlist_Get_Tagname_By_Line()}]\ %=%-19(\LINE\ [%l/%L]\ COL\ [%02c%03V]%)\ %P
set statusline=[%n]\ %<%f\ %([%1*%M%*%R%Y]%)\ \ \ [%{Tlist_Get_Tagname_By_Line()}]\ %=%-19(\LINE\ [%l/%L]\ COL\ [%02c%03V]%)\ %P\ [%{&encoding}]
"set statusline=[%n]\ %<%f\ %([%1*%M%*%R%Y]%)\ \ \ [%{Tlist_Get_Tag_Prototype_By_Line()}]\ %=%-19(\LINE\ [%l/%L]\ COL\ [%02c%03V]%)\ %P
"map F :TlistShowPrototype <CR>
map <F7> <ESC>:wincmd p<CR>
nmap <silent> <F12> :TagbarToggle<CR>
"自動更新
au! CursorHold *.[ch] nested exe "TlistUpdate"
au! CursorHold *.cpp nested exe "TlistUpdate"
au! CursorHold *.java nested exe "TlistUpdate"

" TagList options
"let Tlist_Close_On_Select = 1 "close taglist window once we selected something
"let Tlist_Exit_OnlyWindow = 1 "if taglist window is the only window left, exit vim
"let Tlist_Show_Menu = 1 "show Tags menu in gvim
"let Tlist_Show_One_File = 1 "show tags of only one file
"let Tlist_GainFocus_On_ToggleOpen = 1 "automatically switch to taglist window
"let Tlist_Highlight_Tag_On_BufEnter = 1 "highlight current tag in taglist window
"let Tlist_Process_File_Always = 1 "even without taglist window, create tags file, required for displaying tag in statusline
"let Tlist_Use_Right_Window = 1 "display taglist window on the right
"let Tlist_Display_Prototype = 1 "display full prototype instead of just function name
""let Tlist_Ctags_Cmd = /path/to/exuberant/ctags
"nnoremap <F5> :TlistToggle
"nnoremap <F6> :TlistShowPrototype
"set statusline=[%n]\ %<%f\ %([%1*%M%*%R%Y]%)\ \ \ [%{Tlist_Get_Tagname_By_Line()}]\ %=%-19(\LINE\ [%l/%L]\ COL\ [%02c%03V]%)\ %P

"vim-signature
nmap <C-j> ']
nmap <C-k> '[
"nmap .. ]`
"nmap ,, [`
nmap <C-.> ]`
nmap <C-,> [`


" Quich Filter {{{2
" 自動跟著原始檔案
"let g:filteringDefaultAutoFollow = 1

" After / search, use this to show the search result window
" just like quickfix list, but with sync scroll
nmap <space>l :call FilteringNew().addToParameter('alt', @/).run()<CR>
" After / search, use this to enter a keword filtering the search
" i.e. do a second search in the first search result
nmap <space>F :call FilteringNew().parseQuery(input('>'), '<Bar>').run()<CR>
" Re-open previous "look" windows selectively
nmap <space>g :call FilteringGetForSource().return()<CR>

" Old settings, name are more intuitive to understand
" nmap <Leader>F :call Gather(input("Filter on term: "), 0)<CR>
" nmap <Leader>l :call Gather(@/, 0)<CR>:echo<CR>
" nmap <Leader>g :call GotoOpenSearchBuffer()<CR>
" }}}

"Ag.vim
let g:ag_highlight=1
let g:grep_cmd_opts='--line-numbers --noheading'
let g:ag_format="%f:%l:%m"
cabbrev ag <c-r>=(getcmdtype()==':' && getcmdpos()==1 ? 'Ag' : 'ag')<CR>
if has ("Ag")
    copen 30
endif

" 快速移動函數頭尾
nmap <leader>] ]}
nmap <leader>[ [{

"設定vim -p 檔案上限，不然會有限制的開啟前部分的檔案，後面就沒看到了。
set tabpagemax=1000

nmap tl :tabnext<cr>
nmap th :tabprev<cr>
nmap tn :tabnew<cr>
nmap td :tabclose<cr>

let g:gitgutter_sign_added = '✚'
let g:gitgutter_sign_modified = '➡'
let g:gitgutter_sign_removed = '✘'
let g:gitgutter_sign_removed_first_line = '^^'
let g:gitgutter_sign_modified_removed = 'ww'
let g:gitgutter_max_signs = 50000

nmap <leader>w :call SearchWord()<CR>

" 顯示空白
nmap <space>s :call ShowTrailingWhitespace()<CR>
function ShowTrailingWhitespace()
highlight WhitespaceEOL ctermbg=red guibg=red
match WhitespaceEOL /\s\+$/
endfunction


vnoremap <C-a> "-y:echo 'text' @- 'has length' strlen(@-)<CR>"

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" FZF
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" List of buffers
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

let g:fzf_tmux_height = '20%'
let g:fzf_tmux_width = '20%'

"noremap <F12> <ESC>:FZF<CR>

nnoremap <silent> <Leader>o :call fzf#run({
      \   'sink':       'tabe',
      \   'options':     '-m',
      \   'tmux_width': '40%'
      \ })<CR>

let g:rg_command = '
  \ rg --column --line-number --no-heading --fixed-strings --ignore-case --no-ignore --hidden --follow --color "always"
  \ -g "*.{js,json,php,md,styl,jade,html,config,py,cpp,c,go,hs,rb,conf}"
  \ -g "!*.{min.js,swp,o,zip}"
  \ -g "!{.git,node_modules,vendor}/*" '

"noremap <F12> <ESC>:call fzf#vim#grep(g:rg_command .shellescape(<q-args>), 1, <bang>0)<CR>


" -----------------------------------------
"  ale.vim
"  disable particular linters
let g:ale_linters = {
\   'java': ['eslint'],
\}
" -----------------------------------------


" Z - cd to recent / frequent directories
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

highlight BookmarkSign ctermbg=NONE ctermfg=160
"highlight BookmarkLine ctermbg=194 ctermfg=NONE
let g:bookmark_sign = '⚑'
"let g:bookmark_highlight_lines = 1


" ctags mapping
map <Leader>rt :!ctags --extra=+f -R *<CR><CR>
map tt <c-]>
"map tt :TabExpand 2<CR>
map qq <c-t>
map <c-b> :tprevious<CR>
map <c-n> :tnext<CR>
"nnoremap <C-]> viwy:tab tag <C-R>"<CR>
"
"command -nargs=1 TabExpand call HandleTabTagExpand( <f-args> )
"let s:commentchar = """
"function HandleTabTagExpand(tagnumber)
"    let tagident = expand("<cword>")
"    redir @a
"    try
"        sil exe "tselect ".tagident
"    catch /^Vim(\a\+):E433:/ " no tag file
"        echom "No tag file found."
"        return
"    catch /^Vim(\a\+):E426:/ " tag not found
"        echom "Tag not found."
"        return
"    endtry
"    redir END
"    let tagresults = split(@a, "\n")
"    let tagmatches = []
"    let linenum = 0
"    for line in tagresults
"        if linenum % 3 != 1
"            " every third line contains the file names
"            let linenum = linenum + 1
"            continue
"        endif
"        " figure out where the filename actually starts
"        " (it's usually column 32, but it might be farther)
"        " one before 32 is 31, but index is 30 since arrays begin at zero
"        let filestart = 30
"        let c = line[filestart]
"        while (filestart < strlen(line))
"            let filestart = filestart + 1
"            if c == " "
"                break
"            endif
"            let c = line[filestart]
"        endwhile
"        " store the parsed match in an array
"        call add(tagmatches, strpart(line, filestart))
"        let linenum = linenum + 1
"    endfor
"    " navigate to the match specified by tagnumber
"    try
"        exe "tab drop ".tagmatches[a:tagnumber-1]
"    catch /^Vim(\a\+):E471:/ " argument required (means no tag found)
"        echom "Tag not found."
"    endtry
"    let done = 0
"    let matchcount = 0
"    let f_line = ""
"    while done < 1 && matchcount < 1000
"        sil exe "/".tagident
"        let f_line = getline(".")
"        let matchcount = matchcount + 1
"        if match(f_line, "^\s+".s:commentchar) < 0
"            let done = 1
"        endif
"    endwhile
"    let f_index = stridx( f_line, tagident )
"    sil exe "normal 0"
"    sil exe "normal ".f_index."l"
"endfunction

""設置標簽tags
set tags=./.tags;,.tags
"設置根據打開文件自動更換目錄
"set autochdir

" gutentags 搜索工程目錄的標志，當前文件路徑向上遞歸直到碰到這些文件/目錄名
let g:gutentags_project_root = ['.root', '.svn', '.git', '.hg', '.project']
" 所生成的數據文件的名稱
let g:gutentags_ctags_tagfile = '.tags'

" 同時開啟 ctags 和 gtags 支持：
let g:gutentags_modules = []
if executable('ctags')
    let g:gutentags_modules += ['ctags']
endif
if executable('gtags-cscope') && executable('gtags')
    let g:gutentags_modules += ['gtags_cscope']
endif

" 將自動生成的 ctags/gtags 文件全部放入 ~/.cache/tags 目錄中，避免污染工程目錄
let s:vim_tags = expand('~/.cache/tags')
let g:gutentags_cache_dir = s:vim_tags
" 檢測 ~/.cache/tags 不存在就新建 "
if !isdirectory(s:vim_tags)
   silent! call mkdir(s:vim_tags, 'p')
endif

" 配置 ctags 的參數
let g:gutentags_ctags_extra_args = ['--fields=+niazSl']
let g:gutentags_ctags_extra_args += ['--c++-kinds=+px']
let g:gutentags_ctags_extra_args += ['--c-kinds=+px']

" Get ctags version
let g:ctags_version = system('ctags --version')[0:8]

" 如果使用 universal ctags 需要增加下面一行
if g:ctags_version == "Universal"
  let g:gutentags_ctags_extra_args += ['--extras=+q', '--output-format=e-ctags']
endif

" 禁用 gutentags 自動加載 gtags 數據庫的行為
let g:gutentags_auto_add_gtags_cscope = 1
"Change focus to quickfix window after search (optional).
let g:gutentags_plus_switch = 1
"Enable advanced commands: GutentagsToggleTrace, etc.
let g:gutentags_define_advanced_commands = 1
let g:gutentags_trace = 0

let g:coc_node_path = "/home/shihyu/.mybin/node-v17.8.0-linux-x64//bin/node"

"cscope
"if has("cscope")
"    if executable('gtags-cscope') && executable('gtags')
"        "禁用原GscopeFind按鍵映射
"        let g:gutentags_plus_nomap = 1
"        "Find this C symbol 查找C語言符號，即查找函數名、宏、枚舉值等出現的地方
"        nmap <C-\>s :GscopeFind s <C-R>=expand("<cword>")<CR><CR>
"        "Find this difinition 查找函數、宏、枚舉等定義的位置，類似ctags所提供的功能
"        nmap <C-\>g :GscopeFind g <C-R>=expand("<cword>")<CR><CR>
"        "Find functions called by this function 查找本函數調用的函數
"        nmap <C-\>d :GscopeFind d <C-R>=expand("<cword>")<CR><CR>
"        "Find functions calling this function 查找調用本函數的函數
"        nmap <C-\>c :GscopeFind c <C-R>=expand("<cword>")<CR><CR>
"        "Find this text string 查找指定的字符串
"        nmap <C-\>t :GscopeFind t <C-R>=expand("<cword>")<CR><CR>
"        "Find this egrep pattern 查找egrep模式，相當於egrep功能，但查找速度快多了
"        nmap <C-\>e :GscopeFind e <C-R>=expand("<cword>")<CR><CR>
"        "Find this file 查找並打開文件，類似vim的能
"        nmap <C-\>f :GscopeFind f <C-R>=expand("<cfile>")<CR><CR>
"        "Find files #including this file 查找包含本文件的文件
"        nmap <C-\>i :GscopeFind i ^<C-R>=expand("<cfile>")<CR>$<CR>
"    else
"        set csto=1
"        set cst
"        set nocsverb
"        " add any database in current directory
"        if filereadable("cscope.out")
"            cs add cscope.out
"        endif
"        set csverb
"
"        nmap <C-\>s :cs find s <C-R>=expand("<cword>")<CR><CR>
"        nmap <C-\>g :cs find g <C-R>=expand("<cword>")<CR><CR>
"        nmap <C-\>d :cs find d <C-R>=expand("<cword>")<CR><CR>
"        nmap <C-\>c :cs find c <C-R>=expand("<cword>")<CR><CR>
"        nmap <C-\>t :cs find t <C-R>=expand("<cword>")<CR><CR>
"        nmap <C-\>e :cs find e <C-R>=expand("<cword>")<CR><CR>
"        nmap <C-\>f :cs find f <C-R>=expand("<cfile>")<CR><CR>
"        nmap <C-\>i :cs find i ^<C-R>=expand("<cfile>")<CR>$<CR>
"
"        nmap <C-F12> :cs add cscope.out<CR>
"        "F12用ctags生成tags
"        nmap <F12> :!ctags -R --c++-kinds=+p --fields=+ialS --extra=+q -f .tags<CR>
"        "--language-force=C++
"        nmap <S-F12> :!cscope -Rbkq<CR>
"        " cscope參數
"        "-R: 在生成索引文件時，搜索子目錄樹中的代碼
"        "-b: 只生成索引文件，不進入cscope的界面
"        "-d: 只調出cscope gui界面，不跟新cscope.out
"        "-k: 在生成索引文件時，不搜索/usr/include目錄
"        "-q: 生成cscope.in.out和cscope.po.out文件，加快cscope的索引速度
"        "-i: 如果保存文件列表的文件名不是cscope.files時，需要加此選項告訴cscope到哪兒去找源文件列表。可以使用"-"，表示由標准輸入獲得文件列表。
"        "-I dir: 在-I選項指出的目錄中查找頭文件
"        "-u: 掃描所有文件，重新生成交叉索引文件
"        "-C: 在搜索時忽略大小寫
"        "-P path: 在以相對路徑表示的文件前加上的path，這樣，你不用切換到你數據庫文件所在的目錄也可以使用
"    endif
"endif

let g:rainbow_active = 1
let g:rainbow_conf = {
\   'guifgs': ['darkorange3', 'seagreen3', 'royalblue3', 'firebrick'],
\   'ctermfgs': ['lightyellow', 'lightcyan','lightblue', 'lightmagenta'],
\   'operators': '_,_',
\   'parentheses': ['start=/(/ end=/)/ fold', 'start=/\[/ end=/\]/ fold', 'start=/{/ end=/}/ fold'],
\   'separately': {
\       '*': {},
\       'tex': {
\           'parentheses': ['start=/(/ end=/)/', 'start=/\[/ end=/\]/'],
\       },
\       'lisp': {
\           'guifgs': ['darkorange3', 'seagreen3', 'royalblue3', 'firebrick'],
\       },
\       'vim': {
\           'parentheses': ['start=/(/ end=/)/', 'start=/\[/ end=/\]/', 'start=/{/ end=/}/ fold', 'start=/(/ end=/)/ containedin=vimFuncBody', 'start=/\[/ end=/\]/ containedin=vimFuncBody', 'start=/{/ end=/}/ fold containedin=vimFuncBody'],
\       },
\       'html': {
\           'parentheses': ['start=/\v\<((area|base|br|col|embed|hr|img|input|keygen|link|menuitem|meta|param|source|track|wbr)[ >])@!\z([-_:a-zA-Z0-9]+)(\s+[-_:a-zA-Z0-9]+(\=("[^"]*"|'."'".'[^'."'".']*'."'".'|[^ '."'".'"><=`]*))?)*\>/ end=#</\z1># fold'],
\       },
\       'css': 0,
\   }
\}

" if hidden is not set, TextEdit might fail.
set hidden
" Some servers have issues with backup files, see #649
set nobackup
set nowritebackup
 
" You will have bad experience for diagnostic messages when it's default 4000.
set updatetime=300
 
" don't give |ins-completion-menu| messages.
set shortmess+=c
 
" always show signcolumns
set signcolumn=yes
 
" Use tab for trigger completion with characters ahead and navigate.
" Use command ':verbose imap <tab>' to make sure tab is not mapped by other plugin.
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"
 
function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction
 
" Use <c-space> to trigger completion.
inoremap <silent><expr> <c-space> coc#refresh()
 
" Use <cr> to confirm completion, `<C-g>u` means break undo chain at current position.
" Coc only does snippet and additional edit on confirm.
inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
" Or use `complete_info` if your vim support it, like:
" inoremap <expr> <cr> complete_info()["selected"] != "-1" ? "\<C-y>" : "\<C-g>u\<CR>"
 
" Use `[g` and `]g` to navigate diagnostics
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)
" Remap keys for gotos
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
 
" Use K to show documentation in preview window
nnoremap <silent> K :call <SID>show_documentation()<CR>
 
function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction
 
" Highlight symbol under cursor on CursorHold
autocmd CursorHold * silent call CocActionAsync('highlight')
 
" Remap for rename current word
nmap <leader>rn <Plug>(coc-rename)
 
" Remap for format selected region
xmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)
 
augroup mygroup
  autocmd!
  " Setup formatexpr specified filetype(s).
  autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
  " Update signature help on jump placeholder
  autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
augroup end
 
" Remap for do codeAction of selected region, ex: `<leader>aap` for current paragraph
xmap <leader>a  <Plug>(coc-codeaction-selected)
nmap <leader>a  <Plug>(coc-codeaction-selected)
 
" Remap for do codeAction of current line
nmap <leader>ac  <Plug>(coc-codeaction)
" Fix autofix problem of current line
nmap <leader>qf  <Plug>(coc-fix-current)
 
" Create mappings for function text object, requires document symbols feature of languageserver.
xmap if <Plug>(coc-funcobj-i)
xmap af <Plug>(coc-funcobj-a)
omap if <Plug>(coc-funcobj-i)
omap af <Plug>(coc-funcobj-a)
 
" Use `:Format` to format current buffer
command! -nargs=0 Format :call CocAction('format')
 
" Use `:Fold` to fold current buffer
command! -nargs=? Fold :call     CocAction('fold', <f-args>)
 
" use `:OR` for organize import of current buffer
command! -nargs=0 OR   :call     CocAction('runCommand', 'editor.action.organizeImport')
