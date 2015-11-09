syntax on
set ignorecase
set smartcase
set ru
set nu
set showcmd
set hlsearch
set cin
set smartindent
set nobackup
set laststatus=2

hi Comment ctermfg=red
iab fdd <C-R>=strftime("%Y/%m/%d")<CR>

autocmd BufRead,BufNewFile *.sh map <F10> :% w !bash<CR>
autocmd BufRead,BufNewFile *.pl map <F10> :% w !perl<CR>
autocmd BufRead,BufNewFile *.rb map <F10> :% w !ruby<CR>
augroup filetype
  au! BufRead,BufNewFile *.proto setfiletype proto
augroup end

set sw=4 tabstop=4 smarttab expandtab


let mapleader = "e"

nmap t <C-w>
nmap ,, :tabe %<CR>
nmap qq :q<CR>
nmap qa :wind q<CR>
nmap L Lzz
nmap <leader>h gT
nmap <leader>l gt
nmap <leader>/ /:<C-R>=expand("<cword>")<CR>(<CR>
imap jj <ESC>
imap jf <ESC>
imap fj <ESC>

"open A_test.X if current file name is A.X
"open A.X if current file name is A_test.X
function OpenCorrespondingFile()
    let d = split(expand("%"), '_test')
    if len(d) == 1
        let name = expand("%:r") . "_test." . expand("%:e")
    else
        let name = d[0] . d[1]
    endif
    exec 'vsplit ' name
endfunction

map ,v :call OpenCorrespondingFile()<C-M>

" TODO refactor
function OpenCorrespondingFileH()
    let d = split(expand("%"), '_test')
    if len(d) == 1
        let name = expand("%:r") . "_test." . expand("%:e")
    else
        let name = d[0] . d[1]
    endif
    exec 'split ' name
endfunction

map ,h :call OpenCorrespondingFileH()<C-M>
map ,n :call OpenCorrespondingFileH()<C-M>


"autocmd BufRead,BufNewFile *.lisp so ~/.vim/ftplugin/lisp/limp.vim
filetype plugin indent on
filetype plugin on

:set foldmethod=indent

"nnoremap <F12> :TlistToggle<CR>
nmap <F12> :TagbarToggle<CR>

"use pydiction
let g:pydiction_location = '~/.vim/pydiction/complete-dict'

" map clipboard to the default register
set clipboard=unnamed


"-----------------------------------------------------------
" Colors / Highlights
"-----------------------------------------------------------

" Use 256 colors
set t_Co=256
colorscheme wombat256
set cursorline cursorcolumn
hi CursorLine cterm=NONE ctermbg=darkyellow ctermfg=white
hi CursorColumn cterm=NONE ctermbg=darkyellow ctermfg=white
" highlight current line and add marker. To return the this line, use 'l
:nnoremap <silent> <Leader>L ml:execute 'match Search /\%'.line('.').'l/'<CR>

hi KeywordTODO ctermfg=DarkGreen
:syn match KeywordTODO "TODO"

" temporarily highlight keyword
hi KeywordTemp ctermfg=red
hi KeywordTemp2 ctermfg=darkgreen
hi KeywordTemp3 ctermfg=darkblue
nmap <leader>* :syn match KeywordTemp /\<<C-R>=expand("<cword>")<CR>\>/<CR>
nmap <leader>( :syn match KeywordTemp2 /\<<C-R>=expand("<cword>")<CR>\>/<CR>
nmap <leader>) :syn match KeywordTemp3 /\<<C-R>=expand("<cword>")<CR>\>/<CR>
nmap <leader>c :syn clear KeywordTemp<CR>:syn clear KeywordTemp2<CR>:syn clear KeywordTemp3<CR>

syn match BacktracePrefix /\v^#[0-9]+/
syn match BacktraceFileNum #\v[^ ]+/[^ ]+:[0-9]+$#
hi BacktraceFileNum ctermfg=darkgreen guifg=green
hi BacktracePrefix ctermfg=yellow guifg=yellow


" C/C++
function LoadCppMain()
    0r ~/.vim/template/production.cpp
    normal Gddkk
endfunction

autocmd BufNewFile *.cpp call LoadCppMain()

function LoadCMain()
    0r ~/.vim/template/production.c
    normal Gddkk
endfunction

autocmd BufNewFile *.c call LoadCMain()

" bash
function LoadBashTemplate()
    0r ~/.vim/template/bash.sh
    normal Gdd
endfunction

autocmd BufNewFile *.sh call LoadBashTemplate()


"-----------------------------------------------------------
" My functions
"-----------------------------------------------------------

" Used by ShowMatched()
" Wrap the command in a function to achieve a silent call.
function! GetMatched(pattern)
    let @/ = a:pattern
    execute "g/" . a:pattern . "/p"
    execute "normal! \<c-o>"
endfunction

" Used by ShowMatched()
" Open <filename> at <line_number> in the 'right place' according to <index>
function! OpenMatchedInNewWindow(filename, line_number, index)
    if a:index >= 12
        return
    endif

    if a:index % 6 == 0
        execute "tabe +" . a:line_number . " " . a:filename
    elseif a:index % 6 == 1
        execute "vsplit +" . a:line_number . " " . a:filename
    elseif a:index % 6 == 2
        execute "normal! \<c-w>l"
        execute "split +" . a:line_number . " " . a:filename
    elseif a:index % 6 == 3
        execute "normal! \<c-w>h"
        execute "split +" . a:line_number . " " . a:filename
    elseif a:index % 6 == 4
        execute "normal! \<c-w>l"
        execute "split +" . a:line_number . " " . a:filename
    elseif a:index % 6 == 5
        execute "normal! \<c-w>h"
        execute "split +" . a:line_number . " " . a:filename
    else
        " Ignore.
    endif

    " unfold all if fold is used.
    normal zR
endfunction

" Open a new tab with at most 6 windows where each window's cursor is at
" the matched pattern in current file.
function! ShowMatched(pattern)
    redir @a
    silent call GetMatched(a:pattern)
    redir END
    let alist = split(@a, "\n")

    " Filter
    let numbers = []
    for line in alist
        if match(line, '^\s*\d\+\s') < 0
            continue
        endif

        let num = substitute(line, '^\s*\(\d\+\)\s.*', '\1', "")
        if strlen(num) == 0
            continue
        endif

        call add(numbers, num)
    endfor

    if len(numbers) <= 1
        echo "No matched or only one matched."
        return
    endif

    let i = 0
    for line_number in numbers
        call OpenMatchedInNewWindow("%", line_number, i)
        let i += 1
    endfor
endfunction
" Open a new tab to show where the word under the cursor is.
nnoremap <silent> <Leader>f :call ShowMatched("\\<" . "<c-r><c-w>" . "\\>")<CR>$N
nnoremap <silent> <Leader>F :call ShowMatched(input("Search for: "))<CR>

" Open .h if it's a cpp file, and vice versa.
function! OpenComplementFile()
  let f = expand('%')
  let suffix = matchstr(f, '\.\a\+$')
  let pattern = suffix . "$"
  if suffix == '.h'
    let suffixes = ['.cpp', '.cc', '.mm', '.m', '.h']
    for suf in suffixes
      let target = substitute(f, pattern, suf, '')
      if filereadable(target)
        break
      endif
    endfor
  elseif suffix == '.cpp' || suffix == '.cc' || suffix == '.m' || suffix == '.mm'
    let target = substitute(f, pattern, '.h', '')
    if !filereadable(target)
      let tmp = target
      let target = substitute(tmp, '\v(.+)\..+', 'public/\1.h', '')
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

fun! ShowFuncName()
  let lnum = line(".")
  let col = col(".")
  echohl ModeMsg
  echo getline(search("^[^ \t#/]\\{2}.*[^:]\s*$", 'bW'))
  echohl None
  call search("\\%" . lnum . "l" . "\\%" . col . "c")
endfun
map F :call ShowFuncName() <CR>

" gj in vim
"let g:ackprg="gj_without_interaction"
"nnoremap <silent> <Leader>g :Ack<CR>
"nnoremap <silent> <Leader>G :Ack -d1 <C-R>=expand("<cword>")<CR> <CR>
"nnoremap <silent> <Leader>d :Ack -d2 <C-R>=expand("<cword>")<CR> <CR>

" C++ shortcut
imap sss const std::string& 


"-----------------------------------------------------------
" vundle
"-----------------------------------------------------------
set rtp+=~/.vim/bundle/vundle/
call vundle#rc()

" let Vundle manage Vundle
" required! 
Bundle 'gmarik/vundle'

" plugins on GitHub
Bundle 'mattn/webapi-vim'
Bundle 'mattn/gist-vim'
Bundle 'tpope/vim-fugitive'
Bundle 'scrooloose/syntastic'
Bundle 'mileszs/ack.vim'
Bundle 'fcamel/gj'

" plugins not on GitHub
Bundle 'git://github.com/majutsushi/tagbar'
"Bundle 'file:///home/fcamel/dev/personal/gj'

"-----------------------------------------------------------
" plugins settings
"-----------------------------------------------------------

" ctrlp setting
let g:ctrlp_working_path_mode = ''
let g:ctrlp_clear_cache_on_exit = 0
let g:ctrlp_max_files = 1000000
let g:ctrlp_user_command = 'find %s -type f'

" syntastics
"let g:syntastic_python_checkers = ['flake8', 'pep257', 'pep8', 'py3kwarn', 'pyflakes', 'pylama', 'pylint', 'python']

"-----------------------------------------------------------
" Customized setting
"-----------------------------------------------------------
so ~/.vimrc_private
