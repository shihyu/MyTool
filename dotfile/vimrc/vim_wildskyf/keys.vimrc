" ========================================
" ================  Map  =================
" ========================================

" original
"    F2           : save session
"    F3           : load session
"    F8           : toggle tagbar
"    F10          : switch number on & off
"    F12          : switch number re & abs

" leader (<SPACE>)
"    p f          : ctrlP
"    <tab>        : next buffer

let mapleader = "\<Space>"
let g:ctrlp_map = '<leader>pf'
let g:minimap_toggle='<F5>'

nmap ZZ :x<cr>
vmap '' :w !pbcopy<CR><CR>
noremap  <Home> ^
nnoremap ; :
nnoremap <leader><Tab>   :bnext<CR>
nnoremap <leader><S-Tab> :bprevious<CR>
nnoremap <leader>tt      :TagbarToggle<CR>
nnoremap <leader><up>       :5winc +<CR>
nnoremap <leader><down>       :5winc -<CR>
nnoremap <leader><left>       :5winc <<CR>
nnoremap <leader><right>      :5winc ><CR>
nnoremap <F2>  :mksession! ~/.vim_session <CR>
nnoremap <F3>  :source ~/.vim_session <CR>
nnoremap <F10> :call NumberToggle()<CR>
nnoremap <F12> :call NumberToggleRe()<CR>
map k gk
map <UP> gk
map <C-k>  5gk
map <C-UP> 5gk
map j gj
map <DOWN> gj
map <C-j>  5gj
map <C-DOWN> 5gj
inoremap <Home> <ESC>^i

:set pastetoggle=<F9>

:command WQ wq
:command Wq wq
:command W w
:command Q q
:command Copythis call CopyThis()

function! NumberToggleRe()
	if(&relativenumber == 1)
		call SetNumber()
	else
		call SetRelativeNumber()
	endif
endfunc

function! SetNumber()
	set norelativenumber
	set number
endfunc

function! SetRelativeNumber()
	set relativenumber
	set nonumber
endfunc

function! NumberToggle()
	if(&relativenumber == 1 || &number == 1)
		set nonumber
		set norelativenumber
	else
		call SetNumber()
	endif
endfunc

function! CopyThis()
	%w !pbcopy
endfunc


" ===========================
" ======== TESTING ==========
" ===========================

" move line up/down
nnoremap - :m .+1<CR>==
nnoremap = :m .-2<CR>==
vnoremap - :m '>+1<CR>gv=gv
vnoremap = :m '<-2<CR>gv=gv

nnoremap <S-DOWN> :m .+1<CR>==
nnoremap <S-UP> :m .-2<CR>==
inoremap <S-DOWN> <Esc>:m .+1<CR>==gi
inoremap <S-UP> <Esc>:m .-2<CR>==gi
vnoremap <S-DOWN> :m '>+1<CR>gv=gv
vnoremap <S-UP> :m '<-2<CR>gv=gv

